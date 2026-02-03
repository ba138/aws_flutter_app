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

    final messageId = const Uuid().v4();
    final now = DateTime.now().toIso8601String();

    // ------------------ ADD OPTIMISTIC UI ------------------
    messages.add({
      'id': messageId,
      'fromMe': true,
      'senderId': currentUserId,
      'receiverId': otherUserId,
      'text': text.trim(),
      'createdAt': now,
    });

    messages.sort(
      (a, b) => DateTime.parse(
        a['createdAt'],
      ).compareTo(DateTime.parse(b['createdAt'])),
    );
    // -------------------------------------------------------

    const createMessageMutation = '''
  mutation CreateMessage(\$input: CreateMessageInput!) {
    createMessage(input: \$input) {
      id
      text
      createdAt
    }
  }
  ''';

    const upsertConversationMutation = '''
  mutation UpsertConversation(\$input: CreateConversationInput!) {
    createConversation(input: \$input) {
      id
      lastMessage
      updatedAt
    }
  }
  ''';

    final messageInput = {
      "id": messageId,
      "conversationId": conversationId,
      "senderId": currentUserId,
      "receiverId": otherUserId,
      "text": text.trim(),
    };

    final conversationInput = {
      "id": conversationId,
      "userA": currentUserId,
      "userB": otherUserId,
      "lastMessage": text.trim(),
    };

    try {
      // 1️⃣ Save message to backend
      final msgResponse = await Amplify.API
          .mutate(
            request: GraphQLRequest(
              document: createMessageMutation,
              variables: {"input": messageInput},
            ),
          )
          .response;

      if (msgResponse.errors.isNotEmpty) {
        safePrint("Message failed: ${msgResponse.errors}");
        // Optionally remove optimistic message if backend failed
        messages.removeWhere((m) => m['id'] == messageId);
        return;
      }

      // 2️⃣ Update inbox
      await Amplify.API
          .mutate(
            request: GraphQLRequest(
              document: upsertConversationMutation,
              variables: {"input": conversationInput},
            ),
          )
          .response;
    } catch (e) {
      safePrint("Send message error: $e");
      // Optionally remove optimistic message if error
      messages.removeWhere((m) => m['id'] == messageId);
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
