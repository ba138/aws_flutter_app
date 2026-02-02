import 'dart:async';
import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:get/get.dart' hide GraphQLResponse;
import 'package:uuid/uuid.dart';

class ChatController extends GetxController {
  RxList<Map<String, dynamic>> messages = <Map<String, dynamic>>[].obs;
  RxBool isLoading = false.obs;
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

  /// 📥 FETCH MESSAGES
  Future<void> fetchMessages() async {
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

      if (response.data == null) {
        messages.value = [];
        return;
      }

      final data = jsonDecode(response.data!);
      final items = data['messagesByConversation']?['items'] ?? [];

      messages.value = List<Map<String, dynamic>>.from(
        items.map<Map<String, dynamic>>((item) {
          return {
            'id': item['id'] ?? '',
            'senderId': item['senderId'] ?? '',
            'receiverId': item['receiverId'] ?? '',
            'text': item['text'] ?? '',
            'createdAt': item['createdAt'] ?? '',
          };
        }),
      );

      // Sort by createdAt
      messages.sort((a, b) => a['createdAt'].compareTo(b['createdAt']));
    } catch (e) {
      print("Error fetching messages: $e");
      messages.value = [];
    }
  }

  /// 📤 SEND MESSAGE
  Future<void> sendMessage(String text) async {
    try {
      final messageId = Uuid().v4();
      final createdAt = DateTime.now().toIso8601String();

      const mutation = '''
      mutation SendMessage(\$input: CreateMessageInput!) {
        createMessage(input: \$input) {
          id
          senderId
          receiverId
          text
          createdAt
        }
      }
      ''';

      final variables = {
        "input": {
          "id": messageId,
          "conversationId": conversationId,
          "receiverId": otherUserId,
          "text": text,
          "createdAt": createdAt,
        },
      };

      await Amplify.API
          .mutate(
            request: GraphQLRequest(document: mutation, variables: variables),
          )
          .response;

      // Add to local list
      messages.add({
        'id': messageId,
        'senderId': currentUserId,
        'receiverId': otherUserId,
        'text': text,
        'createdAt': createdAt,
      });

      // Keep messages sorted
      messages.sort((a, b) => a['createdAt'].compareTo(b['createdAt']));

      safePrint('Message sent successfully');
    } catch (e) {
      safePrint('Send message error: $e');
    }
  }

  /// 🔴 REALTIME SUBSCRIPTION
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
          onEstablished: () => safePrint('Subscription established'),
        )
        .listen(
          (event) {
            if (event.data == null) return;

            final decoded = jsonDecode(event.data!);
            final msg = decoded['onCreateMessage'];
            if (msg == null) return;

            if (msg['conversationId'] == conversationId) {
              messages.add(Map<String, dynamic>.from(msg));
              messages.sort((a, b) => a['createdAt'].compareTo(b['createdAt']));
            }
          },
          onError: (error) {
            safePrint('Subscription error: $error');
          },
        );
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}
