import '../entities/odontologist.dart';
import '../repositories/odontologist_repository.dart';

class ObserveOdontologists {
  ObserveOdontologists(this._repository);

  final OdontologistRepository _repository;

  Stream<List<Odontologist>> call() {
    return _repository.observeAll();
  }
}
