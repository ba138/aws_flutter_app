import 'dart:async';
import 'dart:convert';

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:get/get.dart' hide GraphQLResponse;
import 'package:uuid/uuid.dart';

class ChatController extends GetxController {
  final RxList<Map<String, dynamic>> messages = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;

  StreamSubscription<GraphQLResponse<String>>? _subscription;

  late String currentUserId;
  late String otherUserId;
  late String conversationId;

  /// INIT CHAT
  Future<void> initChat(String otherUser) async {
    final user = await Amplify.Auth.getCurrentUser();
    currentUserId = user.userId;
    otherUserId = otherUser;

    conversationId = _conversationId(currentUserId, otherUserId);

    await fetchMessages();
    subscribeMessages();
  }

  String _conversationId(String a, String b) {
    final ids = [a, b]..sort();
    return ids.join('_');
  }

  // ---------------------------------------------------------------------------
  // FETCH MESSAGES
  // ---------------------------------------------------------------------------
  Future<void> fetchMessages() async {
    isLoading.value = true;

    const query = '''
    query MessagesByConversation(\$cid: String!) {
      messagesByConversation(conversationId: \$cid) {
        items {
          id
          senderId
          receiverId
          text
          createdAt
        }
      }
    }
    ''';

    try {
      final response = await Amplify.API
          .query(
            request: GraphQLRequest(
              document: query,
              variables: {"cid": conversationId},
            ),
          )
          .response;

      if (response.errors.isNotEmpty) {
        safePrint("Fetch messages error: ${response.errors}");
        messages.clear();
        return;
      }

      if (response.data == null) {
        messages.clear();
        return;
      }

      final decoded = jsonDecode(response.data!);
      final items = decoded['messagesByConversation']?['items'] as List? ?? [];

      messages.value = items.map<Map<String, dynamic>>((item) {
        final senderId = item['senderId'];
        return {
          'id': item['id'],
          'fromMe': senderId == currentUserId,
          'senderId': senderId,
          'receiverId': item['receiverId'],
          'text': item['text'],
          'createdAt': item['createdAt'],
        };
      }).toList();

      messages.sort(
        (a, b) => DateTime.parse(
          a['createdAt'],
        ).compareTo(DateTime.parse(b['createdAt'])),
      );
    } catch (e) {
      safePrint("Error fetching messages: $e");
      messages.clear();
    } finally {
      isLoading.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // SEND MESSAGE
  // ---------------------------------------------------------------------------
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    const mutation = '''
    mutation SendMessage(\$input: CreateMessageInput!) {
      createMessage(input: \$input) {
        id
        conversationId
        senderId
        receiverId
        text
        createdAt
      }
    }
    ''';

    final variables = {
      "input": {
        "id": const Uuid().v4(),
        "conversationId": conversationId,
        "senderId": currentUserId,
        "receiverId": otherUserId,
        "text": text.trim(),
      },
    };

    try {
      final response = await Amplify.API
          .mutate(
            request: GraphQLRequest(document: mutation, variables: variables),
          )
          .response;

      if (response.errors.isNotEmpty) {
        safePrint("Send message failed: ${response.errors}");
        return;
      }

      // ❗ DO NOT add locally
      // Subscription OR refetch will handle it
    } catch (e) {
      safePrint("Send message error: $e");
    }
  }

  // ---------------------------------------------------------------------------
  // REALTIME SUBSCRIPTION
  // ---------------------------------------------------------------------------
  void subscribeMessages() {
    const subscription = '''
  subscription OnCreateMessage {
    onCreateMessage {
      id
      conversationId
      senderId
      receiverId
      text
      createdAt
    }
  }
  ''';

    _subscription = Amplify.API
        .subscribe(
          GraphQLRequest<String>(document: subscription),
          onEstablished: () => safePrint("Chat subscription established"),
        )
        .listen(
          (event) {
            if (event.data == null) return;

            final decoded = jsonDecode(event.data!);
            final msg = decoded['onCreateMessage'];
            if (msg == null) return;

            // 🔥 FILTER HERE
            if (msg['conversationId'] != conversationId) return;

            // Prevent duplicates
            if (messages.any((m) => m['id'] == msg['id'])) return;

            messages.add({
              'id': msg['id'],
              'fromMe': msg['senderId'] == currentUserId,
              'senderId': msg['senderId'],
              'receiverId': msg['receiverId'],
              'text': msg['text'],
              'createdAt': msg['createdAt'],
            });

            messages.sort(
              (a, b) => DateTime.parse(
                a['createdAt'],
              ).compareTo(DateTime.parse(b['createdAt'])),
            );
          },
          onError: (error) {
            safePrint("Subscription error: $error");
          },
        );
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}
