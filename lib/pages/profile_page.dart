// lib/pages/profile_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:email_validator/email_validator.dart';
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
  final _stepsCtl = TextEditingController(); // <-- new

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
        _stepsCtl.text = (map['target_steps'] ?? 5000).toString();
        _initialized = true;
      });
    } else {
      await _db.createProfile(userId);
      await _loadProfile(userId);
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
        'target_steps': int.tryParse(_stepsCtl.text) ?? 5000,
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
    _stepsCtl.dispose();
    super.dispose();
  }

  // ---- Dialogs for change email and password ----
  // (unchanged methods from your original file)
  Future<void> _showChangeEmailDialog(int userId) async {
    final _dlgKey = GlobalKey<FormState>();
    String? _dlgError;
    bool _dlgLoading = false;

    await showDialog(
      context: context,
      builder: (ctx) {
        final emailCtl = TextEditingController();
        final passCtl = TextEditingController();

        return StatefulBuilder(
          builder: (ctx2, setStateDlg) {
            return AlertDialog(
              title: const Text('Change email'),
              content: SingleChildScrollView(
                child: Form(
                  key: _dlgKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_dlgError != null) ...[
                        Text(
                          _dlgError!,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 8),
                      ],
                      TextFormField(
                        controller: emailCtl,
                        decoration: const InputDecoration(
                          labelText: 'New email',
                        ),
                        validator: (v) =>
                            (v == null ||
                                !RegExp(
                                  r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                                ).hasMatch(v.trim()))
                            ? 'Неверный email'
                            : null,
                      ),
                      TextFormField(
                        controller: passCtl,
                        decoration: const InputDecoration(
                          labelText: 'Current password',
                        ),
                        obscureText: true,
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Введите текущий пароль'
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx2).pop(),
                  child: const Text('Cancel'),
                ),
                _dlgLoading
                    ? const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : TextButton(
                        onPressed: () async {
                          if (!_dlgKey.currentState!.validate()) return;
                          setStateDlg(() {
                            _dlgError = null;
                            _dlgLoading = true;
                          });
                          try {
                            await Provider.of<AuthProvider>(
                              context,
                              listen: false,
                            ).changeEmail(
                              currentPassword: passCtl.text,
                              newEmail: emailCtl.text.trim(),
                            );
                            Navigator.of(ctx2).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Email updated')),
                            );
                          } catch (e) {
                            var msg = e.toString();
                            if (msg.contains('invalid_current_password'))
                              msg = 'Неверный текущий пароль';
                            if (msg.contains('email_taken'))
                              msg = 'Этот email уже занят';
                            if (msg.contains('invalid_email_format'))
                              msg = 'Неверный формат email';
                            setStateDlg(() {
                              _dlgError = msg;
                              _dlgLoading = false;
                            });
                          }
                        },
                        child: const Text('Change'),
                      ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showChangePasswordDialog(int userId) async {
    final _dlgKey = GlobalKey<FormState>();
    String? _dlgError;
    bool _dlgLoading = false;

    await showDialog(
      context: context,
      builder: (ctx) {
        final currentCtl = TextEditingController();
        final newCtl = TextEditingController();
        final confirmCtl = TextEditingController();

        return StatefulBuilder(
          builder: (ctx2, setStateDlg) {
            return AlertDialog(
              title: const Text('Change password'),
              content: SingleChildScrollView(
                child: Form(
                  key: _dlgKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_dlgError != null) ...[
                        Text(
                          _dlgError!,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 8),
                      ],
                      TextFormField(
                        controller: currentCtl,
                        decoration: const InputDecoration(
                          labelText: 'Current password',
                        ),
                        obscureText: true,
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Введите текущий пароль'
                            : null,
                      ),
                      TextFormField(
                        controller: newCtl,
                        decoration: const InputDecoration(
                          labelText: 'New password',
                        ),
                        obscureText: true,
                        validator: (v) => (v == null || v.length < 6)
                            ? 'Пароль должен быть >= 6 символов'
                            : null,
                      ),
                      TextFormField(
                        controller: confirmCtl,
                        decoration: const InputDecoration(
                          labelText: 'Confirm new password',
                        ),
                        obscureText: true,
                        validator: (v) =>
                            (v != newCtl.text) ? 'Пароли не совпадают' : null,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx2).pop(),
                  child: const Text('Cancel'),
                ),
                _dlgLoading
                    ? const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : TextButton(
                        onPressed: () async {
                          if (!_dlgKey.currentState!.validate()) return;
                          setStateDlg(() {
                            _dlgError = null;
                            _dlgLoading = true;
                          });
                          try {
                            await Provider.of<AuthProvider>(
                              context,
                              listen: false,
                            ).changePassword(
                              currentPassword: currentCtl.text,
                              newPassword: newCtl.text,
                            );
                            Navigator.of(ctx2).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Password updated')),
                            );
                          } catch (e) {
                            var msg = e.toString();
                            if (msg.contains('invalid_current_password'))
                              msg = 'Неверный текущий пароль';
                            if (msg.contains('password_too_short'))
                              msg = 'Новый пароль слишком короткий';
                            setStateDlg(() {
                              _dlgError = msg;
                              _dlgLoading = false;
                            });
                          }
                        },
                        child: const Text('Change'),
                      ),
              ],
            );
          },
        );
      },
    );
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
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) {
                            if (v == 'change_email') {
                              _showChangeEmailDialog(user.id!);
                            } else if (v == 'change_password') {
                              _showChangePasswordDialog(user.id!);
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'change_email',
                              child: Text('Change email'),
                            ),
                            PopupMenuItem(
                              value: 'change_password',
                              child: Text('Change password'),
                            ),
                          ],
                        ),
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
                          const SizedBox(height: 8),
                          // NEW: daily steps target
                          TextFormField(
                            controller: _stepsCtl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Daily steps target',
                              hintText: 'e.g. 5000',
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return null;
                              final n = int.tryParse(v);
                              if (n == null || n <= 0)
                                return 'Введите корректное число шагов';
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
