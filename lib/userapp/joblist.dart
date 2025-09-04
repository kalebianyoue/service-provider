import 'package:flutter/material.dart';

/// 2. Job List Page
////////////////////////////////////
class Joblist extends StatelessWidget {
  const Joblist({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Job List",
          style: TextStyle(color: Colors.white,fontSize: 20, fontWeight: FontWeight.bold),),
        backgroundColor: Colors.blue,
      ),
      body: const Center(
        child: Text(""),
      ),
    );
  }
}
