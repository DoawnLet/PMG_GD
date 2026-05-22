import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/submission.dart';
import '../../services/export_service.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/results_table_header.dart';
import '../../widgets/results_table_row.dart';
import '../../widgets/request_detail.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});
  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  LocalSubmission? _selected;
  bool _exporting = false;

  Future<void> _export(List<LocalSubmission> subs) async {
    setState(() => _exporting = true);
    final ok = await ExportService().exportToExcel(subs, context.read<AppProvider>().rubric);
    setState(() => _exporting = false);
    if (mounted && ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Xuat Excel thanh cong!'),
          backgroundColor: Color(0xFF1D9E75),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<AppProvider>(builder: (_, p, _) {
      final done =
          p.submissions.where((s) => s.status == GradingStatus.done).toList();
      final s = p.stats;
      return Column(children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: const Border(
                bottom:
                    BorderSide(color: Color(0xFFD3D1C7), width: 0.5)),
          ),
          child: Row(children: [
            const Icon(Icons.bar_chart_outlined, size: 22),
            const SizedBox(width: 10),
            Text('Ket qua cham diem', style: theme.textTheme.headlineMedium),
            const Spacer(),
            ElevatedButton.icon(
              icon: _exporting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.download_outlined, size: 16),
              label: const Text('Xuat Excel'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D9E75)),
              onPressed:
                  done.isEmpty || _exporting ? null : () => _export(p.submissions),
            ),
          ]),
        ),

        if (s.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Row(children: [
              StatCard('Da cham', '${s['total']}',
                  color: const Color(0xFF1A1A18)),
              const SizedBox(width: 10),
              StatCard('Diem TB', (s['avg'] as double).toStringAsFixed(1),
                  color: const Color(0xFF1D9E75)),
              const SizedBox(width: 10),
              StatCard('Cao nhat', (s['max'] as double).toStringAsFixed(1),
                  color: const Color(0xFF1D9E75)),
              const SizedBox(width: 10),
              StatCard('Thap nhat', (s['min'] as double).toStringAsFixed(1),
                  color: const Color(0xFFE24B4A)),
              const SizedBox(width: 10),
              StatCard('Dat (>=5)', '${s['pass']}',
                  color: const Color(0xFFBA7517)),
            ].map((w) => Expanded(child: w)).toList()),
          ),

        const SizedBox(height: 12),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                flex: 3,
                child: Card(
                  child: done.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox_outlined,
                                  size: 48, color: Colors.grey[300]),
                              const SizedBox(height: 8),
                              Text('Chua co bai nao duoc cham',
                                  style: TextStyle(color: Colors.grey[400])),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: done.length + 1,
                          itemBuilder: (_, i) {
                            if (i == 0) {
                              return ResultsTableHeader(
                                  requestCount: p.rubric?.requests.length ?? 0);
                            }
                            final sub = done[i - 1];
                            return ResultsTableRow(
                              submission: sub,
                              requestCount: p.rubric?.requests.length ?? 0,
                              isSelected: _selected?.id == sub.id,
                              onTap: () => setState(() => _selected = sub),
                            );
                          },
                        ),
                ),
              ),
              if (_selected != null) ...[
                const SizedBox(width: 16),
                SizedBox(
                  width: 320,
                  child: Card(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(
                              child: Text(_selected!.fileName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14)),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 16),
                              onPressed: () =>
                                  setState(() => _selected = null),
                            ),
                          ]),
                          Text(
                            '${_selected!.totalScore100.toStringAsFixed(1)}/100  =>  ${_selected!.totalScore10}/10',
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1D9E75)),
                          ),
                          const Divider(height: 20),
                          ..._selected!.results.map((res) => RequestDetail(
                                result: res,
                                submissionId: _selected!.id,
                              )),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ]),
          ),
        ),
      ]);
    });
  }
}
