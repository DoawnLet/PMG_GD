import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/grading_logger.dart';

class LogPanel extends StatefulWidget {
  const LogPanel({super.key});

  @override
  State<LogPanel> createState() => _LogPanelState();
}

class _LogPanelState extends State<LogPanel> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Color _colorFor(LogLevel level) => switch (level) {
        LogLevel.info => const Color(0xFF555550),
        LogLevel.success => const Color(0xFF1D9E75),
        LogLevel.warning => const Color(0xFFBA7517),
        LogLevel.error => const Color(0xFFE24B4A),
      };

  IconData _iconFor(LogLevel level) => switch (level) {
        LogLevel.info => Icons.info_outline,
        LogLevel.success => Icons.check_circle_outline,
        LogLevel.warning => Icons.warning_amber_outlined,
        LogLevel.error => Icons.error_outline,
      };

  void _copyAll(GradingLogger logger) {
    final text = logger.entries.map((e) {
      final prefix = e.submissionName != null ? '[${e.submissionName}] ' : '';
      return '${e.timeFormatted} [${e.level.name.toUpperCase()}] $prefix${e.message}';
    }).join('\n');
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Da copy log vao clipboard'),
        backgroundColor: Color(0xFF1D9E75),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final logger = context.watch<AppProvider>().logger;
    final entries = logger.entries.reversed.toList();

    return Container(
      width: 480,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8),
          bottomLeft: Radius.circular(8),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(-4, 0)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFD3D1C7), width: 0.5)),
          ),
          child: Row(children: [
            const Icon(Icons.terminal_outlined, size: 18),
            const SizedBox(width: 8),
            Text(
              'Log hoat dong cham diem (${logger.length})',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            const Spacer(),
            IconButton(
              tooltip: 'Copy tat ca',
              icon: const Icon(Icons.copy_all_outlined, size: 18),
              onPressed: entries.isEmpty ? null : () => _copyAll(logger),
            ),
            IconButton(
              tooltip: 'Xoa log',
              icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFE24B4A)),
              onPressed: entries.isEmpty ? null : logger.clear,
            ),
            IconButton(
              tooltip: 'Dong',
              icon: const Icon(Icons.close, size: 18),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ]),
        ),
        Expanded(
          child: entries.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox_outlined, size: 40, color: Colors.grey[300]),
                      const SizedBox(height: 8),
                      Text('Chua co log',
                          style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: entries.length,
                  itemBuilder: (_, i) {
                    final e = entries[i];
                    final color = _colorFor(e.level);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(_iconFor(e.level), size: 14, color: color),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 64,
                            child: Text(
                              e.timeFormatted,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                color: Color(0xFF888880),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (e.submissionName != null)
                                  Text(
                                    e.submissionName!,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF888880),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                Text(
                                  e.message,
                                  style: TextStyle(fontSize: 12, color: color, height: 1.35),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}

void showLogPanel(BuildContext context) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Log',
    barrierColor: Colors.black26,
    pageBuilder: (_, _, _) => const Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        height: double.infinity,
        child: LogPanel(),
      ),
    ),
    transitionBuilder: (_, anim, _, child) => SlideTransition(
      position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(
        CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
      ),
      child: child,
    ),
    transitionDuration: const Duration(milliseconds: 220),
  );
}
