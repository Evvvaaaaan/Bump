import 'package:bump/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("My Personas"),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: "Business"),
            Tab(text: "Social"),
            Tab(text: "Private"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBusinessForm(),
          _buildSocialForm(),
          _buildPrivateForm(),
        ],
      ),
    );
  }

  Widget _buildBusinessForm() {
    return _buildFormLayout(
      color: AppColors.businessPrimary,
      children: [
        _buildTextField("Company Name", "Tech Corp"),
        _buildTextField("Role", "Senior UX Designer"),
        _buildTextField("Email", "evan@example.com"),
        _buildTextField("LinkedIn", "linkedin.com/in/evan"),
        const SizedBox(height: 20),
        Center(child: _buildUploadButton("Upload Business Card Image")),
      ],
    );
  }

  Widget _buildSocialForm() {
    return _buildFormLayout(
      color: AppColors.socialPrimary,
      children: [
        _buildTextField("Nickname", "Evan"),
        _buildTextField("Instagram", "@evan_design"),
        _buildTextField("MBTI", "ENFP"),
        const SizedBox(height: 20),
        const Text("Hobbies (Max 5)", style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: [
            _buildChip("Tennis", true),
            _buildChip("Travel", true),
            _buildChip("Wine", false),
            _buildChip("Coding", false),
          ],
        ),
      ],
    );
  }

  Widget _buildPrivateForm() {
    return _buildFormLayout(
      color: AppColors.privatePrimary,
      children: [
        _buildTextField("Private Email", "me@gmail.com"),
        _buildTextField("Phone", "+82 10-1234-5678"),
        const SizedBox(height: 20),
        const Text("Only shared with trusted connections.", style: TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildFormLayout({required Color color, required List<Widget> children}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Container(
             height: 5, 
             width: 50, 
             decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
             margin: const EdgeInsets.only(bottom: 20),
           ),
           ...children,
           const SizedBox(height: 40),
           SizedBox(
             width: double.infinity,
             child: ElevatedButton(
               style: ElevatedButton.styleFrom(backgroundColor: color),
               onPressed: () {}, 
               child: const Text("Save & Preview", style: TextStyle(color: Colors.white)),
             ),
           )
        ],
      ),
    );
  }

  Widget _buildTextField(String label, String placeholder) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 5),
          TextField(
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: TextStyle(color: Colors.grey[700]),
              filled: true,
              fillColor: Colors.grey[900],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadButton(String label) {
    return Container(
      width: double.infinity,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.upload_file, color: Colors.grey),
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildChip(String label, bool selected) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (v) {},
      backgroundColor: Colors.grey[900],
      selectedColor: AppColors.socialAccent.withOpacity(0.5),
      labelStyle: TextStyle(color: selected ? Colors.white : Colors.grey),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
    );
  }
}
