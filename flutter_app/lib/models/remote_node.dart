/// Modelo que representa un archivo o directorio en el servidor remoto.
/// Contiene información sobre archivos encontrados durante la exploración SSH.
class RemoteNode {
  /// Nombre del archivo o directorio.
  String name;
  
  /// Indica si el nodo es un directorio.
  final bool isDirectory;
  
  /// Indica si el archivo es una imagen.
  final bool isImage;
  
  /// Permisos del archivo en formato de texto (ej: rwxr-xr-x).
  String permissions;

  /// Constructor de RemoteNode.
  RemoteNode({
    required this.name,
    required this.isDirectory,
    required this.isImage,
    required this.permissions,
  });
}
