import 'package:flutter/material.dart';

import '../screens/connection_screen.dart';
import '../theme/app_palette.dart';

class CustomWidgetApp extends StatelessWidget {
  const CustomWidgetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Remote Control Hub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppPalette.primary,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppPalette.background,
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: const ConnectionScreen(title: 'Remote Control Hub'),
    );
  }
}
