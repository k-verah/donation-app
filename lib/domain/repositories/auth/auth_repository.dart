import 'package:donation_app/domain/entities/auth/auth_user.dart';

abstract class AuthRepository {
  Stream<AuthUser?> authStateChanges();
  AuthUser? get currentUser;
  Future<AuthUser> signIn({required String email, required String password});
  Future<AuthUser> signUp({
    required String name,
    required String email,
    required String password,
    required String city,
    required List<String> interests,
  });
  Future<void> signOut();
}
