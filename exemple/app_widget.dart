import 'package:flutter/material.dart';
import 'package:modugo/src/modugo.dart';

class AppWidget extends StatelessWidget {
  const AppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Modugo App',
      routerConfig: Modugo.routerConfig,
    );
  }
}
