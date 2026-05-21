import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/rubric_data.dart';
import '../models/rubric.dart';
import '../models/submission.dart';
import '../services/gemini_service.dart';
import '../services/docx_rubric_parser.dart';
import '../services/grading_service.dart';

class AppProvider extends ChangeNotifier {
  final _gemini = GeminiService();
  late final GradingService _grading;

  List<LocalSubmission> submissions = [];
  bool isGrading = false;
  String gradingProgress = '';
  String apiKey = '';

  Rubric? _customRubric;
  bool isLoadingRubric = false;
  String? rubricError;

  Rubric get rubric => _customRubric ?? pmg201cRubric;
  bool get isCustomRubric => _customRubric != null;

  AppProvider() {
    _grading = GradingService(_gemini);
  }

  Future<void> loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    apiKey = prefs.getString('gemini_api_key') ?? '';
    if (apiKey.isNotEmpty) _gemini.setApiKey(apiKey);

    final rubricJson = prefs.getString('custom_rubric');
    if (rubricJson != null) {
      try {
        _customRubric = Rubric.fromJson(jsonDecode(rubricJson) as Map<String, dynamic>);
      } catch (_) {
        await prefs.remove('custom_rubric');
      }
    }

    notifyListeners();
  }

  Future<void> saveApiKey(String key) async {
    apiKey = key;
    _gemini.setApiKey(key);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_api_key', key);
    notifyListeners();
  }

  bool get hasApiKey => _gemini.hasApiKey;

  Future<void> uploadRubric(String filePath) async {
    isLoadingRubric = true;
    rubricError = null;
    notifyListeners();

    try {
      final parsed = DocxRubricParser().parse(filePath);
      _customRubric = parsed;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('custom_rubric', jsonEncode(parsed.toJson()));
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('custom_rubric');
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
    if (isGrading || !hasApiKey) return;
    isGrading = true;
    notifyListeners();
    final pending = submissions.where((s) => s.status == GradingStatus.pending).toList();
    for (final sub in pending) {
      sub.status = GradingStatus.grading;
      notifyListeners();
      try {
        await _grading.gradeSubmission(sub, rubric, onProgress: (msg) {
          gradingProgress = '${sub.fileName}: $msg';
          notifyListeners();
        });
      } catch (e) {
        sub.status = GradingStatus.error;
        sub.errorMessage = e.toString();
      }
      notifyListeners();
    }
    isGrading = false;
    gradingProgress = '';
    notifyListeners();
  }

  Future<void> gradeSingle(String id) async {
    if (!hasApiKey) return;
    final sub = submissions.firstWhere((s) => s.id == id);
    sub.status = GradingStatus.grading;
    notifyListeners();
    try {
      await _grading.gradeSubmission(sub, rubric, onProgress: (msg) {
        gradingProgress = msg;
        notifyListeners();
      });
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
