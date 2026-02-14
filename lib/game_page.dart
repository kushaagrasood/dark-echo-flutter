import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'game_model.dart';
import 'game_painter.dart';
import 'main_menu.dart';

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

  // Dynamic joystick
  Offset? _joystickAnchor;
  Offset? _joystickThumb;
  bool _joystickActive = false;
  final double _joystickRadius = 60.0;
  final double _joystickDeadzone = 0.15;
  double _joystickOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    
    _model = GameModel();
    
    _model.addListener(() {
      setState(() {});
      
      if (_model.isGameOver || _model.isGameWon) {
        _joystickVelocity = Offset.zero;
        _joystickActive = false;
        _joystickAnchor = null;
        _joystickThumb = null;
      }
    });

    _ticker = createTicker((Duration elapsed) {
      double dt = (elapsed - _lastTime).inMicroseconds / 1000000.0;
      _lastTime = elapsed;
      
      _model.velocity = _joystickVelocity;
      _model.update(dt);
      
      // Fade out joystick when not in use
      if (_joystickActive) {
        if (_joystickOpacity < 1.0) {
          setState(() {
            _joystickOpacity += dt * 3.0;
            if (_joystickOpacity > 1.0) _joystickOpacity = 1.0;
          });
        }
      } else {
        if (_joystickOpacity > 0.0) {
          setState(() {
            _joystickOpacity -= dt * 2.0;
            if (_joystickOpacity < 0.0) _joystickOpacity = 0.0;
          });
        }
      }
    });
    
    _ticker.start();
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    
    _ticker.dispose();
    _model.dispose();
    super.dispose();
  }

  void _handleJoystickStart(Offset globalPosition) {
    if (_model.isGameOver || _model.isGameWon) return;
    
    setState(() {
      _joystickActive = true;
      _joystickAnchor = globalPosition;
      _joystickThumb = globalPosition;
    });
  }

  void _handleJoystickUpdate(Offset globalPosition) {
    if (!_joystickActive || _joystickAnchor == null) return;
    
    setState(() {
      Offset delta = globalPosition - _joystickAnchor!;
      
      // Constrain thumb within joystick radius
      if (delta.distance > _joystickRadius) {
        delta = (delta / delta.distance) * _joystickRadius;
      }
      
      _joystickThumb = _joystickAnchor! + delta;
      
      // Apply deadzone
      double normalizedDistance = delta.distance / _joystickRadius;
      if (normalizedDistance < _joystickDeadzone) {
        _joystickVelocity = Offset.zero;
      } else {
        // Smooth interpolation
        double scaledDistance = (normalizedDistance - _joystickDeadzone) / (1.0 - _joystickDeadzone);
        _joystickVelocity = (delta / delta.distance) * scaledDistance;
      }
    });
  }

  void _handleJoystickEnd() {
    setState(() {
      _joystickActive = false;
      _joystickVelocity = Offset.zero;
      
      // Don't immediately clear anchor/thumb for fade-out animation
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!_joystickActive) {
          setState(() {
            _joystickAnchor = null;
            _joystickThumb = null;
          });
        }
      });
    });
  }

  void _showDifficultyMenu() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0A0A0A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: const BorderSide(color: Colors.white24, width: 2),
        ),
        title: Text(
          '[ SELECT DIFFICULTY ]',
          style: GoogleFonts.vt323(
            textStyle: const TextStyle(color: Colors.white, fontSize: 28),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDifficultyButton('EASY', Difficulty.easy, Colors.greenAccent),
            const SizedBox(height: 10),
            _buildDifficultyButton('MEDIUM', Difficulty.medium, Colors.yellowAccent),
            const SizedBox(height: 10),
            _buildDifficultyButton('HARD', Difficulty.hard, Colors.redAccent),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyButton(String label, Difficulty difficulty, Color color) {
    bool isSelected = _model.currentDifficulty == difficulty;
    
    return GestureDetector(
      onTap: () {
        _model.changeDifficulty(difficulty);
        Navigator.pop(context);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? color : Colors.white24,
            width: isSelected ? 3 : 1,
          ),
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
        ),
        child: Text(
          isSelected ? '> $label <' : label,
          textAlign: TextAlign.center,
          style: GoogleFonts.vt323(
            textStyle: TextStyle(
              color: isSelected ? color : Colors.white54,
              fontSize: 24,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: Stack(
        children: [
          // 1. Game Layer
          Positioned.fill(
            child: CustomPaint(
              painter: GamePainter(_model),
            ),
          ),

          // 2. Difficulty Selector (Top-left)
          if (!_model.isGameOver && !_model.isGameWon)
            Positioned(
              top: 20,
              left: 20,
              child: GestureDetector(
                onTap: _showDifficultyMenu,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white24, width: 1),
                    color: Colors.black.withValues(alpha: 0.6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.settings,
                        color: Colors.white54,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _model.currentDifficulty.name.toUpperCase(),
                        style: GoogleFonts.vt323(
                          textStyle: const TextStyle(
                            color: Colors.white54,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 3. Timer (Top-center)
          if (!_model.isGameOver && !_model.isGameWon)
            Positioned(
              top: 20,
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

          // 4. Echo Charges (Top-right)
          if (!_model.isGameOver && !_model.isGameWon)
            Positioned(
              top: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.5), width: 1),
                  color: Colors.black.withValues(alpha: 0.6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.circle,
                      color: Colors.cyanAccent,
                      size: 12,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'PINGS: ${_model.currentEchoCharges}',
                      style: GoogleFonts.vt323(
                        textStyle: const TextStyle(
                          color: Colors.cyanAccent,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 5. Dynamic Joystick
          if (!_model.isGameOver && !_model.isGameWon)
            GestureDetector(
              onPanStart: (details) => _handleJoystickStart(details.globalPosition),
              onPanUpdate: (details) => _handleJoystickUpdate(details.globalPosition),
              onPanEnd: (_) => _handleJoystickEnd(),
              behavior: HitTestBehavior.translucent,
              child: Container(
                color: Colors.transparent,
                child: _joystickAnchor != null
                    ? CustomPaint(
                        painter: _DynamicJoystickPainter(
                          anchor: _joystickAnchor!,
                          thumb: _joystickThumb ?? _joystickAnchor!,
                          radius: _joystickRadius,
                          opacity: _joystickOpacity,
                        ),
                      )
                    : null,
              ),
            ),

          // 6. Ping Button
          if (!_model.isGameOver && !_model.isGameWon)
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
                    child: Text("[PING]", style: GoogleFonts.vt323(
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

          // 7. Game Over Screen
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
                            Shadow(color: Colors.white70, blurRadius: 2, offset: Offset(-2, 2)),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent, 
                            foregroundColor: Colors.white54,
                            side: const BorderSide(color: Colors.white54, width: 2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
                          ),
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const MainMenu()),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            child: Text("[ BACK ]", style: GoogleFonts.vt323(textStyle: const TextStyle(fontSize: 24))),
                          ),
                        ),
                        const SizedBox(width: 20),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent, 
                            foregroundColor: Colors.redAccent,
                            side: const BorderSide(color: Colors.redAccent, width: 2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
                          ),
                          onPressed: () => _model.resetGame(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            child: Text("[ REBOOT SYSTEM ]", style: GoogleFonts.vt323(textStyle: const TextStyle(fontSize: 28))),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),

          // 8. Victory Screen
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent, 
                            foregroundColor: Colors.white54,
                            side: const BorderSide(color: Colors.white54, width: 2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
                          ),
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const MainMenu()),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            child: Text("[ BACK ]", style: GoogleFonts.vt323(textStyle: const TextStyle(fontSize: 24))),
                          ),
                        ),
                        const SizedBox(width: 20),
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
                        ),
                      ],
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

// Custom Painter for Dynamic Joystick
class _DynamicJoystickPainter extends CustomPainter {
  final Offset anchor;
  final Offset thumb;
  final double radius;
  final double opacity;

  _DynamicJoystickPainter({
    required this.anchor,
    required this.thumb,
    required this.radius,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Base circle
    final basePaint = Paint()
      ..color = Colors.white.withValues(alpha: opacity * 0.15)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(anchor, radius, basePaint);

    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: opacity * 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    canvas.drawCircle(anchor, radius, borderPaint);

    // Thumb
    final thumbPaint = Paint()
      ..color = Colors.white.withValues(alpha: opacity * 0.5)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(thumb, 25.0, thumbPaint);

    final thumbBorderPaint = Paint()
      ..color = Colors.white.withValues(alpha: opacity * 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    canvas.drawCircle(thumb, 25.0, thumbBorderPaint);
  }

  @override
  bool shouldRepaint(_DynamicJoystickPainter oldDelegate) {
    return oldDelegate.thumb != thumb || 
           oldDelegate.anchor != anchor ||
           oldDelegate.opacity != opacity;
  }
}