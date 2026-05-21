import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/submission.dart';
import '../providers/app_provider.dart';

class RequestDetail extends StatelessWidget {
  final RequestResult result;
  final String? submissionId;

  const RequestDetail({super.key, required this.result, this.submissionId});

  Color _confidenceColor(double c) {
    if (c >= 0.8) return const Color(0xFF1D9E75);
    if (c >= 0.6) return const Color(0xFFBA7517);
    return const Color(0xFFE24B4A);
  }

  String _confidenceLabel(double c) {
    if (c >= 0.8) return 'Tin cay cao';
    if (c >= 0.6) return 'Can kiem tra';
    return 'Can xem lai';
  }

  Future<void> _showOverrideDialog(
    BuildContext context,
    CriterionScore cs,
    AppProvider provider,
  ) async {
    final controller = TextEditingController(
      text: cs.isOverridden
          ? cs.overriddenScore!.toString()
          : cs.score.toString(),
    );
    final newScore = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Chinh diem: ${cs.criterionId} — ${cs.criterionName}'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(
            'Diem AI: ${cs.score} / ${cs.maxPoints.toInt()}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Diem moi (0 – ${cs.maxPoints.toInt()})',
            ),
            autofocus: true,
          ),
        ]),
        actions: [
          if (cs.isOverridden)
            TextButton(
              onPressed: () => Navigator.pop(ctx, -1),
              child: const Text('Xoa override', style: TextStyle(color: Color(0xFFE24B4A))),
            ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Huy')),
          ElevatedButton(
            onPressed: () {
              final v = double.tryParse(controller.text.trim());
              if (v != null) Navigator.pop(ctx, v);
            },
            child: const Text('Luu'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (newScore == null || submissionId == null) return;
    if (newScore < 0) {
      provider.clearOverride(submissionId!, result.requestNumber, cs.criterionId);
    } else {
      provider.overrideScore(submissionId!, result.requestNumber, cs.criterionId, newScore);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();
    final confidenceColor = _confidenceColor(result.confidence);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Request header row
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF1D9E75).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text('YC${result.requestNumber}',
                style: const TextStyle(
                    color: Color(0xFF1D9E75),
                    fontWeight: FontWeight.w700,
                    fontSize: 11)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(result.requestTitle,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          ),
          // Confidence badge
          if (result.confidence < 1.0)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: confidenceColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(
                  result.needsReview ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                  size: 10,
                  color: confidenceColor,
                ),
                const SizedBox(width: 3),
                Text(
                  _confidenceLabel(result.confidence),
                  style: TextStyle(fontSize: 10, color: confidenceColor, fontWeight: FontWeight.w600),
                ),
              ]),
            ),
          Text(
            '${result.totalScore.toStringAsFixed(1)}/${result.maxPoints.toInt()}',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ]),

        if (result.overallComment.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(result.overallComment,
                style: const TextStyle(fontSize: 11, color: Colors.grey, height: 1.4)),
          ),

        if (result.errorsFound.isNotEmpty) ...[
          const SizedBox(height: 6),
          ...result.errorsFound.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('! ',
                      style: TextStyle(fontSize: 11, color: Color(0xFFE24B4A))),
                  Expanded(
                    child: Text(e,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFFE24B4A), height: 1.3)),
                  ),
                ]),
              )),
        ],

        const SizedBox(height: 6),
        // Criteria rows
        ...result.criteriaScores.map((cs) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(
                  width: 28,
                  child: Text(cs.criterionId,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1D9E75))),
                ),
                SizedBox(
                  width: 52,
                  child: Row(children: [
                    Text(
                      '${cs.effectiveScore}/${cs.maxPoints.toInt()}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: cs.isOverridden ? const Color(0xFFBA7517) : null,
                      ),
                    ),
                    if (cs.isOverridden)
                      const Padding(
                        padding: EdgeInsets.only(left: 2),
                        child: Icon(Icons.edit, size: 9, color: Color(0xFFBA7517)),
                      ),
                  ]),
                ),
                Expanded(
                  child: Text(cs.feedback,
                      style: const TextStyle(
                          fontSize: 11, color: Colors.grey, height: 1.3)),
                ),
                if (submissionId != null)
                  GestureDetector(
                    onTap: () => _showOverrideDialog(context, cs, provider),
                    child: const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Icon(Icons.edit_outlined, size: 12, color: Colors.grey),
                    ),
                  ),
              ]),
            )),

        const Divider(height: 16),
      ]),
    );
  }
}
