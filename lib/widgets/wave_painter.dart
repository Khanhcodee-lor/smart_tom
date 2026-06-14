import 'package:flutter/material.dart';
import 'dart:math' as math;

/// A custom painter that draws smooth wave curves.
class WavePainter extends CustomPainter {
  final double animationValue;
  final Color color;

  WavePainter({required this.animationValue, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.6);

    for (double i = 0; i <= size.width; i++) {
      path.lineTo(
        i,
        size.height * 0.6 +
            math.sin((i / size.width * 2 * math.pi) +
                    (animationValue * 2 * math.pi)) *
                8 +
            math.sin((i / size.width * 4 * math.pi) +
                    (animationValue * 3 * math.pi)) *
                4,
      );
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}
