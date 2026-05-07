import 'package:path/path.dart' as p;

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

bool hasImageExtension(String fileName) {
  final imageExtensions = ['.png', '.jpg', '.jpeg', '.gif', '.bmp', '.webp'];
  final extension = p.extension(fileName).toLowerCase();

  return imageExtensions.contains(extension);
}
