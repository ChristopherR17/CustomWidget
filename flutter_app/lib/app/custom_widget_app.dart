/// Módulo principal de la aplicación que configura la interfaz de usuario.
/// Define el tema, paleta de colores y la pantalla inicial de la aplicación.

import 'package:flutter/material.dart';

import '../screens/connection_screen.dart';
import '../theme/app_palette.dart';

/// Widget raíz de la aplicación.
/// Configura la aplicación MaterialApp con tema personalizado y pantalla inicial.
class CustomWidgetApp extends StatelessWidget {
  const CustomWidgetApp({super.key});

  /// Construye la estructura de la aplicación con configuración de tema y navegación.
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
