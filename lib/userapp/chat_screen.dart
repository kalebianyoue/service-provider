import 'package:flutter/material.dart';


class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final controller = TextEditingController();
  String username = "User${DateTime.now().millisecondsSinceEpoch % 1000}";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
    );
  }
}
