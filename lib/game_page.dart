import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_joystick/flutter_joystick.dart';
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

  // Joystick tuning
  static const double joystickDeadzone = 0.15;
  static const double joystickSmoothingFactor = 0.85;
  Offset _smoothedVelocity = Offset.zero;

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
        _smoothedVelocity = Offset.zero;
      }
    });

    _ticker = createTicker((Duration elapsed) {
      double dt = (elapsed - _lastTime).inMicroseconds / 1000000.0;
      _lastTime = elapsed;
      
      // Apply smoothing and deadzone to joystick input
      Offset targetVelocity = _joystickVelocity;
      
      // Deadzone
      if (targetVelocity.distance < joystickDeadzone) {
        targetVelocity = Offset.zero;
      } else {
        // Remap from deadzone to 1.0
        double magnitude = (targetVelocity.distance - joystickDeadzone) / (1.0 - joystickDeadzone);
        magnitude = magnitude.clamp(0.0, 1.0);
        targetVelocity = Offset(
          targetVelocity.dx / targetVelocity.distance * magnitude,
          targetVelocity.dy / targetVelocity.distance * magnitude,
        );
      }
      
      // Smooth interpolation
      _smoothedVelocity = Offset(
        _smoothedVelocity.dx * joystickSmoothingFactor + targetVelocity.dx * (1.0 - joystickSmoothingFactor),
        _smoothedVelocity.dy * joystickSmoothingFactor + targetVelocity.dy * (1.0 - joystickSmoothingFactor),
      );
      
      _model.velocity = _smoothedVelocity;
      _model.update(dt); 
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
          // 1. BOTTOM LAYER: Game Canvas (ALWAYS VISIBLE)
          Positioned.fill(
            child: CustomPaint(
              painter: GamePainter(_model),
            ),
          ),

          // 2. HUD Layer (Does NOT block canvas)
          // Difficulty Selector (Top-left)
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

          // Timer (Top-center)
          if (!_model.isGameOver && !_model.isGameWon)
            Positioned(
              top: 20,
              left: 0,
              right: 0,
              child: IgnorePointer(
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
            ),

          // Echo Charges (Top-right)
          if (!_model.isGameOver && !_model.isGameWon)
            Positioned(
              top: 20,
              right: 20,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3), width: 1),
                    color: Colors.black.withValues(alpha: 0.6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'PING:',
                        style: GoogleFonts.vt323(
                          textStyle: const TextStyle(
                            color: Colors.white54,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ...List.generate(_model.currentEchoCharges, (index) => 
                        Padding(
                          padding: const EdgeInsets.only(left: 2),
                          child: Icon(
                            Icons.circle,
                            size: 12,
                            color: Colors.cyanAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 3. CONTROLS LAYER - constrained to specific areas
          // Joystick (Bottom-left) - IMPROVED SIZE AND RESPONSIVENESS
          if (!_model.isGameOver && !_model.isGameWon)
            Positioned(
              bottom: 30,
              left: 30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.1),
                      blurRadius: 20,
                      spreadRadius: 4,
                    )
                  ],
                ),
                child: Joystick(
                  mode: JoystickMode.all,
                  base: JoystickBase(
                    size: 140, // Increased base size
                    decoration: JoystickBaseDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      drawOuterCircle: true,
                    ),
                  ),
                  stick: JoystickStick(
                    size: 60, // Increased stick size
                    decoration: JoystickStickDecoration(
                      color: Colors.white.withValues(alpha: 0.6),
                      shadowColor: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  listener: (details) {
                    // Raw input from joystick
                    _joystickVelocity = Offset(details.x, details.y);
                  },
                ),
              ),
            ),

          // Ping Button (Bottom-right)
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

          // 4. OVERLAY LAYERS (Full-screen when active)
          // Game Over Screen
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

          // Victory Screen
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