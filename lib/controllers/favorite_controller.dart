import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:get/get.dart';

class FavoriteController extends GetxController {
  RxBool isLoading = false.obs;
  RxSet<String> favoriteProductIds = <String>{}.obs;

  @override
  void onInit() {
    fetchFavorites();
    super.onInit();
  }

  /// ⭐ ADD PRODUCT TO FAVORITES
  Future<void> addToFavorites({
    required String productId,
    required String userId,
  }) async {
    isLoading.value = true;

    final mutation =
        '''
    mutation CreateFavorite {
      createFavorite(input: {
        productId: "$productId"
        userId: "$userId"
      }) {
        id
        productId
      }
    }
    ''';

    try {
      final response = await Amplify.API
          .mutate(request: GraphQLRequest(document: mutation))
          .response;

      if (response.errors.isNotEmpty) {
        safePrint(response.errors.first.message);
        return;
      }

      favoriteProductIds.add(productId);
      Get.snackbar("Saved", "Added to favorites ❤️");
    } catch (e) {
      safePrint("Add favorite error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// ❌ REMOVE FROM FAVORITES
  Future<void> removeFromFavorites(String favoriteId) async {
    isLoading.value = true;

    final mutation =
        '''
    mutation DeleteFavorite {
      deleteFavorite(input: {
        id: "$favoriteId"
      }) {
        id
      }
    }
    ''';

    try {
      await Amplify.API
          .mutate(request: GraphQLRequest(document: mutation))
          .response;

      // Remove locally (optional refresh)
      fetchFavorites();
      Get.snackbar("Removed", "Removed from favorites");
    } catch (e) {
      safePrint("Remove favorite error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// 📥 FETCH USER FAVORITES
  Future<void> fetchFavorites() async {
    const query = '''
    query ListFavorites {
      listFavorites {
        items {
          id
          productId
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
      final items = data['listFavorites']['items'] as List;

      favoriteProductIds.clear();
      for (final item in items) {
        favoriteProductIds.add(item['productId']);
      }
    } catch (e) {
      safePrint("Fetch favorites error: $e");
    }
  }

  /// ❤️ CHECK IF PRODUCT IS FAVORITED
  bool isFavorite(String productId) {
    return favoriteProductIds.contains(productId);
  }
}
