import 'package:aws_flutter_app/Screens/product_upload_screen.dart';
import 'package:aws_flutter_app/controllers/auth_controller.dart';
import 'package:aws_flutter_app/controllers/product_list_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  var authController = Get.put(AuthController());
  final ProductListController controller = Get.put(ProductListController());
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
          // ElevatedButton(
          //   onPressed: () {
          //     authController.signOut();
          //   },
          //   child: const Icon(Icons.logout),
          // ),
          Obx(() {
            if (controller.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }

            if (controller.products.isEmpty) {
              return const Center(child: Text("No products found"));
            }

            return ListView.builder(
              itemCount: controller.products.length,
              itemBuilder: (context, index) {
                final product = controller.products[index];

                return Card(
                  child: ListTile(
                    leading: Image.network(
                      product.imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                    title: Text(product.name),
                    subtitle: Text(product.description),
                    trailing: Text("\$${product.price}"),
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }
}
