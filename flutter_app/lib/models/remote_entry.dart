class RemoteEntry {
  final String name;
  final bool isDirectory;
  final int size;
  final int? mode;
  final DateTime? modifiedAt;

  const RemoteEntry({
    required this.name,
    required this.isDirectory,
    required this.size,
    required this.mode,
    required this.modifiedAt,
  });

  bool get isZip => name.toLowerCase().endsWith('.zip');

  String get permissions {
    final value = mode;
    if (value == null) return '---------';
    final bits = value & 0x1FF;
    const chars = ['r', 'w', 'x'];
    final buffer = StringBuffer();
    for (var i = 8; i >= 0; i--) {
      buffer.write((bits & (1 << i)) != 0 ? chars[(8 - i) % 3] : '-');
    }
    return buffer.toString();
  }
}
