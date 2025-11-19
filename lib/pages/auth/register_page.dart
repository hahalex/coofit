import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:email_validator/email_validator.dart';
import '../../providers/auth_provider.dart';
import 'login_page.dart';

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
    setState(() => _error = null);

    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      await Provider.of<AuthProvider>(context, listen: false).register(
        _usernameCtl.text.trim(),
        _emailCtl.text.trim(),
        _passwordCtl.text,
      );
      Navigator.of(
        context,
      ).pop(); // после успешной регистрации возвращаемся к логину
    } catch (e) {
      final errorMsg = e.toString().toLowerCase();
      if (errorMsg.contains('already exists') ||
          errorMsg.contains('user exists') ||
          errorMsg.contains('duplicate')) {
        setState(() => _error = "No way! You already have an account!");
      } else {
        setState(() => _error = "No way! You already have an account!");
      }
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
      backgroundColor: const Color(0xFF232323),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Верхняя часть с иконкой и заголовком
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 20,
              ),
              child: Column(
                children: [
                  ShaderMask(
                    shaderCallback: (Rect bounds) => const LinearGradient(
                      colors: [
                        Color(0xFF009999),
                        Color(0xFFFFC700),
                        Color(0xFFDB0058),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ).createShader(bounds),
                    child: const Icon(
                      Icons.run_circle_outlined,
                      size: 90,
                      color: Colors.white,
                    ),
                  ),
                  ShaderMask(
                    shaderCallback: (Rect bounds) => const LinearGradient(
                      colors: [
                        Color(0xFF009999),
                        Color(0xFFFFC700),
                        Color(0xFFDB0058),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ).createShader(bounds),
                    child: const Text(
                      'Cool Fit',
                      style: TextStyle(
                        fontFamily: 'AllertaStencil',
                        fontSize: 64,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const Text(
                    'Welcome to Cool Fit!\nSign Up to get started',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'InriaSans-Bold',
                      fontSize: 30,
                      color: Color(0xFFDB0058),
                    ),
                  ),
                ],
              ),
            ),

            // Полоса с формой
            Container(
              width: double.infinity,
              color: const Color(0xFF009999),
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildInputField(
                      controller: _usernameCtl,
                      hint: 'Username',
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return 'Enter username';
                        if (v.length > 20) return 'No more than 20 characters';
                        if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v)) {
                          return 'Only latin and numbers';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildInputField(
                      controller: _emailCtl,
                      hint: 'Email',
                      validator: (v) =>
                          (v == null || !EmailValidator.validate(v.trim()))
                          ? 'Enter the correct email address'
                          : null,
                    ),
                    const SizedBox(height: 20),
                    _buildInputField(
                      controller: _passwordCtl,
                      hint: 'Password',
                      obscure: true,
                      validator: (v) => (v == null || v.length < 6)
                          ? 'Password must be ≥ 6 characters'
                          : null,
                    ),
                    // Блок для отображения ошибки
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            // Кнопка Sign Up
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: _loading
                  ? const CircularProgressIndicator(color: Color(0xFFDB0058))
                  : GestureDetector(
                      onTap: _submit,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50),
                          color: const Color(0xFF232323),
                          border: Border.all(
                            color: Color(0xFFDB0058),
                            width: 2,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            color: Color(0xFFDB0058),
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
            ),

            const SizedBox(height: 10),
            const Text(
              "Already have an account?",
              style: TextStyle(
                fontFamily: 'InriaSans-Bold',
                fontSize: 20,
                color: Color(0xFF009999),
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const LoginPage())),
              child: const Text(
                'Sign In',
                style: TextStyle(
                  fontSize: 25,
                  color: Color(0xFFFFC700),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      cursorColor: const Color(0xFF009999),
      style: const TextStyle(
        color: Color(0xFF009999),
        fontFamily: 'InriaSans-Regular',
        fontSize: 20,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white70,
        hintText: hint,
        hintStyle: const TextStyle(
          color: Color(0xFF009999),
          fontFamily: 'InriaSans-Regular',
          fontSize: 20,
        ),
        errorStyle: const TextStyle(color: Colors.white, fontSize: 16),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: BorderSide.none,
        ),
      ),
      validator: validator,
    );
  }
}
