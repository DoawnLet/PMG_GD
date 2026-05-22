import 'package:flutter/foundation.dart';
import '../models/rubric.dart';
import '../models/submission.dart';
import '../services/docx_rubric_parser.dart';
import '../services/gemini_service.dart';
import '../services/grading_logger.dart';
import '../services/grading_service.dart';

class AppProvider extends ChangeNotifier {
  final logger = GradingLogger();
  late final GeminiService _gemini;
  late final GradingService _grading;

  List<LocalSubmission> submissions = [];
  bool isGrading = false;
  String gradingProgress = '';
  String apiKey = '';

  Rubric? _customRubric;
  bool isLoadingRubric = false;
  String? rubricError;

  Rubric? get rubric => _customRubric;
  bool get isCustomRubric => _customRubric != null;

  AppProvider() {
    _gemini = GeminiService(logger: logger);
    _grading = GradingService(_gemini, logger: logger);
  }

  Future<void> loadApiKey() async {}

  Future<void> saveApiKey(String key) async {
    apiKey = key;
    _gemini.setApiKey(key);
    notifyListeners();
  }

  bool get hasApiKey => _gemini.hasApiKey;

  Future<void> uploadRubric(String filePath) async {
    isLoadingRubric = true;
    rubricError = null;
    notifyListeners();

    try {
      _customRubric = DocxRubricParser().parse(filePath);
    } catch (e) {
      rubricError = e.toString();
    } finally {
      isLoadingRubric = false;
      notifyListeners();
    }
  }

  Future<void> resetRubric() async {
    _customRubric = null;
    rubricError = null;
    notifyListeners();
  }

  void addSubmission(String fileName, String content) {
    if (submissions.any((s) => s.fileName == fileName)) return;
    submissions.insert(0, LocalSubmission(fileName: fileName, content: content));
    notifyListeners();
  }

  void removeSubmission(String id) {
    submissions.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  void clearAll() {
    submissions.clear();
    notifyListeners();
  }

  void overrideScore(String submissionId, int requestNumber, String criterionId, double newScore) {
    final sub = submissions.firstWhere((s) => s.id == submissionId);
    final result = sub.results.firstWhere((r) => r.requestNumber == requestNumber);
    final criterion = result.criteriaScores.firstWhere((c) => c.criterionId == criterionId);
    criterion.overriddenScore = newScore.clamp(0, criterion.maxPoints);
    notifyListeners();
  }

  void clearOverride(String submissionId, int requestNumber, String criterionId) {
    final sub = submissions.firstWhere((s) => s.id == submissionId);
    final result = sub.results.firstWhere((r) => r.requestNumber == requestNumber);
    final criterion = result.criteriaScores.firstWhere((c) => c.criterionId == criterionId);
    criterion.overriddenScore = null;
    notifyListeners();
  }

  Future<void> gradeAll() async {
    if (isGrading || !hasApiKey || _customRubric == null) return;
    isGrading = true;
    notifyListeners();
    final pending = submissions.where((s) => s.status == GradingStatus.pending).toList();
    logger.info('=== Bat dau cham ${pending.length} bai ===');
    bool aborted = false;
    int graded = 0;
    for (final sub in pending) {
      sub.status = GradingStatus.grading;
      notifyListeners();
      try {
        await _grading.gradeSubmission(sub, _customRubric!, onProgress: (msg) {
          gradingProgress = '${sub.fileName}: $msg';
          notifyListeners();
        });
        if (sub.allRequestsFailed) {
          sub.status = GradingStatus.error;
          sub.errorMessage = sub.firstGradingError ?? 'Tat ca yeu cau cham deu loi';
        } else {
          graded++;
        }
      } on QuotaExceededException catch (e) {
        sub.status = GradingStatus.error;
        sub.errorMessage = e.toString();
        aborted = true;
        notifyListeners();
        break;
      } catch (e) {
        sub.status = GradingStatus.error;
        sub.errorMessage = e.toString();
      }
      notifyListeners();
    }
    isGrading = false;
    gradingProgress = '';
    if (aborted) {
      logger.error('=== Dung batch: quota Gemini het. Da cham $graded/${pending.length} bai ===');
    } else {
      logger.info('=== Hoan tat batch: $graded/${pending.length} bai thanh cong ===');
    }
    notifyListeners();
  }

  Future<void> gradeSingle(String id) async {
    if (!hasApiKey || _customRubric == null) return;
    final sub = submissions.firstWhere((s) => s.id == id);
    sub.status = GradingStatus.grading;
    notifyListeners();
    try {
      await _grading.gradeSubmission(sub, _customRubric!, onProgress: (msg) {
        gradingProgress = msg;
        notifyListeners();
      });
      if (sub.allRequestsFailed) {
        sub.status = GradingStatus.error;
        sub.errorMessage = sub.firstGradingError ?? 'Tat ca yeu cau cham deu loi';
      }
    } on QuotaExceededException catch (e) {
      sub.status = GradingStatus.error;
      sub.errorMessage = e.toString();
    } catch (e) {
      sub.status = GradingStatus.error;
      sub.errorMessage = e.toString();
    }
    gradingProgress = '';
    notifyListeners();
  }

  Map<String, dynamic> get stats {
    final done = submissions.where((s) => s.status == GradingStatus.done).toList();
    if (done.isEmpty) return {};
    final scores = done.map((s) => s.totalScore10).toList()..sort();
    return {
      'total': done.length,
      'avg': scores.reduce((a, b) => a + b) / scores.length,
      'max': scores.last,
      'min': scores.first,
      'pass': done.where((s) => s.totalScore10 >= 5.0).length,
    };
  }
}
