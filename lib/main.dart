import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
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
      theme: ThemeData(
        brightness: Brightness.dark,
        // Set VT323 as the global font
        textTheme: GoogleFonts.vt323TextTheme(
          ThemeData.dark().textTheme,
        ),
        // Ensure button text also uses VT323
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            textStyle: GoogleFonts.vt323(fontSize: 20),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            textStyle: GoogleFonts.vt323(fontSize: 20),
          ),
        ),
      ),
      home: const MainMenu(),
    );
  }
}