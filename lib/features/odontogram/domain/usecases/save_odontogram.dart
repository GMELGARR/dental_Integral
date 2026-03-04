import '../entities/odontogram.dart';
import '../repositories/odontogram_repository.dart';

class SaveOdontogram {
  SaveOdontogram(this._repo);
  final OdontogramRepository _repo;

  Future<void> call(Odontogram odontogram) => _repo.save(odontogram);
}
