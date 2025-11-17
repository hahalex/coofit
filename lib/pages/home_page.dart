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

  // exerciseId -> 0 (normal), 1 (current), 2 (done)
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

  void _setTimer(int minutes) {
    _timer?.cancel();
    totalSeconds = minutes * 60;
    remainingSeconds = totalSeconds;
    isRunning = false;
    setState(() {});
  }

  void _start() {
    if (remainingSeconds <= 0) return;
    if (isRunning) return;
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
        // создаём контроллер ВНУТРИ builder'а — он живёт столько, сколько живёт диалог
        final controller = TextEditingController();

        return StatefulBuilder(
          builder: (ctx2, setStateDlg) {
            return AlertDialog(
              title: const Text('Установить таймер (минуты)'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: 'Например: 15',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    // закрываем без результата
                    Navigator.of(ctx2).pop(null);
                  },
                  child: const Text('Отмена'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx2).pop(int.tryParse(controller.text));
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );

    // После закрытия диалога: проверяем mounted перед setState
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

  Color _colorFor(int id) {
    final s = exerciseStates[id] ?? 0;
    if (s == 1) return Colors.yellow.withOpacity(0.6); // current
    if (s == 2) return Colors.green.withOpacity(0.6); // done
    return Colors.white; // normal
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;
    final username = user?.username ?? 'Пользователь';

    // Provide a WorkoutProvider scoped to Home. If you already provide WorkoutProvider globally,
    // you can instead read it directly. Here we create a provider instance (non-global)
    // so Home can load workouts for the current user.
    return ChangeNotifierProvider<WorkoutProvider>(
      create: (_) {
        final wp = WorkoutProvider(user?.id ?? -1);
        // only load if user exists
        if (user != null) wp.loadWorkouts();
        return wp;
      },
      child: Consumer<WorkoutProvider>(
        builder: (context, workoutProv, _) {
          // Determine today's day index. Your DB stores day_of_week as INTEGER (likely 1..7 = Mon..Sun)
          final todayIndex =
              DateTime.now().weekday; // 1 = Monday ... 7 = Sunday in Dart

          // Filter workouts for today (note: mapping depends on what you store in day_of_week)
          final todaysWorkouts = workoutProv.workouts.where((w) {
            // we kept Workout.dayOfWeek as string in model; it might be integer string or name.
            final dw = int.tryParse(w.dayOfWeek);
            if (dw != null) return dw == todayIndex;
            // fallback: match by name (English) — map weekday number to name
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
            return (names.length > todayIndex &&
                w.dayOfWeek == names[todayIndex]);
          }).toList();

          // collect exercises for today's workouts
          final List<Exercise> todaysExercises = [];
          for (var w in todaysWorkouts) {
            final list = workoutProv.exercises[w.id] ?? [];
            todaysExercises.addAll(list);
          }

          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 1,
              leading: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Center(
                  child: Text(
                    'Привет, $username',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications, color: Colors.black87),
                  onPressed: () =>
                      Navigator.of(context).pushNamed('/notifications'),
                ),
                IconButton(
                  icon: const Icon(Icons.settings, color: Colors.black87),
                  onPressed: () => Navigator.of(context).pushNamed('/settings'),
                ),
              ],
            ),
            body: Column(
              children: [
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _askSetTimer,
                  child: Column(
                    children: [
                      Text(
                        _format(remainingSeconds),
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        totalSeconds == 0
                            ? 'Нажмите чтобы установить таймер'
                            : 'Осталось: ${_format(remainingSeconds)}',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: _reset,
                      icon: const Icon(Icons.refresh),
                      iconSize: 36,
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: _start,
                      icon: const Icon(Icons.play_arrow),
                      iconSize: 36,
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: _pause,
                      icon: const Icon(Icons.pause),
                      iconSize: 36,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Упражнения на сегодня',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: todaysExercises.isEmpty
                      ? const Center(child: Text('На сегодня нет упражнений'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: todaysExercises.length,
                          itemBuilder: (ctx, i) {
                            final ex = todaysExercises[i];
                            return GestureDetector(
                              onTap: () {
                                if (ex.id != null) _toggleExerciseState(ex.id!);
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: _colorFor(ex.id ?? i),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ex.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if ((ex.description).isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        ex.description,
                                        style: const TextStyle(
                                          color: Colors.black54,
                                        ),
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
