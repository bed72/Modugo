import 'package:flutter/material.dart';

import '../controllers/home_controller.dart';

class HomeScreen extends StatelessWidget {
  final HomeController _controller;

  const HomeScreen({super.key, required HomeController controller})
    : _controller = controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Modugo Example')),
      body: Center(child: Text(_controller.message())),
    );
  }
}
