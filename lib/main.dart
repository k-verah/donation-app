import 'package:donation_app/presentation/screens/donations_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'composition_root.dart';
import 'config/theme/app_theme.dart';

// Screens
import 'presentation/screens/auth_gate.dart';
import 'presentation/screens/start_screen.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/register_screen.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/new_donation_screen.dart';
import 'presentation/screens/notifications_screen.dart';
import 'presentation/screens/schedule_screen.dart';
import 'presentation/screens/pickup_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const Recyclothes());
}

class Recyclothes extends StatelessWidget {
  const Recyclothes({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: CompositionRoot.providers(),
      child: Builder(
        builder: (context) => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Recyclothes',
          theme: AppTheme.light(),
          home: const AuthGate(),
          routes: {
            '/start': (_) => const StartScreen(),
            '/login': (_) => const LoginScreen(),
            '/register': (_) => const RegisterScreen(),
            '/home': (_) => const HomeScreen(),
            '/donations': (_) => const DonationsScreen(),
            '/new-donation': (_) => const NewDonationScreen(),
            '/notifications': (_) => const NotificationsScreen(),
            '/schedule': (_) => const ScheduleScreen(),
            '/pickup': (_) => const PickupScreen(),
          },
        ),
      ),
    );
  }
}
