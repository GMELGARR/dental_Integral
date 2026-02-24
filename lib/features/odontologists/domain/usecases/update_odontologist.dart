import '../entities/specialty.dart';
import '../repositories/odontologist_repository.dart';

class UpdateOdontologist {
  UpdateOdontologist(this._repository);

  final OdontologistRepository _repository;

  Future<void> call({
    required String id,
    required String nombre,
    required Specialty especialidad,
    required String colegiadoActivo,
    required String telefono,
    required String email,
    required bool activo,
    String? notas,
  }) {
    return _repository.update(
      id: id,
      nombre: nombre,
      especialidad: especialidad,
      colegiadoActivo: colegiadoActivo,
      telefono: telefono,
      email: email,
      activo: activo,
      notas: notas,
    );
  }
}
