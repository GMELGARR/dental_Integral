import '../repositories/auth_repository.dart';

class SendPasswordResetEmail {
  SendPasswordResetEmail(this._repository);

  final AuthRepository _repository;

  Future<void> call({required String email}) {
    return _repository.sendPasswordResetEmail(email: email);
  }
}