// lib/pages/splash_page.dart
import 'dart:async';
import 'package:flutter/material.dart';

class SplashPage extends StatefulWidget {
  final VoidCallback onFinish;

  const SplashPage({super.key, required this.onFinish});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      widget.onFinish();
    });
  }

  @override
  Widget build(BuildContext context) {
    final gradient = const LinearGradient(
      colors: [Color(0xFF009999), Color(0xFFFFC700), Color(0xFFDB0058)],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF232323),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.run_circle_outlined, size: 100, color: Colors.white),
            const SizedBox(height: 24),
            ShaderMask(
              shaderCallback: (bounds) => gradient.createShader(
                Rect.fromLTWH(0, 0, bounds.width, bounds.height),
              ),
              child: const Text(
                'Cool Fit',
                style: TextStyle(
                  fontSize: 64,
                  fontFamily: 'AllertaStencil',
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Start your fitness journey',
              style: TextStyle(
                fontSize: 40,
                fontFamily: 'InriaSans',
                color: Color(0xFF009999),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
