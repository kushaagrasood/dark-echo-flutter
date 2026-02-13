import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_joystick/flutter_joystick.dart';
import 'game_model.dart';
import 'game_painter.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with SingleTickerProviderStateMixin {
  late GameModel _model;
  late Ticker _ticker;
  Offset _joystickVelocity = Offset.zero;
  Duration _lastTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _model = GameModel();
    
    // Listen to model changes to trigger a UI repaint
    _model.addListener(() {
      setState(() {});
    });

        // The Game Loop
    _ticker = createTicker((Duration elapsed) {
      // Calculate dynamic delta time (dt) for smooth movement regardless of frame drops
      double dt = (elapsed - _lastTime).inMicroseconds / 1000000.0;
      _lastTime = elapsed;
      
      _model.velocity = _joystickVelocity;
      _model.update(dt); 
    });
    
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: Stack(
        children: [
          // 1. The Game Layer
          Positioned.fill(
            child: CustomPaint(
              painter: GamePainter(_model),
            ),
          ),

          // 2. The Joystick (Bottom Left)
          Positioned(
            bottom: 40,
            left: 40,
            child: Joystick(
              mode: JoystickMode.all, // Allows free movement in any direction
              listener: (details) {
                // The listener callback provides the stick's offset, ranging from -1.0 to 1.0
                _joystickVelocity = Offset(details.x, details.y);
              },
            ),
          ),

          // 3. The "Clap" Button (Bottom Right)
          Positioned(
            bottom: 40,
            right: 40,
            child: GestureDetector(
              onTap: () {
                _model.emitWave();
              },
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white54, width: 2),
                  color: Colors.white.withValues(alpha: 0.1), 
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.15),
                      blurRadius: 12,
                      spreadRadius: 2,
                    )
                  ]
                ),
                child: const Center(
                  child: Text("CLAP", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}