import 'dart:math';
import 'dart:ui' as ui;

import 'package:bump/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CardDetailScreen extends StatefulWidget {
  const CardDetailScreen({super.key});

  @override
  State<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends State<CardDetailScreen> {
  // Rotation state
  double _rotationX = 0.0;
  double _rotationY = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => context.go('/'), // Back to home
        ),
        actions: [
           IconButton(
          icon: const Icon(Icons.share, color: Colors.white),
          onPressed: () {},
        ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // 3D Rotatable Card
            GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _rotationY -= details.delta.dx * 0.01;
                  _rotationX += details.delta.dy * 0.01;
                });
              },
              child: Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateX(_rotationX)
                  ..rotateY(_rotationY),
                alignment: Alignment.center,
                child: _build3DCard(),
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Context Info (Ice Breaking)
            _buildIceBreakingInfo(),
            
            const SizedBox(height: 20),
            
            // Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(child: _buildActionButton(Icons.save_alt, "Save Contact", Colors.blue)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildActionButton(Icons.chat_bubble_outline, "Message", Colors.green)),
                ],
              ),
            ),
             const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _build3DCard() {
    return Container(
      width: 320,
      height: 500,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[900]!,
            Colors.black,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 30,
            spreadRadius: 5,
          )
        ],
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Stack(
        children: [
          // Background Texture
          Positioned.fill(
             child: Opacity(opacity: 0.1, child: const Icon(Icons.grid_4x4, size: 200, color: Colors.white)),
          ),
          
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(radius: 30, backgroundColor: Colors.grey[800], child: const Icon(Icons.person, color: Colors.white)),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text("Jane Doe", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        Text("UX Designer @ Tech Corp", style: TextStyle(color: Colors.grey)),
                      ],
                    )
                  ],
                ),
                const Spacer(),
                const Text("MBTI: ENFP", style: TextStyle(color: Colors.white)),
                const SizedBox(height: 8),
                Row(
                  children: [
                     _buildTag("#Tennis"),
                     _buildTag("#Wine"),
                     _buildTag("#Travel"),
                  ],
                ),
                const SizedBox(height: 20),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.white,
                    child: const Icon(Icons.qr_code, size: 80, color: Colors.black),
                  ),
                )
              ],
            ),
          ),
          
          // Shine Effect
          Positioned.fill(
             child: Container(
               decoration: BoxDecoration(
                 gradient: LinearGradient(
                   begin: Alignment(-_rotationY, -_rotationX),
                   end: Alignment(_rotationY, _rotationX),
                   colors: [
                     Colors.white.withOpacity(0.0),
                     Colors.white.withOpacity(0.1),
                     Colors.white.withOpacity(0.0),
                   ],
                 ),
               ),
             ),
          ),
        ],
      ),
    );
  }

  Widget _buildIceBreakingInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.socialAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.socialAccent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb, color: Colors.yellow),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: const TextSpan(
                style: TextStyle(color: Colors.white),
                children: [
                  TextSpan(text: "Both of you like "),
                  TextSpan(text: "Tennis 🎾 ", style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: "and "),
                  TextSpan(text: "Wine 🍷", style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: "!"),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true))
    .shimmer(duration: 2.seconds, delay: 1.seconds);
  }

  Widget _buildTag(String label) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
    );
  }
  
  Widget _buildActionButton(IconData icon, String label, Color color) {
    return ElevatedButton(
      onPressed: (){},
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.2),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: color.withOpacity(0.5)),
        )
      ),
      child: Column(
        children: [
          Icon(icon),
          const SizedBox(height: 4),
          Text(label),
        ],
      ),
    );
  }
}
