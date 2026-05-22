import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/submission.dart';
import '../../providers/app_provider.dart';
import '../../widgets/dashboard_layout.dart';
import 'sections/stat_row_section.dart';
import 'sections/score_histogram_section.dart';
import 'sections/request_breakdown_section.dart';
import 'sections/submissions_section.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<AppProvider>(builder: (_, p, _) {
      final done = p.submissions
          .where((s) => s.status == GradingStatus.done)
          .toList();
      final lowConf = done.where((s) => s.hasLowConfidence).toList();

      // Empty state: simple scrollable layout, no tabs needed
      if (done.isEmpty) {
        return DashboardLayout(
          title: 'Dashboard',
          icon: Icons.dashboard_outlined,
          children: [
            const StatRowSection(),
            DashboardEmptyState(
              message: p.submissions.isEmpty
                  ? 'Chua co bai nao duoc nop'
                  : 'Cham bai de xem thong ke',
            ),
          ],
        );
      }

      // With data: pinned header + stat row + two tabs
      return DefaultTabController(
        length: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: const Border(
                  bottom: BorderSide(color: Color(0xFFD3D1C7), width: 0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.dashboard_outlined, size: 22),
                    const SizedBox(width: 10),
                    Text('Dashboard', style: theme.textTheme.headlineMedium),
                  ]),
                  const SizedBox(height: 16),
                  const StatRowSection(),
                  const SizedBox(height: 16),
                  const TabBar(
                    tabs: [
                      Tab(
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.bar_chart_outlined, size: 15),
                          SizedBox(width: 6),
                          Text('Bai cham diem'),
                        ]),
                      ),
                      Tab(
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.checklist_outlined, size: 15),
                          SizedBox(width: 6),
                          Text('Rubric'),
                        ]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // Tab 1: Score distribution + graded submissions list
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ScoreHistogramSection(submissions: done),
                        const SizedBox(height: 16),
                        SubmissionsSection(done: done, lowConf: lowConf),
                      ],
                    ),
                  ),
                  // Tab 2: Per-request score breakdown
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: p.rubric != null
                        ? RequestBreakdownSection(
                            submissions: done,
                            rubric: p.rubric!,
                          )
                        : const DashboardEmptyState(
                            message: 'Chua co rubric de phan tich',
                            icon: Icons.checklist_outlined,
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}
