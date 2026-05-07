class RemoteNode {
  String name;
  final bool isDirectory;
  final bool isImage;
  String permissions;

  RemoteNode({
    required this.name,
    required this.isDirectory,
    required this.isImage,
    required this.permissions,
  });
}
