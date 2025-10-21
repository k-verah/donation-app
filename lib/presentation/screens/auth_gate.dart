import 'package:donation_app/presentation/providers/auth/auth_provider.dart';
import 'package:donation_app/presentation/screens/initial_page_screen.dart';
import 'package:donation_app/presentation/screens/start_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return auth.isAuthenticated ? const HomeScreen() : const StartScreen();
  }
}
