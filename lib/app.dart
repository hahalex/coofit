// lib/app.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'pages/home_page.dart';
import 'pages/workout_page.dart';
import 'pages/step_page.dart';
import 'pages/profile_page.dart';
import 'pages/food_page.dart';
import 'pages/auth/login_page.dart';
import 'pages/notifications_page.dart';
import 'pages/settings_page.dart';
import 'providers/auth_provider.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _selectedIndex = 2; // 0-workout,1-step,2-home,3-profile,4-food
  final List<Widget> _pages = [
    const WorkoutPage(),
    const StepPage(),
    const HomePage(),
    const ProfilePage(),
    const FoodPage(),
  ];

  bool _loginShown = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fitness Tracker',

      // глобальная тёмная тема
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF232323),
        canvasColor: const Color(0xFF232323),
        dialogBackgroundColor: const Color(0xFF232323),
        fontFamily: 'InriaSans',
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          secondary: Colors.white70,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF232323),
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white60,
        ),
      ),

      routes: {
        '/notifications': (_) => NotificationsPage(),
        '/settings': (_) => SettingsPage(),
      },

      home: Consumer<AuthProvider>(
        builder: (context, auth, child) {
          // показываем логин после первого фрейма, если не залогинен
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!auth.isLoggedIn && !_loginShown) {
              _loginShown = true;

              // переход без анимации
              Navigator.of(context).push(
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => const LoginPage(),
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                ),
              );
            }

            if (auth.isLoggedIn && _loginShown) {
              _loginShown = false;
            }
          });

          // создаём страницы внутри build — это гарантирует, что при изменении AuthProvider
          // HomePage будет пересоздана и сможет корректно инициализировать данные
          final pages = <Widget>[
            const WorkoutPage(),
            const StepPage(),
            HomePage(), // НЕ const — важно, чтобы HomePage пересоздавалась
            const ProfilePage(),
            const FoodPage(),
          ];

          return Scaffold(
            body: pages[_selectedIndex],
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (i) => setState(() => _selectedIndex = i),
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.fitness_center),
                  label: 'Workout',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.directions_walk),
                  label: 'Steps',
                ),
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: 'Profile',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.fastfood),
                  label: 'Food',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
