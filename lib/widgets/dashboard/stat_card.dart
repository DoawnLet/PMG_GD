import 'package:flutter/material.dart';

class DashboardStat {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const DashboardStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class DashboardStatRow extends StatelessWidget {
  final List<DashboardStat> stats;
  const DashboardStatRow({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < stats.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(child: DashboardStatCard(stat: stats[i])),
        ],
      ],
    );
  }
}

class DashboardStatCard extends StatelessWidget {
  final DashboardStat stat;
  const DashboardStatCard({super.key, required this.stat});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD3D1C7), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              Icon(stat.icon, size: 14, color: stat.color),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  stat.label,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF888880)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ]),
            const SizedBox(height: 6),
            Text(
              stat.value,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w700, color: stat.color),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
}
