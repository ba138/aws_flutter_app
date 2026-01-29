import 'package:aws_flutter_app/controllers/product_list_controller.dart';
import 'package:aws_flutter_app/models/product_model.dart';
import 'package:aws_flutter_app/controllers/cart_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CartScreen extends StatelessWidget {
  CartScreen({super.key});

  final CartController cartController = Get.put(CartController());
  final ProductListController controller = Get.put(ProductListController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Cart"), centerTitle: true),
      body: Obx(() {
        if (cartController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (cartController.cartProducts.isEmpty) {
          return _emptyCart();
        }

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: cartController.cartProducts.length,
                itemBuilder: (context, index) {
                  final product = cartController.cartProducts[index];
                  final quantity = cartController.cartMap[product.id] ?? 1;

                  return _cartItem(product, quantity);
                },
              ),
            ),
            _cartSummary(),
          ],
        );
      }),
    );
  }

  /// 🧺 CART ITEM TILE
  Widget _cartItem(ProductModel product, int quantity) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: FutureBuilder<String?>(
          future: controller.getImageUrl(product.imagePath),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                width: 60,
                height: 60,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
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
                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
              ),
            );
          },
        ),
        title: Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("₹ ${product.price.toStringAsFixed(2)}"),
            const SizedBox(height: 4),
            Text("Qty: $quantity"),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () {
            cartController.removeFromCart(product.id);
          },
        ),
      ),
    );
  }

  /// 🧮 CART SUMMARY
  Widget _cartSummary() {
    double total = 0;

    for (final product in cartController.cartProducts) {
      final qty = cartController.cartMap[product.id] ?? 1;
      total += product.price * qty;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(blurRadius: 6, color: Colors.black.withOpacity(0.1)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Total: ₹ ${total.toStringAsFixed(2)}",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          ElevatedButton(
            onPressed: () {
              Get.snackbar("Checkout", "Proceed to payment 💳");
            },
            child: const Text("Checkout"),
          ),
        ],
      ),
    );
  }

  /// 🧾 EMPTY CART
  Widget _emptyCart() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            "Your cart is empty",
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
