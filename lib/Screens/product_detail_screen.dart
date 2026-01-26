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
                  /// Optional: remove later using favoriteId
                  Get.snackbar(
                    "Already saved",
                    "This product is already in favorites",
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
            Image.network(
              widget.imagePath,
              width: double.infinity,
              height: 250,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.broken_image, size: 100),
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
