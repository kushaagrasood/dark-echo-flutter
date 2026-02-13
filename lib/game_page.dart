import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_joystick/flutter_joystick.dart';
import 'package:google_fonts/google_fonts.dart'; // Added Google Fonts
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
    
    _model.addListener(() {
      setState(() {});
    });

    _ticker = createTicker((Duration elapsed) {
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

          // 2. Live Timer HUD (Now using VT323)
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                "${(_model.elapsedMilliseconds / 1000).toStringAsFixed(2)}s",
                style: GoogleFonts.vt323(
                  textStyle: const TextStyle(
                    color: Colors.white54, 
                    fontSize: 32, 
                    fontWeight: FontWeight.bold, 
                    letterSpacing: 4
                  )
                ),
              ),
            ),
          ),

          // 3. Controls Layer
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
                  child: Center(
                    child: Text("[PING]", style: GoogleFonts.vt323( // VT323 Font applied
                      textStyle: const TextStyle(
                        color: Colors.white, 
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      )
                    )),
                  ),
                ),
              ),
            ),
          ],

          // 4. HORROR Game Over Overlay (Loss)
          if (_model.isGameOver)
            Container(
              decoration: BoxDecoration(
                color: Colors.black,
                gradient: RadialGradient(
                  colors: [Colors.red.withValues(alpha: 0.4), Colors.black],
                  radius: 1.2,
                  center: Alignment.center,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("SIGNAL LOST", 
                      style: GoogleFonts.vt323(
                        textStyle: const TextStyle(
                          fontSize: 72, 
                          color: Colors.redAccent, 
                          fontWeight: FontWeight.bold, 
                          letterSpacing: 10,
                          shadows: [
                            Shadow(color: Colors.red, blurRadius: 20, offset: Offset(0, 0)),
                            Shadow(color: Colors.white70, blurRadius: 2, offset: Offset(-2, 2)), // Glitch effect
                          ]
                        )
                      )
                    ),
                    const SizedBox(height: 10),
                    Text("> fatal error: subject terminated_", 
                      style: GoogleFonts.vt323(
                        textStyle: const TextStyle(fontSize: 24, color: Colors.white54)
                      )
                    ),
                    const SizedBox(height: 50),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent, 
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent, width: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)), // Sharp edges for terminal look
                      ),
                      onPressed: () => _model.resetGame(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        child: Text("[ REBOOT SYSTEM ]", style: GoogleFonts.vt323(textStyle: const TextStyle(fontSize: 28))),
                      ),
                    )
                  ],
                ),
              ),
            ),

          // 5. Cinematic You Escaped Overlay (Win)
          if (_model.isGameWon)
            Container(
              color: Colors.black.withValues(alpha: 0.9),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("CONNECTION SECURED", 
                      style: GoogleFonts.vt323(
                        textStyle: const TextStyle(
                          fontSize: 50, 
                          color: Colors.greenAccent, 
                          fontWeight: FontWeight.bold, 
                          letterSpacing: 5,
                          shadows: [Shadow(color: Colors.green, blurRadius: 15)]
                        )
                      )
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "> time_elapsed: ${(_model.elapsedMilliseconds / 1000).toStringAsFixed(2)}s", 
                      style: GoogleFonts.vt323(textStyle: const TextStyle(fontSize: 28, color: Colors.white70))
                    ),
                    if (_model.bestTimeMilliseconds != null)
                      Text(
                        "> personal_best: ${(_model.bestTimeMilliseconds! / 1000).toStringAsFixed(2)}s", 
                        style: GoogleFonts.vt323(textStyle: const TextStyle(fontSize: 24, color: Colors.white54))
                      ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent, 
                        foregroundColor: Colors.greenAccent,
                        side: const BorderSide(color: Colors.greenAccent, width: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
                      ),
                      onPressed: () => _model.resetGame(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        child: Text("[ INITIATE NEXT SEQUENCE ]", style: GoogleFonts.vt323(textStyle: const TextStyle(fontSize: 24))),
                      ),
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