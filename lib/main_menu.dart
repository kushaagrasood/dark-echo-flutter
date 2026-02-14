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
  bool _isFirstTime = true;

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
    
    // Blinking cursor
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted) setState(() => _showCursor = !_showCursor);
    });

    // Random flicker effect
    Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted && Random().nextDouble() > 0.5) {
        _flickerController.forward(from: 0).then((_) => _flickerController.reverse());
      }
    });
  }

  void _startTypingAnimation() {
    int index = 0;
    _typingTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (index < _fullTitle.length) {
        setState(() {
          _displayedTitle = _fullTitle.substring(0, index + 1);
        });
        index++;
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    bool? hasPlayedBefore = prefs.getBool('has_played_before');
    
    if (hasPlayedBefore == null || !hasPlayedBefore) {
      setState(() { _isFirstTime = true; });
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) _showFirstTimeGuide();
      });
      await prefs.setBool('has_played_before', true);
    } else {
      setState(() { _isFirstTime = false; });
    }
  }

  @override
  void dispose() {
    _menuPlayer.dispose();
    _pulseController.dispose();
    _flickerController.dispose();
    _typingTimer?.cancel();
    _cursorTimer?.cancel();
    super.dispose();
  }

  // --- EXISTING DIALOG LOGIC (STYLED FOR CRT) ---
  void _showFirstTimeGuide() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildTerminalDialog(
        title: '[ FIRST TRANSMISSION ]',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTerminalText('> Welcome, operator.\n'),
            _buildTerminalText('> This is your first time accessing the system.\n'),
            _buildTerminalText('> We recommend reviewing the DATABASE for mission briefing and controls.\n', color: const Color(0xFF4DF3FF)),
            const SizedBox(height: 20),
            _buildTerminalText('> Access [DATABASE] from the main menu for complete intel.\n', color: Colors.white54, isItalic: true),
          ],
        ),
        actions: [
          _TerminalTextButton(
            text: 'OPEN DATABASE',
            onTap: () {
              Navigator.pop(context);
              _showDatabase(context);
            },
            isCyan: true,
          ),
          _TerminalTextButton(
            text: 'SKIP',
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showDatabase(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _buildTerminalDialog(
        title: '[ DATABASE ACCESS ]',
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDatabaseSection('MISSION BRIEFING:', [
                '> Navigate through procedurally generated mazes',
                '> Locate the GREEN EXIT to complete extraction',
                '> Avoid detection by hostile entities',
                '> Time is being monitored',
              ]),
              const SizedBox(height: 20),
              _buildDatabaseSection('CONTROLS:', [
                '> ARROWS: Movement control',
                '> RIGHT BUTTON [PING]: Emit sonar wave',
                '> PING reveals walls temporarily',
                '> Limited PING charges per mission',
              ]),
              const SizedBox(height: 20),
              _buildDatabaseSection('THREAT ASSESSMENT:', [
                '> RED entities are hostile',
                '> They respond to sound (PINGs)',
                '> They have limited vision range',
                '> Contact means mission failure',
              ]),
              const SizedBox(height: 20),
              _buildDatabaseSection('AUDIO INDICATORS:', [
                '> Footsteps: Enemy proximity warning',
                '> Heartbeat: Danger level indicator',
                '> Faster = Closer threat',
              ]),
            ],
          ),
        ),
        actions: [
          _TerminalTextButton(
            text: 'CLOSE',
            onTap: () => Navigator.pop(context),
            isCyan: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTerminalDialog({required String title, required Widget content, required List<Widget> actions}) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0A0A0F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: Color(0xFF4DF3FF), width: 1),
      ),
      title: Text(title, style: GoogleFonts.vt323(textStyle: const TextStyle(color: Color(0xFF4DF3FF), fontSize: 28, shadows: [Shadow(color: Color(0xFF4DF3FF), blurRadius: 10)]))),
      content: content,
      actions: actions,
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
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F), // Dark charcoal
      body: Stack(
        children: [
          // 1. Background Gradient & Vignette
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

          // 2. CRT Scanlines (Lightweight CustomPainter)
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

          // 4. Main UI
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Title (Jitter Fixed)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Text(
                          _displayedTitle,
                          style: GoogleFonts.vt323(
                            textStyle: TextStyle(
                              fontSize: 72,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 12,
                              shadows: [
                                Shadow(
                                  color: const Color(0xFF4DF3FF).withValues(alpha: 0.5 + (_pulseController.value * 0.3)),
                                  blurRadius: 15 + (_pulseController.value * 10),
                                ),
                                const Shadow(color: Colors.white70, blurRadius: 2, offset: Offset(-1, 1)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    // Fixed-width blinking cursor to prevent layout shift
                    SizedBox(
                      width: 40,
                      child: AnimatedOpacity(
                        opacity: (_displayedTitle.length == _fullTitle.length && _showCursor) ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 100),
                        child: Text(
                          "_",
                          style: GoogleFonts.vt323(
                            textStyle: const TextStyle(
                              fontSize: 72,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                Text(
                  "> ECHO LOCATION PROTOCOL v2.1",
                  style: GoogleFonts.vt323(textStyle: const TextStyle(fontSize: 18, color: Colors.white38, letterSpacing: 4)),
                ),
                
                const SizedBox(height: 60),
                
                // Vertical Terminal Menu
                _TerminalMenuItem(
                  text: 'INITIALIZE',
                  onTap: () {
                    _menuPlayer.stop(); 
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const GamePage()));
                  },
                ),
                const SizedBox(height: 15),
                _TerminalMenuItem(
                  text: 'DATABASE',
                  onTap: () => _showDatabase(context),
                ),
                const SizedBox(height: 15),
                _TerminalMenuItem(
                  text: 'CREDITS',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const CreditsScreen()));
                  },
                ),
              ],
            ),
          ),
          
          // 5. Developer Section (Bottom Left)
          Positioned(
            bottom: 20,
            left: 20,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Text(
                  "> dev: kushaagra_sood${_showCursor ? '█' : ' '}",
                  style: GoogleFonts.vt323(
                    textStyle: TextStyle(
                      color: const Color(0xFF4DF3FF).withValues(alpha: 0.7 + (_pulseController.value * 0.3)),
                      fontSize: 18,
                      shadows: [Shadow(color: const Color(0xFF4DF3FF).withValues(alpha: 0.5), blurRadius: 8)],
                    ),
                  ),
                );
              }
            ),
          ),

          // 6. Auth Info (Bottom Right)
          Positioned(
            bottom: 20,
            right: 20,
            child: Text(
              "> auth: operator_01_",
              style: GoogleFonts.vt323(textStyle: const TextStyle(color: Colors.white38, fontSize: 16)),
            ),
          ),
        ],
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

