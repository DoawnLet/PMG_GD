import 'package:flutter/material.dart';
import '../../../models/submission.dart';
import '../../../widgets/dashboard_layout.dart';

/// Biểu đồ phân phối điểm theo 10 bucket [0–1, 1–2, ..., 9–10].
class ScoreHistogramSection extends StatelessWidget {
  final List<LocalSubmission> submissions;

  const ScoreHistogramSection({super.key, required this.submissions});

  @override
  Widget build(BuildContext context) {
    return DashboardSection(
      title: 'Phan phoi diem',
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: _Histogram(submissions: submissions),
    );
  }
}

class _Histogram extends StatelessWidget {
  final List<LocalSubmission> submissions;
  const _Histogram({required this.submissions});

  @override
  Widget build(BuildContext context) {
    final counts = List.filled(10, 0);
    for (final sub in submissions) {
      final idx = (sub.totalScore10.clamp(0.0, 9.99)).floor();
      counts[idx]++;
    }
    final maxCount = counts.reduce((a, b) => a > b ? a : b);

    return Column(children: [
      SizedBox(
        height: 120,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(10, (i) {
            final count = counts[i];
            final ratio = maxCount == 0 ? 0.0 : count / maxCount;
            final color = i >= 8
                ? const Color(0xFF1D9E75)
                : i >= 5
                    ? const Color(0xFFBA7517)
                    : const Color(0xFFE24B4A);
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                  if (count > 0)
                    Text('$count',
                        style: const TextStyle(fontSize: 10, color: Color(0xFF888880))),
                  const SizedBox(height: 2),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    height: ratio * 100 + (count > 0 ? 4 : 0),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.8),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                    ),
                  ),
                ]),
              ),
            );
          }),
        ),
      ),
      const SizedBox(height: 4),
      Row(
        children: List.generate(
          10,
          (i) => Expanded(
            child: Text('$i–${i + 1}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 9, color: Color(0xFF888880))),
          ),
        ),
      ),
    ]);
  }
}
