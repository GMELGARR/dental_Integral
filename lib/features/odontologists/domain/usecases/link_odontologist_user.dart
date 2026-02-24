import '../repositories/odontologist_repository.dart';

class LinkOdontologistUser {
  LinkOdontologistUser(this._repository);

  final OdontologistRepository _repository;

  Future<void> call({
    required String odontologistId,
    required String? userId,
  }) {
    return _repository.linkUser(
      odontologistId: odontologistId,
      userId: userId,
    );
  }
}
