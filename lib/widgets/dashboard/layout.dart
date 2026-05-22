import 'package:flutter/material.dart';

export 'stat_card.dart';
export 'section.dart';
export 'empty_state.dart';

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
