import 'package:donation_app/domain/entities/auth/auth_user.dart';
import 'package:donation_app/domain/repositories/auth/auth_repository.dart';

class GetAuthState {
  final AuthRepository _repo;
  GetAuthState(this._repo);
  Stream<AuthUser?> call() => _repo.authStateChanges();
}
