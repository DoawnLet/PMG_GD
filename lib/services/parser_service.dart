class ParserService {
  /// Splits a student submission .txt into requests, keyed by request number.
  ///
  /// Recognised header formats (case-insensitive, optional markdown `#` prefix):
  /// - `Request 1:` / `Request 1.` / `Request 1)`
  /// - `Yêu cầu 1` / `Yeu cau 1` (with or without diacritics)
  /// - `YC1` / `YC 1` / `YC.1`
  /// - `Câu 1` / `Cau 1`
  /// - `Bài 1` / `Bai 1`
  /// - `Phần 1` / `Phan 1`
  Map<int, String> parseRequests(String content) {
    final result = <int, String>{};
    final pattern = RegExp(
      r'(?:^|\n)\s*#{0,6}\s*'
      r'(?:request|yêu\s*cầu|yeu\s*cau|yc|câu|cau|bài|bai|phần|phan)'
      r'\s*\.?\s*(\d+)\s*[:.\)\-–]',
      caseSensitive: false,
      multiLine: true,
    );
    final matches = pattern.allMatches(content).toList();
    for (var i = 0; i < matches.length; i++) {
      final match = matches[i];
      final num = int.tryParse(match.group(1) ?? '') ?? 0;
      if (num == 0) continue;
      final start = match.end;
      final end = i + 1 < matches.length ? matches[i + 1].start : content.length;
      final text = content.substring(start, end).trim();
      result[num] = text;
    }
    return result;
  }
}
