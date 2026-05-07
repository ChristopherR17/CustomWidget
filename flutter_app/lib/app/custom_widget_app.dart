import 'package:flutter/material.dart';

import '../screens/connection_screen.dart';
import '../theme/app_palette.dart';

class CustomWidgetApp extends StatelessWidget {
  const CustomWidgetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Custom SSH Widget',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppPalette.primary),
        scaffoldBackgroundColor: AppPalette.background,
        useMaterial3: true,
      ),
      home: const ConnectionScreen(title: 'Custom SSH Widget'),
    );
  }
}
