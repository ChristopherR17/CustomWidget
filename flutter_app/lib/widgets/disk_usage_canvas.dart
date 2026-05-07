import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/disk_node.dart';

class DiskUsageCanvas extends StatelessWidget {
  const DiskUsageCanvas({super.key, required this.root});
  final DiskNode root;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(420, 320),
      painter: _DiskPainter(root),
    );
  }
}

class _DiskPainter extends CustomPainter {
  _DiskPainter(this.root);
  final DiskNode root;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) / 2 - 12;
    _drawNode(canvas, root, center, 0, -math.pi / 2, math.pi * 2, maxRadius / 4, maxRadius / 4);

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(text: _format(root.bytes), style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold));
    textPainter.layout();
    textPainter.paint(canvas, center - Offset(textPainter.width / 2, textPainter.height / 2));
  }

  void _drawNode(Canvas canvas, DiskNode node, Offset center, int depth, double start, double sweep, double innerStep, double ringWidth) {
    if (node.children.isEmpty || depth > 3) return;
    final total = node.children.fold<int>(0, (sum, child) => sum + math.max(child.bytes, 1));
    var angle = start;
    for (var i = 0; i < node.children.length; i++) {
      final child = node.children[i];
      final childSweep = sweep * math.max(child.bytes, 1) / total;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ringWidth * .88
        ..color = Colors.primaries[(i + depth * 3) % Colors.primaries.length].shade400;
      final radius = innerStep + depth * ringWidth;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), angle, childSweep, false, paint);
      _drawNode(canvas, child, center, depth + 1, angle, childSweep, innerStep, ringWidth);
      angle += childSweep;
    }
  }

  String _format(int bytes) {
    if (bytes > 1024 * 1024 * 1024) return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(1)} GB';
    if (bytes > 1024 * 1024) return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
    if (bytes > 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '$bytes B';
  }

  @override
  bool shouldRepaint(covariant _DiskPainter oldDelegate) => oldDelegate.root != root;
}
