// lib/pages/step_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/auth_provider.dart';
import '../services/db_service.dart';

class StepPage extends StatefulWidget {
  const StepPage({super.key});

  @override
  State<StepPage> createState() => _StepPageState();
}

class _StepPageState extends State<StepPage> {
  final DBService _db = DBService();

  bool _loading = true;
  int _todaySteps = 0;
  int _goalSteps = 5000;

  StreamSubscription<StepCount>? _stepSub;
  int? _lastSensorValue; // последнее полученное value от датчика (cumulative)
  bool _hasPermission = false;

  String get _today {
    final now = DateTime.now();
    return now.toIso8601String().split('T')[0];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initPermissionAndLoad();
    });
  }

  Future<void> _initPermissionAndLoad() async {
    await _loadProfileAndToday(); // загрузим цель и сегодняшние шаги
    await _requestPermission();
    if (_hasPermission) {
      _startListening();
    }
  }

  Future<void> _loadProfileAndToday() async {
    setState(() => _loading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;
    if (user == null) {
      setState(() {
        _loading = false;
        _todaySteps = 0;
      });
      return;
    }

    final profile = await _db.getProfileByUserId(user.id!);
    if (profile != null) {
      _goalSteps = profile['target_steps'] ?? 5000;
    }

    final metrics = await _db.getDailyMetrics(user.id!, _today);
    if (metrics != null) {
      _todaySteps = metrics['steps'] ?? 0;
    } else {
      // создаём запись, если её нет
      await _db.insertDailyMetrics(
        user.id!,
        _today,
        calories: 0,
        waterGlasses: 0,
        steps: 0,
      );
      _todaySteps = 0;
    }

    if (mounted)
      setState(() {
        _loading = false;
      });
  }

  Future<void> _requestPermission() async {
    // Проверяем и запрашиваем ACTIVITY_RECOGNITION (Android 10+). На iOS pedometer может работать иначе.
    PermissionStatus status;
    try {
      status = await Permission.activityRecognition.status;
      if (status != PermissionStatus.granted) {
        status = await Permission.activityRecognition.request();
      }
    } catch (e) {
      // Если permission_handler не поддерживает эту платформу/версию, считаем разрешение отсутствующим
      status = PermissionStatus.denied;
    }

    setState(() => _hasPermission = status == PermissionStatus.granted);
  }

  void _startListening() {
    // Если уже подписаны — отменим
    _stepSub?.cancel();

    _stepSub = Pedometer.stepCountStream.listen(
      _onStepCount,
      onError: (e) {
        // можно логировать
      },
      cancelOnError: true,
    );
  }

  void _onStepCount(StepCount event) async {
    // event.steps — обычно cumulative steps since boot.
    // Логика: если _lastSensorValue == null -> сохраняем, не добавляем (чтобы не получить резкий скачок)
    // иначе берем delta = event.steps - _lastSensorValue; если delta < 0 (перезагрузка) — используем event.steps (как delta)
    final sensorValue = event.steps;
    if (_lastSensorValue == null) {
      _lastSensorValue = sensorValue;
      return; // не добавляем при первом событии, чтобы избежать большого прыжка
    }

    int delta = sensorValue - _lastSensorValue!;
    if (delta < 0) {
      // reboot или сброс датчика — тогда считаем, что все шаги новые с нуля
      delta = sensorValue;
    }

    // возможно delta может быть очень большим при первом запуске после долгого времени — но мы стараемся минимизировать это
    if (delta > 0) {
      await _addSteps(delta);
    }

    _lastSensorValue = sensorValue;
  }

  Future<void> _addSteps(int delta) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;
    if (user == null) return;

    // Получаем текущие метрики и суммуим
    final metrics = await _db.getDailyMetrics(user.id!, _today);
    if (metrics == null) {
      await _db.insertDailyMetrics(
        user.id!,
        _today,
        calories: 0,
        waterGlasses: 0,
        steps: delta,
      );
    } else {
      final current = metrics['steps'] ?? 0;
      await _db.upsertDailyMetrics(user.id!, _today, steps: current + delta);
    }

    // Обновляем UI
    final updated = await _db.getDailyMetrics(user.id!, _today);
    if (mounted)
      setState(() => _todaySteps = updated?['steps'] ?? _todaySteps + delta);
  }

  Future<void> _manualAddStep() async {
    // кнопка для dev/test — добавить 1 шаг вручную
    await _modifySteps(1);
  }

  Future<void> _modifySteps(int delta) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;
    if (user == null) return;
    final metrics = await _db.getDailyMetrics(user.id!, _today);
    if (metrics == null) {
      await _db.insertDailyMetrics(
        user.id!,
        _today,
        calories: 0,
        waterGlasses: 0,
        steps: delta,
      );
    } else {
      final current = metrics['steps'] ?? 0;
      final newVal = (current + delta) < 0 ? 0 : (current + delta);
      await _db.upsertDailyMetrics(user.id!, _today, steps: newVal);
    }
    final updated = await _db.getDailyMetrics(user.id!, _today);
    if (mounted) setState(() => _todaySteps = updated?['steps'] ?? 0);
  }

  @override
  void dispose() {
    _stepSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // простой UI: большая цифра — шаги, под ней цель и индикатор прогресса
    return Scaffold(
      appBar: AppBar(title: const Text('Steps')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 20.0,
                        horizontal: 8,
                      ),
                      child: Column(
                        children: [
                          Text(
                            '$_todaySteps',
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Goal: $_goalSteps steps',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: (_goalSteps > 0)
                                ? (_todaySteps / _goalSteps).clamp(0.0, 1.0)
                                : 0.0,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!_hasPermission)
                    Card(
                      color: Colors.orange,
                      child: ListTile(
                        leading: const Icon(Icons.warning),
                        title: const Text('Permission required'),
                        subtitle: const Text(
                          'App needs Activity Recognition permission to read step sensor',
                        ),
                        trailing: TextButton(
                          onPressed: () async {
                            await _requestPermission();
                            if (_hasPermission) _startListening();
                          },
                          child: const Text('Grant'),
                        ),
                      ),
                    ),
                  const Spacer(),
                  // Панель для тестирования / ручных действий: добавить/убрать шаг
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _modifySteps(-1),
                        icon: const Icon(Icons.remove),
                        label: const Text('-1 step'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _manualAddStep,
                        icon: const Icon(Icons.add),
                        label: const Text('+1 step'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          // сброс для текущего дня (dev)
                          final auth = Provider.of<AuthProvider>(
                            context,
                            listen: false,
                          );
                          final u = auth.user;
                          if (u == null) return;
                          await _db.upsertDailyMetrics(u.id!, _today, steps: 0);
                          await _loadProfileAndToday();
                        },
                        child: const Text('Reset today'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
      ),
    );
  }
}
