import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:desktop_drop/desktop_drop.dart';
import '../../providers/app_provider.dart';
import '../../models/submission.dart';
import '../../widgets/drop_zone.dart';
import '../../widgets/submission_tile.dart';

class SubmissionsScreen extends StatefulWidget {
  const SubmissionsScreen({super.key});
  @override
  State<SubmissionsScreen> createState() => _SubmissionsScreenState();
}

class _SubmissionsScreenState extends State<SubmissionsScreen> {
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
    final theme = Theme.of(context);
    return Consumer<AppProvider>(builder: (_, p, _) {
      final pending =
          p.submissions.where((s) => s.status == GradingStatus.pending).length;
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
            const Icon(Icons.upload_file_outlined, size: 22),
            const SizedBox(width: 10),
            Text('Nop & Cham bai', style: theme.textTheme.headlineMedium),
            const Spacer(),
            if (p.submissions.isNotEmpty)
              OutlinedButton.icon(
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Xoa tat ca'),
                style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE24B4A)),
                onPressed: p.clearAll,
              ),
            const SizedBox(width: 8),
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
            if (pending > 0)
              ElevatedButton.icon(
                icon: p.isGrading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.play_arrow, size: 16),
                label:
                    Text(p.isGrading ? 'Dang cham...' : 'Cham $pending bai'),
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
                const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
            color: const Color(0xFFE24B4A).withValues(alpha: 0.08),
            child: const Row(children: [
              Icon(Icons.warning_amber_outlined,
                  size: 16, color: Color(0xFFE24B4A)),
              SizedBox(width: 8),
              Text(
                'Chua co API key. Vao tab Cai dat de nhap Claude API key.',
                style: TextStyle(color: Color(0xFFE24B4A), fontSize: 13),
              ),
            ]),
          ),

        if (p.isGrading && p.gradingProgress.isNotEmpty)
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
            color: const Color(0xFFBA7517).withValues(alpha: 0.08),
            child: Row(children: [
              const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2)),
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
