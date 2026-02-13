import 'package:flutter/material.dart';
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
        title: const Text("DATABASE // INSTRUCTIONS",
            style: TextStyle(
                color: Colors.white,
                fontFamily: 'Courier',
                fontWeight: FontWeight.bold)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("> GOAL: Reach the green exit.",
                style: TextStyle(color: Colors.white70, fontFamily: 'Courier')),
            SizedBox(height: 10),
            Text("> MECHANIC: The maze is pitch black. Tap CLAP to emit a sonar wave and reveal walls.",
                style: TextStyle(color: Colors.white70, fontFamily: 'Courier')),
            SizedBox(height: 10),
            Text("> WARNING: Clapping alerts the Listener. It will hunt the source of the sound. Do not get caught.",
                style: TextStyle(color: Colors.redAccent, fontFamily: 'Courier')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("[ CLOSE ]",
                style: TextStyle(color: Colors.white54, fontFamily: 'Courier')),
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
                const Text(
                  "DARK ECHO",
                  style: TextStyle(
                    fontSize: 48,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 10,
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
                    child: const Text("[ INITIALIZE ]",
                        style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Courier',
                            fontSize: 18)),
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
                    child: const Text("[ DATABASE ]",
                        style: TextStyle(
                            color: Colors.white54,
                            fontFamily: 'Courier',
                            fontSize: 18)),
                  ),
                ),
              ],
            ),
          ),

          // Your "About Me" in the corner (Terminal Style)
          const Positioned(
            bottom: 20,
            right: 20,
            child: Text(
              "> auth: your_name_here_",
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