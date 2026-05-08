/// Módulo de logging de la aplicación.
/// Proporciona un logger global configurado con formato pretty print para depuración.

import 'package:logger/logger.dart';

/// Logger global de la aplicación.
/// Configurado con 2 niveles de método para logs normales y 8 para errores.
/// Soporta colores en la consola para mejor legibilidad.
final logger = Logger(
  printer: PrettyPrinter(
    methodCount: 2,
    errorMethodCount: 8,
    lineLength: 120,
    colors: true,
    printEmojis: false,
  ),
);
