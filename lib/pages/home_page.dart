// lib/pages/home_page.dart
import 'package:flutter/material.dart';
import 'notifications_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _minutes = 25;
  int _seconds = 0;
  bool _isRunning = false;

  void _startTimer() {
    if (_isRunning) return;
    _isRunning = true;

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!_isRunning) return false;

      setState(() {
        if (_seconds == 0) {
          if (_minutes == 0) {
            _isRunning = false;
          } else {
            _minutes--;
            _seconds = 59;
          }
        } else {
          _seconds--;
        }
      });

      return _isRunning;
    });
  }

  void _pauseTimer() {
    setState(() {
      _isRunning = false;
    });
  }

  void _resetTimer() {
    setState(() {
      _minutes = 25;
      _seconds = 0;
      _isRunning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // TODO: заменить на имя пользователя из провайдера/аутентификации
    const username = "User";

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Привет, $username'),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationsPage(),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${_minutes.toString().padLeft(2, '0')}:${_seconds.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 72, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _resetTimer,
                  child: const Text('Сбросить'),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: _startTimer,
                  child: const Text('Пуск'),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: _pauseTimer,
                  child: const Text('Пауза'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
