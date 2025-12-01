import 'dart:async';
import 'dart:io';
import 'package:donation_app/domain/entities/auth/auth_user.dart';
import 'package:donation_app/domain/use_cases/auth/get_auth_state.dart';
import 'package:donation_app/domain/use_cases/auth/sign_in.dart';
import 'package:donation_app/domain/use_cases/auth/sign_out.dart';
import 'package:donation_app/domain/use_cases/auth/sign_up.dart';
import 'package:flutter/foundation.dart';

enum AuthStatus { unknown, authenticated, unauthenticated, loading }

class AuthProvider extends ChangeNotifier {
  final SignIn _signIn;
  final SignUp _signUp;
  final SignOut _signOut;
  final GetAuthState _getAuthState;
  String? lastError;

  AuthStatus status = AuthStatus.unknown;
  AuthUser? _user;
  StreamSubscription<AuthUser?>? _sub;

  bool get loading =>
      status == AuthStatus.loading || status == AuthStatus.unknown;
  bool get isAuthenticated => status == AuthStatus.authenticated;
  AuthUser? get user => _user;

  AuthProvider(this._signIn, this._signUp, this._signOut, this._getAuthState) {
    _sub = _getAuthState().listen(
      (u) {
        _user = u;
        status =
            (u == null) ? AuthStatus.unauthenticated : AuthStatus.authenticated;
        lastError = null; // Limpiar error si auth exitoso
        notifyListeners();
      },
      onError: (error) {
        // Si hay error en el stream, mantener estado actual
        debugPrint('⚠️ Auth stream error: $error');
        // Si ya teníamos usuario, mantenerlo (offline)
        if (_user != null) {
          status = AuthStatus.authenticated;
        }
        notifyListeners();
      },
    );
  }

  Future<void> signIn(String email, String password) async {
    _setLoading();
    lastError = null;
    try {
      await _signIn(email, password);
      lastError = null;
    } catch (e) {
      _setError(_parseError(e));
      status = AuthStatus.unauthenticated;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
    required String city,
    required List<String> interests,
  }) async {
    _setLoading();
    lastError = null;
    try {
      await _signUp(
        name: name,
        email: email,
        password: password,
        city: city,
        interests: interests,
      );
      lastError = null;
    } catch (e) {
      _setError(_parseError(e));
      status = AuthStatus.unauthenticated;
      notifyListeners();
      rethrow;
    }
  }

  String _parseError(Object e) {
    final errorStr = e.toString();

    // Errores de red
    if (e is SocketException ||
        errorStr.contains('network') ||
        errorStr.contains('SocketException') ||
        errorStr.contains('Failed host lookup') ||
        errorStr.contains('Connection refused')) {
      return 'No internet connection. Please check your network and try again.';
    }

    // Timeout
    if (e is TimeoutException || errorStr.contains('timeout')) {
      return 'Connection timeout. Please try again.';
    }

    return errorStr.replaceAll('Exception: ', '');
  }

  Future<void> signOut() async {
    _setLoading();
    await _signOut();
  }

  void _setLoading() {
    status = AuthStatus.loading;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _setError(Object e) {
    lastError = e.toString().replaceAll('Exception: ', '');
    notifyListeners();
  }

  void clearError() {
    lastError = null;
    notifyListeners();
  }
}
