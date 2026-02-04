import 'dart:async';
import 'dart:convert';

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide GraphQLResponse;

class ConversationController extends GetxController {
  static ConversationController get instance => Get.find();

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

    debugPrint("🟢 Current userId: $currentUserId");

    await loadConversations();
    subscribeConversations();
  }

  // ------------------------- LOAD EXISTING CONVERSATIONS -------------------------
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
          .map<Map<String, dynamic>>((c) => _mapConversation(c))
          .toList();

      _sortInbox();
      debugPrint("💾 Loaded ${conversations.length} conversations");
    } catch (e) {
      safePrint("Inbox load error: $e");
      conversations.clear();
    } finally {
      isLoading.value = false;
    }
  }

  // ------------------------- REALTIME SUBSCRIPTIONS -------------------------
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

    // 🆕 New conversations
    _createSub = Amplify.API
        .subscribe(GraphQLRequest<String>(document: onCreate))
        .listen((event) {
          debugPrint("🔔 onCreate event: ${event.data}");
          if (event.data == null) return;

          final convo = jsonDecode(event.data!)['onCreateConversation'];
          if (convo == null || !_belongsToMe(convo)) return;

          if (!conversations.any((c) => c['id'] == convo['id'])) {
            conversations.add(_mapConversation(convo));
            _sortInbox();
            debugPrint("📨 New conversation added: ${convo['lastMessage']}");
          }
        });

    // ✏️ Updated conversations
    _updateSub = Amplify.API
        .subscribe(GraphQLRequest<String>(document: onUpdate))
        .listen((event) {
          debugPrint("🔔 onUpdate event: ${event.data}");
          if (event.data == null) return;

          final convo = jsonDecode(event.data!)['onUpdateConversation'];
          if (convo == null || !_belongsToMe(convo)) return;

          final index = conversations.indexWhere((c) => c['id'] == convo['id']);
          if (index != -1) {
            conversations[index] = _mapConversation(convo);
            debugPrint("📨 Conversation updated: ${convo['lastMessage']}");
          } else {
            conversations.add(_mapConversation(convo));
            debugPrint(
              "📨 Conversation added on update: ${convo['lastMessage']}",
            );
          }

          _sortInbox();
        });
  }

  // ------------------------- OPTIMISTIC LOCAL UPDATE -------------------------
  void updateLocalConversation(
    String conversationId,
    String otherUserId,
    String lastMessage,
  ) {
    final now = DateTime.now().toUtc().toIso8601String();

    final index = conversations.indexWhere((c) => c['id'] == conversationId);
    if (index != -1) {
      conversations[index]['lastMessage'] = lastMessage;
      conversations[index]['updatedAt'] = now;
    } else {
      conversations.add({
        'id': conversationId,
        'otherUserId': otherUserId,
        'lastMessage': lastMessage,
        'updatedAt': now,
      });
    }

    _sortInbox();
    debugPrint("⚡ Local conversation updated: $lastMessage");
  }

  // ------------------------- HELPERS -------------------------
  bool _belongsToMe(Map<String, dynamic> c) {
    return c['userA'] == currentUserId || c['userB'] == currentUserId;
  }

  Map<String, dynamic> _mapConversation(Map<String, dynamic> c) {
    final otherUser = c['userA'] == currentUserId ? c['userB'] : c['userA'];
    return {
      'id': c['id'],
      'otherUserId': otherUser,
      'lastMessage': c['lastMessage'] ?? '',
      'updatedAt': c['updatedAt'] ?? DateTime.now().toUtc().toIso8601String(),
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
