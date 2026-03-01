import '../entities/patient.dart';

abstract class PatientRepository {
  Stream<List<Patient>> observeAll();

  Future<void> create({
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
  });

  Future<void> update({
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
  });
}
