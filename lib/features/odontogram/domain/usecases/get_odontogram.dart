import '../entities/odontogram.dart';
import '../repositories/odontogram_repository.dart';

class GetOdontogram {
  GetOdontogram(this._repo);
  final OdontogramRepository _repo;

  Future<Odontogram> call(String pacienteId) => _repo.get(pacienteId);
}
