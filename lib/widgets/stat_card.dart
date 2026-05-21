import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const StatCard(this.label, this.value, {super.key, this.color});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(height: 4),
              Text(value,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
        ),
      );
}
