import '../entities/odontogram.dart';

/// Abstract repository for odontogram operations.
abstract class OdontogramRepository {
  Future<Odontogram> get(String pacienteId);
  Stream<Odontogram> observe(String pacienteId);
  Future<void> save(Odontogram odontogram);
}
