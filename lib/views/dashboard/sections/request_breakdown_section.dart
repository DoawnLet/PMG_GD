import 'package:flutter/material.dart';
import '../../../models/rubric.dart';
import '../../../models/submission.dart';
import '../../../widgets/dashboard_layout.dart';

/// Bar ngang thể hiện điểm TB từng yêu cầu (YC1–YCn).
class RequestBreakdownSection extends StatelessWidget {
  final List<LocalSubmission> submissions;
  final Rubric rubric;

  const RequestBreakdownSection({
    super.key,
    required this.submissions,
    required this.rubric,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardSection(
      title: 'Diem trung binh theo yeu cau',
      child: _BreakdownBars(submissions: submissions, rubric: rubric),
    );
  }
}

class _BreakdownBars extends StatelessWidget {
  final List<LocalSubmission> submissions;
  final Rubric rubric;

  const _BreakdownBars({required this.submissions, required this.rubric});

  @override
  Widget build(BuildContext context) {
    final rows = rubric.requests.map((req) {
      final scores = submissions
          .expand((s) => s.results.where((r) => r.requestNumber == req.number))
          .map((r) => r.totalScore)
          .toList();

      final avg = scores.isEmpty
          ? 0.0
          : scores.reduce((a, b) => a + b) / scores.length;
      final pct = req.maxPoints == 0 ? 0.0 : avg / req.maxPoints;

      return (req: req, avg: avg, pct: pct);
    }).toList();

    return Column(
      children: rows.map((row) {
        final color = row.pct >= 0.8
            ? const Color(0xFF1D9E75)
            : row.pct >= 0.5
                ? const Color(0xFFBA7517)
                : const Color(0xFFE24B4A);

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(children: [
            SizedBox(
              width: 32,
              child: Text(
                'YC${row.req.number}',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: LayoutBuilder(builder: (_, constraints) {
                return Stack(children: [
                  Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD3D1C7).withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOut,
                    height: 10,
                    width: constraints.maxWidth * row.pct.clamp(0.0, 1.0),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ]);
              }),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 76,
              child: Text(
                '${row.avg.toStringAsFixed(1)}/${row.req.maxPoints.toInt()}  '
                '(${(row.pct * 100).toStringAsFixed(0)}%)',
                style: const TextStyle(fontSize: 11, color: Color(0xFF888880)),
                textAlign: TextAlign.right,
              ),
            ),
          ]),
        );
      }).toList(),
    );
  }
}
