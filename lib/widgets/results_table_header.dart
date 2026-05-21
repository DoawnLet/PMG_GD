import 'package:flutter/material.dart';

class ResultsTableHeader extends StatelessWidget {
  final int requestCount;

  const ResultsTableHeader({super.key, required this.requestCount});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F4F0),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(children: [
          const SizedBox(
            width: 180,
            child: Text('File bai lam',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
          ),
          ...List.generate(
            requestCount,
            (i) => SizedBox(
              width: 70,
              child: Text('YC${i + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                  textAlign: TextAlign.center),
            ),
          ),
          const SizedBox(
            width: 70,
            child: Text('Tong',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                textAlign: TextAlign.center),
          ),
          const SizedBox(
            width: 60,
            child: Text('/10',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                textAlign: TextAlign.center),
          ),
        ]),
      );
}
