import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'providers/app_provider.dart';
import 'views/widget_tree.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await windowManager.ensureInitialized();
  await windowManager.waitUntilReadyToShow(
    const WindowOptions(
      size: Size(1280, 800),
      minimumSize: Size(960, 640),
      center: true,
      title: 'PMG Grader - Cham diem AI',
      backgroundColor: Colors.transparent,
    ),
    () async {
      await windowManager.show();
      await windowManager.focus();
    },
  );

  final provider = AppProvider();
  await provider.loadApiKey();

  runApp(WidgetTree(provider: provider));
}
