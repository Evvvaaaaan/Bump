import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double scaleAmount;
  final Duration duration;

  const ScaleButton({
    super.key,
    required this.child,
    required this.onTap,
    this.scaleAmount = 0.96, // 눌렀을 때 96% 크기로 줄어듦
    this.duration = const Duration(milliseconds: 100), // 0.1초 만에 반응
  });

  @override
  State<ScaleButton> createState() => _ScaleButtonState();
}

class _ScaleButtonState extends State<ScaleButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scaleAmount).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward(); // 크기 줄이기
    HapticFeedback.lightImpact(); // [디테일] 누르는 순간 가벼운 진동
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse(); // 크기 복구
    widget.onTap(); // 실제 기능 실행
  }

  void _onTapCancel() {
    _controller.reverse(); // 손가락을 밖으로 드래그했다면 취소 (크기만 복구)
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}