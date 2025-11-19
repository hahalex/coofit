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
  int? _lastSensorValue;
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
    await _loadProfileAndToday();
    await _requestPermission();
    if (_hasPermission) _startListening();
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
    if (profile != null) _goalSteps = profile['target_steps'] ?? 5000;

    final metrics = await _db.getDailyMetrics(user.id!, _today);
    if (metrics != null) {
      _todaySteps = metrics['steps'] ?? 0;
    } else {
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
    PermissionStatus status;
    try {
      status = await Permission.activityRecognition.status;
      if (status != PermissionStatus.granted) {
        status = await Permission.activityRecognition.request();
      }
    } catch (e) {
      status = PermissionStatus.denied;
    }
    setState(() => _hasPermission = status == PermissionStatus.granted);
  }

  void _startListening() {
    _stepSub?.cancel();
    _stepSub = Pedometer.stepCountStream.listen(
      _onStepCount,
      onError: (e) {},
      cancelOnError: true,
    );
  }

  void _onStepCount(StepCount event) async {
    final sensorValue = event.steps;
    if (_lastSensorValue == null) {
      _lastSensorValue = sensorValue;
      return;
    }

    int delta = sensorValue - _lastSensorValue!;
    if (delta < 0) delta = sensorValue;

    if (delta > 0) await _addSteps(delta);

    _lastSensorValue = sensorValue;
  }

  Future<void> _addSteps(int delta) async {
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
      await _db.upsertDailyMetrics(user.id!, _today, steps: current + delta);
    }

    final updated = await _db.getDailyMetrics(user.id!, _today);
    if (mounted)
      setState(() => _todaySteps = updated?['steps'] ?? _todaySteps + delta);
  }

  Future<void> _manualAddStep() async {
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
    return Scaffold(
      backgroundColor: const Color(0xFF232323),
      appBar: AppBar(
        backgroundColor: const Color(0xFF232323),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Steps menu',
          style: TextStyle(color: Color(0xFFDB0058), fontSize: 28),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // ---- ВЕРХНЯЯ ПОЛОВИНА ----
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "Today's Steps",
                            style: TextStyle(
                              fontSize: 20,
                              color: Color(0xFFFFC700),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '$_todaySteps',
                            style: const TextStyle(
                              fontFamily: 'AllertaStencil',
                              fontSize: 64,
                              color: Color(0xFFFFC700),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Goal: $_goalSteps steps',
                            style: TextStyle(
                              fontSize: 20,
                              color: const Color(0xFFFFC700).withOpacity(0.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ---- НИЖНЯЯ ПОЛОВИНА (пока пустая) ----
                  const Expanded(child: SizedBox()),
                ],
              ),
      ),
    );
  }
}
