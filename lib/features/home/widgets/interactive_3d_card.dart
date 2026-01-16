import 'dart:math';
import 'package:flutter/material.dart';

class Interactive3DCard extends StatefulWidget {
  final Widget child;
  const Interactive3DCard({super.key, required this.child});

  @override
  State<Interactive3DCard> createState() => _Interactive3DCardState();
}

class _Interactive3DCardState extends State<Interactive3DCard> with SingleTickerProviderStateMixin {
  Offset _offset = Offset.zero;
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = Tween<Offset>(begin: Offset.zero, end: Offset.zero).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    setState(() {
      _offset += details.delta;
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    // Release causes the card to slowly float back or stay? 
    // Usually "viewing while moving" implies control. 
    // Resetting to zero looks cleaner as a UI element.
    final currentOffset = _offset;
    _animation = Tween<Offset>(begin: currentOffset, end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward(from: 0);
    setState(() {
      _offset = Offset.zero;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final offset = _controller.isAnimating ? _animation.value : _offset;
        
        // Sensitivity factor
        const double sensitivity = 0.002;
        
        // Calculate rotation angles
        // Dragging horizontally (dx) rotates around Y axis
        // Dragging vertically (dy) rotates around X axis
        // Invert X rotation so dragging up tilts card away (top goes back)
        final double rotateX = 0 - (offset.dy * sensitivity); 
        final double rotateY = offset.dx * sensitivity;

        // Clamp rotation to prevent flipping (approx 45 degrees)
        final double clampedX = rotateX.clamp(-pi / 3, pi / 3);
        final double clampedY = rotateY.clamp(-pi / 3, pi / 3);

        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001) // Perspective
            ..rotateX(clampedX)
            ..rotateY(clampedY),
          alignment: Alignment.center,
          child: GestureDetector(
            onPanUpdate: _handlePanUpdate,
            onPanEnd: _handlePanEnd,
            // Use transparent hit test behavior to catch touches everywhere on the card
            behavior: HitTestBehavior.opaque, 
            child: widget.child,
          ),
        );
      },
    );
  }
}
