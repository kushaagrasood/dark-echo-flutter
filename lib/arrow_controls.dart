import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Arrow-based directional controls for player movement
/// Supports diagonal movement when multiple arrows pressed simultaneously
class ArrowControls extends StatefulWidget {
  final Function(Offset) onDirectionChanged;
  
  const ArrowControls({
    super.key,
    required this.onDirectionChanged,
  });

  @override
  State<ArrowControls> createState() => _ArrowControlsState();
}

class _ArrowControlsState extends State<ArrowControls> {
  // Track which directions are currently pressed
  bool _upPressed = false;
  bool _downPressed = false;
  bool _leftPressed = false;
  bool _rightPressed = false;

  void _updateVelocity() {
    // Calculate velocity based on pressed buttons
    double dx = 0.0;
    double dy = 0.0;

    if (_leftPressed) dx -= 1.0;
    if (_rightPressed) dx += 1.0;
    if (_upPressed) dy -= 1.0;
    if (_downPressed) dy += 1.0;

    // Normalize diagonal movement to prevent faster diagonal speed
    if (dx != 0 && dy != 0) {
      double magnitude = 1.0 / 1.414; // 1/sqrt(2)
      dx *= magnitude;
      dy *= magnitude;
    }

    widget.onDirectionChanged(Offset(dx, dy));
  }

  Widget _buildArrowButton({
    required IconData icon,
    required bool isPressed,
    required Function() onPressStart,
    required Function() onPressEnd,
  }) {
    return Listener(
      onPointerDown: (_) {
        onPressStart();
        _updateVelocity();
      },
      onPointerUp: (_) {
        onPressEnd();
        _updateVelocity();
      },
      onPointerCancel: (_) {
        onPressEnd();
        _updateVelocity();
      },
      child: Container(
        width: 55,
        height: 55,
        decoration: BoxDecoration(
          color: isPressed 
              ? Colors.white.withValues(alpha: 0.2)
              : Colors.black.withValues(alpha: 0.5),
          border: Border.all(
            color: isPressed 
                ? Colors.white.withValues(alpha: 0.8)
                : Colors.white.withValues(alpha: 0.3),
            width: isPressed ? 2 : 1,
          ),
        ),
        child: Icon(
          icon,
          color: isPressed 
              ? Colors.white
              : Colors.white.withValues(alpha: 0.6),
          size: 28,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      height: 170,
      child: Stack(
        children: [
          // Up Arrow
          Positioned(
            top: 0,
            left: 57.5,
            child: _buildArrowButton(
              icon: Icons.keyboard_arrow_up,
              isPressed: _upPressed,
              onPressStart: () => setState(() => _upPressed = true),
              onPressEnd: () => setState(() => _upPressed = false),
            ),
          ),

          // Down Arrow
          Positioned(
            bottom: 0,
            left: 57.5,
            child: _buildArrowButton(
              icon: Icons.keyboard_arrow_down,
              isPressed: _downPressed,
              onPressStart: () => setState(() => _downPressed = true),
              onPressEnd: () => setState(() => _downPressed = false),
            ),
          ),

          // Left Arrow
          Positioned(
            top: 57.5,
            left: 0,
            child: _buildArrowButton(
              icon: Icons.keyboard_arrow_left,
              isPressed: _leftPressed,
              onPressStart: () => setState(() => _leftPressed = true),
              onPressEnd: () => setState(() => _leftPressed = false),
            ),
          ),

          // Right Arrow
          Positioned(
            top: 57.5,
            right: 0,
            child: _buildArrowButton(
              icon: Icons.keyboard_arrow_right,
              isPressed: _rightPressed,
              onPressStart: () => setState(() => _rightPressed = true),
              onPressEnd: () => setState(() => _rightPressed = false),
            ),
          ),

          // Center indicator (optional - shows combined direction)
          Positioned(
            top: 57.5,
            left: 57.5,
            child: IgnorePointer(
              child: Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    "◆",
                    style: GoogleFonts.vt323(
                      textStyle: TextStyle(
                        color: (_upPressed || _downPressed || _leftPressed || _rightPressed)
                            ? Colors.cyanAccent.withValues(alpha: 0.8)
                            : Colors.white.withValues(alpha: 0.3),
                        fontSize: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}