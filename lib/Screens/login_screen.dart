import 'package:aws_flutter_app/Screens/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController controller = Get.put(AuthController());

    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            Obx(
              () => ElevatedButton(
                onPressed: controller.isLoading.value
                    ? null
                    : () => controller.signIn(
                        email: emailController.text,
                        password: passwordController.text,
                      ),
                child: controller.isLoading.value
                    ? const CircularProgressIndicator()
                    : const Text('Login'),
              ),
            ),
            Text('Don\'t have an account?'),
            TextButton(
              onPressed: () {
                Get.to(() => const RegisterScreen());
              },
              child: const Text('Register Here'),
            ),
          ],
        ),
      ),
    );
  }
}
