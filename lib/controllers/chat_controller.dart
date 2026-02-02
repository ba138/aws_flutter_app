import 'dart:async';
import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:get/get.dart' hide GraphQLResponse;

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

    final response = await Amplify.API
        .query(
          request: GraphQLRequest(
            document: query,
            variables: {"cid": conversationId},
          ),
        )
        .response;

    final data = jsonDecode(response.data!);
    messages.value = List<Map<String, dynamic>>.from(
      data['messagesByConversation']['items'],
    );
  }

  /// 📤 SEND MESSAGE
  Future<void> sendMessage(String text) async {
    final mutation =
        '''
    mutation SendMessage {
      createMessage(input: {
        conversationId: "$conversationId"
        senderId: "$currentUserId"
        receiverId: "$otherUserId"
        text: "$text"
        createdAt: "${DateTime.now().toIso8601String()}"
      }) {
        id
      }
    }
    ''';

    await Amplify.API
        .mutate(request: GraphQLRequest(document: mutation))
        .response;
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