// --- INTERACTIVE TERMINAL MENU ITEM ---
class _TerminalMenuItem extends StatefulWidget {
  final String text;
  final VoidCallback onTap;

  const _TerminalMenuItem({required this.text, required this.onTap});

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
      child: AnimatedScale(
        scale: _isHovered ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          color: Colors.transparent, // Keeps tap target large
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _isHovered ? "> " : "  ",
                style: GoogleFonts.vt323(textStyle: const TextStyle(color: Color(0xFF4DF3FF), fontSize: 26)),
              ),
              Text(
                "[ ${widget.text} ]",
                style: GoogleFonts.vt323(
                  textStyle: TextStyle(
                    color: _isHovered ? const Color(0xFF4DF3FF) : Colors.white60,
                    fontSize: 26,
                    shadows: _isHovered ? const [Shadow(color: Color(0xFF4DF3FF), blurRadius: 10)] : [],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- DIALOG BUTTON ---
class _TerminalTextButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final bool isCyan;

  const _TerminalTextButton({required this.text, required this.onTap, this.isCyan = false});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      child: Text(
        '[ $text ]',
        style: GoogleFonts.vt323(
          textStyle: TextStyle(color: isCyan ? const Color(0xFF4DF3FF) : Colors.white54, fontSize: 20),
        ),
      ),
    );
  }
}