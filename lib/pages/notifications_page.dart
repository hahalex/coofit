import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // НЕ используем const Scaffold — чтобы не требовать const для AppBar/Text
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: const Center(child: Text('Уведомления (заглушка)')),
    );
  }
}
