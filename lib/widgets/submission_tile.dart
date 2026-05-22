import 'package:flutter/material.dart';
import '../models/submission.dart';

class SubmissionTile extends StatelessWidget {
  final LocalSubmission submission;
  final Color statusColor;
  final String statusLabel;
  final VoidCallback? onGrade;
  final VoidCallback onDelete;

  const SubmissionTile({
    super.key,
    required this.submission,
    required this.statusColor,
    required this.statusLabel,
    required this.onGrade,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            const Icon(Icons.description_outlined, size: 20, color: Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(submission.fileName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  if (submission.status == GradingStatus.done)
                    Text(
                      'Tong: ${submission.totalScore100.toStringAsFixed(1)}/100 = ${submission.totalScore10}/10',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    )
                  else if (submission.errorMessage != null)
                    Text(submission.errorMessage!,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFFE24B4A)))
                  else
                    _ParsedBadge(count: submission.parsedRequestCount),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(statusLabel,
                  style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12)),
            ),
            if (onGrade != null) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.play_circle_outline, size: 20),
                tooltip: 'Cham bai nay',
                onPressed: onGrade,
              ),
            ],
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
              onPressed: onDelete,
            ),
          ]),
        ),
      );
}

class _ParsedBadge extends StatelessWidget {
  final int count;
  const _ParsedBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final isWarn = count == 0;
    final color = isWarn ? const Color(0xFFE24B4A) : const Color(0xFF888880);
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(children: [
        Icon(
          isWarn ? Icons.warning_amber_outlined : Icons.list_alt_outlined,
          size: 12,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          isWarn
              ? 'Khong phat hien yeu cau nao (can header "Request N:" hoac "YCN:")'
              : 'Phat hien $count yeu cau',
          style: TextStyle(fontSize: 12, color: color),
        ),
      ]),
    );
  }
}
