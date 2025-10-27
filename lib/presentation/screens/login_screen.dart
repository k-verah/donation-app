import 'package:donation_app/main.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth/auth_provider.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/password_field.dart';
import '../widgets/app_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await context.read<AuthProvider>().signIn(
            _email.text.trim(),
            _pass.text.trim(),
          );
    } catch (e) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final provider = context.read<AuthProvider>();
      messenger
          .showSnackBar(
            SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
          )
          .closed
          .then((_) {
        if (mounted) provider.clearError();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthProvider>().status == AuthStatus.loading;

    return AppScaffold(
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            const Text(
              "Sign In",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            AppTextField(
              controller: _email,
              label: "Email address",
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter your email' : null,
            ),
            const SizedBox(height: 12),
            PasswordField(
              controller: _pass,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter a password' : null,
              onSubmitted: (_) => loading ? null : _login(),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF003137),
                foregroundColor: Colors.white,
              ),
              onPressed: loading ? null : _login,
              child: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text("Enter"),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, '/start'),
              child: const Text("Back"),
            ),
          ],
        ),
      ),
    );
  }
}
