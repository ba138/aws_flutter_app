import 'package:aws_flutter_app/Screens/dashboard/message_screen.dart';
import 'package:aws_flutter_app/controllers/conversation_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ConversationController());

    return Scaffold(
      appBar: AppBar(title: const Text("Chats")),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.conversations.isEmpty) {
          return const Center(child: Text("No conversations yet"));
        }

        return ListView.separated(
          itemCount: controller.conversations.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final convo = controller.conversations[i];

            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(convo['otherUserId']),
              subtitle: Text(
                convo['lastMessage'],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Text(
                _formatTime(convo['updatedAt']),
                style: const TextStyle(fontSize: 12),
              ),
              onTap: () {
                Get.to(() => MessageScreen(otherUserId: convo['otherUserId']));
              },
            );
          },
        );
      }),
    );
  }

  String _formatTime(String iso) {
    final time = DateTime.parse(iso);
    final now = DateTime.now();

    if (now.difference(time).inDays == 0) {
      return "${time.hour}:${time.minute.toString().padLeft(2, '0')}";
    }
    return "${time.day}/${time.month}/${time.year}";
  }
}
