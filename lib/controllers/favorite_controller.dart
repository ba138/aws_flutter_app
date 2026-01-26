import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:get/get.dart';
import '../models/product_model.dart';

class FavoriteController extends GetxController {
  RxBool isLoading = false.obs;

  /// ❤️ Favorite product IDs (for icon state)
  RxSet<String> favoriteProductIds = <String>{}.obs;

  /// 📦 Favorite products (for UI list)
  RxList<ProductModel> favoriteProducts = <ProductModel>[].obs;

  RxString userId = ''.obs;

  @override
  void onInit() {
    fetchFavoriteProducts();
    super.onInit();
  }

  /// ⭐ ADD TO FAVORITES
  Future<void> addToFavorites({required String productId}) async {
    isLoading.value = true;

    try {
      final user = await Amplify.Auth.getCurrentUser();
      userId.value = user.userId;

      final mutation =
          '''
      mutation CreateFavorite {
        createFavorite(input: {
          userId: "${user.userId}"
          productId: "$productId"
        }) {
          id
        }
      }
      ''';

      await Amplify.API
          .mutate(request: GraphQLRequest(document: mutation))
          .response;

      favoriteProductIds.add(productId);
      await fetchFavoriteProducts();

      Get.snackbar("Saved", "Added to favorites ❤️");
    } catch (e) {
      safePrint("Add favorite error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// ❌ REMOVE FROM FAVORITES
  Future<void> removeFromFavorites({required String productId}) async {
    isLoading.value = true;

    try {
      final user = await Amplify.Auth.getCurrentUser();

      final query =
          '''
      query GetFavorite {
        listFavorites(
          filter: {
            userId: { eq: "${user.userId}" }
            productId: { eq: "$productId" }
          }
        ) {
          items { id }
        }
      }
      ''';

      final response = await Amplify.API
          .query(request: GraphQLRequest(document: query))
          .response;

      final data = jsonDecode(response.data!);
      final favId = data['listFavorites']['items'][0]['id'];

      final mutation =
          '''
      mutation DeleteFavorite {
        deleteFavorite(input: { id: "$favId" }) {
          id
        }
      }
      ''';

      await Amplify.API
          .mutate(request: GraphQLRequest(document: mutation))
          .response;

      favoriteProductIds.remove(productId);
      await fetchFavoriteProducts();

      Get.snackbar("Removed", "Removed from favorites");
    } catch (e) {
      safePrint("Remove favorite error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// 📥 FETCH FAVORITE PRODUCTS (MAIN FUNCTION)
  Future<void> fetchFavoriteProducts() async {
    isLoading.value = true;

    try {
      final user = await Amplify.Auth.getCurrentUser();
      userId.value = user.userId;

      /// 1️⃣ Get favorites of current user
      final favQuery =
          '''
      query ListFavorites {
        listFavorites(
          filter: { userId: { eq: "${user.userId}" } }
        ) {
          items {
            productId
          }
        }
      }
      ''';

      final favResponse = await Amplify.API
          .query(request: GraphQLRequest(document: favQuery))
          .response;

      final favData = jsonDecode(favResponse.data!);
      final favItems = favData['listFavorites']['items'] as List;

      favoriteProductIds.clear();
      favoriteProducts.clear();

      /// 2️⃣ Fetch each product by ID
      for (final fav in favItems) {
        final productId = fav['productId'];
        favoriteProductIds.add(productId);

        final productQuery =
            '''
        query GetProduct {
          getProduct(id: "$productId") {
            id
            name
            description
            price
            imagePath
            owner
            createdAt
          }
        }
        ''';

        final productResponse = await Amplify.API
            .query(request: GraphQLRequest(document: productQuery))
            .response;

        final productData = jsonDecode(productResponse.data!)['getProduct'];

        if (productData != null) {
          favoriteProducts.add(ProductModel.fromJson(productData));
        }
      }
    } catch (e) {
      safePrint("Fetch favorite products error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// ❤️ CHECK FAVORITE STATUS
  bool isFavorite(String productId) {
    return favoriteProductIds.contains(productId);
  }
}
