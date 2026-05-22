import 'package:uuid/uuid.dart';
import '../services/parser_service.dart';

enum GradingStatus { pending, grading, done, error }

class CriterionScore {
  final String criterionId;
  final String criterionName;
  final double maxPoints;
  final double score; // AI score
  double? overriddenScore; // teacher override

  double get effectiveScore => overriddenScore ?? score;
  bool get isOverridden => overriddenScore != null;

  CriterionScore({
    required this.criterionId,
    required this.criterionName,
    required this.maxPoints,
    required this.score,
    required this.feedback,
    this.overriddenScore,
  });

  final String feedback;

  factory CriterionScore.fromJson(Map<String, dynamic> json) => CriterionScore(
        criterionId: json['id']?.toString() ?? '',
        criterionName: json['name']?.toString() ?? '',
        maxPoints: (json['max_points'] as num?)?.toDouble() ?? 0,
        score: (json['score'] as num?)?.toDouble() ?? 0,
        feedback: json['feedback']?.toString() ?? '',
      );
}

class RequestResult {
  final int requestNumber;
  final String requestTitle;
  final double maxPoints;
  final double confidence; // AI confidence 0.0–1.0
  final List<CriterionScore> criteriaScores;
  final List<String> errorsFound;
  final String overallComment;

  // Computed from criteriaScores so teacher overrides are reflected
  double get totalScore => criteriaScores.isEmpty
      ? _fallbackTotal
      : criteriaScores.fold(0.0, (sum, c) => sum + c.effectiveScore);

  final double _fallbackTotal;

  RequestResult({
    required this.requestNumber,
    required this.requestTitle,
    required this.maxPoints,
    double totalScore = 0,
    required this.criteriaScores,
    required this.errorsFound,
    required this.overallComment,
    this.confidence = 1.0,
  }) : _fallbackTotal = totalScore;

  factory RequestResult.fromJson(
    Map<String, dynamic> json,
    int reqNum,
    String reqTitle,
    double maxPts,
  ) {
    final criteriaList = (json['criteria_scores'] as List<dynamic>? ?? [])
        .map((c) => CriterionScore.fromJson(c as Map<String, dynamic>))
        .toList();
    return RequestResult(
      requestNumber: reqNum,
      requestTitle: reqTitle,
      maxPoints: maxPts,
      totalScore: (json['total_score'] as num?)?.toDouble() ?? 0,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
      criteriaScores: criteriaList,
      errorsFound: (json['errors_found'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      overallComment: json['overall_comment']?.toString() ?? '',
    );
  }

  bool get needsReview => confidence < 0.7;
}

class LocalSubmission {
  final String id;
  final String fileName;
  final String content;
  final DateTime createdAt;
  GradingStatus status;
  List<RequestResult> results;
  String? errorMessage;

  LocalSubmission({
    String? id,
    required this.fileName,
    required this.content,
    DateTime? createdAt,
    this.status = GradingStatus.pending,
    this.results = const [],
    this.errorMessage,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  double get totalScore100 =>
      results.fold(0.0, (sum, r) => sum + r.totalScore);
  double get totalScore10 =>
      double.parse((totalScore100 / 10).toStringAsFixed(1));

  bool get hasLowConfidence => results.any((r) => r.needsReview);

  /// Số yêu cầu (request) tách được từ nội dung .txt.
  /// Dùng để cảnh báo user nếu file không có header chuẩn.
  int get parsedRequestCount => ParserService().parseRequests(content).length;

  /// True khi tất cả request đều fail (criteriaScores rỗng).
  /// Báo hiệu grading thực ra không thành công dù status=done.
  bool get allRequestsFailed =>
      results.isNotEmpty && results.every((r) => r.criteriaScores.isEmpty);

  /// Lỗi đầu tiên gặp khi chấm (từ overallComment có prefix "Loi khi cham:").
  /// Null nếu không có request nào lỗi.
  String? get firstGradingError {
    for (final r in results) {
      final c = r.overallComment;
      if (c.startsWith('Loi khi cham:') || c.startsWith('Lỗi')) {
        return c;
      }
    }
    return null;
  }
}
