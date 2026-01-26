import 'package:aws_flutter_app/controllers/product_list_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/favorite_controller.dart';
import '../controllers/auth_controller.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  final String productName;
  final String productDescription;
  final double productPrice;
  final String imagePath;

  const ProductDetailScreen({
    super.key,
    required this.productId,
    required this.productName,
    required this.productDescription,
    required this.productPrice,
    required this.imagePath,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final FavoriteController favoriteController = Get.put(FavoriteController());
  final ProductListController controller = Get.put(ProductListController());

  final AuthController authController = Get.put(AuthController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Product Details"),
        actions: [
          Obx(() {
            final isFav = favoriteController.isFavorite(widget.productId);

            return IconButton(
              icon: Icon(
                isFav ? Icons.favorite : Icons.favorite_border,
                color: Colors.red,
              ),
              onPressed: () {
                if (isFav) {
                  favoriteController.removeFromFavorites(
                    productId: widget.productId,
                  );
                } else {
                  favoriteController.addToFavorites(
                    productId: widget.productId,
                  );
                }
              },
            );
          }),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<String?>(
              future: controller.getImageUrl(widget.imagePath),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    width: double.infinity,
                    height: 200,
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
                  borderRadius: BorderRadius.circular(0),
                  child: Image.network(
                    snapshot.data!,
                    width: double.infinity,
                    height: 300,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.broken_image),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.productName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(widget.productDescription),
                  const SizedBox(height: 12),
                  Text(
                    "\$${widget.productPrice.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
