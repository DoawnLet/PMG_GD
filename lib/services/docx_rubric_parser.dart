import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';
import '../models/rubric.dart';

/// Parses a .docx file into a [Rubric] model.
///
/// Expected template structure:
/// - Heading 1: Exam title
/// - Heading 2: "Request N: Title (Xpts)"
/// - Table (6 columns): ID | Name | MaxPoints | Full Credit | Partial Credit | No Credit
/// - Bullet list paragraphs after the table: Common errors
class DocxRubricParser {
  Rubric parse(String filePath) {
    final bytes = File(filePath).readAsBytesSync();
    final archive = ZipDecoder().decodeBytes(bytes);

    final docFile = archive.findFile('word/document.xml');
    if (docFile == null) {
      throw Exception('File không hợp lệ: không tìm thấy word/document.xml');
    }

    final xmlContent = utf8.decode(docFile.content as List<int>);
    final doc = XmlDocument.parse(xmlContent);

    final bodyEl = doc.descendants.whereType<XmlElement>().firstWhere(
      (e) => e.localName == 'body',
      orElse: () => throw Exception('Không tìm thấy body trong document.xml'),
    );

    final children = bodyEl.children.whereType<XmlElement>().toList();

    String examTitle = 'Custom Rubric';
    final requests = <RequestRubric>[];

    // State machine: walk through body elements
    int i = 0;
    while (i < children.length) {
      final el = children[i];

      if (el.localName == 'p') {
        final style = _getParaStyle(el);
        final text = _getParaText(el).trim();

        if (_isHeading(style, 1) && text.isNotEmpty) {
          examTitle = text;
          i++;
          continue;
        }

        final isReqHeading =
            (_isHeading(style, 2) || _looksLikeRequestPara(el, text)) &&
            text.isNotEmpty;
        if (isReqHeading) {
          // Flexible regex: separator and points are optional.
          // Supports "Request N", "Yêu cầu N", "Yeu cau N".
          final match = RegExp(
            r'(?:request|yêu\s*cầu|yeu\s*cau)\s+(\d+)\s*(?:[:\-–—]\s*)?(.+?)(?:\s*[\(\[（](\d+(?:\.\d+)?)\s*(?:pts?|đ|điểm|diem|points?)?[\)\]）])?$',
            caseSensitive: false,
          ).firstMatch(text);

          if (match == null) {
            i++;
            continue;
          }

          final num = int.parse(match.group(1)!);
          final title = match.group(2)!.trim();
          final maxPts = match.group(3) != null
              ? double.parse(match.group(3)!)
              : 0.0;

          i++;
          List<Criterion> criteria = [];
          List<String> errors = [];
          List<String> descLines = [];
          bool foundTable = false;
          bool expectingErrors = false;

          while (i < children.length) {
            final next = children[i];

            if (next.localName == 'p') {
              final nextStyle = _getParaStyle(next);
              final nextText = _getParaText(next).trim();

              // Next request heading or Heading 1 → stop
              if (_isHeading(nextStyle, 1)) break;
              if (_isHeading(nextStyle, 2)) break;
              if (_looksLikeRequestPara(next, nextText)) break;

              if (nextText.isEmpty) {
                i++;
                continue;
              }

              if (_isErrorHeader(nextText)) {
                expectingErrors = true;
                i++;
                continue;
              }

              if (expectingErrors) {
                final cleaned = nextText.replaceFirst(RegExp(r'^[-•*]\s*'), '');
                if (cleaned.isNotEmpty) errors.add(cleaned);
              } else if (!foundTable) {
                // Text before the criteria table = requirement description
                descLines.add(nextText);
              }

              i++;
            } else if (next.localName == 'tbl') {
              final parsed = _parseTable(next);
              criteria = _mergeCriteria(criteria, parsed);
              foundTable = true;
              expectingErrors = true;
              i++;
            } else {
              i++;
            }
          }

          final description = descLines.join('\n').trim();

          // If maxPoints not in heading, sum from criteria table
          final effectiveMax = maxPts > 0
              ? maxPts
              : criteria.fold(0.0, (s, c) => s + c.maxPoints);

          requests.add(
            RequestRubric(
              number: num,
              title: title,
              maxPoints: effectiveMax,
              description: description,
              criteria: criteria,
              commonErrors: errors,
            ),
          );
          continue;
        }
      }

      i++;
    }

    if (requests.isEmpty) {
      throw Exception(
        'Không tìm thấy Request nào.\n'
        'Heading 2 phải có dạng: "Request N: Tên yêu cầu (Xpts)"',
      );
    }

    return Rubric(examTitle: examTitle, requests: requests);
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  String _getParaStyle(XmlElement p) {
    for (final child in p.children.whereType<XmlElement>()) {
      if (child.localName == 'pPr') {
        for (final pp in child.children.whereType<XmlElement>()) {
          if (pp.localName == 'pStyle') {
            return pp.getAttribute('w:val') ?? pp.getAttribute('val') ?? '';
          }
        }
      }
    }
    return '';
  }

  bool _isHeading(String style, int level) {
    final s = style.toLowerCase().replaceAll(' ', '').replaceAll('-', '');
    if (s == 'heading$level') return true;
    if (s == 'heading${level}char') return true;
    // Vietnamese Word heading styles: "Tiêu đề 1", "Tiêu đề 2"
    if (s == 'tiêuđề$level' || s == 'tieude$level') return true;
    // Some templates use plain number style names
    if (s == '$level') return true;
    // Catch-all: style starts with "heading" and contains the level digit
    if (s.startsWith('heading') && s.contains('$level')) return true;
    return false;
  }

  /// True when a paragraph's text looks like a Request heading regardless of style.
  /// Used as fallback when the document doesn't use standard heading styles.
  bool _looksLikeRequestPara(XmlElement p, String text) {
    if (!RegExp(
      r'^(request|yêu\s*cầu|yeu\s*cau)\s+\d+',
      caseSensitive: false,
    ).hasMatch(text)) {
      return false;
    }
    // Must have bold run OR large font to avoid matching body text
    for (final rPr in p.descendants.whereType<XmlElement>().where(
      (e) => e.localName == 'rPr',
    )) {
      if (rPr.children.whereType<XmlElement>().any((e) => e.localName == 'b')) {
        return true;
      }
      for (final sz in rPr.children.whereType<XmlElement>().where(
        (e) => e.localName == 'sz',
      )) {
        final val =
            int.tryParse(
              sz.getAttribute('w:val') ?? sz.getAttribute('val') ?? '0',
            ) ??
            0;
        if (val >= 28) return true; // ≥14pt
      }
    }
    return false;
  }

  bool _isErrorHeader(String text) {
    final t = text.toLowerCase();
    return t.contains('common error') ||
        t.contains('lỗi thường') ||
        t.contains('loi thuong') ||
        t.contains('lỗi hay gặp') ||
        (t.contains('lỗi') && t.length < 30);
  }

  String _getParaText(XmlElement p) {
    final buf = StringBuffer();
    for (final t in p.descendants.whereType<XmlElement>().where(
      (e) => e.localName == 't',
    )) {
      buf.write(t.innerText);
    }
    return buf.toString();
  }

  List<Criterion> _parseTable(XmlElement tbl) {
    final rows = tbl.children
        .whereType<XmlElement>()
        .where((e) => e.localName == 'tr')
        .toList();

    final criteria = <Criterion>[];
    if (rows.isEmpty) return criteria;

    // Collect all row texts. Detect if row 0 is a header (contains keywords like
    // "tiêu chí", "điểm", "đánh giá") — skip it if so. Otherwise, treat row 0 as data.
    final allRows = rows
        .map(
          (row) => row.children
              .whereType<XmlElement>()
              .where((e) => e.localName == 'tc')
              .map(_getCellText)
              .toList(),
        )
        .where((r) => r.isNotEmpty)
        .toList();

    if (allRows.isEmpty) return criteria;

    final firstRowText = allRows.first.join(' ').toLowerCase();
    final hasHeader = firstRowText.contains('tiêu chí') ||
        firstRowText.contains('tieu chi') ||
        firstRowText.contains('điểm') && firstRowText.contains('đạt') ||
        firstRowText.contains('full credit') ||
        firstRowText.contains('partial credit');

    final dataRows = hasHeader ? allRows.skip(1).toList() : allRows;
    if (dataRows.isEmpty) return criteria;

    // Detect dedicated score column starting from col 1 (some templates combine
    // ID+Name in col 0, others have separate ID col 0 / Name col 1).
    final colCount = dataRows
        .map((r) => r.length)
        .reduce((a, b) => a > b ? a : b);
    int scoreCol = -1;
    for (int col = 1; col < colCount; col++) {
      int hits = 0;
      for (final row in dataRows) {
        if (col < row.length && _isShortScore(row[col])) hits++;
      }
      if (hits > dataRows.length * 0.5) {
        scoreCol = col;
        break;
      }
    }

    for (final texts in dataRows) {
      String id;
      String name;
      double maxPts;

      if (scoreCol == 1) {
        // 2-col or 5-col format: [ID + Name combined] | [Score] | ...
        final extracted = _splitIdName(texts[0]);
        id = extracted.$1;
        name = extracted.$2;
        maxPts = _tryParseScore(texts[scoreCol]) ?? 0;
      } else if (scoreCol >= 2) {
        // Legacy 6-col format: [ID] | [Name] | [Score] | [Full] | [Partial] | [No credit]
        id = texts[0];
        name = texts.length > 1 ? texts[1] : '';
        maxPts = _tryParseScore(texts[scoreCol]) ?? 0;
        final cleaned = _splitNameScore(name).$1;
        if (cleaned.isNotEmpty) name = cleaned;
      } else {
        // No dedicated score column — try to extract from name
        final extracted = _splitIdName(texts[0]);
        id = extracted.$1;
        name = extracted.$2;
        final (n, s) = _splitNameScore(name);
        if (s > 0) {
          name = n;
          maxPts = s;
        } else {
          maxPts = 0;
        }
      }

      // Build description columns: everything from col 1 onwards except scoreCol
      final descs = <String>[];
      for (int c = 1; c < texts.length; c++) {
        if (c == scoreCol) continue;
        descs.add(texts[c]);
      }
      final fullDesc = descs.isNotEmpty ? descs[0] : '';
      final acceptDesc = descs.length > 1 ? descs[1] : '';
      final failDesc = descs.length > 2 ? descs[2] : '';

      if (id.isEmpty && name.isEmpty) continue;
      if (_isSummaryRow(name)) continue;

      criteria.add(
        Criterion(
          id: id,
          name: name,
          maxPoints: maxPts,
          fullDesc: fullDesc,
          acceptDesc: acceptDesc,
          failDesc: failDesc,
        ),
      );
    }

    return criteria;
  }

  /// Detects summary rows like "TỔNG ĐIỂM", "TỔNG", "TOTAL" that should not be
  /// included in the criteria list (they're row totals, not actual criteria).
  bool _isSummaryRow(String name) {
    final n = name.toLowerCase().trim();
    if (n.isEmpty) return false;
    return n.startsWith('tổng') ||
        n.startsWith('tong') ||
        n.startsWith('total') ||
        n == 'sum';
  }

  /// Splits "1.1 Tên dự án rõ ràng" into ("1.1", "Tên dự án rõ ràng").
  /// If no ID prefix found, returns ('', whole_string).
  (String, String) _splitIdName(String raw) {
    final trimmed = raw.trim();
    final match = RegExp(r'^(\d+(?:\.\d+)*)\s+(.+)$', dotAll: true).firstMatch(trimmed);
    if (match != null) {
      return (match.group(1)!, match.group(2)!.trim());
    }
    return ('', trimmed);
  }

  /// Merges criteria from multiple tables. Keys by id; for duplicates, picks the
  /// longer name, non-zero score, and longer descriptions.
  List<Criterion> _mergeCriteria(List<Criterion> a, List<Criterion> b) {
    if (a.isEmpty) return b;
    if (b.isEmpty) return a;
    final map = <String, Criterion>{};
    int idx = 0;
    final order = <String>[];
    void put(Criterion c) {
      final key = c.id.isNotEmpty ? c.id : 'idx_${idx++}_${c.name}';
      final existing = map[key];
      if (existing == null) {
        map[key] = c;
        order.add(key);
      } else {
        map[key] = Criterion(
          id: existing.id.isNotEmpty ? existing.id : c.id,
          name: c.name.length > existing.name.length ? c.name : existing.name,
          maxPoints: existing.maxPoints > 0 ? existing.maxPoints : c.maxPoints,
          fullDesc: c.fullDesc.length > existing.fullDesc.length ? c.fullDesc : existing.fullDesc,
          acceptDesc: c.acceptDesc.length > existing.acceptDesc.length ? c.acceptDesc : existing.acceptDesc,
          failDesc: c.failDesc.length > existing.failDesc.length ? c.failDesc : existing.failDesc,
        );
      }
    }
    for (final c in a) {
      put(c);
    }
    for (final c in b) {
      put(c);
    }
    return order.map((k) => map[k]!).toList();
  }

  /// True when [text] looks like a standalone score cell: ≤8 chars, numeric, 0 < value ≤ 100.
  bool _isShortScore(String text) {
    final t = text.trim();
    if (t.isEmpty || t.length > 8) return false;
    final val = _tryParseScore(t);
    return val != null && val > 0 && val <= 100;
  }

  /// Parses a numeric score from text like "2", "2đ", "2.5 điểm". Returns null on failure.
  double? _tryParseScore(String text) {
    final cleaned = text.trim().replaceAll(RegExp(r'[^\d.]'), '');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  /// Splits a criterion name that has a trailing score into (cleanName, score).
  /// "Tên dự án rõ ràng và phù hợp 2đ" → ("Tên dự án rõ ràng và phù hợp", 2.0)
  /// "Không có score" → ("Không có score", 0.0)
  (String, double) _splitNameScore(String raw) {
    final match = RegExp(
      r'[\s\t]*[\(\[（]?\s*(\d+(?:\.\d+)?)\s*(?:đ|d|điểm|diem|pts?|points?)[\s\)\]）]*$',
      caseSensitive: false,
    ).firstMatch(raw);
    if (match != null) {
      final score = double.tryParse(match.group(1)!) ?? 0;
      final name = raw.substring(0, match.start).trim();
      if (name.isNotEmpty) return (name, score);
    }
    return (raw.trim(), 0);
  }

  String _getCellText(XmlElement tc) {
    final buf = StringBuffer();
    bool firstPara = true;
    for (final p in tc.children.whereType<XmlElement>().where(
      (e) => e.localName == 'p',
    )) {
      if (!firstPara) buf.write('\n');
      for (final t in p.descendants.whereType<XmlElement>().where(
        (e) => e.localName == 't',
      )) {
        buf.write(t.innerText);
      }
      firstPara = false;
    }
    return buf.toString().trim();
  }
}
