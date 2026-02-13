import 'package:flutter/material.dart';
import 'main_menu.dart'; // Import the new menu

void main() {
  runApp(const EchoLabyrinthApp());
}

class EchoLabyrinthApp extends StatelessWidget {
  const EchoLabyrinthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dark Echo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.dark),
      home: const MainMenu(), // Change this to MainMenu!
    );
  }
}