import 'package:aws_flutter_app/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfileScreen extends StatelessWidget {
  ProfileScreen({super.key});

  final AuthController authController = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profile"), centerTitle: true),
      body: Obx(() {
        final user = authController.currentUser.value;

        if (user == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              /// 👤 PROFILE ICON
              const CircleAvatar(
                radius: 40,
                child: Icon(Icons.person, size: 45),
              ),

              const SizedBox(height: 16),

              /// 👤 NAME
              Text(
                user.name.isNotEmpty ? user.name : "No Name",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              /// 📧 EMAIL
              Text(
                user.email,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),

              const SizedBox(height: 12),

              /// 🆔 USER ID
              Text(
                "User ID:",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              Text(
                user.userId,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
              ),

              const Spacer(),

              /// 🚪 LOGOUT BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    authController.signOut();
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text("Logout"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.redAccent,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
