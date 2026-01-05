import 'package:flutter/material.dart';

class SlideToExchange extends StatefulWidget {
  final VoidCallback onSlideComplete;

  const SlideToExchange({super.key, required this.onSlideComplete});

  @override
  State<SlideToExchange> createState() => _SlideToExchangeState();
}

class _SlideToExchangeState extends State<SlideToExchange> {
  double _dragValue = 0.0;
  final double _maxWidth = 300.0;
  final double _buttonWidth = 60.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _maxWidth,
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(35),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          const Center(
            child: Text(
              "Slide to Exchange  >>>",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Positioned(
            left: _dragValue,
            child: GestureDetector(
              onHorizontalDragUpdate: (details) {
                setState(() {
                  _dragValue += details.delta.dx;
                  _dragValue = _dragValue.clamp(0.0, _maxWidth - _buttonWidth - 10);
                });
              },
              onHorizontalDragEnd: (details) {
                // Check if dragged enough (e.g., > 80%)
                if (_dragValue > (_maxWidth - _buttonWidth - 10) * 0.8) {
                   widget.onSlideComplete();
                   // Snap to end
                   setState(() {
                     _dragValue = _maxWidth - _buttonWidth - 10;
                   });
                } else {
                  // Reset
                  setState(() {
                    _dragValue = 0.0;
                  });
                }
              },
              child: Container(
                width: _buttonWidth,
                height: 60,
                margin: const EdgeInsets.only(left: 5),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_forward, color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
