import 'dart:math';
import 'package:flutter/material.dart';

/// A circular hardware load gauge rendering a progress arc with dynamic threshold colors.
class CircularLoadGauge extends StatelessWidget {
  final double percentage;
  final double size;
  final double strokeWidth;
  final String label;

  const CircularLoadGauge({
    super.key,
    required this.percentage,
    this.size = 64,
    this.strokeWidth = 6,
    this.label = 'CPU',
  });

  Color _getColor(double pct) {
    if (pct < 60) return Colors.greenAccent.shade700;
    if (pct < 85) return Colors.amberAccent.shade700;
    return Colors.redAccent.shade700;
  }

  @override
  Widget build(BuildContext context) {
    final clamped = percentage.clamp(0.0, 100.0);
    final color = _getColor(clamped);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _GaugePainter(
              percentage: clamped,
              color: color,
              backgroundColor: Colors.white12,
              strokeWidth: strokeWidth,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${clamped.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: size * 0.24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (label.isNotEmpty)
                Text(
                  label,
                  style: TextStyle(
                    fontSize: size * 0.16,
                    color: Colors.white54,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double percentage;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;

  const _GaugePainter({
    required this.percentage,
    required this.color,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background track
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Active arc starting from top (-pi / 2)
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = (percentage / 100.0) * 2 * pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      oldDelegate.percentage != percentage ||
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth;
}
