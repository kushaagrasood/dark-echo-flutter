import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart'; // Add this
import 'game_page.dart';

class MainMenu extends StatefulWidget {
  const MainMenu({super.key});

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  final AudioPlayer _menuPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    // Start playing menu theme on loop
    _menuPlayer.setReleaseMode(ReleaseMode.loop);
    _menuPlayer.play(AssetSource('audio/menu_theme.ogg'));
  }

  @override
  void dispose() {
    _menuPlayer.dispose(); // Clean up audio when leaving menu
    super.dispose();
  }

  void _showDatabase(BuildContext context) {
    // ... KEEP YOUR EXISTING _showDatabase DIALOG CODE HERE ...
    // (I am hiding it here for brevity, paste your AlertDialog code back in)
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
                const Text(
                  "DARK ECHO",
                  style: TextStyle(fontSize: 48, color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 10),
                ),
                const SizedBox(height: 50),
                GestureDetector(
                  onTap: () {
                    // STOP MUSIC BEFORE GOING TO GAME
                    _menuPlayer.stop(); 
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const GamePage()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    decoration: BoxDecoration(border: Border.all(color: Colors.white54), color: Colors.white.withValues(alpha: 0.05)),
                    child: const Text("[ INITIALIZE ]", style: TextStyle(color: Colors.white, fontFamily: 'Courier', fontSize: 18)),
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => _showDatabase(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    decoration: BoxDecoration(border: Border.all(color: Colors.white24)),
                    child: const Text("[ DATABASE ]", style: TextStyle(color: Colors.white54, fontFamily: 'Courier', fontSize: 18)),
                  ),
                ),
              ],
            ),
          ),
          const Positioned(
            bottom: 20, right: 20,
            child: Text("> auth: your_name_here_", style: TextStyle(color: Colors.white38, fontFamily: 'Courier', fontSize: 14)),
          ),
        ],
      ),
    );
  }
}