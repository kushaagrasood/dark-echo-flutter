import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'main_menu.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set landscape orientation globally
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]).then((_) {
    runApp(const DarkEchoApp());
  });
}

class DarkEchoApp extends StatelessWidget {
  const DarkEchoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dark Echo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.dark),
      home: const MainMenu(),
    );
  }
}