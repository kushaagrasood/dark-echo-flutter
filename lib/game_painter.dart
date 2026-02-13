import 'package:flutter/material.dart';
import 'game_model.dart';

class GamePainter extends CustomPainter {
  final GameModel model;

  GamePainter(this.model) : super(repaint: model);

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFF050505);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    for (var wave in model.waves) {
      final wallPaint = Paint()
        // <-- Cleanly using withValues(alpha: ...)
        ..color = Colors.white.withValues(alpha: wave.opacity.clamp(0.0, 1.0))
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke;

      for (var wall in model.walls) {
        for (int i = 0; i < wall.length - 1; i++) {
          Offset p1 = wall[i];
          Offset p2 = wall[i + 1];

          if (_isWaveHittingSegment(wave, p1, p2)) {
            canvas.drawLine(p1, p2, wallPaint);
          }
        }
      }
    }

    for (var bot in model.bots) {
      final botPaint = Paint()
        ..color = Colors.redAccent.withValues(alpha: bot.opacity.clamp(0.0, 1.0));
      canvas.drawCircle(bot.position, 10.0, botPaint);
    }

    final playerPaint = Paint()..color = Colors.blueAccent;
    canvas.drawCircle(model.playerPos, 8.0, playerPaint);
  }

  bool _isWaveHittingSegment(EchoWave wave, Offset p1, Offset p2) {
    double dist = _distToSegment(wave.center, p1, p2);
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