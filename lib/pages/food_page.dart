import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/db_service.dart';

class FoodPage extends StatefulWidget {
  const FoodPage({super.key});

  @override
  State<FoodPage> createState() => _FoodPageState();
}

class _FoodPageState extends State<FoodPage> {
  final DBService _db = DBService();

  int _calories = 0;
  int _water = 0;

  int _goalCalories = 1500;
  int _goalWater = 8;

  bool _loading = true;

  String get _today {
    final now = DateTime.now();
    return now.toIso8601String().split('T')[0];
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }
    final uid = user.id!;
    final profile = await _db.getProfileByUserId(uid);
    if (profile != null) {
      _goalCalories = profile['daily_calories'] ?? 1500;
      _goalWater = profile['water_glasses'] ?? 8;
    }
    final metrics = await _db.getDailyMetrics(uid, _today);
    if (metrics != null) {
      _calories = metrics['calories'] ?? 0;
      _water = metrics['water_glasses'] ?? 0;
    } else {
      await _db.insertDailyMetrics(
        uid,
        _today,
        calories: 0,
        waterGlasses: 0,
        steps: 0,
      );
      _calories = 0;
      _water = 0;
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _modifyValue(
    String field,
    int delta, {
    bool absolute = false,
  }) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;
    if (user == null) return;
    final uid = user.id!;
    final metrics = await _db.getDailyMetrics(uid, _today);
    if (metrics == null) {
      await _db.insertDailyMetrics(
        uid,
        _today,
        calories: 0,
        waterGlasses: 0,
        steps: 0,
      );
    }

    if (field == 'calories') {
      final current = metrics?['calories'] ?? _calories;
      int newVal = absolute ? delta : current + delta;
      if (newVal < 0) newVal = 0;
      await _db.upsertDailyMetrics(uid, _today, calories: newVal);
    } else if (field == 'water') {
      final current = metrics?['water_glasses'] ?? _water;
      int newVal = absolute ? delta : current + delta;
      if (newVal < 0) newVal = 0;
      await _db.upsertDailyMetrics(uid, _today, waterGlasses: newVal);
    }

    await _loadAll();
  }

  Future<void> _askNumberAndAddCalories() async {
    final ctl = TextEditingController();
    final result = await _showNumberDialog(
      title: 'Add calories',
      ctl: ctl,
      hint: 'Enter',
    );
    if (result == null) return;
    await _modifyValue('calories', result, absolute: false);
  }

  Future<void> _askNumberAndReduceCalories() async {
    final ctl = TextEditingController();
    final result = await _showNumberDialog(
      title: 'Reduce calories',
      ctl: ctl,
      hint: 'Current: $_calories',
    );
    if (result == null) return;
    await _modifyValue('calories', -result);
  }

  Future<int?> _showNumberDialog({
    required String title,
    required TextEditingController ctl,
    required String hint,
  }) async {
    return await showGeneralDialog<int?>(
      context: context,
      barrierDismissible: true,
      barrierLabel: title,
      barrierColor: Colors.transparent,
      pageBuilder: (ctx, anim1, anim2) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: const Color(0xFF232323),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF009999), width: 2),
              ),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFFFFC700),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: ctl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(hintText: hint),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(null),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: Color(0xFFDB0058)),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            final v = int.tryParse(ctl.text.trim());
                            Navigator.of(ctx).pop(v);
                          },
                          child: const Text(
                            'Ok',
                            style: TextStyle(color: Color(0xFFFFC700)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  Widget _buildCountersCard() {
    return Container(
      color: const Color(0xFF009999),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Calories row with buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _askNumberAndReduceCalories,
                icon: const Icon(Icons.remove, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  const Text(
                    "Today's Kilocalories",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$_calories',
                    style: const TextStyle(
                      fontFamily: 'AllertaStencil-Regular',
                      fontSize: 64,
                      color: Color(0xFFFFC700),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Goal: $_goalCalories',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: _askNumberAndAddCalories,
                icon: const Icon(Icons.add, color: Colors.white, size: 32),
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Water row with buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () async => await _modifyValue('water', -1),
                icon: const Icon(Icons.remove, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  const Text(
                    "Today's glasses of water",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$_water',
                    style: const TextStyle(
                      fontFamily: 'AllertaStencil-Regular',
                      fontSize: 64,
                      color: Color(0xFFFFC700),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Goal: $_goalWater',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () async => await _modifyValue('water', 1),
                icon: const Icon(Icons.add, color: Colors.white, size: 32),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      backgroundColor: const Color(0xFF232323),
      appBar: AppBar(
        backgroundColor: const Color(0xFF232323),
        centerTitle: true,
        title: const Text(
          'Food tracker',
          style: TextStyle(color: Color(0xFFDB0058), fontSize: 28),
        ),
      ),
      body: Center(
        child: SizedBox(width: double.infinity, child: _buildCountersCard()),
      ),
    );
  }
}
