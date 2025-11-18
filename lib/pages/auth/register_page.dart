// lib/pages/auth/register_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:email_validator/email_validator.dart';
import '../../providers/auth_provider.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtl = TextEditingController();
  final _emailCtl = TextEditingController();
  final _passwordCtl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _error = null;
    });
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await Provider.of<AuthProvider>(context, listen: false).register(
        _usernameCtl.text.trim(),
        _emailCtl.text.trim(),
        _passwordCtl.text,
      );
      // after registration, navigate to home (replace)
      Navigator.of(context).pop(); // go back to login page
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _usernameCtl.dispose();
    _emailCtl.dispose();
    _passwordCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 8),
            ],
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _usernameCtl,
                    decoration: const InputDecoration(labelText: 'Username'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty)
                        return 'Введите username';
                      if (v.length > 20)
                        return 'Username не должен превышать 20 символов';
                      // Проверка на латиницу (A-Z, a-z, 0-9, подчеркивание)
                      final regex = RegExp(r'^[a-zA-Z0-9_]+$');
                      if (!regex.hasMatch(v))
                        return 'Используйте только латинские буквы и цифры';
                      return null;
                    },
                  ),

                  TextFormField(
                    controller: _emailCtl,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (v) =>
                        (v == null || !EmailValidator.validate(v.trim()))
                        ? 'Неверный email'
                        : null,
                  ),
                  TextFormField(
                    controller: _passwordCtl,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    validator: (v) => (v == null || v.length < 6)
                        ? 'Пароль должен быть >= 6 символов'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _loading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _submit,
                          child: const Text('Register'),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
