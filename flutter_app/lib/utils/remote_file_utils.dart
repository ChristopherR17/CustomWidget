/// Utilidades para el manejo de archivos remotos.
/// Proporciona funciones para formatear permisos y detectar tipos de archivo.

import 'package:path/path.dart' as p;

/// Formatea bits de permisos Unix en formato legible (rwx).
/// Convierte un valor de modo de archivo en la representación estándar Unix de 9 caracteres.
String formatPermissionBits(int? mode) {
  if (mode == null) return '---------';

  final bits = mode & 0x1FF;
  String result = '';
  final symbols = ['r', 'w', 'x'];

  for (int i = 0; i < 9; i++) {
    if ((bits >> (8 - i)) & 1 == 1) {
      result += symbols[i % 3];
    } else {
      result += '-';
    }
  }

  return result;
}

/// Verifica si un archivo tiene extensión de imagen.
/// Comprueba si la extensión del archivo coincide con las extensiones de imagen soportadas.
bool hasImageExtension(String fileName) {
  final imageExtensions = ['.png', '.jpg', '.jpeg', '.gif', '.bmp', '.webp'];
  final extension = p.extension(fileName).toLowerCase();

  return imageExtensions.contains(extension);
}
