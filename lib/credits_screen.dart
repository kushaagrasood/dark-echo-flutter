import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      // Silently fail - don't show error to user in this minimal UI
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Title
              Text(
                "DARK ECHO",
                style: GoogleFonts.vt323(
                  textStyle: const TextStyle(
                    fontSize: 56,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                    shadows: [
                      Shadow(color: Colors.cyanAccent, blurRadius: 15),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 10),
              
              Text(
                "> ECHO LOCATION PROTOCOL v2.1",
                style: GoogleFonts.vt323(
                  textStyle: const TextStyle(
                    fontSize: 16,
                    color: Colors.white38,
                    letterSpacing: 2,
                  ),
                ),
              ),
              
              const SizedBox(height: 60),
              
              // Developer Section
              Text(
                "[ DEVELOPMENT ]",
                style: GoogleFonts.vt323(
                  textStyle: const TextStyle(
                    fontSize: 24,
                    color: Colors.cyanAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              Text(
                "Developer: Kushaagra Sood",
                style: GoogleFonts.vt323(
                  textStyle: const TextStyle(
                    fontSize: 20,
                    color: Colors.white70,
                  ),
                ),
              ),
              
              const SizedBox(height: 30),
              
              // GitHub Link
              GestureDetector(
                onTap: () => _launchURL('https://github.com/kushaagrasood/'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white54, width: 1),
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.code,
                        color: Colors.white54,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "[ GITHUB ]",
                        style: GoogleFonts.vt323(
                          textStyle: const TextStyle(
                            fontSize: 20,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 15),
              
              // LinkedIn Link
              GestureDetector(
                onTap: () => _launchURL('https://www.linkedin.com/in/kushaagrasood23/'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white54, width: 1),
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.business,
                        color: Colors.white54,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "[ LINKEDIN ]",
                        style: GoogleFonts.vt323(
                          textStyle: const TextStyle(
                            fontSize: 20,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 50),
              
              // Back Button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Text(
                    "[ BACK ]",
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
      ),
    );
  }
}