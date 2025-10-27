import 'package:donation_app/presentation/providers/auth/auth_provider.dart';
import 'package:donation_app/presentation/screens/donations_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'composition_root.dart';
import 'config/theme/app_theme.dart';

// Screens
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

  static final _navKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: CompositionRoot.providers(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        navigatorKey: _navKey,
        title: 'Recyclothes',
        theme: AppTheme.light(),
        home: const StartScreen(),
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
        builder: (context, child) =>
            _AuthRedirector(navKey: _navKey, child: child ?? const SizedBox()),
      ),
    );
  }
}

class _AuthRedirector extends StatefulWidget {
  const _AuthRedirector({
    required this.navKey,
    required this.child,
  });

  final GlobalKey<NavigatorState> navKey;
  final Widget child;

  @override
  State<_AuthRedirector> createState() => _AuthRedirectorState();
}

class _AuthRedirectorState extends State<_AuthRedirector> {
  AuthStatus? _last;

  void _maybeRedirect(AuthStatus status) {
    if (_last == status) return;
    _last = status;

    if (status == AuthStatus.authenticated) {
      widget.navKey.currentState
          ?.pushNamedAndRemoveUntil('/home', (route) => false);
    } else if (status == AuthStatus.unauthenticated) {
      widget.navKey.currentState
          ?.pushNamedAndRemoveUntil('/start', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = context.select<AuthProvider, AuthStatus>((a) => a.status);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeRedirect(status));
    if (status == AuthStatus.unknown || status == AuthStatus.loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return widget.child;
  }
}
