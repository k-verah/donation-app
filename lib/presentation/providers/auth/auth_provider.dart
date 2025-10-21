import 'dart:async';
import 'package:donation_app/domain/entities/auth/auth_user.dart';
import 'package:donation_app/domain/use_cases/get_auth_state.dart';
import 'package:donation_app/domain/use_cases/sign_in.dart';
import 'package:donation_app/domain/use_cases/sign_out.dart';
import 'package:donation_app/domain/use_cases/sign_up.dart';
import 'package:flutter/foundation.dart';

enum AuthStatus { unknown, authenticated, unauthenticated, loading }

class AuthProvider extends ChangeNotifier {
  final SignIn _signIn;
  final SignUp _signUp;
  final SignOut _signOut;
  final GetAuthState _getAuthState;
  bool get loading =>
      _status == AuthStatus.loading || _status == AuthStatus.unknown;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  AuthUser? _user;
  AuthUser? get user => _user;

  AuthStatus _status = AuthStatus.unknown;
  AuthStatus get status => _status;

  StreamSubscription<AuthUser?>? _sub;

  AuthProvider({
    required SignIn signIn,
    required SignUp signUp,
    required SignOut signOut,
    required GetAuthState getAuthState,
  })  : _signIn = signIn,
        _signUp = signUp,
        _signOut = signOut,
        _getAuthState = getAuthState {
    _sub = _getAuthState().listen((u) {
      _user = u;
      _status =
          (u == null) ? AuthStatus.unauthenticated : AuthStatus.authenticated;
      notifyListeners();
    });
  }

  Future<void> signIn(String email, String password) async {
    _setLoading();
    await _signIn(email, password);
  }

  Future<void> signUp(
    String name,
    String email,
    String password,
    String city,
    List<String> interests,
  ) async {
    _setLoading();
    await _signUp(
      name: name,
      email: email,
      password: password,
      city: city,
      interests: interests,
    );
  }

  Future<void> signOut() async {
    _setLoading();
    await _signOut();
  }

  void _setLoading() {
    _status = AuthStatus.loading;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
