import 'package:firebase_auth/firebase_auth.dart' as fb;

class FirebaseAuthDatasource {
  final fb.FirebaseAuth _auth;
  FirebaseAuthDatasource(this._auth);

  Stream<fb.User?> authState() => _auth.authStateChanges();
  fb.User? get current => _auth.currentUser;

  Future<fb.User> signIn(String email, String password) async {
    final credentials = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credentials.user!;
  }

  Future<fb.User> signUp(String email, String password) async {
    final credentials = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credentials.user!;
  }

  Future<void> signOut() => _auth.signOut();
}
