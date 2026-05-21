import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../widgets/nav_tile.dart';
import '../../widgets/sidebar_stat_row.dart';
import '../dashboard/dashboard_screen.dart';
import 'setup_screen.dart';
import 'files_screen.dart';
import 'results_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _idx = 0;
  final _pages = [
    const DashboardScreen(),
    const SetupScreen(),
    const FilesScreen(),
    const ResultsScreen(),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Row(children: [
          _Sidebar(selectedIndex: _idx, onTap: (i) => setState(() => _idx = i)),
          Expanded(child: _pages[_idx]),
        ]),
      );
}

class _Sidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  const _Sidebar({required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.dashboard_outlined, 'Dashboard'),
      (Icons.settings_outlined, 'Cai dat'),
      (Icons.folder_outlined, 'Files'),
      (Icons.bar_chart_outlined, 'Ket qua'),
    ];
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A18),
        border: Border(right: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Row(children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFF1D9E75),
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Icon(Icons.school, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('PMG Grader',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
              Text('Cham diem AI',
                  style: TextStyle(color: Colors.white38, fontSize: 10)),
            ]),
          ]),
        ),
        for (var i = 0; i < items.length; i++)
          NavTile(
            icon: items[i].$1,
            label: items[i].$2,
            selected: selectedIndex == i,
            onTap: () => onTap(i),
          ),
        const Spacer(),
        Consumer<AppProvider>(builder: (_, p, _) {
          final s = p.stats;
          if (s.isEmpty) return const SizedBox.shrink();
          return Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Tong ket',
                  style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              SidebarStatRow('Bai da cham', '${s['total']}'),
              SidebarStatRow('Diem TB', (s['avg'] as double).toStringAsFixed(1)),
              SidebarStatRow('Dat (>=5)', '${s['pass']}/${s['total']}'),
            ]),
          );
        }),
        const SizedBox(height: 8),
      ]),
    );
  }
}
