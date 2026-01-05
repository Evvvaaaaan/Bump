import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class FlyingCard extends StatelessWidget {
  final bool isMine;
  final bool isExchanging;

  const FlyingCard({
    super.key,
    required this.isMine,
    required this.isExchanging,
  });

  @override
  Widget build(BuildContext context) {
    // 3D Transform values
    final Matrix4 transform = Matrix4.identity()
      ..setEntry(3, 2, 0.001) // Perspective
      ..rotateX(isMine ? -0.5 : 0.5)
      ..rotateY(isMine ? 0.2 : -0.2);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 800),
      curve: Curves.fastOutSlowIn,
      transform: isExchanging 
          ? (Matrix4.identity()..setEntry(3, 2, 0.001)..rotateX(0)..rotateY(0)..scale(0.5)..translate(0.0, isMine ? -100.0 : 100.0)) // Fly to center
          : transform, 
      child: Container(
        width: 200,
        height: 120,
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isMine ? Colors.blue.withOpacity(0.5) : Colors.pink.withOpacity(0.5),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
          gradient: LinearGradient(
            colors: isMine 
              ? [const Color(0xFF1E3A8A), const Color(0xFF2563EB)] 
              : [Colors.grey.withOpacity(0.3), Colors.grey.withOpacity(0.1)], // blurred for opponent
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: isMine 
          ? _buildMyCardContent()
          : _buildOpponentCardContent(),
      ),
    )
    .animate(target: isExchanging ? 1 : 0)
    .shimmer(duration: 1.seconds); // Add shimmer when exchanging
  }

  Widget _buildMyCardContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.nfc, color: Colors.white, size: 40),
        SizedBox(height: 8),
        Text("Evan's Card", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildOpponentCardContent() {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: const Center(
            child: Icon(Icons.question_mark, color: Colors.white, size: 40),
          ),
        ),
      ),
    );
  }
}
