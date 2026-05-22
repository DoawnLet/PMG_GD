import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:desktop_drop/desktop_drop.dart';
import '../../../providers/app_provider.dart';
import '../../../models/submission.dart';
import '../../../widgets/drop_zone.dart';
import '../../../widgets/log_panel.dart';
import '../../../widgets/submission_tile.dart';

class SubmissionsTab extends StatefulWidget {
  const SubmissionsTab({super.key});

  @override
  State<SubmissionsTab> createState() => _SubmissionsTabState();
}

class _SubmissionsTabState extends State<SubmissionsTab> {
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
        const SnackBar(content: Text('Khong tim thay file .txt nao trong thu muc')),
      );
      return;
    }
    await _loadFiles(txtFiles);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Da them ${txtFiles.length} file tu thu muc'),
        backgroundColor: const Color(0xFF1D9E75),
      ));
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFD3D1C7), width: 0.5)),
          ),
          child: Row(children: [
            if (p.submissions.isNotEmpty) ...[
              OutlinedButton.icon(
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Xoa tat ca'),
                style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFE24B4A)),
                onPressed: p.clearAll,
              ),
              const SizedBox(width: 8),
            ],
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
            const SizedBox(width: 8),
            OutlinedButton.icon(
              icon: Stack(clipBehavior: Clip.none, children: [
                const Icon(Icons.terminal_outlined, size: 16),
                if (p.logger.length > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1D9E75),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      constraints: const BoxConstraints(minWidth: 14),
                      child: Text(
                        '${p.logger.length}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ]),
              label: const Text('Log'),
              onPressed: () => showLogPanel(context),
            ),
            const Spacer(),
            if (pending > 0)
              ElevatedButton.icon(
                icon: p.isGrading
                    ? const SizedBox(width: 14, height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.play_arrow, size: 16),
                label: Text(p.isGrading ? 'Dang cham...' : 'Cham $pending bai'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1D9E75)),
                onPressed: (p.isGrading || !p.hasApiKey || !p.isCustomRubric) ? null : p.gradeAll,
              ),
          ]),
        ),
        if (!p.hasApiKey)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            color: const Color(0xFFE24B4A).withValues(alpha: 0.08),
            child: const Row(children: [
              Icon(Icons.warning_amber_outlined, size: 16, color: Color(0xFFE24B4A)),
              SizedBox(width: 8),
              Text('Chua co API key. Vao Cai dat de nhap Gemini API key.',
                  style: TextStyle(color: Color(0xFFE24B4A), fontSize: 13)),
            ]),
          ),
        if (!p.isCustomRubric)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            color: const Color(0xFFBA7517).withValues(alpha: 0.08),
            child: const Row(children: [
              Icon(Icons.description_outlined, size: 16, color: Color(0xFFBA7517)),
              SizedBox(width: 8),
              Text('Chua co rubric. Vao tab Rubric (.docx) de tai len.',
                  style: TextStyle(color: Color(0xFFBA7517), fontSize: 13)),
            ]),
          ),
        if (p.isGrading && p.gradingProgress.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            color: const Color(0xFFBA7517).withValues(alpha: 0.08),
            child: Row(children: [
              const SizedBox(width: 12, height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2)),
              const SizedBox(width: 10),
              Text(p.gradingProgress, style: const TextStyle(fontSize: 13)),
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
                        onGrade: sub.status == GradingStatus.pending && p.hasApiKey && p.isCustomRubric
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
