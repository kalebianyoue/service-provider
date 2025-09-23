import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatPage extends StatefulWidget {
  final String providerId;
  final String clientId;
  final String Name;

  const ChatPage({
    super.key,
    required this.Name,
    required this.providerId,
    required this.clientId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController messageController = TextEditingController();
  final currentUser = FirebaseAuth.instance.currentUser;

  late final String chatId;

  @override
  void initState() {
    super.initState();
    // Créer un chatId unique (ordre alphabétique pour éviter doublons)
    chatId = widget.providerId.hashCode <= widget.clientId.hashCode
        ? "${widget.providerId}_${widget.clientId}"
        : "${widget.clientId}_${widget.providerId}";
  }

  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty || currentUser == null) return;

    final receiverId = currentUser!.uid == widget.providerId
        ? widget.clientId
        : widget.providerId;

    final message = {
      "text": text,
      "senderId": currentUser!.uid,
      "receiverId": receiverId,
      "timestamp": FieldValue.serverTimestamp(),
    };

    final chatRef = FirebaseFirestore.instance.collection("chats").doc(chatId);

    // 1️⃣ Enregistrer le message
    await chatRef.collection("messages").add(message);

    // 2️⃣ Mettre à jour les infos du chat
    await chatRef.set({
      "participants": [widget.providerId, widget.clientId],
      "lastMessage": text,
      "lastMessageTime": FieldValue.serverTimestamp(),
      "provider": widget.Name, // nom affiché côté ChatList
      "client": widget.Name,
    }, SetOptions(merge: true));

    messageController.clear();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.Name),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          // 🔹 Messages stream
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("chats")
                  .doc(chatId)
                  .collection("messages")
                  .orderBy("timestamp", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true, // les derniers messages en bas
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg =
                    messages[index].data() as Map<String, dynamic>;

                    final isMe = msg["senderId"] == currentUser?.uid;

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(12),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.7,
                        ),
                        decoration: BoxDecoration(
                          color: isMe
                              ? Colors.blueAccent
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: isMe
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Text(
                              msg["text"] ?? "",
                              style: TextStyle(
                                color: isMe ? Colors.white : Colors.black87,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              msg["timestamp"] != null
                                  ? (msg["timestamp"] as Timestamp)
                                  .toDate()
                                  .toLocal()
                                  .toString()
                                  .substring(11, 16) // HH:mm
                                  : "",
                              style: TextStyle(
                                fontSize: 11,
                                color: isMe
                                    ? Colors.white70
                                    : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // 🔹 Input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.grey[200],
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      fillColor: Colors.white,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 0),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
