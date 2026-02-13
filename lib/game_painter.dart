import 'package:flutter/material.dart';
import 'game_model.dart';

class GamePainter extends CustomPainter {
  final GameModel model;

  GamePainter(this.model) : super(repaint: model);

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Background (Black with subtle texture feel)
    final bgPaint = Paint()..color = const Color(0xFF050505);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Note: To add the "vine" texture, I would draw a low-contrast 
    // background image here or use a Path with dark grey strokes.

    // 2. Draw Walls (Only visible when hit by wave)
    for (var wave in model.waves) {
      final wallPaint = Paint()
        ..color = Colors.white.withAlpha((wave.opacity.clamp(0.0, 1.0) * 255).toInt(), //replaces withOpacity since it is deprecated
        )
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke;

      for (var wall in model.walls) {
        for (int i = 0; i < wall.length - 1; i++) {
          Offset p1 = wall[i];
          Offset p2 = wall[i + 1];

          // Check if wave boundary is near the wall segment
          if (_isWaveHittingSegment(wave, p1, p2)) {
            canvas.drawLine(p1, p2, wallPaint);
          }
        }
      }
    }

    // 3. Draw Player
    final playerPaint = Paint()..color = Colors.blueAccent;
    canvas.drawCircle(model.playerPos, 8.0, playerPaint);
  }

  bool _isWaveHittingSegment(EchoWave wave, Offset p1, Offset p2) {
    double dist = _distToSegment(wave.center, p1, p2);
    // Intersection: if distance to wall is roughly equal to wave radius
    return (dist - wave.radius).abs() < 10.0; 
  }

  double _distToSegment(Offset p, Offset v, Offset w) {
    double l2 = (v - w).distanceSquared;
    if (l2 == 0) return (p - v).distance;
    double t = ((p.dx - v.dx) * (w.dx - v.dx) + (p.dy - v.dy) * (w.dy - v.dy)) / l2;
    t = (t < 0) ? 0 : (t > 1 ? 1 : t);
    return (p - Offset(v.dx + t * (w.dx - v.dx), v.dy + t * (w.dy - v.dy))).distance;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}