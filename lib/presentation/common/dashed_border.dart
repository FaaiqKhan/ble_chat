import 'package:flutter/material.dart';

/// A dashed rounded border, drawn over a widget with `foregroundDecoration`.
class DashedBorder extends Decoration {
  const DashedBorder({
    required this.color,
    required this.radius,
    this.strokeWidth = 1.5,
  });

  final Color color;
  final double radius;
  final double strokeWidth;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      _DashedPainter(color, radius, strokeWidth);
}

class _DashedPainter extends BoxPainter {
  _DashedPainter(this.color, this.radius, this.strokeWidth);

  final Color color;
  final double radius;
  final double strokeWidth;

  static const _dash = 6.0;
  static const _gap = 4.0;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration cfg) {
    final size = cfg.size;
    if (size == null) return;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (offset & size).deflate(strokeWidth / 2),
          Radius.circular(radius),
        ),
      );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = color;
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += _dash + _gap) {
        canvas.drawPath(metric.extractPath(d, d + _dash), paint);
      }
    }
  }
}
