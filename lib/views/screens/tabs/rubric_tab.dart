import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_provider.dart';
import '../../../models/rubric.dart';

class RubricTab extends StatefulWidget {
  const RubricTab({super.key});

  @override
  State<RubricTab> createState() => _RubricTabState();
}

class _RubricTabState extends State<RubricTab> {
  Future<void> _pickRubric() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['docx'],
    );
    if (result == null || result.files.single.path == null) return;
    if (!mounted) return;
    await context.read<AppProvider>().uploadRubric(result.files.single.path!);
    if (!mounted) return;
    final error = context.read<AppProvider>().rubricError;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Loi: $error'),
          backgroundColor: const Color(0xFFE24B4A),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Da tai rubric thanh cong'),
          backgroundColor: Color(0xFF1D9E75),
        ),
      );
    }
  }

  Future<void> _resetRubric() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xoa rubric?'),
        content: const Text('Xoa rubric tuy chinh va yeu cau tai len lai?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE24B4A),
            ),
            child: const Text('Xoa'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<AppProvider>().resetRubric();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<AppProvider>(
      builder: (_, p, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Rubric', style: theme.textTheme.titleMedium),
                          const SizedBox(width: 8),
                          _StatusBadge(isCustom: p.isCustomRubric),
                          const Spacer(),
                          ElevatedButton.icon(
                            onPressed: p.isLoadingRubric ? null : _pickRubric,
                            icon: p.isLoadingRubric
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.upload_file_outlined,
                                    size: 16,
                                  ),
                            label: Text(
                              p.isLoadingRubric
                                  ? 'Dang xu ly...'
                                  : 'Tai len .docx',
                            ),
                          ),
                          if (p.isCustomRubric) ...[
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: _resetRubric,
                              icon: const Icon(Icons.delete_outline, size: 16),
                              label: const Text('Xoa'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFE24B4A),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (p.isCustomRubric) ...[
                        const SizedBox(height: 8),
                        Text(
                          p.rubric!.examTitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${p.rubric!.requests.length} yeu cau · ${p.rubric!.totalPoints.toInt()} diem',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                      if (p.rubricError != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 14,
                              color: Color(0xFFE24B4A),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                p.rubricError!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFE24B4A),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (!p.isCustomRubric) _EmptyRubricHint(onUpload: _pickRubric),
              if (p.isCustomRubric) ...[
                Text(
                  'Chi tiết điểm chấm bài: ${p.rubric!.examTitle}',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                ...p.rubric!.requests.map((req) => _RequestCard(req: req)),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ── Request expansion card ─────────────────────────────────────────────────

class _RequestCard extends StatelessWidget {
  final RequestRubric req;
  const _RequestCard({required this.req});

  //Kiểm tra request đọc lấy điểm tổng
  double get _totalPoints {
    return req.criteria.fold(0.0, (s, c) => s + c.maxPoints);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF1D9E75).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'YC${req.number}',
                style: const TextStyle(
                  color: Color(0xFF1D9E75),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(req.title, style: theme.textTheme.titleMedium),
            ),
            const SizedBox(width: 8),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (req.description.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F7FF),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFFB8D4F0),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      req.description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF334A6B),
                      ),
                    ),
                  ),
                ],
                ...req.criteria.map((c) => _CriterionRow(c: c)),
                if (req.criteria.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D9E75).withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFF1D9E75).withValues(alpha: 0.25),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tổng điểm yêu cầu',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1D9E75),
                          ),
                        ),
                        //Kiểm tra tại đây tại sao lại bị lỗi không tính điểm total
                        Text(
                          '${_totalPoints.toInt()}đ',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1D9E75),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (req.commonErrors.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Loi thuong gap:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFE24B4A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...req.commonErrors.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '• ',
                            style: TextStyle(
                              color: Color(0xFFE24B4A),
                              fontSize: 12,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              e,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFFE24B4A),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Criterion card ─────────────────────────────────────────────────────────

class _CriterionRow extends StatelessWidget {
  final Criterion c;
  const _CriterionRow({required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F4F0),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD3D1C7), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (c.id.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D9E75).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    c.id,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1D9E75),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  c.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${c.maxPoints.toInt()}d',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1D9E75),
                ),
              ),
            ],
          ),
          if (c.fullDesc.isNotEmpty) ...[
            const SizedBox(height: 8),
            _ScoreLevel(
              label: 'Full',
              color: const Color(0xFF1D9E75),
              text: c.fullDesc,
            ),
          ],
          if (c.acceptDesc.isNotEmpty) ...[
            const SizedBox(height: 4),
            _ScoreLevel(
              label: 'Partial',
              color: const Color(0xFFBA7517),
              text: c.acceptDesc,
            ),
          ],
          if (c.failDesc.isNotEmpty) ...[
            const SizedBox(height: 4),
            _ScoreLevel(
              label: 'No credit',
              color: const Color(0xFFE24B4A),
              text: c.failDesc,
            ),
          ],
        ],
      ),
    );
  }
}

class _ScoreLevel extends StatelessWidget {
  final String label;
  final Color color;
  final String text;
  const _ScoreLevel({
    required this.label,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 62,
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(fontSize: 12, color: Color(0xFF555550)),
        ),
      ),
    ],
  );
}

class _StatusBadge extends StatelessWidget {
  final bool isCustom;
  const _StatusBadge({required this.isCustom});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: isCustom
          ? const Color(0xFF1D9E75).withValues(alpha: 0.12)
          : const Color(0xFF888880).withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      isCustom ? 'Tuy chinh' : 'Chua co',
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: isCustom ? const Color(0xFF1D9E75) : const Color(0xFF888880),
      ),
    ),
  );
}

class _EmptyRubricHint extends StatelessWidget {
  final VoidCallback onUpload;
  const _EmptyRubricHint({required this.onUpload});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        Icon(Icons.description_outlined, size: 52, color: Colors.grey[300]),
        const SizedBox(height: 12),
        Text(
          'Chua co rubric',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[500],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Tai len file .docx de bat dau cham bai',
          style: TextStyle(fontSize: 12, color: Colors.grey[400]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: onUpload,
          icon: const Icon(Icons.upload_file_outlined, size: 16),
          label: const Text('Tai len rubric .docx'),
        ),
        const SizedBox(height: 40),
      ],
    ),
  );
}
