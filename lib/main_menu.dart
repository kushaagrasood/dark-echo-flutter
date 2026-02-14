import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game_page.dart';
import 'credits_screen.dart';

class MainMenu extends StatefulWidget {
  const MainMenu({super.key});

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> with TickerProviderStateMixin {
  final AudioPlayer _menuPlayer = AudioPlayer();
  // ignore: unused_field
  final bool _isFirstTime = true;

  // Animations
  late AnimationController _pulseController;
  late AnimationController _flickerController;
  
  String _displayedTitle = "";
  final String _fullTitle = "DARK ECHO";
  bool _showCursor = true;
  Timer? _typingTimer;
  Timer? _cursorTimer;

  @override
  void initState() {
    super.initState();
    _checkFirstTime();
    
    _menuPlayer.setReleaseMode(ReleaseMode.loop);
    _menuPlayer.play(AssetSource('audio/menu_theme.ogg'));

    // Setup Animations
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _flickerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    _startTypingAnimation();
    _startCursorBlink();
  }

  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    bool? firstTime = prefs.getBool('first_time');
    if (firstTime == null || firstTime) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showTutorial(context);
        prefs.setBool('first_time', false);
      });
    }
  }

  void _startTypingAnimation() {
    int currentIndex = 0;
    _typingTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (currentIndex < _fullTitle.length) {
        setState(() {
          _displayedTitle = _fullTitle.substring(0, currentIndex + 1);
        });
        currentIndex++;
      } else {
        timer.cancel();
      }
    });
  }

  void _startCursorBlink() {
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      setState(() {
        _showCursor = !_showCursor;
      });
    });
  }

  void _randomFlicker() {
    if (Random().nextDouble() < 0.05) {
      _flickerController.forward().then((_) {
        _flickerController.reverse();
      });
    }
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _cursorTimer?.cancel();
    _pulseController.dispose();
    _flickerController.dispose();
    _menuPlayer.dispose();
    super.dispose();
  }

  void _showTutorial(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF0A0A0F),
        child: Container(
          padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxWidth: 500),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF4DF3FF), width: 2),
            color: const Color(0xFF0A0A0F),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('[ FIRST-TIME INITIALIZATION ]', style: GoogleFonts.vt323(textStyle: const TextStyle(color: Color(0xFF4DF3FF), fontSize: 22, fontWeight: FontWeight.bold))),
              const SizedBox(height: 16),
              _buildTerminalText('> WELCOME TO DARK ECHO.\\n', color: Colors.greenAccent),
              _buildTerminalText('> We recommend reviewing the DATABASE for mission briefing and controls.\\n', color: Colors.greenAccent),
              const SizedBox(height: 8),
              _buildTerminalText('> Access [DATABASE] from the main menu for complete intel.\\n', isItalic: true),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(border: Border.all(color: const Color(0xFF4DF3FF))),
                    child: Text('[ OPEN DATABASE ]', style: GoogleFonts.vt323(textStyle: const TextStyle(color: Color(0xFF4DF3FF), fontSize: 20))),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).then((_) => _showDatabase(context));
  }

  void _showDatabase(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF0A0A0F),
        child: Container(
          padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 500),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF4DF3FF), width: 2),
            color: const Color(0xFF0A0A0F),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('[ DATABASE ACCESS ]', style: GoogleFonts.vt323(textStyle: const TextStyle(color: Color(0xFF4DF3FF), fontSize: 22, fontWeight: FontWeight.bold))),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDatabaseSection('OBJECTIVE', [
                        '• Navigate the maze to reach the exit',
                        '• Use echolocation to reveal your surroundings',
                        '• Avoid enemy patrols'
                      ]),
                      const SizedBox(height: 16),
                      _buildDatabaseSection('CONTROLS', [
                        '• Arrow Keys: Move in 4 directions',
                        '• Ping Button: Emit sound wave',
                        '• Diagonal movement: Press 2 arrows simultaneously'
                      ]),
                      const SizedBox(height: 16),
                      _buildDatabaseSection('ECHO SYSTEM', [
                        '• Sound waves reveal walls temporarily',
                        '• Limited charges - use strategically',
                        '• Charges regenerate slowly'
                      ]),
                      const SizedBox(height: 16),
                      _buildDatabaseSection('ENEMY AI', [
                        '• An enemy patrols the maze',
                        '• It hears your pings',
                        '• Approximate tracking - not omniscient',
                        '• Use decoy pings to mislead it'
                      ]),
                      const SizedBox(height: 16),
                      _buildDatabaseSection('AUDIO CUES', [
                        '• Heartbeat: Enemy proximity',
                        '• Footsteps: Your movement',
                        '• Tension layer: Chase sequences'
                      ]),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(border: Border.all(color: const Color(0xFF4DF3FF))),
                    child: Text('[ CLOSE ]', style: GoogleFonts.vt323(textStyle: const TextStyle(color: Color(0xFF4DF3FF), fontSize: 20))),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTerminalText(String text, {Color color = Colors.white70, bool isItalic = false}) {
    return Text(text, style: GoogleFonts.vt323(textStyle: TextStyle(color: color, fontSize: 20, fontStyle: isItalic ? FontStyle.italic : FontStyle.normal)));
  }

  Widget _buildDatabaseSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.vt323(textStyle: const TextStyle(color: Color(0xFF4DF3FF), fontSize: 22, fontWeight: FontWeight.bold))),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(padding: const EdgeInsets.only(left: 8, bottom: 4), child: _buildTerminalText(item))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    _randomFlicker();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Stack(
          children: [
            // 1. Background Gradient
            Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [Color(0xFF14141A), Color(0xFF020205)],
                  stops: [0.2, 1.0],
                ),
              ),
            ),

            // 2. CRT Scanlines
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _ScanlinePainter()),
              ),
            ),

            // 3. Flicker Overlay
            AnimatedBuilder(
              animation: _flickerController,
              builder: (context, child) {
                return Container(
                  color: Colors.white.withValues(alpha: _flickerController.value * 0.05),
                );
              },
            ),

            // 4. Main Content - FIXED LAYOUT (~240px total, fits landscape)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated Title - 40px font
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Text(
                            _displayedTitle,
                            style: GoogleFonts.vt323(
                              fontSize: 56,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 6,
                              shadows: [
                                Shadow(
                                  color: const Color(0xFF4DF3FF).withValues(
                                    alpha: 0.5 + (_pulseController.value * 0.3)
                                  ),
                                  blurRadius: 15 + (_pulseController.value * 10),
                                ),
                                const Shadow(
                                  color: Colors.white70,
                                  blurRadius: 2,
                                  offset: Offset(-1, 1),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      // Cursor
                      SizedBox(
                        width: 20,
                        child: AnimatedOpacity(
                          opacity: (_displayedTitle.length == _fullTitle.length && _showCursor) ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 100),
                          child: Text(
                            "_",
                            style: GoogleFonts.vt323(
                              fontSize: 40,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Subtitle - 13px font
                  Text(
                    "> ECHO LOCATION PROTOCOL v2.1",
                    style: GoogleFonts.vt323(
                      fontSize: 13,
                      color: Colors.white38,
                      letterSpacing: 2,
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Menu Items - 20px font
                  _TerminalMenuItem(
                    text: 'INITIALIZE',
                    onTap: () {
                      _menuPlayer.stop();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const GamePage()),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 10),
                  
                  _TerminalMenuItem(
                    text: 'DATABASE',
                    onTap: () => _showDatabase(context),
                  ),
                  
                  const SizedBox(height: 10),
                  
                  _TerminalMenuItem(
                    text: 'CREDITS',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CreditsScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
            
            // 5. Footer - 18px font
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Developer credit
                  Flexible(
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Text(
                          "> dev: kushaagra_sood${_showCursor ? '█' : ' '}",
                          style: GoogleFonts.vt323(
                            fontSize: 18,
                            color: const Color(0xFF4DF3FF).withValues(
                              alpha: 0.7 + (_pulseController.value * 0.3)
                            ),
                            shadows: [
                              Shadow(
                                color: const Color(0xFF4DF3FF).withValues(alpha: 0.5),
                                blurRadius: 8,
                              )
                            ],
                          ),
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    ),
                  ),
                  
                  // User info
                  Flexible(
                    child: Text(
                      "> user: operator_01_",
                      style: GoogleFonts.vt323(
                        fontSize: 18,
                        color: Colors.white38,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TerminalMenuItem extends StatefulWidget {
  final String text;
  final VoidCallback onTap;

  const _TerminalMenuItem({
    required this.text,
    required this.onTap,
  });

  @override
  State<_TerminalMenuItem> createState() => _TerminalMenuItemState();
}

class _TerminalMenuItemState extends State<_TerminalMenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isHovered = true),
      onTapUp: (_) {
        setState(() => _isHovered = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
        decoration: BoxDecoration(
          border: Border.all(
            color: _isHovered ? const Color(0xFF4DF3FF) : Colors.white54,
            width: _isHovered ? 2 : 1,
          ),
          color: _isHovered
              ? const Color(0xFF4DF3FF).withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.03),
        ),
        child: Text(
          "> [ ${widget.text} ]",
          style: GoogleFonts.vt323(
            fontSize: 20,
            color: _isHovered ? const Color(0xFF4DF3FF) : Colors.white,
            shadows: _isHovered
                ? [
                    const Shadow(color: Color(0xFF4DF3FF), blurRadius: 15)
                  ]
                : [],
          ),
        ),
      ),
    );
  }
}

// --- LIGHTWEIGHT CRT SCANLINE PAINTER ---
class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    for (double i = 0; i < size.height; i += 3) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}