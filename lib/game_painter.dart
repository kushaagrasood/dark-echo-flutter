import 'package:flutter/material.dart';
import 'dart:math'; 
import 'dart:ui' as ui;
import 'package:google_fonts/google_fonts.dart';
import 'game_model.dart';

class GamePainter extends CustomPainter {
  final GameModel model;

  // Reusable TextPainter instances for performance
  static final TextPainter _playerPainter = TextPainter(
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
  );
  
  static final TextPainter _botPainter = TextPainter(
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
  );

  GamePainter(this.model) : super(repaint: model);

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Calculate Fear Factor
    double minBotDist = double.infinity;
    bool isChasing = false;

    for (var bot in model.bots) {
      double dist = (bot.position - model.playerPos).distance;
      if (dist < minBotDist) minBotDist = dist;
      if (bot.state == BotState.chasing) isChasing = true;
    }

    double fearFactor = 0.0;
    if (minBotDist < 200.0) {
      fearFactor = 1.0 - (minBotDist / 200.0).clamp(0.0, 1.0);
    }

    // 2. Draw Base Background
    final bgPaint = Paint()..color = const Color(0xFF050505);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // --- START CAMERA & DISTORTION LAYER ---
    canvas.save(); 

    // Apply Camera Offset
    canvas.translate(-model.cameraOffset.dx, -model.cameraOffset.dy);

    // Apply Screen Shake during chase
    if (isChasing && fearFactor > 0) {
      final random = Random();
      double shakeIntensity = fearFactor * 3.0; // Subtle shake
      double dx = (random.nextDouble() - 0.5) * 2 * shakeIntensity;
      double dy = (random.nextDouble() - 0.5) * 2 * shakeIntensity;
      canvas.translate(dx, dy);
    }

