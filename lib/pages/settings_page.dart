import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  // Виджет кнопки-заглушки
  Widget _buildSettingButton(String text) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF009999),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'InriaSans-Regular',
              fontSize: 20,
            ),
          ),
          const Text(
            '>',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'InriaSans-Regular',
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF232323),
      appBar: AppBar(
        backgroundColor: const Color(0xFF232323),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: const Color(0xFFDB0058),
          iconSize: 30,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Padding(
          padding: EdgeInsets.only(left: 8.0), // смещение заголовка влево
          child: Text(
            'Settings',
            style: TextStyle(
              color: Color(0xFFDB0058),
              fontFamily: 'InriaSans-Regular',
              fontSize: 30,
            ),
          ),
        ),
        centerTitle: false,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min, // центрирует по вертикали
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSettingButton('Change language'),
            _buildSettingButton('Change theme'),
            _buildSettingButton('Cloud'),
            _buildSettingButton('Privacy Policy'),
          ],
        ),
      ),
    );
  }
}
