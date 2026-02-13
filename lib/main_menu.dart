import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'game_page.dart';

class MainMenu extends StatelessWidget {
  const MainMenu({super.key});

  void _showDatabase(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF111111),
        shape: RoundedRectangleBorder(
            side: const BorderSide(color: Colors.white24),
            borderRadius: BorderRadius.circular(0)),
        title: Text("DATABASE // INSTRUCTIONS",
            style: GoogleFonts.vt323(
              textStyle: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            )),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("> GOAL: Reach the green exit.",
                style: GoogleFonts.vt323(textStyle: const TextStyle(color: Colors.white70, fontSize: 20))),
            const SizedBox(height: 10),
            Text("> MECHANIC: The maze is pitch black. Tap CLAP to emit a sonar wave and reveal walls.",
                style: GoogleFonts.vt323(textStyle: const TextStyle(color: Colors.white70, fontSize: 20))),
            const SizedBox(height: 10),
            Text("> WARNING: Clapping alerts the Listener. It will hunt the source of the sound. Do not get caught.",
                style: GoogleFonts.vt323(textStyle: const TextStyle(color: Colors.redAccent, fontSize: 20))),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("[ CLOSE ]",
                style: GoogleFonts.vt323(textStyle: const TextStyle(color: Colors.white54, fontSize: 20))),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: Stack(
        children: [
          // Center Content
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
                        Shadow(color: Colors.white54, blurRadius: 15) // Adds a slight neon bloom to the title
                      ]
                    ),
                  ),
                ),
                const SizedBox(height: 50),
                // PLAY BUTTON
                GestureDetector(
                  onTap: () {
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
                    child: Text("[ INITIALIZE ]",
                        style: GoogleFonts.vt323(
                            textStyle: const TextStyle(color: Colors.white, fontSize: 24))),
                  ),
                ),
                const SizedBox(height: 20),
                // INSTRUCTIONS BUTTON
                GestureDetector(
                  onTap: () => _showDatabase(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Text("[ DATABASE ]",
                        style: GoogleFonts.vt323(
                            textStyle: const TextStyle(color: Colors.white54, fontSize: 24))),
                  ),
                ),
              ],
            ),
          ),

          // "About Me" in the corner
          Positioned(
            bottom: 20,
            right: 20,
            child: Text(
              "> auth: your_name_here_",
              style: GoogleFonts.vt323(
                textStyle: const TextStyle(
                  color: Colors.white38,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}