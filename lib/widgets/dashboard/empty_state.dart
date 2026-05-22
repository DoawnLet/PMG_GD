import 'package:flutter/material.dart';

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
