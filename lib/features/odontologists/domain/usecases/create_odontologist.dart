import '../entities/specialty.dart';
import '../repositories/odontologist_repository.dart';

class CreateOdontologist {
  CreateOdontologist(this._repository);

  final OdontologistRepository _repository;

  Future<void> call({
    required String nombre,
    required Specialty especialidad,
    required String colegiadoActivo,
    required String telefono,
    required String email,
    String? notas,
  }) {
    return _repository.create(
      nombre: nombre,
      especialidad: especialidad,
      colegiadoActivo: colegiadoActivo,
      telefono: telefono,
      email: email,
      notas: notas,
    );
  }
}
