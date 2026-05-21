import 'package:flutter/material.dart';

// ── Data model ────────────────────────────────────────────────────────────────

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

// ── DashboardLayout ───────────────────────────────────────────────────────────
// Outer shell: header bar + scrollable body with consistent padding/spacing.

class DashboardLayout extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const DashboardLayout({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Header bar
      Container(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: const Border(
              bottom: BorderSide(color: Color(0xFFD3D1C7), width: 0.5)),
        ),
        child: Row(children: [
          Icon(icon, size: 22),
          const SizedBox(width: 10),
          Text(title, style: theme.textTheme.headlineMedium),
        ]),
      ),

      // Scrollable body
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _intersperse(children, const SizedBox(height: 16)),
          ),
        ),
      ),
    ]);
  }

  static List<Widget> _intersperse(List<Widget> items, Widget separator) {
    if (items.isEmpty) return [];
    return [
      for (int i = 0; i < items.length; i++) ...[
        if (i > 0) separator,
        items[i],
      ],
    ];
  }
}

// ── DashboardStatRow ──────────────────────────────────────────────────────────
// A horizontal row of stat cards, each taking equal width.

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

// ── DashboardStatCard ─────────────────────────────────────────────────────────

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
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: stat.color),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
}

// ── DashboardSection ──────────────────────────────────────────────────────────
// A titled card section. Pass [trailing] for header actions (e.g. a button).

class DashboardSection extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const DashboardSection({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: padding,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(title, style: theme.textTheme.titleMedium),
            if (trailing != null) ...[
              const Spacer(),
              trailing!,
            ],
          ]),
          const SizedBox(height: 12),
          child,
        ]),
      ),
    );
  }
}

// ── DashboardTwoColumn ────────────────────────────────────────────────────────
// Side-by-side layout: left takes [leftFlex], right takes remaining space.
// Right slot is hidden when [right] is null.

class DashboardTwoColumn extends StatelessWidget {
  final Widget left;
  final Widget? right;
  final int leftFlex;

  const DashboardTwoColumn({
    super.key,
    required this.left,
    this.right,
    this.leftFlex = 2,
  });

  @override
  Widget build(BuildContext context) {
    if (right == null) return left;
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(flex: leftFlex, child: left),
      const SizedBox(width: 16),
      Expanded(child: right!),
    ]);
  }
}

// ── DashboardEmptyState ───────────────────────────────────────────────────────

class DashboardEmptyState extends StatelessWidget {
  final String message;
  final IconData icon;

  const DashboardEmptyState({
    super.key,
    required this.message,
    this.icon = Icons.bar_chart_outlined,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 300,
        child: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 56, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
          ]),
        ),
      );
}
