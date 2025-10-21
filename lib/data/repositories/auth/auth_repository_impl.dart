import 'package:donation_app/data/datasources/auth/firebase_auth_datasource.dart';
import 'package:donation_app/data/datasources/users/user_profile_datasource.dart';
import 'package:donation_app/domain/entities/auth/auth_user.dart';
import 'package:donation_app/domain/repositories/auth/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthDatasource authds;
  final UserProfileDataSource profileds;
  AuthRepositoryImpl(this.authds, this.profileds);

  AuthUser _toDomain(fb.User u) => AuthUser(uid: u.uid, email: u.email);

  @override
  Stream<AuthUser?> authStateChanges() =>
      authds.authState().map((u) => u == null ? null : _toDomain(u));

  @override
  AuthUser? get currentUser =>
      authds.current == null ? null : _toDomain(authds.current!);

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final u = await authds.signIn(email, password);
      return _toDomain(u);
    } on fb.FirebaseAuthException {
      throw Exception();
    }
  }

  @override
  Future<AuthUser> signUp({
    required String name,
    required String email,
    required String password,
    required String city,
    required List<String> interests,
  }) async {
    try {
      final u = await authds.signUp(email, password);
      await profileds.saveProfile(
        uid: u.uid,
        name: name,
        email: email,
        city: city,
        interests: interests,
      );
      return _toDomain(u);
    } on fb.FirebaseAuthException {
      throw Exception();
    }
  }

  @override
  Future<void> signOut() => authds.signOut();
}
