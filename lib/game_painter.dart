import 'package:flutter/material.dart';
import 'dart:math'; 
import 'game_model.dart';

class GamePainter extends CustomPainter {
  final GameModel model;

  GamePainter(this.model) : super(repaint: model);

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Calculate Fear Factor based on nearest bot
    double minBotDist = double.infinity;
    bool isChasing = false;

    for (var bot in model.bots) {
      double dist = (bot.position - model.playerPos).distance;
      if (dist < minBotDist) minBotDist = dist;
      if (bot.state == BotState.chasing) isChasing = true;
    }

    // Fear scales from 0.0 (safe) to 1.0 (touching)
    double fearFactor = 0.0;
    if (minBotDist < 200.0) {
      fearFactor = 1.0 - (minBotDist / 200.0).clamp(0.0, 1.0);
    }

    // 2. Draw Base Background
    final bgPaint = Paint()..color = const Color(0xFF050505);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // --- START DISTORTION LAYER ---
    canvas.save(); 

    // Apply Screen Shake if being chased
    if (isChasing && fearFactor > 0) {
      final random = Random();
      double shakeIntensity = fearFactor * 4.0; 
      double dx = (random.nextDouble() - 0.5) * 2 * shakeIntensity;
      double dy = (random.nextDouble() - 0.5) * 2 * shakeIntensity;
      canvas.translate(dx, dy);
    }

    // 3. Draw Exit Door (Removed the \r formatting errors)
    final exitPaint = Paint()
      ..color = Colors.greenAccent.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10.0)
      ..style = PaintingStyle.fill;
      
    canvas.drawRect(
      Rect.fromCenter(center: model.exitPos, width: model.exitRadius * 2, height: model.exitRadius * 2),
      exitPaint,
    );

    // 4. Draw Walls (Echoes)
    for (var wave in model.waves) {
      final wallPaint = Paint()
        ..color = Colors.white.withValues(alpha: wave.opacity.clamp(0.0, 1.0))
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round 
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3.0) 
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

    // 5. Draw Enemy Bots
    for (var bot in model.bots) {
      final botPaint = Paint()
        ..color = Colors.redAccent.withValues(alpha: bot.opacity.clamp(0.0, 1.0));
      canvas.drawCircle(bot.position, 10.0, botPaint);
    }

    // 6. Draw Player
    final playerPaint = Paint()..color = Colors.blueAccent;
    canvas.drawCircle(model.playerPos, 8.0, playerPaint);

    // 7. Draw Fear Vignette Overlay
    if (fearFactor > 0) {
      final vignettePaint = Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 1.5 - (fearFactor * 0.7), 
          colors: [
            Colors.transparent,
            Colors.redAccent.withValues(alpha: fearFactor * 0.15), 
            Colors.black.withValues(alpha: fearFactor * 0.95),     
          ],
          stops: const [0.3, 0.7, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..blendMode = BlendMode.srcOver; 

      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), vignettePaint);
    }

    // --- END DISTORTION LAYER ---
    canvas.restore(); 
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