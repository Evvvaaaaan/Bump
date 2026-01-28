import 'package:bump/features/settings/settings_provider.dart'; // [필수] 설정 가져오기
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // [필수] 리버팟

// [수정] StatefulWidget -> ConsumerStatefulWidget
class ScaleButton extends ConsumerStatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double scaleAmount;
  final Duration duration;

  const ScaleButton({
    super.key,
    required this.child,
    required this.onTap,
    this.scaleAmount = 0.96,
    this.duration = const Duration(milliseconds: 100),
  });

  @override
  ConsumerState<ScaleButton> createState() => _ScaleButtonState();
}

class _ScaleButtonState extends ConsumerState<ScaleButton> with SingleTickerProviderStateMixin {
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
    _controller.forward();
    
    // [핵심 수정] 설정이 켜져있을 때만 진동!
    final isHapticEnabled = ref.read(settingsProvider).isHapticEnabled;
    if (isHapticEnabled) {
      // HapticFeedback.lightImpact(); 
    }
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    _controller.reverse();
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