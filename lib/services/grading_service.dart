import '../models/rubric.dart';
import '../models/submission.dart';
import 'gemini_service.dart';
import 'grading_logger.dart';
import 'parser_service.dart';

class GradingService {
  final GeminiService _gemini;
  final GradingLogger? logger;
  final _parser = ParserService();

  GradingService(this._gemini, {this.logger});

  Future<void> gradeSubmission(
    LocalSubmission submission,
    Rubric rubric, {
    void Function(String message)? onProgress,
  }) async {
    logger?.info('Bat dau cham bai (${rubric.requests.length} yeu cau)',
        submissionName: submission.fileName);
    final requests = _parser.parseRequests(submission.content);
    logger?.info('Tach duoc ${requests.length}/${rubric.requests.length} yeu cau tu file',
        submissionName: submission.fileName);
    final results = <RequestResult>[];
    final examContext = _buildExamContext(rubric);

    for (var idx = 0; idx < rubric.requests.length; idx++) {
      final rubricRequest = rubric.requests[idx];
      // Gemini 2.5 Flash free tier = 5 RPM. 13s gives a safe 4.6 RPM cap.
      if (idx > 0) {
        await Future<void>.delayed(const Duration(seconds: 13));
      }
      final answer = requests[rubricRequest.number];
      if (answer == null || answer.isEmpty) {
        onProgress?.call('Request ${rubricRequest.number}: Khong tim thay cau tra loi');
        logger?.warning(
          'YC${rubricRequest.number}: khong tim thay cau tra loi trong file',
          submissionName: submission.fileName,
        );
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

      logger?.info(
        'Gui YC${rubricRequest.number} cho AI: rubric ${rubricRequest.criteria.length} tieu chi '
        '(max ${rubricRequest.maxPoints.toInt()}d) + bai lam ${answer.length} ky tu',
        submissionName: submission.fileName,
      );
      try {
        final json = await _gemini.gradeRequest(
          rubric: rubricRequest,
          studentAnswer: answer,
          examContext: examContext,
          submissionName: submission.fileName,
        );
        final result = RequestResult.fromJson(
          json,
          rubricRequest.number,
          rubricRequest.title,
          rubricRequest.maxPoints,
        );
        results.add(result);
        logger?.success(
          'YC${rubricRequest.number}: ${result.totalScore.toStringAsFixed(1)}/${rubricRequest.maxPoints.toInt()}d '
          '(confidence ${(result.confidence * 100).toInt()}%)',
          submissionName: submission.fileName,
        );
      } on QuotaExceededException catch (e) {
        // Daily quota exhausted — fill remaining YCs with placeholder error
        // results so the user knows nothing got graded, then re-throw so the
        // caller can abort the whole batch.
        results.add(_failedResult(rubricRequest, 'Loi khi cham: $e'));
        for (var j = idx + 1; j < rubric.requests.length; j++) {
          results.add(_failedResult(rubric.requests[j], 'Bo qua: quota het'));
        }
        submission.results = results;
        submission.status = GradingStatus.done;
        logger?.error(
          'Dung cham bai vi quota het (da xu ly ${idx + 1}/${rubric.requests.length} YC)',
          submissionName: submission.fileName,
        );
        rethrow;
      } catch (e) {
        final msg = e.toString();
        final short = msg.length > 150 ? '${msg.substring(0, 150)}...' : msg;
        logger?.error('YC${rubricRequest.number}: $short',
            submissionName: submission.fileName);
        results.add(_failedResult(rubricRequest, 'Loi khi cham: $e'));
      }
    }

    submission.results = results;
    submission.status = GradingStatus.done;
    final ok = results.where((r) => r.criteriaScores.isNotEmpty).length;
    logger?.info(
      'Hoan tat cham: $ok/${rubric.requests.length} YC thanh cong, '
      'tong ${submission.totalScore100.toStringAsFixed(1)}/100',
      submissionName: submission.fileName,
    );
  }

  RequestResult _failedResult(RequestRubric req, String comment) => RequestResult(
        requestNumber: req.number,
        requestTitle: req.title,
        maxPoints: req.maxPoints,
        totalScore: 0,
        criteriaScores: [],
        errorsFound: [],
        overallComment: comment,
      );

  String _buildExamContext(Rubric rubric) {
    final requestList = rubric.requests
        .map((r) => 'Request ${r.number}: ${r.title}')
        .join(', ');
    return '${rubric.examTitle}. Students answer ${rubric.requests.length} requests: $requestList. '
        'Answers are in English (students may be non-native English speakers, so minor grammar issues are acceptable).';
  }
}
