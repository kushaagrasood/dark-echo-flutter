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
    // Get screen dimensions
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Proportional font sizing - EVERYTHING scales
    final titleFontSize = screenWidth * 0.08;
    final subtitleFontSize = screenWidth * 0.024;
    final labelFontSize = screenWidth * 0.03;
    final nameFontSize = screenWidth * 0.055;
    final clubFontSize = screenWidth * 0.045;
    final buttonFontSize = screenWidth * 0.027;
    
    // Proportional spacing - scales with screen height
    final smallGap = screenHeight * 0.01;
    final mediumGap = screenHeight * 0.025;
    final largeGap = screenHeight * 0.05;
    final buttonGap = screenHeight * 0.06;
    
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Stack(
          children: [
            // 1. Background Gradient
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

            // 3. Content - NO SCROLL, everything fits proportionally
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    "DARK ECHO",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.vt323(
                      textStyle: TextStyle(
                        fontSize: titleFontSize,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 8,
                        shadows: const [
                          Shadow(color: Color(0xFF4DF3FF), blurRadius: 15)
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: smallGap),
                  
                  Text(
                    "> SYSTEM ARCHITECTS",
                    style: GoogleFonts.vt323(
                      textStyle: TextStyle(
                        fontSize: subtitleFontSize,
                        color: Colors.white38,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  
                  SizedBox(height: largeGap),
                  
                  // Developer Section
                  Text(
                    "Developer:",
                    style: GoogleFonts.vt323(
                      textStyle: TextStyle(
                        fontSize: labelFontSize,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  
                  SizedBox(height: smallGap * 0.5),
                  
                  Text(
                    "Kushaagra Sood",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.vt323(
                      textStyle: TextStyle(
                        fontSize: nameFontSize,
                        color: Colors.white,
                        shadows: const [
                          Shadow(color: Colors.blueAccent, blurRadius: 15)
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: mediumGap),
                  
                  Text(
                    "Android Club VIT Chennai",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.vt323(
                      textStyle: TextStyle(
                        fontSize: clubFontSize,
                        color: Colors.white,
                        shadows: const [
                          Shadow(color: Colors.greenAccent, blurRadius: 15)
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: mediumGap * 1.2),
                  
                  // Links Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _TerminalLinkButton(
                        icon: Icons.code,
                        text: 'GITHUB',
                        fontSize: buttonFontSize,
                        iconSize: buttonFontSize * 0.9,
                        onTap: () => _launchURL('https://github.com/kushaagrasood/'),
                      ),
                      SizedBox(width: screenWidth * 0.03),
                      _TerminalLinkButton(
                        icon: Icons.business,
                        text: 'LINKEDIN',
                        fontSize: buttonFontSize,
                        iconSize: buttonFontSize * 0.9,
                        onTap: () => _launchURL('https://www.linkedin.com/in/kushaagrasood23/'),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: buttonGap),
                  
                  // Back Button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.06,
                        vertical: screenHeight * 0.015,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white24),
                        color: Colors.white.withValues(alpha: 0.02),
                      ),
                      child: Text(
                        "[ RETURN ]",
                        style: GoogleFonts.vt323(
                          textStyle: TextStyle(
                            color: Colors.white54,
                            fontSize: buttonFontSize,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TerminalLinkButton extends StatefulWidget {
  final IconData icon;
  final String text;
  final double fontSize;
  final double iconSize;
  final VoidCallback onTap;

  const _TerminalLinkButton({
    required this.icon,
    required this.text,
    required this.fontSize,
    required this.iconSize,
    required this.onTap,
  });

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
        padding: EdgeInsets.symmetric(
          horizontal: widget.fontSize * 0.7,
          vertical: widget.fontSize * 0.4,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: _isHovered ? const Color(0xFF4DF3FF) : Colors.white24,
              width: 2,
            ),
          ),
          color: _isHovered
              ? const Color(0xFF4DF3FF).withValues(alpha: 0.1)
              : Colors.transparent,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.icon,
              color: _isHovered ? const Color(0xFF4DF3FF) : Colors.white54,
              size: widget.iconSize,
            ),
            SizedBox(width: widget.fontSize * 0.4),
            Text(
              "[ ${widget.text} ]",
              style: GoogleFonts.vt323(
                textStyle: TextStyle(
                  fontSize: widget.fontSize,
                  color: _isHovered ? const Color(0xFF4DF3FF) : Colors.white70,
                  shadows: _isHovered
                      ? const [
                          Shadow(color: Color(0xFF4DF3FF), blurRadius: 10)
                        ]
                      : [],
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