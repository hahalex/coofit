import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _idCtl = TextEditingController();
  final _passwordCtl = TextEditingController();
  String? _error;
  bool _loading = false;

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await Provider.of<AuthProvider>(
        context,
        listen: false,
      ).login(_idCtl.text.trim(), _passwordCtl.text);
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      // Вместо e.toString() показываем дружелюбное сообщение
      setState(() => _error = "Oops! There are no such people here!");
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _idCtl.dispose();
    _passwordCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF232323),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
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
                'Welcome to Cool Fit!\nGlad to see you again!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'InriaSans-Bold',
                  fontSize: 30,
                  color: Color(0xFFDB0058),
                ),
              ),
              const SizedBox(height: 40),

              // Полоса цвета #009999 с формой
              Container(
                width: double.infinity,
                color: const Color(0xFF009999),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: _buildInputField(
                          controller: _idCtl,
                          hint: 'Username or email',
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: _buildInputField(
                          controller: _passwordCtl,
                          hint: 'Password',
                          obscure: true,
                        ),
                      ),
                      // Отображение ошибки авторизации
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
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

              const SizedBox(height: 80),

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
                            'Sign In',
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
                "Don't have an account?",
                style: TextStyle(
                  fontFamily: 'InriaSans-Bold',
                  fontSize: 20,
                  color: Color(0xFF009999),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const RegisterPage())),
                child: const Text(
                  'Sign Up',
                  style: TextStyle(
                    fontSize: 25,
                    color: Color(0xFFFFC700),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
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
          fontFamily: 'InriaSans-Bold',
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
      validator: (v) => (v == null || v.trim().isEmpty)
          ? 'Please enter your login details'
          : null,
    );
  }
}
