import 'package:flutter/material.dart';

class StatusDot extends StatelessWidget {
  const StatusDot({super.key, required this.enabled, this.size = 14});

  final bool enabled;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.square(size), painter: _StatusDotPainter(enabled));
  }
}

class _StatusDotPainter extends CustomPainter {
  _StatusDotPainter(this.enabled);
  final bool enabled;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = enabled ? Colors.green : Colors.red;
    canvas.drawCircle(size.center(Offset.zero), size.width / 2, paint);
  }

  @override
  bool shouldRepaint(covariant _StatusDotPainter oldDelegate) => oldDelegate.enabled != enabled;
}
