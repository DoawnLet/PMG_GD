import '../models/rubric.dart';
import '../models/submission.dart';
import 'gemini_service.dart';
import 'parser_service.dart';

class GradingService {
  final GeminiService _gemini;
  final _parser = ParserService();

  GradingService(this._gemini);

  Future<void> gradeSubmission(
    LocalSubmission submission,
    Rubric rubric, {
    void Function(String message)? onProgress,
  }) async {
    final requests = _parser.parseRequests(submission.content);
    final results = <RequestResult>[];
    final examContext = _buildExamContext(rubric);

    for (final rubricRequest in rubric.requests) {
      final answer = requests[rubricRequest.number];
      if (answer == null || answer.isEmpty) {
        onProgress?.call('Request ${rubricRequest.number}: Khong tim thay cau tra loi');
        results.add(RequestResult(
          requestNumber: rubricRequest.number,
          requestTitle: rubricRequest.title,
          maxPoints: rubricRequest.maxPoints,
          totalScore: 0,
          criteriaScores: rubricRequest.criteria
              .map((c) => CriterionScore(
                    criterionId: c.id,
                    criterionName: c.name,
                    maxPoints: c.maxPoints,
                    score: 0,
                    feedback: 'Khong co cau tra loi',
                  ))
              .toList(),
          errorsFound: ['Khong co cau tra loi cho yeu cau nay'],
          overallComment: 'Khong co cau tra loi',
        ));
        continue;
      }

      onProgress?.call('Dang cham Request ${rubricRequest.number}/${rubric.requests.length}...');

      try {
        final json = await _gemini.gradeRequest(
          rubric: rubricRequest,
          studentAnswer: answer,
          examContext: examContext,
        );
        results.add(RequestResult.fromJson(
          json,
          rubricRequest.number,
          rubricRequest.title,
          rubricRequest.maxPoints,
        ));
      } catch (e) {
        results.add(RequestResult(
          requestNumber: rubricRequest.number,
          requestTitle: rubricRequest.title,
          maxPoints: rubricRequest.maxPoints,
          totalScore: 0,
          criteriaScores: [],
          errorsFound: [],
          overallComment: 'Loi khi cham: $e',
        ));
      }
    }

    submission.results = results;
    submission.status = GradingStatus.done;
  }

  String _buildExamContext(Rubric rubric) {
    final requestList = rubric.requests
        .map((r) => 'Request ${r.number}: ${r.title}')
        .join(', ');
    return '${rubric.examTitle}. Students answer ${rubric.requests.length} requests: $requestList. '
        'Answers are in English (students may be non-native English speakers, so minor grammar issues are acceptable).';
  }
}
