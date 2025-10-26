import 'package:donation_app/data/datasources/auth/firebase_auth_datasource.dart';
import 'package:donation_app/data/datasources/users/user_profile_datasource.dart';
import 'package:donation_app/domain/entities/auth/auth_user.dart';
import 'package:donation_app/domain/repositories/auth/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthDatasource authds;
  final UserProfileDataSource profileds;
  AuthRepositoryImpl(this.authds, this.profileds);

  AuthUser _toDomain(fb.User u, {Map<String, dynamic>? profile}) {
    return AuthUser(
      uid: u.uid,
      email: u.email,
      name: profile?['name'],
      city: profile?['city'],
      interests: profile?['interests'] != null
          ? List<String>.from(profile!['interests'])
          : null,
    );
  }

  @override
  Stream<AuthUser?> authStateChanges() async* {
    await for (final u in authds.authState()) {
      if (u == null) {
        yield null;
      } else {
        final profile = await profileds.getProfile(u.uid);
        yield _toDomain(u, profile: profile);
      }
    }
  }

  @override
  AuthUser? get currentUser {
    final u = authds.current;
    if (u == null) return null;
    return _toDomain(u);
  }

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
      final profile = await profileds.getProfile(u.uid);
      return _toDomain(u, profile: profile);
    } on fb.FirebaseAuthException {
      throw Exception();
    }
  }

  @override
  Future<void> signOut() => authds.signOut();
}
