import 'package:flutter/material.dart';
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

            // 3. Content - ULTRA-COMPACT (~212px total, -28px from previous)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title - 42px (reduced from 48px)
                  const Text(
                    "DARK ECHO",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'VT323',
                      fontSize: 42,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 5,
                      shadows: [
                        Shadow(color: Color(0xFF4DF3FF), blurRadius: 15)
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 3),
                  
                  // Subtitle - 13px (reduced from 14px)
                  const Text(
                    "> SYSTEM ARCHITECTS",
                    style: TextStyle(
                      fontFamily: 'VT323',
                      fontSize: 13,
                      color: Colors.white38,
                      letterSpacing: 2,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Developer Label - 15px (reduced from 16px)
                  const Text(
                    "Developer:",
                    style: TextStyle(
                      fontFamily: 'VT323',
                      fontSize: 15,
                      color: Colors.white70,
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Developer Name - 26px (reduced from 28px)
                  const Text(
                    "Kushaagra Sood",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'VT323',
                      fontSize: 26,
                      color: Colors.white,
                      shadows: [
                        Shadow(color: Colors.blueAccent, blurRadius: 15)
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Club Name - 20px (reduced from 22px)
                  const Text(
                    "Android Club VIT Chennai",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'VT323',
                      fontSize: 20,
                      color: Colors.white,
                      shadows: [
                        Shadow(color: Colors.greenAccent, blurRadius: 15)
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 22),
                  
                  // Links Row - 15px (reduced from 16px)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _TerminalLinkButton(
                        icon: Icons.code,
                        text: 'GITHUB',
                        onTap: () => _launchURL('https://github.com/kushaagrasood/'),
                      ),
                      const SizedBox(width: 14),
                      _TerminalLinkButton(
                        icon: Icons.business,
                        text: 'LINKEDIN',
                        onTap: () => _launchURL('https://www.linkedin.com/in/kushaagrasood23/'),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 28),
                  
                  // Back Button - 17px (reduced from 18px)
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white24),
                        color: Colors.white.withValues(alpha: 0.02),
                      ),
                      child: const Text(
                        "[ RETURN ]",
                        style: TextStyle(
                          fontFamily: 'VT323',
                          fontSize: 17,
                          color: Colors.white54,
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
  final VoidCallback onTap;

  const _TerminalLinkButton({
    required this.icon,
    required this.text,
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
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 7,
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
              size: 15,
            ),
            const SizedBox(width: 7),
            Text(
              "[ ${widget.text} ]",
              style: TextStyle(
                fontFamily: 'VT323',
                fontSize: 15,
                color: _isHovered ? const Color(0xFF4DF3FF) : Colors.white70,
                shadows: _isHovered
                    ? const [
                        Shadow(color: Color(0xFF4DF3FF), blurRadius: 10)
                      ]
                    : null,
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