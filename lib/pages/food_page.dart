import 'package:flutter/material.dart';

class FoodPage extends StatelessWidget {
  const FoodPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF232323), // фон страницы
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(
            height: 40,
          ), // небольшой отступ сверху для статуса телефона
          // Надпись "Food tracker" сверху
          const Center(
            child: Text(
              'Food tracker',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'InriaSans-Regular',
                fontSize: 30,
                color: Color(0xFFDB0058),
              ),
            ),
          ),
          const SizedBox(height: 40),

          // Остальная часть контента по центру
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Градиентная иконка
                  ShaderMask(
                    shaderCallback: (Rect bounds) => const LinearGradient(
                      colors: [
                        Color(0xFF009999),
                        Color(0xFFFFC700),
                        Color(0xFFDB0058),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ).createShader(bounds),
                    child: const Icon(
                      Icons.run_circle_outlined,
                      size: 90,
                      color: Colors.white, // важно для ShaderMask
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Градиентная надпись Cool Fit
                  ShaderMask(
                    shaderCallback: (Rect bounds) => const LinearGradient(
                      colors: [
                        Color(0xFF009999),
                        Color(0xFFFFC700),
                        Color(0xFFDB0058),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ).createShader(bounds),
                    child: const Text(
                      'Cool Fit',
                      style: TextStyle(
                        fontFamily: 'AllertaStencil',
                        fontSize: 64,
                        color: Colors.white, // важно для ShaderMask
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Текст "Coming soon..."
                  const Text(
                    'Coming soon to all cinemas across the country',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'InriaSans-Bold',
                      fontSize: 30,
                      color: Color(0xFFDB0058),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
