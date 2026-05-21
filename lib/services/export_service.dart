import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import '../data/rubric_data.dart';
import '../models/submission.dart';

class ExportService {
  Future<bool> exportToExcel(List<LocalSubmission> submissions) async {
    final done = submissions.where((s) => s.status == GradingStatus.done).toList();
    if (done.isEmpty) return false;

    final excel = Excel.createExcel();
    final sheet = excel['Ket qua'];
    excel.delete('Sheet1');

    CellStyle headerStyle() => CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#1A1A18'),
          fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
          horizontalAlign: HorizontalAlign.Center,
        );

    const rubric = pmg201cRubric;

    // Title
    sheet.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('H1'));
    final title = sheet.cell(CellIndex.indexByString('A1'));
    title.value = TextCellValue('BAO CAO CHAM DIEM - ${rubric.examTitle.toUpperCase()}');
    title.cellStyle = CellStyle(
      bold: true, fontSize: 13,
      horizontalAlign: HorizontalAlign.Center,
      backgroundColorHex: ExcelColor.fromHexString('#1D9E75'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
    );
    sheet.setRowHeight(0, 26);
    sheet.cell(CellIndex.indexByString('A2')).value =
        TextCellValue('Ngay xuat: ${DateTime.now().toString().substring(0, 10)} | Tong bai: ${done.length}');

    // Headers
    final headers = [
      'STT', 'File bai lam',
      ...rubric.requests.map((r) => 'YC${r.number} (/${r.maxPoints.toInt()}d)'),
      'Tong /100', 'Diem /10',
    ];
    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 3));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = headerStyle();
    }
    sheet.setRowHeight(3, 32);

    // Data
    for (var i = 0; i < done.length; i++) {
      final sub = done[i];
      final row = i + 4;
      final cells = <CellValue>[
        IntCellValue(i + 1),
        TextCellValue(sub.fileName),
        ...rubric.requests.map((r) {
          final res = sub.results.where((x) => x.requestNumber == r.number).firstOrNull;
          return TextCellValue(res != null ? '${res.totalScore}/${r.maxPoints.toInt()}' : '-');
        }),
        DoubleCellValue(sub.totalScore100),
        DoubleCellValue(sub.totalScore10),
      ];
      for (var j = 0; j < cells.length; j++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: j, rowIndex: row)).value = cells[j];
      }
    }

    // Sheet 2: Detail
    final detail = excel['Chi tiet loi'];
    final dHeaders = ['File', 'Request', 'Tieu chi', 'Max', 'Diem', 'Nhan xet', 'Loi mac phai'];
    for (var i = 0; i < dHeaders.length; i++) {
      final cell = detail.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(dHeaders[i]);
      cell.cellStyle = headerStyle();
    }
    var dRow = 1;
    for (final sub in done) {
      for (final res in sub.results) {
        for (final cs in res.criteriaScores) {
          final row = [
            sub.fileName, 'Request ${res.requestNumber}',
            cs.criterionName, cs.maxPoints.toString(), cs.score.toString(),
            cs.feedback, res.errorsFound.join('; '),
          ];
          for (var j = 0; j < row.length; j++) {
            detail.cell(CellIndex.indexByColumnRow(columnIndex: j, rowIndex: dRow)).value =
                TextCellValue(row[j]);
          }
          dRow++;
        }
      }
    }

    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Luu file Excel',
      fileName: 'ChamDiem_PMG_${DateTime.now().toString().substring(0, 10)}.xlsx',
      allowedExtensions: ['xlsx'],
      type: FileType.custom,
    );
    if (savePath == null) return false;
    final bytes = excel.encode();
    if (bytes == null) return false;
    final path = savePath.endsWith('.xlsx') ? savePath : '$savePath.xlsx';
    await File(path).writeAsBytes(bytes);
    return true;
  }
}
