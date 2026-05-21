import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:desktop_drop/desktop_drop.dart';
import '../../providers/app_provider.dart';
import '../../models/rubric.dart';
import '../../models/submission.dart';
import '../../widgets/drop_zone.dart';
import '../../widgets/submission_tile.dart';

class FilesScreen extends StatelessWidget {
  const FilesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: const Border(
                bottom: BorderSide(color: Color(0xFFD3D1C7), width: 0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.folder_outlined, size: 22),
                  const SizedBox(width: 10),
                  Text('Files', style: theme.textTheme.headlineMedium),
                ]),
                const SizedBox(height: 12),
                const TabBar(
                  tabs: [
                    Tab(
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.description_outlined, size: 15),
                        SizedBox(width: 6),
                        Text('Rubric (.docx)'),
                      ]),
                    ),
                    Tab(
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.upload_file_outlined, size: 15),
                        SizedBox(width: 6),
                        Text('Bai lam (.txt)'),
                      ]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                _RubricTab(),
                _SubmissionsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Rubric tab ────────────────────────────────────────────────────────────────

class _RubricTab extends StatefulWidget {
  const _RubricTab();

  @override
  State<_RubricTab> createState() => _RubricTabState();
}

class _RubricTabState extends State<_RubricTab> {
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
        title: const Text('Reset rubric?'),
        content: const Text(
          'Xoa rubric tuy chinh va tro ve rubric mac dinh (PMG201c)?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
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
    return Consumer<AppProvider>(builder: (_, p, _) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Upload card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
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
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.upload_file_outlined, size: 16),
                        label: Text(
                            p.isLoadingRubric ? 'Dang xu ly...' : 'Tai len .docx'),
                      ),
                      if (p.isCustomRubric) ...[
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: _resetRubric,
                          icon: const Icon(Icons.restore, size: 16),
                          label: const Text('Xoa'),
                          style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFE24B4A)),
                        ),
                      ],
                    ]),
                    if (p.isCustomRubric) ...[
                      const SizedBox(height: 8),
                      Text(
                        p.rubric.examTitle,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${p.rubric.requests.length} yeu cau · ${p.rubric.totalPoints.toInt()} diem',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                    if (p.rubricError != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 14, color: Color(0xFFE24B4A)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              p.rubricError!,
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFFE24B4A)),
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

            // Rubric detail — only after upload
            if (!p.isCustomRubric)
              _EmptyRubricHint(onUpload: _pickRubric),

            if (p.isCustomRubric) ...[
              Text(
                'Chi tiet: ${p.rubric.examTitle}',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              ...p.rubric.requests.map((req) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    title: Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF1D9E75).withValues(alpha: 0.1),
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
                        child: Text(req.title,
                            style: theme.textTheme.titleMedium),
                      ),
                      Text(
                        '${req.maxPoints.toInt()}d',
                        style: const TextStyle(
                          color: Color(0xFF1D9E75),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ]),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...req.criteria.map((c) => _CriterionRow(c: c)),
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
                                      const Text('• ',
                                          style: TextStyle(
                                              color: Color(0xFFE24B4A),
                                              fontSize: 12)),
                                      Expanded(
                                        child: Text(e,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFFE24B4A))),
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
                )),
            ],
          ],
        ),
      );
    });
  }
}

