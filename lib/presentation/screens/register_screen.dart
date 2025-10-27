import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth/auth_provider.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_text_field.dart';
import '../widgets/password_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _city = TextEditingController();
  final _interests = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    _city.dispose();
    _interests.dispose();
    super.dispose();
  }

  List<String> _parseInterests(String raw) =>
      raw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final interests = _parseInterests(_interests.text);
    await context.read<AuthProvider>().signUp(
          name: _name.text.trim(),
          email: _email.text.trim(),
          password: _pass.text.trim(),
          city: _city.text.trim(),
          interests: interests,
        );
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthProvider>().status == AuthStatus.loading;

    return AppScaffold(
      title: 'Create Account',
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            const Text(
              'Join our network of donors and volunteers!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _name,
              label: 'Name *',
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _email,
              label: 'Email address *',
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
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _city,
              label: 'City *',
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter your city' : null,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _interests,
              label: 'Interests * (e.g., Donating, Volunteering)',
              validator: (v) => _parseInterests(v ?? '').isEmpty
                  ? 'Add at least one interest'
                  : null,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: loading ? null : _register,
                icon: const Icon(Icons.check),
                label: loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Create account'),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (_) => false,
              ),
              child: const Text("Already have an account? Log in"),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context,
                '/start',
                (_) => false,
              ),
              child: const Text("Back"),
            ),
          ],
        ),
      ),
    );
  }
}
