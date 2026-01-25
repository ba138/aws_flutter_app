import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:get/get.dart';
import '../models/product_model.dart';

class ProductListController extends GetxController {
  RxList<ProductModel> products = <ProductModel>[].obs;
  RxBool isLoading = false.obs;

  @override
  void onInit() {
    fetchProducts();
    super.onInit();
  }

  Future<void> fetchProducts() async {
    isLoading.value = true;

    const query = '''
    query ListProducts {
      listProducts {
        items {
          id
          name
          description
          price
          imagePath
          owner
          createdAt
        }
      }
    }
    ''';

    try {
      final response = await Amplify.API
          .query(request: GraphQLRequest(document: query))
          .response;

      if (response.errors.isNotEmpty) {
        safePrint(response.errors.first.message);
        return;
      }

      final data = jsonDecode(response.data!);
      final items = data['listProducts']['items'] as List;

      products.value = items
          .where((e) => e != null)
          .map((e) => ProductModel.fromJson(e))
          .toList();
    } catch (e) {
      safePrint('Fetch error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshProducts() async {
    await fetchProducts();
  }

  Future<String?> getImageUrl(String path) async {
    try {
      final result = await Amplify.Storage.getUrl(
        path: StoragePath.fromString(path),
      ).result;

      return result.url.toString();
    } catch (e) {
      safePrint('Get URL error: $e');
      return null;
    }
  }
}
