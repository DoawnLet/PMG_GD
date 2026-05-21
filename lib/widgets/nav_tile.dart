import 'package:flutter/material.dart';

class NavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const NavTile({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF1D9E75).withValues(alpha: 0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            border: selected
                ? Border.all(color: const Color(0xFF1D9E75).withValues(alpha: 0.35))
                : null,
          ),
          child: Row(children: [
            Icon(icon,
                color: selected ? const Color(0xFF5DCAA5) : Colors.white38,
                size: 16),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.white60,
                  fontSize: 12,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.normal,
                )),
          ]),
        ),
      );
}
