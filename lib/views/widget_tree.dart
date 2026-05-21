import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_theme.dart';
import '../providers/app_provider.dart';
import 'screens/main_shell.dart';

class WidgetTree extends StatelessWidget {
  const WidgetTree({super.key, required this.provider});

  final AppProvider provider;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: provider,
      child: const PMGApp(),
    );
  }
}

class PMGApp extends StatelessWidget {
  const PMGApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PMG Grader',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme(),
      home: const MainShell(),
    );
  }
}
