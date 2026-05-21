import 'package:flutter/material.dart';
import '../../../models/submission.dart';
import '../../../widgets/dashboard_layout.dart';

/// Layout hai cột: danh sách bài đã chấm (trái) + bài cần xem lại (phải).
class SubmissionsSection extends StatelessWidget {
  final List<LocalSubmission> done;
  final List<LocalSubmission> lowConf;

  const SubmissionsSection({
    super.key,
    required this.done,
    required this.lowConf,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardTwoColumn(
      leftFlex: 2,
      left: DashboardSection(
        title: 'Bai da cham (${done.length})',
        child: GradedListContent(submissions: done),
      ),
      right: lowConf.isNotEmpty
          ? DashboardSection(
              title: 'Can xem lai (${lowConf.length})',
              trailing: const Icon(Icons.warning_amber_rounded,
                  size: 16, color: Color(0xFFE24B4A)),
              child: LowConfidenceContent(submissions: lowConf),
            )
          : null,
    );
  }
}

// ── Content widgets (có thể dùng độc lập) ────────────────────────────────────

class GradedListContent extends StatelessWidget {
  final List<LocalSubmission> submissions;
  const GradedListContent({super.key, required this.submissions});

  @override
  Widget build(BuildContext context) => Column(
        children: submissions
            .map((sub) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(children: [
                    Expanded(
                      child: Text(
                        sub.fileName,
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ScoreBadge(sub.totalScore10),
                    if (sub.hasLowConfidence)
                      const Padding(
                        padding: EdgeInsets.only(left: 6),
                        child: Icon(Icons.warning_amber_rounded,
                            size: 14, color: Color(0xFFBA7517)),
                      ),
                  ]),
                ))
            .toList(),
      );
}

class LowConfidenceContent extends StatelessWidget {
  final List<LocalSubmission> submissions;
  const LowConfidenceContent({super.key, required this.submissions});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AI khong tu tin vao ket qua cham',
            style: TextStyle(fontSize: 11, color: Color(0xFF888880)),
          ),
          const SizedBox(height: 10),
          ...submissions.map((sub) {
            final lowReqs = sub.results.where((r) => r.needsReview).toList();
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  sub.fileName,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                ...lowReqs.map((r) => Text(
                      'YC${r.requestNumber}: ${(r.confidence * 100).toInt()}% tin cay',
                      style: const TextStyle(fontSize: 11, color: Color(0xFFBA7517)),
                    )),
              ]),
            );
          }),
        ],
      );
}

/// Badge điểm màu xanh/cam/đỏ — public để dùng ở các màn hình khác.
class ScoreBadge extends StatelessWidget {
  final double score;
  const ScoreBadge(this.score, {super.key});

  Color get _color => score >= 8
      ? const Color(0xFF1D9E75)
      : score >= 5
          ? const Color(0xFFBA7517)
          : const Color(0xFFE24B4A);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: _color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          score.toStringAsFixed(1),
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _color),
        ),
      );
}
