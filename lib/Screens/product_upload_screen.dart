import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/product_controller.dart';

class ProductUploadScreen extends StatelessWidget {
  ProductUploadScreen({super.key});

  final ProductController controller = Get.put(ProductController());
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController descCtrl = TextEditingController();
  final TextEditingController priceCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upload Product")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// Image Picker
            Obx(
              () => GestureDetector(
                onTap: controller.pickImage,
                child: Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: controller.imageFile.value == null
                      ? const Center(child: Text("Tap to select image"))
                      : Image.file(
                          controller.imageFile.value!,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            /// Name
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: "Product Name"),
            ),

            /// Description
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(
                labelText: "Product Description",
              ),
              maxLines: 3,
            ),

            /// Price
            TextField(
              controller: priceCtrl,
              decoration: const InputDecoration(labelText: "Price"),
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 24),

            /// Upload Button
            Obx(
              () => SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: controller.isLoading.value
                      ? null
                      : () {
                          controller.uploadProduct(
                            name: nameCtrl.text.trim(),
                            description: descCtrl.text.trim(),
                            price: double.parse(priceCtrl.text.trim()),
                          );
                        },
                  child: controller.isLoading.value
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Upload Product"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
