import 'package:flutter/material.dart';

import 'screens/widget_catalog_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const TrainventGeneralExampleApp());
}

class TrainventGeneralExampleApp extends StatelessWidget {
  const TrainventGeneralExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Widget Library',
      theme: AppTheme.light,
      home: const WidgetCatalogScreen(),
    );
  }
}
