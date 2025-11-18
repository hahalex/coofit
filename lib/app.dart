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

  // Флаг, чтобы один раз показать страницу логина и не пушить её снова при rebuild
  bool _loginShown = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fitness Tracker',
      theme: ThemeData(
        fontFamily: 'InriaSans', // <--- шрифт по умолчанию
      ),
      routes: {
        '/notifications': (_) => NotificationsPage(),
        '/settings': (_) => SettingsPage(),
      },
      home: Consumer<AuthProvider>(
        builder: (context, auth, child) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!auth.isLoggedIn && !_loginShown) {
              _loginShown = true;
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const LoginPage()));
            }
            if (auth.isLoggedIn && _loginShown) {
              _loginShown = false;
            }
          });

          return Scaffold(
            body: _pages[_selectedIndex],
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
