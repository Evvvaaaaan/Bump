import 'dart:ui';
import 'package:flutter/material.dart';

class ParallaxBackground extends StatefulWidget {
  final Color primaryColor;
  final Color accentColor;

  const ParallaxBackground({
    super.key,
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  State<ParallaxBackground> createState() => _ParallaxBackgroundState();
}

class _ParallaxBackgroundState extends State<ParallaxBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // 무한 반복 애니메이션 컨트롤러
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: [
            // 배경색 (부드러운 전환)
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              color: Colors.black,
            ),
            // 오로라 원 1 (위쪽)
            Positioned(
              top: -100 + (_controller.value * 20),
              left: -50,
              child: _buildBlurCircle(widget.primaryColor, 300),
            ),
            // 오로라 원 2 (아래쪽)
            Positioned(
              bottom: -50 - (_controller.value * 30),
              right: -50,
              child: _buildBlurCircle(widget.accentColor, 250),
            ),
            // 전체 블러 처리 (Glass Effect)
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(color: Colors.transparent),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBlurCircle(Color color, double size) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.4),
      ),
    );
  }
}