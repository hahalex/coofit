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
    final result = await showDialog<int?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add calories'),
        content: TextField(
          controller: ctl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'Enter'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final v = int.tryParse(ctl.text.trim());
              Navigator.of(ctx).pop(v);
            },
            child: const Text('Ok'),
          ),
        ],
      ),
    );

    if (result == null) return;
    await _modifyValue('calories', result, absolute: false);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  Widget _centerCounter({
    required String bigText,
    required String smallText,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
    Color cardColor = const Color(0xFF232323),
  }) {
    return Card(
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8),
        child: Row(
          children: [
            IconButton(
              onPressed: onMinus,
              icon: const Icon(Icons.remove, color: Colors.white),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    bigText,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    smallText,
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onPlus,
              icon: const Icon(Icons.add, color: Colors.white),
            ),
          ],
        ),
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _centerCounter(
              bigText: '$_calories Kcal',
              smallText: 'Goal: $_goalCalories',
              onMinus: () async {
                final v = await _askSubtractDialog('calories', _calories);
                if (v != null) await _modifyValue('calories', -v);
              },
              onPlus: _askNumberAndAddCalories,
              cardColor: const Color(0xFF009999),
            ),
            const SizedBox(height: 12),
            _centerCounter(
              bigText: '$_water glasses',
              smallText: 'Goal: $_goalWater',
              onMinus: () async {
                await _modifyValue('water', -1);
              },
              onPlus: () async {
                await _modifyValue('water', 1);
              },
              cardColor: const Color(0xFF009999),
            ),
            const SizedBox(height: 18),
            /*
            ElevatedButton(
              onPressed: () async {
                final auth = Provider.of<AuthProvider>(context, listen: false);
                final u = auth.user;
                if (u == null) return;
                await _db.upsertDailyMetrics(
                  u.id!,
                  _today,
                  calories: 0,
                  waterGlasses: 0,
                  steps: 0,
                );
                await _loadAll();
              },
              child: const Text('Reset today (dev)'),
            ),
            */
          ],
        ),
      ),
    );
  }

  Future<int?> _askSubtractDialog(String field, int current) async {
    final ctl = TextEditingController();
    final res = await showDialog<int?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reduce calories'),
        content: TextField(
          controller: ctl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(hintText: 'Current: $current'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final v = int.tryParse(ctl.text.trim());
              Navigator.of(ctx).pop(v);
            },
            child: const Text('Ok'),
          ),
        ],
      ),
    );
    return res;
  }
}
