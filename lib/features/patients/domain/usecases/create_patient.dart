import '../repositories/patient_repository.dart';

class CreatePatient {
  CreatePatient(this._repository);
  final PatientRepository _repository;

  Future<void> call({
    required String nombre,
    required String dpi,
    required DateTime? fechaNacimiento,
    required String genero,
    required String telefono,
    String? telefonoEmergencia,
    String? contactoEmergencia,
    String? direccion,
    String? email,
    String? alergias,
    String? enfermedadesSistemicas,
    String? medicamentosActuales,
    String? notasClinicas,
  }) {
    return _repository.create(
      nombre: nombre,
      dpi: dpi,
      fechaNacimiento: fechaNacimiento,
      genero: genero,
      telefono: telefono,
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
