import 'package:flutter/material.dart';
import 'tabs/rubric_tab.dart';
import 'tabs/submissions_tab.dart';

class FilesScreen extends StatelessWidget {
  const FilesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                  const Icon(Icons.folder_outlined, size: 22),
                  const SizedBox(width: 10),
                  Text('Files', style: theme.textTheme.headlineMedium),
                ]),
                const SizedBox(height: 12),
                const TabBar(
                  tabs: [
                    Tab(
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.description_outlined, size: 15),
                        SizedBox(width: 6),
                        Text('Rubric (.docx)'),
                      ]),
                    ),
                    Tab(
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.upload_file_outlined, size: 15),
                        SizedBox(width: 6),
                        Text('Bai lam (.txt)'),
                      ]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                RubricTab(),
                SubmissionsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
