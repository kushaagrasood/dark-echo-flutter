import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'game_model.dart';
import 'game_painter.dart';
import 'main_menu.dart';
import 'arrow_controls.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with SingleTickerProviderStateMixin {
  late GameModel _model;
  late Ticker _ticker;
  Offset _inputVelocity = Offset.zero;
  Duration _lastTime = Duration.zero;

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
        _inputVelocity = Offset.zero;
      }
    });

    _ticker = createTicker((Duration elapsed) {
      double dt = (elapsed - _lastTime).inMicroseconds / 1000000.0;
      _lastTime = elapsed;
      
      // Arrow controls provide clean digital input (no smoothing needed)
      _model.velocity = _inputVelocity;
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
          // Arrow Controls (Bottom-left)
          if (!_model.isGameOver && !_model.isGameWon)
            Positioned(
              bottom: 20,
              left: 20,
              child: ArrowControls(
                onDirectionChanged: (direction) {
                  setState(() {
                    _inputVelocity = direction;
                  });
                },
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