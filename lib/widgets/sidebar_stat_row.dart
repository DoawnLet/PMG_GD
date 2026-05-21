import 'package:flutter/material.dart';

class SidebarStatRow extends StatelessWidget {
  final String label;
  final String value;

  const SidebarStatRow(this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(color: Colors.white38, fontSize: 10)),
            Text(value,
                style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );
}
