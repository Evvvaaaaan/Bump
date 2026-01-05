import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

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
  // Parallax offsets
  double _xOffset = 0.0;
  double _yOffset = 0.0;
  StreamSubscription<GyroscopeEvent>? _streamSubscription;

  // Animation controller for the "Aurora" flow
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(seconds: 10))
      ..repeat(reverse: true);

    // Subscribe to gyroscope
    _streamSubscription = gyroscopeEvents.listen((GyroscopeEvent event) {
      if (mounted) {
        setState(() {
          // Accumulate rotation to shift background
          // Sensitivity factor
          const double sensitivity = 2.0; 
          _xOffset -= event.y * sensitivity;
          _yOffset -= event.x * sensitivity;

          // Clamp offsets to keep it subtle
          _xOffset = _xOffset.clamp(-50.0, 50.0);
          _yOffset = _yOffset.clamp(-50.0, 50.0);
        });
      }
    });
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base dark layer
        Container(color: Colors.black),
        
        // Animated Gradient Layer
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft + Alignment(_xOffset * 0.01, _yOffset * 0.01),
                  end: Alignment.bottomRight + Alignment(_xOffset * 0.01, _yOffset * 0.01),
                  colors: [
                    Colors.black,
                    widget.primaryColor.withOpacity(0.6),
                    widget.accentColor.withOpacity(0.4),
                    Colors.black,
                  ],
                  stops: [
                    0.0,
                    0.3 + 0.1 * sin(_controller.value * 2 * pi), 
                    0.7 - 0.1 * cos(_controller.value * 2 * pi), 
                    1.0
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
