import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  final Map<String, String> _fakeUsers = {
    'test@test.com': '123456',
    'juli@tatis.com': 'pass123',
  };

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final pw = _passwordController.text.trim();

    if (email.isEmpty || pw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa correo y contraseña')),
      );
      return;
    }

    setState(() => _loading = true);

    // Simulación de retraso de red
    await Future.delayed(const Duration(milliseconds: 500));

    final expected = _fakeUsers[email];
    if (expected != null && expected == pw) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Credenciales incorrectas')),
      );
    }

    setState(() => _loading = false);
  }

  void _register() {
    // Registro simulado
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Registro simulado exitoso')),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF003137);
    const background = Color(0xFFAFC7CA);

    return Scaffold(
      backgroundColor: background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Iniciar Sesión",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 30),

                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: "Correo electrónico",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),

                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Contraseña",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 25),

                ElevatedButton(
                  onPressed: _loading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text("Entrar"),
                ),

                const SizedBox(height: 10),

                TextButton(
                  onPressed: _register,
                  child: const Text("Registrarse"),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}