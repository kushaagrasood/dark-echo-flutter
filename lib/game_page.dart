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

          // 2. Controls Layer (Only show if playing)
          if (!_model.isGameOver && !_model.isGameWon) ...[
            Positioned(
              bottom: 40,
              left: 40,
              child: Joystick(
                mode: JoystickMode.all,
                listener: (details) {
                  _joystickVelocity = Offset(details.x, details.y);
                },
              ),
            ),
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

          // 3. Phase 2: Game Over Overlay (Loss)
          if (_model.isGameOver)
            Container(
              color: Colors.redAccent.withValues(alpha: 0.8),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("CAUGHT", style: TextStyle(fontSize: 50, color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 5)),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                      onPressed: () => _model.resetGame(),
                      child: const Text("TRY AGAIN"),
                    )
                  ],
                ),
              ),
            ),

          // 4. Phase 2: You Escaped Overlay (Win)
          if (_model.isGameWon)
            Container(
              color: Colors.greenAccent.withValues(alpha: 0.8),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("ESCAPED", style: TextStyle(fontSize: 50, color: Colors.black, fontWeight: FontWeight.bold, letterSpacing: 5)),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                      onPressed: () => _model.resetGame(),
                      child: const Text("PLAY AGAIN"),
                    )
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}