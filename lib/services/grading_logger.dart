import 'package:flutter/foundation.dart';

enum LogLevel { info, success, warning, error }

class LogEntry {
  final DateTime time;
  final LogLevel level;
  final String message;
  final String? submissionName;

  LogEntry({
    required this.level,
    required this.message,
    this.submissionName,
    DateTime? time,
  }) : time = time ?? DateTime.now();

  String get timeFormatted {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    final s = time.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

/// In-memory grading activity log. Kept in `AppProvider` so the UI can render
/// recent events; capped to avoid unbounded growth.
class GradingLogger extends ChangeNotifier {
  static const int _maxEntries = 500;
  final List<LogEntry> _entries = [];

  List<LogEntry> get entries => List.unmodifiable(_entries);
  int get length => _entries.length;

  void log(LogLevel level, String message, {String? submissionName}) {
    _entries.add(LogEntry(
      level: level,
      message: message,
      submissionName: submissionName,
    ));
    if (_entries.length > _maxEntries) {
      _entries.removeRange(0, _entries.length - _maxEntries);
    }
    notifyListeners();
  }

  void info(String message, {String? submissionName}) =>
      log(LogLevel.info, message, submissionName: submissionName);
  void success(String message, {String? submissionName}) =>
      log(LogLevel.success, message, submissionName: submissionName);
  void warning(String message, {String? submissionName}) =>
      log(LogLevel.warning, message, submissionName: submissionName);
  void error(String message, {String? submissionName}) =>
      log(LogLevel.error, message, submissionName: submissionName);

  void clear() {
    _entries.clear();
    notifyListeners();
  }
}
