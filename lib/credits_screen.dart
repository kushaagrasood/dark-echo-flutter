import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class CreditsScreen extends StatefulWidget {
  const CreditsScreen({super.key});

  @override
  State<CreditsScreen> createState() => _CreditsScreenState();
}

class _CreditsScreenState extends State<CreditsScreen> {

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Stack(
        children: [
          // 1. Background Gradient & Vignette (Matches Main Menu)
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

          // 3. Content
          Center(
            child: Container(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "DARK ECHO",
                    style: GoogleFonts.vt323(
                      textStyle: const TextStyle(
                        fontSize: 48,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 8,
                        shadows: [Shadow(color: Color(0xFF4DF3FF), blurRadius: 15)],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 10),
                  
                  Text(
                    "> SYSTEM ARCHITECTS",
                    style: GoogleFonts.vt323(
                      textStyle: const TextStyle(fontSize: 18, color: Colors.white38, letterSpacing: 2),
                    ),
                  ),
                  
                  const SizedBox(height: 50),
                  
                  // Updated Developer & Club Section
                  Text(
                    "Developer:",
                    style: GoogleFonts.vt323(
                      textStyle: const TextStyle(fontSize: 22, color: Colors.white70),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Kushaagra Sood",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.vt323(
                      textStyle: const TextStyle(
                        fontSize: 32, 
                        color: Colors.white,
                        shadows: [Shadow(color: Colors.blueAccent, blurRadius: 15)], // Blue Glow
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "Android Club VIT Chennai",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.vt323(
                      textStyle: const TextStyle(
                        fontSize: 26, // Slightly smaller than developer name
                        color: Colors.white,
                        shadows: [Shadow(color: Colors.greenAccent, blurRadius: 15)], // Green Glow
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Links Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _TerminalLinkButton(
                        icon: Icons.code,
                        text: 'GITHUB',
                        onTap: () => _launchURL('https://github.com/kushaagrasood/'),
                      ),
                      const SizedBox(width: 20),
                      _TerminalLinkButton(
                        icon: Icons.business,
                        text: 'LINKEDIN',
                        onTap: () => _launchURL('https://www.linkedin.com/in/kushaagrasood23/'),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 60),
                  
                  // Back Button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white24),
                        color: Colors.white.withValues(alpha: 0.02),
                      ),
                      child: Text(
                        "[ RETURN ]",
                        style: GoogleFonts.vt323(
                          textStyle: const TextStyle(color: Colors.white54, fontSize: 20),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TerminalLinkButton extends StatefulWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const _TerminalLinkButton({required this.icon, required this.text, required this.onTap});

  @override
  State<_TerminalLinkButton> createState() => _TerminalLinkButtonState();
}

class _TerminalLinkButtonState extends State<_TerminalLinkButton> {
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: _isHovered ? const Color(0xFF4DF3FF) : Colors.white24, width: 2)),
          color: _isHovered ? const Color(0xFF4DF3FF).withValues(alpha: 0.1) : Colors.transparent,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.icon, color: _isHovered ? const Color(0xFF4DF3FF) : Colors.white54, size: 20),
            const SizedBox(width: 10),
            Text(
              "[ ${widget.text} ]",
              style: GoogleFonts.vt323(
                textStyle: TextStyle(
                  fontSize: 20,
                  color: _isHovered ? const Color(0xFF4DF3FF) : Colors.white70,
                  shadows: _isHovered ? const [Shadow(color: Color(0xFF4DF3FF), blurRadius: 10)] : [],
                ),
              ),
            ),
          ],
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