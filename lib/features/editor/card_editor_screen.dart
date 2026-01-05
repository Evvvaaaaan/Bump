import 'package:bump/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CardEditorScreen extends StatefulWidget {
  const CardEditorScreen({super.key});

  @override
  State<CardEditorScreen> createState() => _CardEditorScreenState();
}

class _CardEditorScreenState extends State<CardEditorScreen> {
  // Editing State
  int _selectedTexture = 0; // 0:Matte, 1:Glossy, 2:Metal
  int _selectedTheme = 0; // 0:Aurora, 1:Cyber, 2:Minimal
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text("The Studio"),
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(), // Save and exit
            child: const Text("Done", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: Column(
        children: [
          // 1. Preview Area (Top Half)
          Expanded(
            flex: 3,
            child: Center(
              child: _buildCardPreview(),
            ),
          ),
          
          // 2. Tools Panel (Bottom Half)
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Texture", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  _buildTextureSelector(),
                  
                  const SizedBox(height: 20),
                  
                  const Text("Theme", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  _buildThemeSelector(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardPreview() {
    return Container(
      width: 280,
      height: 450,
      decoration: BoxDecoration(
        color: _getThemeColor(),
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getThemeColor().withOpacity(0.8),
            Colors.black,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: _getThemeColor().withOpacity(0.5),
            blurRadius: 30,
            spreadRadius: 2,
          )
        ],
        border: Border.all(
          color: Colors.white.withOpacity(_selectedTexture == 2 ? 0.5 : 0.1), // Metal border
          width: _selectedTexture == 2 ? 2 : 1,
        )
      ),
      child: Stack(
        children: [
          // Texture Overlay
          if (_selectedTexture == 1) // Glossy
            Positioned(
              top: 0, left: 0, right: 0, height: 200,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white.withOpacity(0.2), Colors.transparent], 
                    begin: Alignment.topCenter, end: Alignment.bottomCenter
                  )
                ),
              ),
            ),
            
           Center(
             child: Column(
               mainAxisAlignment: MainAxisAlignment.center,
               children: const [
                 CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
                 SizedBox(height: 10),
                 Text("Evan's Card", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
               ],
             ),
           ),
        ],
      ),
    );
  }

  Color _getThemeColor() {
    switch (_selectedTheme) {
      case 0: return AppColors.businessPrimary;
      case 1: return AppColors.socialPrimary;
      case 2: return AppColors.privatePrimary;
      default: return Colors.blue;
    }
  }

  Widget _buildTextureSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildToolOption("Matte", 0, _selectedTexture, (v) => setState(() => _selectedTexture = v)),
        _buildToolOption("Glossy", 1, _selectedTexture, (v) => setState(() => _selectedTexture = v)),
        _buildToolOption("Metal", 2, _selectedTexture, (v) => setState(() => _selectedTexture = v)),
      ],
    );
  }

  Widget _buildThemeSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildToolOption("Aurora", 0, _selectedTheme, (v) => setState(() => _selectedTheme = v)),
        _buildToolOption("Cyber", 1, _selectedTheme, (v) => setState(() => _selectedTheme = v)),
        _buildToolOption("Mono", 2, _selectedTheme, (v) => setState(() => _selectedTheme = v)),
      ],
    );
  }

  Widget _buildToolOption(String label, int value, int groupValue, Function(int) onTap) {
    bool isSelected = value == groupValue;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label, 
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
          )
        ),
      ),
    );
  }
}
