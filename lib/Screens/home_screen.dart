import 'package:aws_flutter_app/Screens/product_detail_screen.dart';
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
  final AuthController authController = Get.put(AuthController());
  final ProductListController controller = Get.put(ProductListController());
  String imageUrl = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Products'), centerTitle: true),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.to(() => ProductUploadScreen());
        },
        child: const Icon(Icons.add),
      ),

      body: Obx(() {
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

            return GestureDetector(
              onTap: () {
                Get.to(
                  () => ProductDetailScreen(
                    productId: product.id,
                    productName: product.name,
                    productDescription: product.description,
                    productPrice: product.price,
                    imagePath: imageUrl,
                  ),
                );
              },
              child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// ✅ IMAGE (Amplify-safe)
                      FutureBuilder<String?>(
                        future: controller.getImageUrl(product.imagePath),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const SizedBox(
                              width: 60,
                              height: 60,
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          }

                          if (!snapshot.hasData || snapshot.data == null) {
                            return const SizedBox(
                              width: 60,
                              height: 60,
                              child: Icon(Icons.broken_image),
                            );
                          }
                          imageUrl = snapshot.data!;
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              snapshot.data!,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.broken_image),
                            ),
                          );
                        },
                      ),

                      const SizedBox(width: 12),

                      /// ✅ PRODUCT INFO
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              product.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "\$${product.price}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
