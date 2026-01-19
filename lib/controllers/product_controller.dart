import 'dart:io';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class ProductController extends GetxController {
  final ImagePicker _picker = ImagePicker();

  Rx<File?> imageFile = Rx<File?>(null);
  RxBool isLoading = false.obs;

  Future<void> pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      imageFile.value = File(pickedFile.path);
    }
  }

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

      /// ✅ MUST be public/
      final storagePath = StoragePath.fromString(
        'public/products/$productId.jpg',
      );

      final uploadResult = await Amplify.Storage.uploadFile(
        localFile: AWSFile.fromPath(imageFile.value!.path),
        path: storagePath,
        onProgress: (p) =>
            safePrint('Upload progress: ${p.fractionCompleted * 100}%'),
      ).result;

      final urlResult = await Amplify.Storage.getUrl(
        path: StoragePath.fromString(uploadResult.uploadedItem.path),
      ).result;

      final imageUrl = urlResult.url.toString();

      final mutation =
          '''
      mutation CreateProduct {
        createProduct(input: {
          id: "$productId"
          name: "$name"
          description: "$description"
          price: $price
          imageUrl: "$imageUrl"
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
