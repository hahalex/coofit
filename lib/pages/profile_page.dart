import 'dart:ui';

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
  final _stepsCtl = TextEditingController();

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

  // ---- Dialogs ----
  Future<void> _showOptionDialog(int userId) async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Options',
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
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF009999), width: 2),
              ),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Profile Options',
                      style: TextStyle(
                        color: Color(0xFFFFC700),
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _showChangeEmailDialog(userId);
                      },
                      child: const Text('Change email'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _showChangePasswordDialog(userId);
                      },
                      child: const Text('Change password'),
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

  Future<void> _showChangeEmailDialog(int userId) async {
    final _dlgKey = GlobalKey<FormState>();
    String? _dlgError;
    bool _dlgLoading = false;

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Change Email',
      barrierColor: Colors.transparent,
      pageBuilder: (ctx, anim1, anim2) {
        final emailCtl = TextEditingController();
        final passCtl = TextEditingController();
        final auth = Provider.of<AuthProvider>(context, listen: false);

        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: const Color(0xFF232323),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF009999), width: 2),
              ),
              child: Material(
                color: Colors.transparent,
                child: StatefulBuilder(
                  builder: (ctx2, setStateDlg) => Form(
                    key: _dlgKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Change email',
                            style: TextStyle(
                              color: Color(0xFFFFC700),
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
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
                                    !EmailValidator.validate(v.trim()))
                                ? 'Invalid email'
                                : null,
                          ),
                          TextFormField(
                            controller: passCtl,
                            decoration: const InputDecoration(
                              labelText: 'Current password',
                            ),
                            obscureText: true,
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'Enter your current password'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx2).pop(),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(color: Color(0xFFDB0058)),
                                ),
                              ),
                              _dlgLoading
                                  ? const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      child: SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    )
                                  : TextButton(
                                      onPressed: () async {
                                        if (!_dlgKey.currentState!.validate())
                                          return;
                                        setStateDlg(() {
                                          _dlgError = null;
                                          _dlgLoading = true;
                                        });
                                        try {
                                          await auth.changeEmail(
                                            currentPassword: passCtl.text,
                                            newEmail: emailCtl.text.trim(),
                                          );
                                          Navigator.of(ctx2).pop();
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text('Email updated'),
                                            ),
                                          );
                                        } catch (e) {
                                          setStateDlg(() {
                                            _dlgError = e.toString();
                                            _dlgLoading = false;
                                          });
                                        }
                                      },
                                      child: const Text(
                                        'Change',
                                        style: TextStyle(
                                          color: Color(0xFFFFC700),
                                        ),
                                      ),
                                    ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showChangePasswordDialog(int userId) async {
    final _dlgKey = GlobalKey<FormState>();
    String? _dlgError;
    bool _dlgLoading = false;

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Change Password',
      barrierColor: Colors.transparent,
      pageBuilder: (ctx, anim1, anim2) {
        final currentCtl = TextEditingController();
        final newCtl = TextEditingController();
        final confirmCtl = TextEditingController();
        final auth = Provider.of<AuthProvider>(context, listen: false);

        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: const Color(0xFF232323),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF009999), width: 2),
              ),
              child: Material(
                color: Colors.transparent,
                child: StatefulBuilder(
                  builder: (ctx2, setStateDlg) => Form(
                    key: _dlgKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Change password',
                            style: TextStyle(
                              color: Color(0xFFFFC700),
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
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
                                ? 'Enter your current password'
                                : null,
                          ),
                          TextFormField(
                            controller: newCtl,
                            decoration: const InputDecoration(
                              labelText: 'New password',
                            ),
                            obscureText: true,
                            validator: (v) => (v == null || v.length < 6)
                                ? 'Password must be >= 6 characters'
                                : null,
                          ),
                          TextFormField(
                            controller: confirmCtl,
                            decoration: const InputDecoration(
                              labelText: 'Confirm new password',
                            ),
                            obscureText: true,
                            validator: (v) => (v != newCtl.text)
                                ? 'Passwords do not match'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx2).pop(),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(color: Color(0xFFDB0058)),
                                ),
                              ),
                              _dlgLoading
                                  ? const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      child: SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    )
                                  : TextButton(
                                      onPressed: () async {
                                        if (!_dlgKey.currentState!.validate())
                                          return;
                                        setStateDlg(() {
                                          _dlgError = null;
                                          _dlgLoading = true;
                                        });
                                        try {
                                          await auth.changePassword(
                                            currentPassword: currentCtl.text,
                                            newPassword: newCtl.text,
                                          );
                                          Navigator.of(ctx2).pop();
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text('Password updated'),
                                            ),
                                          );
                                        } catch (e) {
                                          setStateDlg(() {
                                            _dlgError = e.toString();
                                            _dlgLoading = false;
                                          });
                                        }
                                      },
                                      child: const Text(
                                        'Change',
                                        style: TextStyle(
                                          color: Color(0xFFFFC700),
                                        ),
                                      ),
                                    ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
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
      backgroundColor: const Color(0xFF232323),
      appBar: AppBar(
        backgroundColor: const Color(0xFF232323),
        centerTitle: true,
        title: const Text(
          'Profile',
          style: TextStyle(color: Color(0xFFDB0058), fontSize: 28),
        ),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout, color: Color(0xFFDB0058)),
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
                      color: const Color(0xFF009999),
                      child: ListTile(
                        title: Text(
                          user.username,
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          user.email,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        leading: const Icon(Icons.person, color: Colors.white),
                        trailing: IconButton(
                          icon: const Icon(Icons.settings, color: Colors.white),
                          onPressed: () => _showOptionDialog(user.id!),
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
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Weight (kg)',
                              hintText: '70.5',
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _heightCtl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Height (cm)',
                              hintText: '175',
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _caloriesCtl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Daily calories',
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _waterCtl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Glasses of water per day',
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _stepsCtl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Daily steps target',
                              hintText: '5000',
                            ),
                          ),
                          const SizedBox(height: 16),
                          _loading
                              ? const CircularProgressIndicator()
                              : ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF009999),
                                  ),
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
