import 'package:aws_flutter_app/controllers/chat_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MessageScreen extends StatelessWidget {
  final String otherUserId;
  MessageScreen({super.key, required this.otherUserId});

  final ChatController controller = Get.put(ChatController());
  final TextEditingController textCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    controller.initChat(otherUserId);

    return Scaffold(
      appBar: AppBar(title: const Text("Chat")),
      body: Column(
        children: [
          Expanded(
            child: Obx(
              () => ListView.builder(
                itemCount: controller.messages.length,
                itemBuilder: (_, i) {
                  final msg = controller.messages[i];
                  final isMe = msg['senderId'] == controller.currentUserId;

                  return Align(
                    alignment: isMe
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isMe ? Colors.blue : Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(msg['text']),
                    ),
                  );
                },
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: textCtrl,
                  decoration: InputDecoration(
                    fillColor: Colors.grey[200],
                    filled: true,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: () {
                  controller.sendMessage(textCtrl.text);
                  textCtrl.clear();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
