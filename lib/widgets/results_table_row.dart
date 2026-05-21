import 'package:flutter/material.dart';
import '../models/submission.dart';

class ResultsTableRow extends StatelessWidget {
  final LocalSubmission submission;
  final int requestCount;
  final bool isSelected;
  final VoidCallback onTap;

  const ResultsTableRow({
    super.key,
    required this.submission,
    required this.requestCount,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final score10 = submission.totalScore10;
    final col = score10 >= 7
        ? const Color(0xFF1D9E75)
        : score10 >= 5
            ? const Color(0xFFBA7517)
            : const Color(0xFFE24B4A);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1D9E75).withValues(alpha: 0.06) : null,
          border: isSelected
              ? Border.all(color: const Color(0xFF1D9E75).withValues(alpha: 0.3))
              : null,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(children: [
          SizedBox(
            width: 180,
            child: Text(
              submission.fileName,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ...List.generate(requestCount, (i) {
            final res =
                submission.results.where((r) => r.requestNumber == i + 1).firstOrNull;
            return SizedBox(
              width: 70,
              child: Text(
                res != null ? res.totalScore.toStringAsFixed(1) : '-',
                style: const TextStyle(fontSize: 13),
                textAlign: TextAlign.center,
              ),
            );
          }),
          SizedBox(
            width: 70,
            child: Text(
              submission.totalScore100.toStringAsFixed(1),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: 60,
            child: Text(
              score10.toString(),
              style: TextStyle(
                  color: col, fontWeight: FontWeight.w700, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
        ]),
      ),
    );
  }
}