    // 3. Draw Exit Door
    final exitPaint = Paint()
      ..color = Colors.greenAccent.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10.0)
      ..style = PaintingStyle.fill;
      
    canvas.drawRect(
      Rect.fromCenter(center: model.exitPos, width: model.exitRadius * 2, height: model.exitRadius * 2),
      exitPaint,
    );

    // 4. Draw Walls - whole-wall reveal system
    for (int wallIdx = 0; wallIdx < model.walls.length; wallIdx++) {
      var wall = model.walls[wallIdx];
      
      double opacity = 0.0;
      if (model.wallRevealTimers.containsKey(wallIdx)) {
        opacity = model.wallRevealTimers[wallIdx]!.clamp(0.0, 1.0);
      }

      if (opacity > 0) {
        final wallPaint = Paint()
          ..color = Colors.white.withValues(alpha: opacity)
          ..strokeWidth = 3.0
          ..strokeCap = StrokeCap.round 
          ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3.0) 
          ..style = PaintingStyle.stroke;

        for (int i = 0; i < wall.length - 1; i++) {
          canvas.drawLine(wall[i], wall[i + 1], wallPaint);
        }
      }
    }

    // 5. Draw wave rings
    for (var wave in model.waves) {
      if (wave.opacity > 0) {
        double baseWidth = 4.0;
        double distanceFactor = (wave.radius / wave.maxRadius).clamp(0.0, 1.0);
        double strokeWidth = baseWidth * (1.0 - distanceFactor * 0.7);
        
        final wavePaint = Paint()
          ..color = Colors.cyanAccent.withValues(alpha: wave.opacity * 0.4)
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2.0);
        
        canvas.drawCircle(wave.center, wave.radius, wavePaint);
      }
    }

    // 6. Draw Enemy Bots (ASCII Character "Θ")
    for (var bot in model.bots) {
      // Calculate flicker effect (subtle alpha variation)
      final random = Random(bot.position.dx.toInt() + bot.position.dy.toInt());
      double flicker = 0.85 + (random.nextDouble() * 0.15); // 0.85 to 1.0
      double finalOpacity = (bot.opacity * flicker).clamp(0.0, 1.0);
      
      // Red glow behind bot (larger, 1.7x)
      final botGlowPaint = Paint()
        ..color = Colors.redAccent.withValues(alpha: finalOpacity * 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20.0);
      canvas.drawCircle(bot.position, 20.0, botGlowPaint);
      
      // Enhanced glow during chase
      if (bot.state == BotState.chasing) {
        final chaseGlowPaint = Paint()
          ..color = Colors.redAccent.withValues(alpha: 0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25.0);
        canvas.drawCircle(bot.position, 30.0, chaseGlowPaint);
      }
      
      // Draw bot character "Θ" with shadow
      _botPainter.text = TextSpan(
        text: 'Θ',
        style: GoogleFonts.vt323(
          fontSize: 36.0, // 1.7x larger than player (36 vs 24)
          color: Colors.redAccent.withValues(alpha: finalOpacity),
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.red.withValues(alpha: finalOpacity * 0.8),
              blurRadius: 8.0,
            ),
          ],
        ),
      );
      _botPainter.layout();
      
      // Center text on bot position
      final botOffset = bot.position - Offset(_botPainter.width / 2, _botPainter.height / 2);
      _botPainter.paint(canvas, botOffset);
    }

    // 7. Draw Player (ASCII Character "@")
    // Faint glow around player
    final playerGlowPaint = Paint()
      ..color = Colors.blueAccent.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12.0);
    canvas.drawCircle(model.playerPos, 18.0, playerGlowPaint);
    
    // Draw player character "@" with shadow
    _playerPainter.text = TextSpan(
      text: '@',
      style: GoogleFonts.vt323(
        fontSize: 28.0,
        color: Colors.blueAccent,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(
            color: Colors.blue.withValues(alpha: 0.6),
            blurRadius: 6.0,
          ),
        ],
      ),
    );
    _playerPainter.layout();
    
    // Center text on player position
    final playerOffset = model.playerPos - Offset(_playerPainter.width / 2, _playerPainter.height / 2);
    _playerPainter.paint(canvas, playerOffset);

    // 8. Visual Heartbeat Pulse
    if (model.visualPulseIntensity > 0) {
      double pulseRadius = 50.0 + ((1.0 - model.visualPulseIntensity) * 150.0); 
      
      final pulsePaint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.redAccent.withValues(alpha: model.visualPulseIntensity * 0.25),
            Colors.transparent,
          ],
          stops: const [0.2, 1.0],
        ).createShader(Rect.fromCircle(center: model.playerPos, radius: pulseRadius))
        ..blendMode = BlendMode.srcOver;

      canvas.drawCircle(model.playerPos, pulseRadius, pulsePaint);
    }

    canvas.restore(); 
    // --- END CAMERA LAYER ---

    // 9. PANIC VISUAL LAYER (Screen-space effects)
    if (model.panicIntensity > 0.0) {
      // Darker vignette
      final panicVignette = Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 1.2 - (model.panicIntensity * 0.3),
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: model.panicIntensity * 0.4),
            Colors.black.withValues(alpha: model.panicIntensity * 0.8),
          ],
          stops: const [0.3, 0.7, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..blendMode = BlendMode.srcOver;

      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), panicVignette);

      // Subtle screen grain overlay
      if (model.panicIntensity > 0.3) {
        _drawGrainOverlay(canvas, size, model.panicIntensity);
      }
    }

    // 10. Standard Fear Vignette
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
  }

  // Lightweight grain overlay
  void _drawGrainOverlay(Canvas canvas, Size size, double intensity) {
    final random = Random();
    final grainPaint = Paint()
      ..color = Colors.white.withValues(alpha: intensity * 0.02)
      ..blendMode = BlendMode.overlay;

    // Draw subtle grain pixels
    for (int i = 0; i < 200; i++) {
      double x = random.nextDouble() * size.width;
      double y = random.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), 0.5, grainPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}