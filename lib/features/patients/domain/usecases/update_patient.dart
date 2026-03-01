import '../repositories/patient_repository.dart';

class UpdatePatient {
  UpdatePatient(this._repository);
  final PatientRepository _repository;

  Future<void> call({
    required String id,
    required String nombre,
    required String dpi,
    required DateTime? fechaNacimiento,
    required String genero,
    required String telefono,
    required bool activo,
    String? telefonoEmergencia,
    String? contactoEmergencia,
    String? direccion,
    String? email,
    String? alergias,
    String? enfermedadesSistemicas,
    String? medicamentosActuales,
    String? notasClinicas,
  }) {
    return _repository.update(
      id: id,
      nombre: nombre,
      dpi: dpi,
      fechaNacimiento: fechaNacimiento,
      genero: genero,
      telefono: telefono,
      activo: activo,
      telefonoEmergencia: telefonoEmergencia,
      contactoEmergencia: contactoEmergencia,
      direccion: direccion,
      email: email,
      alergias: alergias,
      enfermedadesSistemicas: enfermedadesSistemicas,
      medicamentosActuales: medicamentosActuales,
      notasClinicas: notasClinicas,
    );
  }
}
