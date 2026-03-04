import '../entities/odontogram.dart';
import '../repositories/odontogram_repository.dart';

class ObserveOdontogram {
  ObserveOdontogram(this._repo);
  final OdontogramRepository _repo;

  Stream<Odontogram> call(String pacienteId) => _repo.observe(pacienteId);
}
