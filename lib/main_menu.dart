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

  void _showFirstTimeGuide() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildTerminalDialog(
        title: '[ FIRST TRANSMISSION ]',
        children: [
          _buildTerminalText('> Welcome, operator.\n'),
          _buildTerminalText('> This is your first time accessing the system.\n'),
          _buildTerminalText('> We recommend reviewing the DATABASE for mission briefing and controls.\n', color: Colors.greenAccent),
          const SizedBox(height: 20),
          _buildTerminalText('> Access [DATABASE] from the main menu for complete intel.\n', isItalic: true),
        ],
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showDatabase(context);
            },
            child: Text('[ OPEN DATABASE ]', style: GoogleFonts.vt323(textStyle: const TextStyle(color: Color(0xFF4DF3FF), fontSize: 20))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('[ SKIP ]', style: GoogleFonts.vt323(textStyle: const TextStyle(color: Colors.white54, fontSize: 20))),
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
        children: [
          _buildDatabaseSection('MISSION BRIEFING:', [
            '> Navigate through procedurally generated mazes',
            '> Locate the GREEN EXIT to complete extraction',
            '> Avoid detection by hostile entities',
            '> Time is being monitored',
          ]),
          const SizedBox(height: 15),
          _buildDatabaseSection('CONTROLS:', [
            '> ARROW KEYS: Movement control',
            '> RIGHT BUTTON [PING]: Emit sonar wave',
            '> PING reveals walls temporarily',
            '> Limited PING charges per mission',
          ]),
          const SizedBox(height: 15),
          _buildDatabaseSection('THREAT ASSESSMENT:', [
            '> RED entities are hostile',
            '> They respond to sound (PINGs)',
            '> They have limited vision range',
            '> Contact means mission failure',
          ]),
          const SizedBox(height: 15),
          _buildDatabaseSection('AUDIO INDICATORS:', [
            '> Footsteps: Enemy proximity warning',
            '> Heartbeat: Danger level indicator',
            '> Faster = Closer threat',
          ]),
          const SizedBox(height: 15),
          _buildDatabaseSection('DIFFICULTY MODES:', [
            '> EASY: Slower enemies, more PINGs',
            '> MEDIUM: Balanced challenge',
            '> HARD: Fast enemies, limited PINGs',
          ]),
        ],
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('[ CLOSE ]', style: GoogleFonts.vt323(textStyle: const TextStyle(color: Colors.white54, fontSize: 24))),
          ),
        ],
      ),
    );
  }

  Widget _buildTerminalDialog({required String title, required List<Widget> children, required List<Widget> actions}) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0A0A0A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: Colors.white24, width: 2),
      ),
      title: Text(title, style: GoogleFonts.vt323(textStyle: const TextStyle(color: Colors.white, fontSize: 28))),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
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
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Responsive sizing
            final screenHeight = constraints.maxHeight;
            final screenWidth = constraints.maxWidth;
            
            // Adaptive spacing
            final double smallGap = screenHeight * 0.01;
            final double mediumGap = screenHeight * 0.02;
            final double largeGap = screenHeight * 0.08;
            
            // Adaptive font sizes
            final double titleSize = (screenWidth * 0.12).clamp(48.0, 72.0);
            final double subtitleSize = (screenWidth * 0.03).clamp(14.0, 18.0);
            final double menuSize = (screenWidth * 0.04).clamp(20.0, 28.0);
            final double footerSize = (screenWidth * 0.03).clamp(14.0, 18.0);
            
            return Stack(
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

                // 4. Main Content - Properly centered with flexible spacing
                Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.08,
                              vertical: screenHeight * 0.05,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Animated Title
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: AnimatedBuilder(
                                        animation: _pulseController,
                                        builder: (context, child) {
                                          return Text(
                                            _displayedTitle,
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.vt323(
                                              textStyle: TextStyle(
                                                fontSize: titleSize,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: screenWidth * 0.02,
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
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    // Cursor
                                    SizedBox(
                                      width: titleSize * 0.5,
                                      child: AnimatedOpacity(
                                        opacity: (_displayedTitle.length == _fullTitle.length && _showCursor) ? 1.0 : 0.0,
                                        duration: const Duration(milliseconds: 100),
                                        child: Text(
                                          "_",
                                          style: GoogleFonts.vt323(
                                            textStyle: TextStyle(
                                              fontSize: titleSize,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                
                                SizedBox(height: smallGap),
                                
                                Text(
                                  "> ECHO LOCATION PROTOCOL v2.1",
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.vt323(
                                    textStyle: TextStyle(
                                      fontSize: subtitleSize,
                                      color: Colors.white38,
                                      letterSpacing: 4,
                                    ),
                                  ),
                                ),
                                
                                SizedBox(height: largeGap),
                                
                                // Menu Items
                                _TerminalMenuItem(
                                  text: 'INITIALIZE',
                                  fontSize: menuSize,
                                  onTap: () {
                                    _menuPlayer.stop();
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(builder: (context) => const GamePage()),
                                    );
                                  },
                                ),
                                
                                SizedBox(height: mediumGap),
                                
                                _TerminalMenuItem(
                                  text: 'DATABASE',
                                  fontSize: menuSize,
                                  onTap: () => _showDatabase(context),
                                ),
                                
                                SizedBox(height: mediumGap),
                                
                                _TerminalMenuItem(
                                  text: 'CREDITS',
                                  fontSize: menuSize,
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
                        ),
                      ),
                    ),
                    
                    // Footer Section - Safely positioned at bottom
                    Padding(
                      padding: EdgeInsets.only(
                        left: screenWidth * 0.04,
                        right: screenWidth * 0.04,
                        bottom: screenHeight * 0.02,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Developer credit
                          Flexible(
                            child: AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) {
                                return Text(
                                  "> dev: kushaagra_sood${_showCursor ? '█' : ' '}",
                                  style: GoogleFonts.vt323(
                                    textStyle: TextStyle(
                                      color: const Color(0xFF4DF3FF).withValues(
                                        alpha: 0.7 + (_pulseController.value * 0.3)
                                      ),
                                      fontSize: footerSize,
                                      shadows: [
                                        Shadow(
                                          color: const Color(0xFF4DF3FF).withValues(alpha: 0.5),
                                          blurRadius: 8,
                                        )
                                      ],
                                    ),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                );
                              },
                            ),
                          ),
                          
                          // Auth info
                          Flexible(
                            child: Text(
                              "> auth: operator_01_",
                              textAlign: TextAlign.end,
                              style: GoogleFonts.vt323(
                                textStyle: TextStyle(
                                  color: Colors.white38,
                                  fontSize: footerSize,
                                ),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// --- TERMINAL MENU ITEM ---
class _TerminalMenuItem extends StatefulWidget {
  final String text;
  final double fontSize;
  final VoidCallback onTap;

  const _TerminalMenuItem({
    required this.text,
    required this.fontSize,
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
        padding: EdgeInsets.symmetric(
          horizontal: widget.fontSize * 1.5,
          vertical: widget.fontSize * 0.4,
        ),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: _isHovered ? const Color(0xFF4DF3FF) : Colors.white24,
              width: 3,
            ),
          ),
          color: _isHovered
              ? const Color(0xFF4DF3FF).withValues(alpha: 0.1)
              : Colors.transparent,
        ),
        child: Text(
          "> [ ${widget.text} ]",
          style: GoogleFonts.vt323(
            textStyle: TextStyle(
              fontSize: widget.fontSize,
              color: _isHovered ? const Color(0xFF4DF3FF) : Colors.white70,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
              shadows: _isHovered
                  ? const [Shadow(color: Color(0xFF4DF3FF), blurRadius: 12)]
                  : [],
            ),
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