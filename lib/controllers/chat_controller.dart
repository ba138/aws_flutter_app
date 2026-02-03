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
    final now = DateTime.now().toUtc().toIso8601String();

    // ------------------ 1️⃣ Optimistic UI ------------------
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

    // ------------------ 2️⃣ Save message to backend ------------------
    const createMessageMutation = '''
  mutation CreateMessage(\$input: CreateMessageInput!) {
    createMessage(input: \$input) {
      id
      text
      createdAt
    }
  }
  ''';

    final messageInput = {
      "id": messageId,
      "conversationId": conversationId,
      "senderId": currentUserId,
      "receiverId": otherUserId,
      "text": text.trim(),
      "createdAt": now,
    };

    try {
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
        messages.removeWhere(
          (m) => m['id'] == messageId,
        ); // rollback optimistic UI
        return;
      }

      // ------------------ 3️⃣ Update Inbox (Conversation) ------------------
      const getQuery = '''
    query GetConversation(\$id: ID!) {
      getConversation(id: \$id) {
        id
        lastMessage
      }
    }
    ''';

      final getResp = await Amplify.API
          .query(
            request: GraphQLRequest(
              document: getQuery,
              variables: {"id": conversationId},
            ),
          )
          .response;

      final exists =
          getResp.data != null &&
          jsonDecode(getResp.data!)['getConversation'] != null;

      if (exists) {
        // Conversation exists → update it
        const updateMutation = '''
      mutation UpdateConversation(\$input: UpdateConversationInput!) {
        updateConversation(input: \$input) {
          id
          lastMessage
          updatedAt
        }
      }
      ''';

        final input = {"id": conversationId, "lastMessage": text.trim()};

        await Amplify.API
            .mutate(
              request: GraphQLRequest(
                document: updateMutation,
                variables: {"input": input},
              ),
            )
            .response;
      } else {
        // Conversation does not exist → create it
        const createMutation = '''
      mutation CreateConversation(\$input: CreateConversationInput!) {
        createConversation(input: \$input) {
          id
          lastMessage
          updatedAt
        }
      }
      ''';

        final input = {
          "id": conversationId,
          "userA": currentUserId,
          "userB": otherUserId,
          "lastMessage": text.trim(),
        };

        await Amplify.API
            .mutate(
              request: GraphQLRequest(
                document: createMutation,
                variables: {"input": input},
              ),
            )
            .response;
      }
    } catch (e) {
      safePrint("Send message error: $e");
      messages.removeWhere((m) => m['id'] == messageId); // rollback if error
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
