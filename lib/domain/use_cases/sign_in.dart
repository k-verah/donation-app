import 'package:donation_app/domain/entities/auth/auth_user.dart';
import 'package:donation_app/domain/repositories/auth/auth_repository.dart';

class SignIn {
  final AuthRepository _repo;
  SignIn(this._repo);
  Future<AuthUser> call(String email, String password) =>
      _repo.signIn(email: email, password: password);
}
