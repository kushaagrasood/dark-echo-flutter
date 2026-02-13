import 'package:flutter/material.dart';
import 'game_page.dart';

void main() {
  runApp(const DarkEchoApp());
}

class DarkEchoApp extends StatelessWidget {
  const DarkEchoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Echo Labyrinth',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.dark),
      home: const GamePage(),
    );
  }
}