import 'package:aws_flutter_app/Screens/dashboard/chat_screen.dart';
import 'package:aws_flutter_app/controllers/chat_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MessageScreen extends StatefulWidget {
  final String otherUserId;

  const MessageScreen({super.key, required this.otherUserId});

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  late final ChatController controller;
  final TextEditingController textCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Create controller ONCE
    controller = Get.put(ChatController(), tag: widget.otherUserId);

    // Init chat ONCE
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.initChat(widget.otherUserId);
    });
  }

  @override
  void dispose() {
    textCtrl.dispose();
    Get.delete<ChatController>(tag: widget.otherUserId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Chat")),
      body: Column(
        children: [
          // -------------------- MESSAGES --------------------
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.messages.isEmpty) {
                return const Center(child: Text("No messages yet"));
              }

              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 8),
                reverse: false,
                itemCount: controller.messages.length,
                itemBuilder: (_, i) {
                  final msg = controller.messages[i];
                  final isMe = msg['fromMe'] == true;

                  return Align(
                    alignment: isMe
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 8,
                      ),
                      padding: const EdgeInsets.all(12),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.7,
                      ),
                      decoration: BoxDecoration(
                        color: isMe ? Colors.blue : Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        msg['text'],
                        style: TextStyle(
                          color: isMe ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),

          // -------------------- INPUT --------------------
          SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: textCtrl,
                    minLines: 1,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    final text = textCtrl.text.trim();
                    if (text.isEmpty) return;

                    controller.sendMessage(text);
                    textCtrl.clear();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
