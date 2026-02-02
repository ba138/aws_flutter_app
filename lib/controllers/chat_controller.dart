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

    fetchMessages();
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

      // Check if API returned null data
      if (response.data == null) {
        print("No data returned from API");
        messages.value = [];
        return;
      }

      final data = jsonDecode(response.data!);

      // Safely get the items list
      final items = data['messagesByConversation']?['items'] ?? [];

      // Map items and ensure no nulls for String fields
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

      print("Fetched ${messages.value.length} messages successfully.");
    } catch (e) {
      print("Error fetching messages: $e");
      messages.value = [];
    }
  }

  /// 📤 SEND MESSAGE

  Future<void> sendMessage(String text) async {
    try {
      // Generate a unique ID for the new message
      final messageId = Uuid().v4();
      final createdAt = DateTime.now().toIso8601String();

      // GraphQL mutation with variables
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

      final response = await Amplify.API
          .mutate(
            request: GraphQLRequest(document: mutation, variables: variables),
          )
          .response;

      // Update local messages list immediately
      messages.value = [
        ...messages.value,
        {
          'id': messageId,
          'senderId': /* your userId */
              conversationId, // replace with your sender ID
          'receiverId': otherUserId,
          'text': text,
          'createdAt': createdAt,
        },
      ];

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

            if (msg['conversationId'] == conversationId) {
              messages.add(Map<String, dynamic>.from(msg));
            }
          },
          onError: (error) {
            safePrint('Subscription error: $error');
          },
        );
  }
}
