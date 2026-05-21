import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/rubric.dart';

class ClaudeService {
  static const _baseUrl = 'https://api.anthropic.com/v1/messages';

  String _apiKey = '';
  void setApiKey(String key) => _apiKey = key.trim();
  bool get hasApiKey => _apiKey.isNotEmpty;

  Future<Map<String, dynamic>> gradeRequest({
    required RequestRubric rubric,
    required String studentAnswer,
    required String examContext,
  }) async {
    if (_apiKey.isEmpty) throw Exception('API key chua duoc thiet lap');

    final prompt = _buildPrompt(rubric, studentAnswer, examContext);

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'x-api-key': _apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': 'claude-haiku-4-5-20251001',
        'max_tokens': 2048,
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
      }),
    );

    if (response.statusCode != 200) {
      final body = utf8.decode(response.bodyBytes);
      throw Exception('Claude API error ${response.statusCode}: $body');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final content = (data['content'] as List).first['text'] as String;

    final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(content);
    if (jsonMatch == null) throw Exception('Khong the parse JSON tu AI response');

    return jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
  }

  String _buildPrompt(RequestRubric rubric, String studentAnswer, String examContext) {
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