// ── Shared helper widgets ─────────────────────────────────────────────────────

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
          isCustom ? 'Tuy chinh' : 'Mac dinh',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isCustom ? const Color(0xFF1D9E75) : const Color(0xFF888880),
          ),
        ),
      );
}

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
          // Header: ID + name + max points
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
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
            Expanded(
              child: Text(
                c.name,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
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
          ]),
          if ((c.fullDesc).isNotEmpty) ...[
            const SizedBox(height: 8),
            _ScoreLevel(
              label: 'Full',
              color: const Color(0xFF1D9E75),
              text: c.fullDesc,
            ),
          ],
          if ((c.acceptDesc).isNotEmpty) ...[
            const SizedBox(height: 4),
            _ScoreLevel(
              label: 'Partial',
              color: const Color(0xFFBA7517),
              text: c.acceptDesc,
            ),
          ],
          if ((c.failDesc).isNotEmpty) ...[
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
  const _ScoreLevel({required this.label, required this.color, required this.text});

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
              'Chua co rubric tuy chinh',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[500]),
            ),
            const SizedBox(height: 6),
            Text(
              'Tai len file .docx de su dung rubric rieng cho ky thi',
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

// ── Submissions tab ───────────────────────────────────────────────────────────

class _SubmissionsTab extends StatefulWidget {
  const _SubmissionsTab();

  @override
  State<_SubmissionsTab> createState() => _SubmissionsTabState();
}

class _SubmissionsTabState extends State<_SubmissionsTab> {
  bool _isDragOver = false;

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt'],
      allowMultiple: true,
    );
    if (result == null) return;
    await _loadFiles(result.files.map((f) => f.path!).toList());
  }

  Future<void> _pickFolder() async {
    final dirPath = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Chon thu muc chua file .txt',
    );
    if (dirPath == null) return;
    final dir = Directory(dirPath);
    final txtFiles = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.txt'))
        .map((f) => f.path)
        .toList();
    if (txtFiles.isEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Khong tim thay file .txt nao trong thu muc')),
      );
      return;
    }
    await _loadFiles(txtFiles);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Da them ${txtFiles.length} file tu thu muc'),
          backgroundColor: const Color(0xFF1D9E75),
        ),
      );
    }
  }

  Future<void> _loadFiles(List<String> paths) async {
    final p = context.read<AppProvider>();
    for (final path in paths) {
      final file = File(path);
      if (!await file.exists()) continue;
      final name = path.split(Platform.pathSeparator).last;
      final content = await file.readAsString();
      p.addSubmission(name, content);
    }
  }

  Color _statusColor(GradingStatus s) => switch (s) {
        GradingStatus.done => const Color(0xFF1D9E75),
        GradingStatus.grading => const Color(0xFFBA7517),
        GradingStatus.error => const Color(0xFFE24B4A),
        GradingStatus.pending => Colors.grey,
      };

  String _statusLabel(GradingStatus s) => switch (s) {
        GradingStatus.done => 'Da cham',
        GradingStatus.grading => 'Dang cham...',
        GradingStatus.error => 'Loi',
        GradingStatus.pending => 'Cho cham',
      };

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder: (_, p, _) {
      final pending =
          p.submissions.where((s) => s.status == GradingStatus.pending).length;
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Action bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(
                bottom: BorderSide(color: Color(0xFFD3D1C7), width: 0.5)),
          ),
          child: Row(children: [
            if (p.submissions.isNotEmpty)
              OutlinedButton.icon(
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Xoa tat ca'),
                style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE24B4A)),
                onPressed: p.clearAll,
              ),
            if (p.submissions.isNotEmpty) const SizedBox(width: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.folder_open_outlined, size: 16),
              label: const Text('Import thu muc'),
              onPressed: _pickFolder,
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Them file .txt'),
              onPressed: _pickFiles,
            ),
            const Spacer(),
            if (pending > 0)
              ElevatedButton.icon(
                icon: p.isGrading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.play_arrow, size: 16),
                label: Text(
                    p.isGrading ? 'Dang cham...' : 'Cham $pending bai'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D9E75)),
                onPressed: (p.isGrading || !p.hasApiKey) ? null : p.gradeAll,
              ),
          ]),
        ),

        if (!p.hasApiKey)
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            color: const Color(0xFFE24B4A).withValues(alpha: 0.08),
            child: const Row(children: [
              Icon(Icons.warning_amber_outlined,
                  size: 16, color: Color(0xFFE24B4A)),
              SizedBox(width: 8),
              Text(
                'Chua co API key. Vao tab Cai dat de nhap Claude API key.',
                style:
                    TextStyle(color: Color(0xFFE24B4A), fontSize: 13),
              ),
            ]),
          ),

        if (p.isGrading && p.gradingProgress.isNotEmpty)
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            color: const Color(0xFFBA7517).withValues(alpha: 0.08),
            child: Row(children: [
              const SizedBox(
                  width: 12,
                  height: 12,
                  child:
                      CircularProgressIndicator(strokeWidth: 2)),
              const SizedBox(width: 10),
              Text(p.gradingProgress,
                  style: const TextStyle(fontSize: 13)),
            ]),
          ),

        Expanded(
          child: DropTarget(
            onDragEntered: (_) => setState(() => _isDragOver = true),
            onDragExited: (_) => setState(() => _isDragOver = false),
            onDragDone: (detail) {
              setState(() => _isDragOver = false);
              _loadFiles(detail.files.map((f) => f.path).toList());
            },
            child: p.submissions.isEmpty
                ? DropZone(isDragOver: _isDragOver, onTap: _pickFiles)
                : ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: p.submissions.length,
                    itemBuilder: (_, i) {
                      final sub = p.submissions[i];
                      return SubmissionTile(
                        submission: sub,
                        statusColor: _statusColor(sub.status),
                        statusLabel: _statusLabel(sub.status),
                        onGrade: sub.status == GradingStatus.pending &&
                                p.hasApiKey
                            ? () => p.gradeSingle(sub.id)
                            : null,
                        onDelete: () => p.removeSubmission(sub.id),
                      );
                    },
                  ),
          ),
        ),
      ]);
    });
  }
}
