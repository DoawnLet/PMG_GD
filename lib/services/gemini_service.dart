import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/rubric.dart';
import 'grading_logger.dart';

/// Thrown when Gemini returns 429 with a `retryDelay` longer than 60s — strong
/// signal the daily quota is exhausted rather than a transient per-minute throttle.
class QuotaExceededException implements Exception {
  final String message;
  QuotaExceededException(this.message);
  @override
  String toString() => 'QuotaExceededException: $message';
}

class GeminiService {
  static const _model = 'gemini-2.5-flash';
  static const _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';

  final GradingLogger? logger;
  GeminiService({this.logger});

  String _apiKey = '';
  void setApiKey(String key) => _apiKey = key.trim();
  bool get hasApiKey => _apiKey.isNotEmpty;

  Future<Map<String, dynamic>> gradeRequest({
    required RequestRubric rubric,
    required String studentAnswer,
    required String examContext,
    String? submissionName,
  }) async {
    if (_apiKey.isEmpty) throw Exception('API key chua duoc thiet lap');

    final prompt = _buildPrompt(rubric, studentAnswer, examContext);
    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.3,
        'maxOutputTokens': 8192,
        // Disable Gemini 2.5 Flash thinking so tokens go to the JSON output,
        // not internal reasoning that's discarded.
        'thinkingConfig': {'thinkingBudget': 0},
      },
    });

    // Retry on 429 (quota). Prefer Gemini's suggested retryDelay; fall back to
    // exponential backoff if not provided. Cap at 90s per attempt.
    const fallbackBackoffs = [
      Duration(seconds: 15),
      Duration(seconds: 30),
      Duration(seconds: 60),
    ];
    const maxAttempts = 4;
    late http.Response response;
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      logger?.info('YC${rubric.number}: goi Gemini (lan ${attempt + 1})',
          submissionName: submissionName);
      response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: body,
      );
      if (response.statusCode != 429) break;

      final suggested = _extractRetryDelay(utf8.decode(response.bodyBytes));
      // If Google says wait > 60s, the daily quota is exhausted — abort
      // immediately so we don't burn time retrying a known-broken endpoint.
      if (suggested != null && suggested.inSeconds > 60) {
        logger?.error(
          'YC${rubric.number}: Quota ngay da het (Google de nghi doi '
          '${suggested.inSeconds}s). Bo qua retry.',
          submissionName: submissionName,
        );
        throw QuotaExceededException(
          'Quota Gemini ngay da het. Doi reset hoac doi API key.',
        );
      }

      if (attempt == maxAttempts - 1) break;
      final wait = suggested ?? fallbackBackoffs[attempt];
      logger?.warning(
        'YC${rubric.number}: HTTP 429 - doi ${wait.inSeconds}s'
        '${suggested != null ? " (theo retryDelay cua Google)" : ""}',
        submissionName: submissionName,
      );
      await Future<void>.delayed(wait);
    }

    if (response.statusCode != 200) {
      final body = utf8.decode(response.bodyBytes);
      // Truncate to first 300 chars so the error message stays readable
      final trimmed = body.length > 300 ? '${body.substring(0, 300)}...' : body;
      throw Exception('Gemini API HTTP ${response.statusCode}: $trimmed');
    }

    final data =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

    final candidates = data['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      final block = data['promptFeedback']?['blockReason'];
      throw Exception(block != null
          ? 'Gemini chan noi dung: $block'
          : 'Gemini khong tra ve ket qua nao');
    }

    final cand = candidates.first as Map<String, dynamic>;
    final parts = (cand['content']?['parts']) as List?;
    if (parts == null || parts.isEmpty) {
      final reason = cand['finishReason'] ?? 'unknown';
      throw Exception('Gemini tra ve rong (finishReason=$reason)');
    }

    final content = parts.first['text'] as String? ?? '';
    if (content.isEmpty) {
      throw Exception('Gemini tra ve text rong');
    }

    // Strip markdown code fences if present. Handle truncated responses where
    // only the opening fence exists (Gemini hit maxOutputTokens mid-output).
    var cleaned = content.trim();
    final closedFence = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```').firstMatch(cleaned);
    if (closedFence != null) {
      cleaned = closedFence.group(1)!.trim();
    } else if (cleaned.startsWith('```')) {
      final nl = cleaned.indexOf('\n');
      cleaned = nl > 0 ? cleaned.substring(nl + 1).trim() : cleaned.substring(3).trim();
      if (cleaned.endsWith('```')) {
        cleaned = cleaned.substring(0, cleaned.length - 3).trim();
      }
    }

    final start = cleaned.indexOf('{');
    if (start < 0) {
      final preview = content.length > 200 ? '${content.substring(0, 200)}...' : content;
      throw Exception('Khong tim thay JSON trong response: $preview');
    }
    final lastBrace = cleaned.lastIndexOf('}');
    final payload = lastBrace > start
        ? cleaned.substring(start, lastBrace + 1)
        : _repairTruncatedJson(cleaned.substring(start));

    try {
      return jsonDecode(payload) as Map<String, dynamic>;
    } catch (e) {
      // Last-resort repair: try with a JSON repair on the same payload.
      try {
        return jsonDecode(_repairTruncatedJson(payload)) as Map<String, dynamic>;
      } catch (_) {
        final preview = payload.length > 200 ? '${payload.substring(0, 200)}...' : payload;
        throw Exception('JSON parse loi: $e | payload: $preview');
      }
    }
  }

  /// Attempts to repair JSON that was truncated mid-write by closing open
  /// strings/arrays/objects. Best-effort; failure throws downstream.
  String _repairTruncatedJson(String partial) {
    final buf = StringBuffer();
    final stack = <String>[];
    bool inString = false;
    bool escape = false;
    for (final ch in partial.split('')) {
      buf.write(ch);
      if (escape) {
        escape = false;
        continue;
      }
      if (ch == r'\') {
        escape = true;
        continue;
      }
      if (ch == '"') {
        inString = !inString;
        continue;
      }
      if (inString) continue;
      if (ch == '{') {
        stack.add('}');
      } else if (ch == '[') {
        stack.add(']');
      } else if (ch == '}' || ch == ']') {
        if (stack.isNotEmpty) stack.removeLast();
      }
    }
    if (inString) buf.write('"');
    // Close any open trailing comma / unfinished value with a null.
    var s = buf.toString().trimRight();
    if (s.endsWith(',')) s = '${s.substring(0, s.length - 1)} ';
    if (s.endsWith(':')) s = '${s}null';
    final result = StringBuffer(s);
    for (final closer in stack.reversed) {
      result.write(closer);
    }
    return result.toString();
  }

  /// Parses Gemini's 429 error body and returns the `retryDelay` from
  /// `error.details[].retryDelay` (format like "60s" or "12.5s"). Returns null
  /// if not found or unparseable.
  Duration? _extractRetryDelay(String body) {
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      final details = data['error']?['details'] as List?;
      if (details == null) return null;
      for (final d in details) {
        if (d is! Map) continue;
        final raw = d['retryDelay'];
        if (raw is! String) continue;
        final m = RegExp(r'(\d+(?:\.\d+)?)s').firstMatch(raw);
        if (m == null) continue;
        final secs = double.tryParse(m.group(1)!);
        if (secs == null) continue;
        return Duration(milliseconds: (secs * 1000).round());
      }
    } catch (_) {
      // Body wasn't JSON or shape mismatch — fall through to null.
    }
    return null;
  }

  String _buildPrompt(
      RequestRubric rubric, String studentAnswer, String examContext) {
    final criteriaDesc = rubric.criteria.map((c) {
      final partial = (c.maxPoints * 0.6).toStringAsFixed(1);
      return '- [${c.id}] ${c.name} (max ${c.maxPoints}pts):\n'
          '  Full (${c.maxPoints}pts): ${c.fullDesc}\n'
          '  Partial (~${partial}pts): ${c.acceptDesc}\n'
          '  Zero (0pts): ${c.failDesc}';
    }).join('\n');

    final errorsDesc = rubric.commonErrors.map((e) => '- $e').join('\n');

    return '''You are grading a project management exam (PMG201c). Be strict but fair.

EXAM CONTEXT:
$examContext

RUBRIC - Request ${rubric.number}: "${rubric.title}" (MAX ${rubric.maxPoints} points)
$criteriaDesc

COMMON ERRORS TO CHECK:
$errorsDesc

STUDENT ANSWER FOR REQUEST ${rubric.number}:
$studentAnswer

Instructions:
1. Grade each criterion using the rubric levels (can use decimals).
2. Identify which common errors appear in this answer.
3. total_score must equal the sum of all criteria scores.
4. Write feedback in Vietnamese.

Return ONLY valid JSON with no markdown fences:
{
  "criteria_scores": [
    {"id": "X.X", "name": "...", "max_points": X, "score": X.X, "feedback": "..."}
  ],
  "total_score": X.X,
  "confidence": 0.85,
  "errors_found": ["..."],
  "overall_comment": "..."
}
confidence is a float 0.0–1.0: how certain you are about this grading (low = answer is ambiguous or unclear).''';
  }
}
