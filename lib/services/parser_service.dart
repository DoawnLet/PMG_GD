class ParserService {
  Map<int, String> parseRequests(String content) {
    final result = <int, String>{};
    final pattern = RegExp(
      r'(?:Request|Yêu\s*cầu)\s*(\d+)\s*:',
      caseSensitive: false,
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
