import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

class ObserveAuthState {
  ObserveAuthState(this._repository);

  final AuthRepository _repository;

  Stream<AuthUser?> call() {
    return _repository.observeAuthState();
  }
}