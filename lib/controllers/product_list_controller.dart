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
          imageUrl
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

      products.value = items.map((e) => ProductModel.fromJson(e)).toList();
    } catch (e) {
      safePrint('Fetch error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Optional: refresh like Firestore pull-to-refresh
  Future<void> refreshProducts() async {
    await fetchProducts();
  }
}
