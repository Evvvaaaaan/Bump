import 'package:bump/features/bump/widgets/flying_card.dart';
import 'package:bump/features/bump/widgets/slide_to_exchange.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vibration/vibration.dart';

class BumpScreen extends StatefulWidget {
  const BumpScreen({super.key});

  @override
  State<BumpScreen> createState() => _BumpScreenState();
}

class _BumpScreenState extends State<BumpScreen> {
  bool _isExchanging = false;
  bool _exchangeComplete = false;

  @override
  void initState() {
    super.initState();
    // Vibrate on entry
    Vibration.vibrate(duration: 200);
  }

  void _handleExchange() {
    if (_isExchanging) return;

    setState(() {
      _isExchanging = true;
    });

    // Simulate network delay and animation
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _exchangeComplete = true;
        });
        
         // Success haptic
        Vibration.vibrate(pattern: [0, 50, 100, 50]);
        
        // Navigate to Card Detail after brief delay
        Future.delayed(const Duration(milliseconds: 500), () {
          context.go('/card_detail'); 
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.9), // Dimmed background
      body: Stack(
        children: [
          // Close Button
          Positioned(
            top: 50,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => context.pop(),
            ),
          ),

          // Flying Cards Animation Area
          Center(
            child: SizedBox(
              height: 400,
              width: double.infinity,
              child: Stack(
                children: [
                   // Opponent Card (Top Right descending)
                   Align(
                     alignment: Alignment.topRight,
                     child: FlyingCard(
                       isMine: false,
                       isExchanging: _isExchanging,
                     ),
                   ),
                   // My Card (Bottom Left ascending)
                   Align(
                     alignment: Alignment.bottomLeft,
                     child: FlyingCard(
                       isMine: true,
                       isExchanging: _isExchanging,
                     ),
                   ),
                ],
              ),
            ),
          ),

          // Slide to Exchange Button
          if (!_exchangeComplete)
          Positioned(
            bottom: 80,
            left: 40,
            right: 40,
            child: SlideToExchange(
              onSlideComplete: _handleExchange,
            ),
          ),
          
          if (_exchangeComplete)
            const Center(
              child: Text("Connected!", style: TextStyle(
                color: Colors.white, 
                fontSize: 32, 
                fontWeight: FontWeight.bold)
              ),
            )
        ],
      ),
    );
  }
}
