import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF232323), // фон всей страницы
      appBar: AppBar(
        backgroundColor: const Color(0xFF232323), // фон верхней панели
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: const Color(0xFFDB0058), // цвет кнопки назад
          iconSize: 30,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Padding(
          padding: EdgeInsets.only(left: 8.0), // смещение заголовка влево
          child: Text(
            'Notifications',
            style: TextStyle(
              color: Color(0xFFDB0058), // цвет текста
              fontFamily: 'InriaSans-Regular',
              fontSize: 30,
            ),
          ),
        ),
        centerTitle: false, // чтобы заголовок не был строго по центру
      ),
      body: const Center(),
    );
  }
}
