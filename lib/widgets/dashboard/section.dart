import 'package:flutter/material.dart';

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
