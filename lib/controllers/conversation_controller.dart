import 'dart:convert';

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:get/get.dart';

class ConversationController extends GetxController {
  final RxList<Map<String, dynamic>> conversations =
      <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;

  late String currentUserId;

  @override
  void onInit() {
    super.onInit();
    loadConversations();
  }

  Future<void> loadConversations() async {
    isLoading.value = true;

    final user = await Amplify.Auth.getCurrentUser();
    currentUserId = user.userId;

    const query = '''
    query ListConversations {
      listConversations {
        items {
          id
          userA
          userB
          lastMessage
          updatedAt
        }
      }
    }
    ''';

    try {
      final response = await Amplify.API
          .query(request: GraphQLRequest(document: query))
          .response;

      if (response.errors.isNotEmpty) {
        safePrint("Inbox error: ${response.errors}");
        conversations.clear();
        return;
      }

      if (response.data == null) {
        conversations.clear();
        return;
      }

      final decoded = jsonDecode(response.data!);
      final items = decoded['listConversations']?['items'] as List? ?? [];

      conversations.value = items.map<Map<String, dynamic>>((c) {
        final otherUser = c['userA'] == currentUserId ? c['userB'] : c['userA'];

        return {
          'id': c['id'],
          'otherUserId': otherUser,
          'lastMessage': c['lastMessage'] ?? '',
          'updatedAt': c['updatedAt'],
        };
      }).toList();

      // Latest chat on top
      conversations.sort(
        (a, b) => DateTime.parse(
          b['updatedAt'],
        ).compareTo(DateTime.parse(a['updatedAt'])),
      );
    } catch (e) {
      safePrint("Load inbox error: $e");
      conversations.clear();
    } finally {
      isLoading.value = false;
    }
  }
}
