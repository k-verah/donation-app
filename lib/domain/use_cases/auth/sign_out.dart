import 'package:donation_app/domain/repositories/auth/auth_repository.dart';

class SignOut {
  final AuthRepository _repo;
  SignOut(this._repo);
  Future<void> call() => _repo.signOut();
}
