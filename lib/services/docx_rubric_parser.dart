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
    if (docFile == null) throw Exception('File không hợp lệ: không tìm thấy word/document.xml');

    final xmlContent = utf8.decode(docFile.content as List<int>);
    final doc = XmlDocument.parse(xmlContent);

    final bodyEl = doc.descendants
        .whereType<XmlElement>()
        .firstWhere((e) => e.localName == 'body', orElse: () => throw Exception('Không tìm thấy body trong document.xml'));

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

        final isReqHeading = (_isHeading(style, 2) || _looksLikeRequestPara(el, text)) && text.isNotEmpty;
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
          final maxPts = match.group(3) != null ? double.parse(match.group(3)!) : 0.0;

          i++;
          List<Criterion> criteria = [];
          List<String> errors = [];
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

              if (expectingErrors || _isListItem(next, nextStyle)) {
                final cleaned = nextText.replaceFirst(RegExp(r'^[-•*]\s*'), '');
                if (cleaned.isNotEmpty) errors.add(cleaned);
              }

              i++;
            } else if (next.localName == 'tbl') {
              criteria = _parseTable(next);
              expectingErrors = true;
              i++;
            } else {
              i++;
            }
          }

          // If maxPoints not in heading, sum from criteria table
          final effectiveMax = maxPts > 0
              ? maxPts
              : criteria.fold(0.0, (s, c) => s + c.maxPoints);

          requests.add(RequestRubric(
            number: num,
            title: title,
            maxPoints: effectiveMax,
            criteria: criteria,
            commonErrors: errors,
          ));
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
    if (!RegExp(r'^(request|yêu\s*cầu|yeu\s*cau)\s+\d+', caseSensitive: false).hasMatch(text)) {
      return false;
    }
    // Must have bold run OR large font to avoid matching body text
    for (final rPr in p.descendants
        .whereType<XmlElement>()
        .where((e) => e.localName == 'rPr')) {
      if (rPr.children.whereType<XmlElement>().any((e) => e.localName == 'b')) {
        return true;
      }
      for (final sz in rPr.children
          .whereType<XmlElement>()
          .where((e) => e.localName == 'sz')) {
        final val = int.tryParse(sz.getAttribute('w:val') ?? sz.getAttribute('val') ?? '0') ?? 0;
        if (val >= 28) return true; // ≥14pt
      }
    }
    return false;
  }

  bool _isListItem(XmlElement p, String style) {
    final s = style.toLowerCase();
    if (s.contains('list') || s.contains('bullet')) return true;
    // Also detect via w:numPr (numbered/bulleted list)
    for (final child in p.children.whereType<XmlElement>()) {
      if (child.localName == 'pPr') {
        for (final pp in child.children.whereType<XmlElement>()) {
          if (pp.localName == 'numPr') return true;
        }
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
    for (final t in p.descendants.whereType<XmlElement>().where((e) => e.localName == 't')) {
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

    // Skip header row (index 0)
    for (int i = 1; i < rows.length; i++) {
      final cells = rows[i].children
          .whereType<XmlElement>()
          .where((e) => e.localName == 'tc')
          .toList();

      if (cells.length < 6) continue;

      final id = _getCellText(cells[0]);
      final name = _getCellText(cells[1]);
      final maxPtsStr = _getCellText(cells[2]);
      final fullDesc = _getCellText(cells[3]);
      final acceptDesc = _getCellText(cells[4]);
      final failDesc = _getCellText(cells[5]);

      if (id.isEmpty && name.isEmpty) continue;

      final maxPts = double.tryParse(maxPtsStr.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;

      criteria.add(Criterion(
        id: id,
        name: name,
        maxPoints: maxPts,
        fullDesc: fullDesc,
        acceptDesc: acceptDesc,
        failDesc: failDesc,
      ));
    }

    return criteria;
  }

  String _getCellText(XmlElement tc) {
    final buf = StringBuffer();
    bool firstPara = true;
    for (final p in tc.children.whereType<XmlElement>().where((e) => e.localName == 'p')) {
      if (!firstPara) buf.write('\n');
      for (final t in p.descendants.whereType<XmlElement>().where((e) => e.localName == 't')) {
        buf.write(t.innerText);
      }
      firstPara = false;
    }
    return buf.toString().trim();
  }
}
