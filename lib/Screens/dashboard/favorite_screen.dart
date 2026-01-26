import 'package:aws_flutter_app/controllers/favorite_controller.dart';
import 'package:aws_flutter_app/controllers/product_list_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FavoriteScreen extends StatelessWidget {
  const FavoriteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FavoriteController controller = Get.put(FavoriteController());
    final ProductListController homeController = Get.put(
      ProductListController(),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('My Favorites ❤️'), centerTitle: true),
      body: Obx(() {
        /// ⏳ Loading
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        /// 😕 Empty State
        if (controller.favoriteProducts.isEmpty) {
          return const Center(
            child: Text(
              "No favorite products yet",
              style: TextStyle(fontSize: 16),
            ),
          );
        }

        /// 📦 Favorite Products List
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: controller.favoriteProducts.length,
          itemBuilder: (context, index) {
            final product = controller.favoriteProducts[index];

            return Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),

                /// 🖼️ Image
                leading: FutureBuilder<String?>(
                  future: homeController.getImageUrl(product.imagePath),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        width: 60,
                        height: 60,
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
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

                /// 📝 Info
                title: Text(
                  product.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  product.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                /// 💰 Price + Remove
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "\$${product.price.toStringAsFixed(2)}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () {
                        controller.removeFromFavorites(productId: product.id);
                      },
                      child: const Icon(Icons.favorite, color: Colors.red),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
