import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PulseAvatar extends StatelessWidget {
  final Color accentColor;
  final VoidCallback onTap;

  const PulseAvatar({
    super.key,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ripple 1
          _buildRipple(1, 200),
          // Ripple 2
          _buildRipple(1.5, 400),
          // Ripple 3
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.6),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          // Avatar Image
          CircleAvatar(
            radius: 55,
            backgroundColor: Colors.grey[900],
            // Placeholder: User Initials or Icon
            child: const Icon(Icons.person, size: 50, color: Colors.white),
            // backgroundImage: AssetImage('assets/profile.jpg'), // TODO: Real image
          ),
        ],
      ),
    );
  }

  Widget _buildRipple(double scale, int delayMs) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: accentColor.withOpacity(0.3), width: 2),
      ),
    )
    .animate(onPlay: (controller) => controller.repeat())
    .scale(
      begin: const Offset(1, 1),
      end: Offset(scale, scale),
      duration: const Duration(seconds: 2),
      curve: Curves.easeOut,
      delay: Duration(milliseconds: delayMs),
    )
    .fadeOut(
      duration: const Duration(seconds: 2),
      curve: Curves.easeOut,
      delay: Duration(milliseconds: delayMs),
    );
  }
}
