import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game_page.dart';

class MainMenu extends StatefulWidget {
  const MainMenu({super.key});

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  final AudioPlayer _menuPlayer = AudioPlayer();
  bool _isFirstTime = true;

  @override
  void initState() {
    super.initState();
    _checkFirstTime();
    // Start playing menu theme on loop
    _menuPlayer.setReleaseMode(ReleaseMode.loop);
    _menuPlayer.play(AssetSource('audio/menu_theme.ogg'));
  }

  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    bool? hasPlayedBefore = prefs.getBool('has_played_before');
    
    if (hasPlayedBefore == null || !hasPlayedBefore) {
      setState(() {
        _isFirstTime = true;
      });
      // Show first-time guide after a short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _showFirstTimeGuide();
        }
      });
      // Mark as played
      await prefs.setBool('has_played_before', true);
    } else {
      setState(() {
        _isFirstTime = false;
      });
    }
  }

  void _showFirstTimeGuide() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0A0A0A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: const BorderSide(color: Colors.cyanAccent, width: 2),
        ),
        title: Text(
          '[ FIRST TRANSMISSION ]',
          style: GoogleFonts.vt323(
            textStyle: const TextStyle(
              color: Colors.cyanAccent,
              fontSize: 28,
            ),
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '> Welcome, operator.\n',
                style: GoogleFonts.vt323(
                  textStyle: const TextStyle(color: Colors.white70, fontSize: 20),
                ),
              ),
              Text(
                '> This is your first time accessing the system.\n',
                style: GoogleFonts.vt323(
                  textStyle: const TextStyle(color: Colors.white70, fontSize: 20),
                ),
              ),
              Text(
                '> We recommend reviewing the DATABASE for mission briefing and controls.\n',
                style: GoogleFonts.vt323(
                  textStyle: const TextStyle(color: Colors.greenAccent, fontSize: 20),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '> Access [DATABASE] from the main menu for complete intel.\n',
                style: GoogleFonts.vt323(
                  textStyle: const TextStyle(color: Colors.white54, fontSize: 18, fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showDatabase(context);
            },
            child: Text(
              '[ OPEN DATABASE ]',
              style: GoogleFonts.vt323(
                textStyle: const TextStyle(color: Colors.cyanAccent, fontSize: 20),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '[ SKIP ]',
              style: GoogleFonts.vt323(
                textStyle: const TextStyle(color: Colors.white54, fontSize: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _menuPlayer.dispose();
    super.dispose();
  }

  void _showDatabase(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0A0A0A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: const BorderSide(color: Colors.white24, width: 2),
        ),
        title: Text(
          '[ DATABASE ACCESS ]',
          style: GoogleFonts.vt323(
            textStyle: const TextStyle(
              color: Colors.white,
              fontSize: 28,
            ),
          ),
        ),
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
                '> LEFT JOYSTICK: Movement control',
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
              const SizedBox(height: 20),
              _buildDatabaseSection('DIFFICULTY MODES:', [
                '> EASY: Slower enemies, more PINGs',
                '> MEDIUM: Balanced challenge',
                '> HARD: Fast enemies, limited PINGs',
              ]),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '[ CLOSE ]',
              style: GoogleFonts.vt323(
                textStyle: const TextStyle(color: Colors.white54, fontSize: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatabaseSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.vt323(
            textStyle: const TextStyle(
              color: Colors.cyanAccent,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 4),
          child: Text(
            item,
            style: GoogleFonts.vt323(
              textStyle: const TextStyle(
                color: Colors.white70,
                fontSize: 18,
              ),
            ),
          ),
        )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "DARK ECHO",
                  style: GoogleFonts.vt323(
                    textStyle: const TextStyle(
                      fontSize: 64, 
                      color: Colors.white, 
                      fontWeight: FontWeight.bold, 
                      letterSpacing: 10,
                      shadows: [
                        Shadow(color: Colors.cyanAccent, blurRadius: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "> ECHO LOCATION PROTOCOL v2.1",
                  style: GoogleFonts.vt323(
                    textStyle: const TextStyle(
                      fontSize: 18,
                      color: Colors.white38,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 50),
                GestureDetector(
                  onTap: () {
                    _menuPlayer.stop(); 
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const GamePage()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white54),
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                    child: Text(
                      "[ INITIALIZE ]",
                      style: GoogleFonts.vt323(
                        textStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => _showDatabase(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Text(
                      "[ DATABASE ]",
                      style: GoogleFonts.vt323(
                        textStyle: const TextStyle(
                          color: Colors.white54,
                          fontSize: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Developer credit - Bottom Left
          Positioned(
            bottom: 20,
            left: 20,
            child: Text(
              "> dev: kushaagra_sood_",
              style: GoogleFonts.vt323(
                textStyle: const TextStyle(
                  color: Colors.white38,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          
          // Auth info - Bottom Right
          const Positioned(
            bottom: 20,
            right: 20,
            child: Text(
              "> auth: operator_01_",
              style: TextStyle(
                color: Colors.white38,
                fontFamily: 'Courier',
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}