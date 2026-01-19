import 'package:aws_flutter_app/Screens/product_upload_screen.dart';
import 'package:aws_flutter_app/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  var authController = Get.put(AuthController());
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.to(() => ProductUploadScreen());
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,

        children: [
          ElevatedButton(
            onPressed: () {
              authController.signOut();
            },
            child: const Icon(Icons.logout),
          ),
        ],
      ),
    );
  }
}
