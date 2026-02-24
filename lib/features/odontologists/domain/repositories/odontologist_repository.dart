import '../entities/odontologist.dart';
import '../entities/specialty.dart';

abstract class OdontologistRepository {
  Stream<List<Odontologist>> observeAll();

  Future<void> create({
    required String nombre,
    required Specialty especialidad,
    required String colegiadoActivo,
    required String telefono,
    required String email,
    String? notas,
  });

  Future<void> update({
    required String id,
    required String nombre,
    required Specialty especialidad,
    required String colegiadoActivo,
    required String telefono,
    required String email,
    required bool activo,
    String? notas,
  });

  Future<void> linkUser({
    required String odontologistId,
    required String? userId,
  });
}
