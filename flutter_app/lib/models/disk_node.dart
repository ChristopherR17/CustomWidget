class DiskNode {
  final String name;
  final int bytes;
  final List<DiskNode> children;

  const DiskNode({required this.name, required this.bytes, this.children = const []});

  bool get isLeaf => children.isEmpty;
}
