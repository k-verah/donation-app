import 'package:donation_app/domain/entities/auth/auth_user.dart';
import 'package:donation_app/domain/repositories/auth/auth_repository.dart';

class SignUp {
  final AuthRepository _repo;
  SignUp(this._repo);
  Future<AuthUser> call({
    required String name,
    required String email,
    required String password,
    required String city,
    required List<String> interests,
  }) {
    return _repo.signUp(
      name: name,
      email: email,
      password: password,
      city: city,
      interests: interests,
    );
  }
}
