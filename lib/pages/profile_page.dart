// lib/pages/profile_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/db_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final DBService _db = DBService();

  final _formKey = GlobalKey<FormState>();
  final _weightCtl = TextEditingController();
  final _heightCtl = TextEditingController();
  final _caloriesCtl = TextEditingController();
  final _waterCtl = TextEditingController();

  bool _loading = false;
  String? _error;
  bool _initialized = false;

  Future<void> _loadProfile(int userId) async {
    final map = await _db.getProfileByUserId(userId);
    if (map != null) {
      setState(() {
        _weightCtl.text = map['weight']?.toString() ?? '';
        _heightCtl.text = map['height']?.toString() ?? '';
        _caloriesCtl.text = (map['daily_calories'] ?? 1500).toString();
        _waterCtl.text = (map['water_glasses'] ?? 8).toString();
        _initialized = true;
      });
    } else {
      // Create default profile if missing
      await _db.createProfile(userId);
      _loadProfile(userId);
    }
  }

  Future<void> _save(int userId) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final values = <String, dynamic>{
        'weight': _weightCtl.text.isEmpty
            ? null
            : double.tryParse(_weightCtl.text),
        'height': _heightCtl.text.isEmpty
            ? null
            : double.tryParse(_heightCtl.text),
        'daily_calories': int.tryParse(_caloriesCtl.text) ?? 1500,
        'water_glasses': int.tryParse(_waterCtl.text) ?? 8,
      };
      await _db.updateProfile(userId, values);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Saved')));
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _weightCtl.dispose();
    _heightCtl.dispose();
    _caloriesCtl.dispose();
    _waterCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    if (user == null) {
      return const Center(
        child: Text('No user', style: TextStyle(fontSize: 18)),
      );
    }

    if (!_initialized) {
      // load profile once
      _loadProfile(user.id!).catchError((e) {
        setState(() => _error = e.toString());
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.logout();
              // After logout, app's Consumer in app.dart will show LoginPage
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _initialized == false
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  children: [
                    if (_error != null) ...[
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 8),
                    ],
                    Card(
                      child: ListTile(
                        title: Text(user.username),
                        subtitle: Text(user.email),
                        leading: const Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _weightCtl,
                            keyboardType: TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Weight (kg)',
                              hintText: 'e.g. 70.5',
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return null;
                              final n = double.tryParse(v);
                              if (n == null || n <= 0)
                                return 'Введите корректный вес';
                              return null;
                            },
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _heightCtl,
                            keyboardType: TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Height (cm)',
                              hintText: 'e.g. 175',
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return null;
                              final n = double.tryParse(v);
                              if (n == null || n <= 0)
                                return 'Введите корректный рост';
                              return null;
                            },
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _caloriesCtl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Daily calories',
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return null;
                              final n = int.tryParse(v);
                              if (n == null || n <= 0)
                                return 'Введите корректное число калорий';
                              return null;
                            },
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _waterCtl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Glasses of water per day',
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return null;
                              final n = int.tryParse(v);
                              if (n == null || n <= 0)
                                return 'Введите корректное число';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _loading
                              ? const CircularProgressIndicator()
                              : ElevatedButton(
                                  onPressed: () => _save(user.id!),
                                  child: const Text('Save'),
                                ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              // optional: navigate to change password page later
                            },
                            child: const Text('Change password'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
