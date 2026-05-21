import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/submission.dart';
import '../../../providers/app_provider.dart';
import '../../../widgets/dashboard_layout.dart';

/// Hàng stat card phía trên dashboard.
/// Tự đọc dữ liệu từ AppProvider — không cần truyền tham số.
class StatRowSection extends StatelessWidget {
  const StatRowSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder: (_, p, _) {
      final done = p.submissions.where((s) => s.status == GradingStatus.done).toList();
      final total = p.submissions.length;
      final stats = p.stats;
      final lowConf = done.where((s) => s.hasLowConfidence).length;

      final passRate = stats.isNotEmpty && done.isNotEmpty
          ? '${((stats['pass'] as int) / done.length * 100).toStringAsFixed(0)}%'
          : '—';

      return DashboardStatRow(stats: [
        DashboardStat(
          label: 'Tong so bai',
          value: '$total',
          icon: Icons.description_outlined,
          color: const Color(0xFF1A1A18),
        ),
        DashboardStat(
          label: 'Da cham',
          value: '${done.length}',
          icon: Icons.check_circle_outline,
          color: const Color(0xFF1D9E75),
        ),
        DashboardStat(
          label: 'Diem TB',
          value: stats.isEmpty ? '—' : (stats['avg'] as double).toStringAsFixed(1),
          icon: Icons.bar_chart_outlined,
          color: const Color(0xFF1D9E75),
        ),
        DashboardStat(
          label: 'Ti le dat',
          value: passRate,
          icon: Icons.school_outlined,
          color: const Color(0xFFBA7517),
        ),
        DashboardStat(
          label: 'Can xem lai',
          value: '$lowConf',
          icon: Icons.warning_amber_outlined,
          color: lowConf == 0 ? const Color(0xFF888880) : const Color(0xFFE24B4A),
        ),
      ]);
    });
  }
}
