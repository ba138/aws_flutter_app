import 'dart:async';
import 'dart:convert';

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:get/get.dart' hide GraphQLResponse;

class ConversationController extends GetxController {
  final RxList<Map<String, dynamic>> conversations =
      <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;

  StreamSubscription<GraphQLResponse<String>>? _createSub;
  StreamSubscription<GraphQLResponse<String>>? _updateSub;

  late String currentUserId;

  @override
  void onInit() {
    super.onInit();
    initInbox();
  }

  Future<void> initInbox() async {
    final user = await Amplify.Auth.getCurrentUser();
    currentUserId = user.userId;

    await loadConversations();
    subscribeConversations();
  }

  // ---------------------------------------------------------------------------
  // INITIAL LOAD
  // ---------------------------------------------------------------------------
  Future<void> loadConversations() async {
    isLoading.value = true;

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

      if (response.errors.isNotEmpty || response.data == null) {
        conversations.clear();
        return;
      }

      final decoded = jsonDecode(response.data!);
      final items = decoded['listConversations']?['items'] as List? ?? [];

      conversations.value = items
          .where(
            (c) => c['userA'] == currentUserId || c['userB'] == currentUserId,
          )
          .map<Map<String, dynamic>>((c) {
            final otherUser = c['userA'] == currentUserId
                ? c['userB']
                : c['userA'];

            return {
              'id': c['id'],
              'otherUserId': otherUser,
              'lastMessage': c['lastMessage'] ?? '',
              'updatedAt': c['updatedAt'],
            };
          })
          .toList();

      _sortInbox();
    } catch (e) {
      safePrint("Inbox load error: $e");
      conversations.clear();
    } finally {
      isLoading.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // REALTIME SUBSCRIPTIONS
  // ---------------------------------------------------------------------------
  void subscribeConversations() {
    const onCreate = '''
    subscription OnCreateConversation {
      onCreateConversation {
        id
        userA
        userB
        lastMessage
        updatedAt
      }
    }
    ''';

    const onUpdate = '''
    subscription OnUpdateConversation {
      onUpdateConversation {
        id
        userA
        userB
        lastMessage
        updatedAt
      }
    }
    ''';

    // 🆕 New conversation
    _createSub = Amplify.API
        .subscribe(GraphQLRequest<String>(document: onCreate))
        .listen((event) {
          if (event.data == null) return;

          final convo = jsonDecode(event.data!)['onCreateConversation'];
          if (convo == null) return;

          if (!_belongsToMe(convo)) return;

          if (conversations.any((c) => c['id'] == convo['id'])) return;

          conversations.add(_mapConversation(convo));
          _sortInbox();
        });

    // ✏️ Updated conversation (new message)
    _updateSub = Amplify.API
        .subscribe(GraphQLRequest<String>(document: onUpdate))
        .listen((event) {
          if (event.data == null) return;

          final convo = jsonDecode(event.data!)['onUpdateConversation'];
          if (convo == null) return;

          if (!_belongsToMe(convo)) return;

          final index = conversations.indexWhere((c) => c['id'] == convo['id']);

          if (index != -1) {
            conversations[index] = _mapConversation(convo);
          } else {
            conversations.add(_mapConversation(convo));
          }

          _sortInbox();
        });
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------
  bool _belongsToMe(Map<String, dynamic> c) {
    return c['userA'] == currentUserId || c['userB'] == currentUserId;
  }

  Map<String, dynamic> _mapConversation(Map<String, dynamic> c) {
    final otherUser = c['userA'] == currentUserId ? c['userB'] : c['userA'];

    return {
      'id': c['id'],
      'otherUserId': otherUser,
      'lastMessage': c['lastMessage'] ?? '',
      'updatedAt': c['updatedAt'],
    };
  }

  void _sortInbox() {
    conversations.sort(
      (a, b) => DateTime.parse(
        b['updatedAt'],
      ).compareTo(DateTime.parse(a['updatedAt'])),
    );
  }

  @override
  void onClose() {
    _createSub?.cancel();
    _updateSub?.cancel();
    super.onClose();
  }
}
