// lib/pages/home_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/workout_provider.dart';
import '../models/exercise.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int totalSeconds = 0;
  int remainingSeconds = 0;
  bool isRunning = false;
  Timer? _timer;

  // exerciseId -> 0 (normal), 1 (first tap), 2 (second tap)
  final Map<int, int> exerciseStates = {};

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _format(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  void _start() {
    if (remainingSeconds <= 0 || isRunning) return;
    isRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (remainingSeconds > 0) {
        setState(() => remainingSeconds--);
      } else {
        _timer?.cancel();
        setState(() => isRunning = false);
      }
    });
    setState(() {});
  }

  void _pause() {
    _timer?.cancel();
    isRunning = false;
    setState(() {});
  }

  void _reset() {
    _timer?.cancel();
    remainingSeconds = totalSeconds;
    isRunning = false;
    setState(() {});
  }

  Future<void> _askSetTimer() async {
    final minutes = await showDialog<int?>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return StatefulBuilder(
          builder: (ctx2, setStateDlg) {
            return AlertDialog(
              title: const Text('Enter minutes'),
              content: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'For example: 15'),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx2).pop(null),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () =>
                      Navigator.of(ctx2).pop(int.tryParse(controller.text)),
                  child: const Text('Ok'),
                ),
              ],
            );
          },
        );
      },
    );
    if (!mounted) return;
    if (minutes != null && minutes > 0) {
      setState(() {
        totalSeconds = minutes * 60;
        remainingSeconds = totalSeconds;
        isRunning = false;
      });
    }
  }

  void _toggleExerciseState(int id) {
    final cur = exerciseStates[id] ?? 0;
    exerciseStates[id] = (cur + 1) % 3;
    setState(() {});
  }

  Color _cardColor(int id) {
    final state = exerciseStates[id] ?? 0;
    switch (state) {
      case 1:
        return const Color(0xFFFFC700); // первый тап
      case 2:
        return const Color(
          0xFF009999,
        ).withOpacity(0.3); // второй тап (прозрачный)
      default:
        return const Color(0xFF009999); // обычная
    }
  }

  Color _textColor(int id) {
    final state = exerciseStates[id] ?? 0;
    switch (state) {
      case 1:
        return const Color(0xFF232323);
      case 2:
        return Colors.white.withOpacity(0.3);
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;
    final username = user?.username ?? 'Пользователь';

    return ChangeNotifierProvider<WorkoutProvider>(
      key: ValueKey('wp-${user?.id ?? -1}'),
      create: (_) {
        final wp = WorkoutProvider(user?.id ?? -1);
        if (user != null) wp.loadWorkouts();
        return wp;
      },
      child: Consumer<WorkoutProvider>(
        builder: (context, workoutProv, _) {
          final todayIndex = DateTime.now().weekday;
          final todaysWorkouts = workoutProv.workouts.where((w) {
            final dw = int.tryParse(w.dayOfWeek);
            if (dw != null) return dw == todayIndex;
            final names = [
              '',
              'Monday',
              'Tuesday',
              'Wednesday',
              'Thursday',
              'Friday',
              'Saturday',
              'Sunday',
            ];
            return names.length > todayIndex &&
                w.dayOfWeek == names[todayIndex];
          }).toList();

          final List<Exercise> todaysExercises = [];
          for (var w in todaysWorkouts) {
            final list = workoutProv.exercises[w.id] ?? [];
            todaysExercises.addAll(list);
          }

          return Scaffold(
            backgroundColor: const Color(0xFF232323),
            appBar: AppBar(
              backgroundColor: const Color(0xFF232323),
              elevation: 0,
              title: Text(
                'Hi, $username',
                style: const TextStyle(
                  color: Color(0xFFFFC700),
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(
                    Icons.notifications,
                    color: Color(0xFFFFC700),
                    size: 30,
                  ),
                  onPressed: () =>
                      Navigator.of(context).pushNamed('/notifications'),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.settings,
                    color: Color(0xFFFFC700),
                    size: 30,
                  ),
                  onPressed: () => Navigator.of(context).pushNamed('/settings'),
                ),
              ],
            ),
            body: Column(
              children: [
                const SizedBox(height: 24), // увеличенный отступ сверху
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF232323),
                    border: Border.all(
                      color: const Color(0xFF009999),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _askSetTimer,
                        child: Column(
                          children: [
                            Text(
                              _format(remainingSeconds),
                              style: const TextStyle(
                                fontFamily: 'AllertaStencil',
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              totalSeconds == 0
                                  ? 'Tap to set the timer'
                                  : 'Minutes left: ${_format(remainingSeconds)}',
                              style: const TextStyle(color: Colors.white54),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: _reset,
                            icon: const Icon(Icons.refresh),
                            iconSize: 36,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            onPressed: _start,
                            icon: const Icon(Icons.play_arrow),
                            iconSize: 36,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            onPressed: _pause,
                            icon: const Icon(Icons.pause),
                            iconSize: 36,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Center(
                  child: Text(
                    'Workouts for today',
                    style: TextStyle(color: Color(0xFFDB0058), fontSize: 30),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: todaysExercises.isEmpty
                      ? const Center(
                          child: Text(
                            'There are no exercises for today',
                            style: TextStyle(color: Colors.white),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: todaysExercises.length,
                          itemBuilder: (ctx, i) {
                            final ex = todaysExercises[i];
                            final textColor = _textColor(ex.id ?? i);
                            return GestureDetector(
                              onTap: () {
                                if (ex.id != null) _toggleExerciseState(ex.id!);
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: _cardColor(ex.id ?? i),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ex.name,
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                    if (ex.description.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        ex.description,
                                        style: TextStyle(color: textColor),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
