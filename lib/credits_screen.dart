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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Responsive sizing
            final screenHeight = constraints.maxHeight;
            final screenWidth = constraints.maxWidth;
            
            // Adaptive spacing based on screen height
            final double smallGap = screenHeight * 0.01; // 1% of height
            final double mediumGap = screenHeight * 0.025; // 2.5% of height
            final double largeGap = screenHeight * 0.06; // 6% of height
            
            // Adaptive font sizes based on screen width
            final double titleSize = (screenWidth * 0.08).clamp(36.0, 52.0);
            final double subtitleSize = (screenWidth * 0.03).clamp(16.0, 22.0);
            final double nameSize = (screenWidth * 0.055).clamp(24.0, 36.0);
            final double clubSize = (screenWidth * 0.045).clamp(20.0, 28.0);
            final double buttonSize = (screenWidth * 0.035).clamp(18.0, 24.0);
            
            return Stack(
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

                // 3. Scrollable Content
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: screenHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.08,
                          vertical: screenHeight * 0.04,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Title
                            Text(
                              "DARK ECHO",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.vt323(
                                textStyle: TextStyle(
                                  fontSize: titleSize,
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
                                  fontSize: subtitleSize,
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
                                  fontSize: subtitleSize,
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
                                  fontSize: nameSize,
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
                                  fontSize: clubSize,
                                  color: Colors.white,
                                  shadows: const [
                                    Shadow(color: Colors.greenAccent, blurRadius: 15)
                                  ],
                                ),
                              ),
                            ),
                            
                            SizedBox(height: mediumGap * 1.2),
                            
                            // Links Row
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 20,
                              runSpacing: 10,
                              children: [
                                _TerminalLinkButton(
                                  icon: Icons.code,
                                  text: 'GITHUB',
                                  fontSize: buttonSize,
                                  onTap: () => _launchURL('https://github.com/kushaagrasood/'),
                                ),
                                _TerminalLinkButton(
                                  icon: Icons.business,
                                  text: 'LINKEDIN',
                                  fontSize: buttonSize,
                                  onTap: () => _launchURL('https://www.linkedin.com/in/kushaagrasood23/'),
                                ),
                              ],
                            ),
                            
                            SizedBox(height: largeGap),
                            
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
                                      fontSize: buttonSize,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            
                            SizedBox(height: mediumGap),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TerminalLinkButton extends StatefulWidget {
  final IconData icon;
  final String text;
  final double fontSize;
  final VoidCallback onTap;

  const _TerminalLinkButton({
    required this.icon,
    required this.text,
    required this.fontSize,
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
              size: widget.fontSize,
            ),
            const SizedBox(width: 10),
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