import 'dart:io';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class ProductController extends GetxController {
  final ImagePicker _picker = ImagePicker();

  Rx<File?> imageFile = Rx<File?>(null);
  RxBool isLoading = false.obs;

  /// Pick image
  Future<void> pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      imageFile.value = File(pickedFile.path);
    }
  }

  /// Upload product
  Future<void> uploadProduct({
    required String name,
    required String description,
    required double price,
  }) async {
    if (imageFile.value == null) {
      Get.snackbar("Error", "Please select an image");
      return;
    }

    isLoading.value = true;

    try {
      final productId = const Uuid().v4();

      /// ✅ PUBLIC PATH (PERMANENT)
      final imagePath = 'public/products/$productId.jpg';
      final storagePath = StoragePath.fromString(imagePath);

      /// ✅ Upload image
      await Amplify.Storage.uploadFile(
        localFile: AWSFile.fromPath(imageFile.value!.path),
        path: storagePath,
        onProgress: (p) => safePrint(
          'Upload progress: ${(p.fractionCompleted * 100).toInt()}%',
        ),
      ).result;

      /// ❌ DO NOT call getUrl() here
      /// ✅ Store only imagePath in DB

      final mutation =
          '''
      mutation CreateProduct {
        createProduct(input: {
          id: "$productId"
          name: "$name"
          description: "$description"
          price: $price
          imagePath: "$imagePath"
        }) {
          id
        }
      }
      ''';

      await Amplify.API
          .mutate(request: GraphQLRequest(document: mutation))
          .response;

      imageFile.value = null;
      Get.back();
      Get.snackbar("Success", "Product uploaded successfully");
    } catch (e) {
      safePrint("Upload error: $e");
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}
