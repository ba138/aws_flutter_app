import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:get/get.dart';
import '../models/product_model.dart';

class CartController extends GetxController {
  RxBool isLoading = false.obs;

  /// productId -> quantity
  RxMap<String, int> cartMap = <String, int>{}.obs;

  /// UI list
  RxList<ProductModel> cartProducts = <ProductModel>[].obs;

  @override
  void onInit() {
    fetchCartProducts();
    super.onInit();
  }

  /// 🔐 Get current user
  Future<String> _getUserId() async {
    final user = await Amplify.Auth.getCurrentUser();
    return user.userId;
  }

  /// ➕ ADD TO CART
  Future<void> addToCart({required String productId}) async {
    try {
      final userId = await _getUserId();

      /// 🔍 Already exists
      if (cartMap.containsKey(productId)) {
        Get.snackbar("Already Added", "This product is already in cart 🛒");
        return;
      }

      const mutation = '''
      mutation CreateCartItem(\$userId: String!, \$productId: ID!) {
        createCartItem(input: {
          userId: \$userId
          productId: \$productId
          quantity: 1
        }) {
          id
          productId
          quantity
        }
      }
      ''';

      final response = await Amplify.API
          .mutate(
            request: GraphQLRequest(
              document: mutation,
              variables: {"userId": userId, "productId": productId},
            ),
          )
          .response;

      if (response.errors.isNotEmpty) {
        safePrint(response.errors.first.message);
        return;
      }

      /// ✅ Update local map only
      cartMap[productId] = 1;

      /// 🔄 Refresh cart products
      await fetchCartProducts();

      Get.snackbar("Success", "Added to cart 🛒");
    } catch (e) {
      safePrint("Add to cart error: $e");
    }
  }

  /// 📥 FETCH CART PRODUCTS
  Future<void> fetchCartProducts() async {
    try {
      final userId = await _getUserId();
      isLoading.value = true;

      /// 1️⃣ Get cart items
      const cartQuery = '''
      query ListCartItems {
        listCartItems {
          items {
            id
            userId
            productId
            quantity
          }
        }
      }
      ''';

      final cartResponse = await Amplify.API
          .query(request: GraphQLRequest(document: cartQuery))
          .response;

      final cartData = jsonDecode(cartResponse.data!);
      final items = cartData['listCartItems']['items'] as List;

      cartMap.clear();
      final productIds = <String>[];

      for (final item in items) {
        if (item['userId'] == userId) {
          cartMap[item['productId']] = item['quantity'];
          productIds.add(item['productId']);
        }
      }

      if (productIds.isEmpty) {
        cartProducts.clear();
        return;
      }

      /// 2️⃣ Get products
      const productQuery = '''
      query ListProducts {
        listProducts {
          items {
            id
            name
            description
            price
            imagePath
            createdAt
          }
        }
      }
      ''';

      final productResponse = await Amplify.API
          .query(request: GraphQLRequest(document: productQuery))
          .response;

      final productData = jsonDecode(productResponse.data!);
      final products = productData['listProducts']['items'] as List;

      cartProducts.value = products
          .where((p) => productIds.contains(p['id']))
          .map((e) => ProductModel.fromJson(e))
          .toList();
    } catch (e) {
      safePrint("Fetch cart error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// ❌ REMOVE FROM CART
  Future<void> removeFromCart(String productId) async {
    try {
      final userId = await _getUserId();

      const query = '''
      query ListCartItems {
        listCartItems {
          items {
            id
            productId
            userId
          }
        }
      }
      ''';

      final response = await Amplify.API
          .query(request: GraphQLRequest(document: query))
          .response;

      final data = jsonDecode(response.data!);
      final items = data['listCartItems']['items'] as List;

      final cartItem = items.firstWhere(
        (e) => e['productId'] == productId && e['userId'] == userId,
        orElse: () => null,
      );

      if (cartItem == null) return;

      final deleteMutation =
          '''
      mutation DeleteCartItem {
        deleteCartItem(input: { id: "${cartItem['id']}" }) {
          id
        }
      }
      ''';

      await Amplify.API
          .mutate(request: GraphQLRequest(document: deleteMutation))
          .response;

      cartMap.remove(productId);
      cartProducts.removeWhere((p) => p.id == productId);

      Get.snackbar("Removed", "Product removed from cart");
    } catch (e) {
      safePrint("Remove cart error: $e");
    }
  }
}
