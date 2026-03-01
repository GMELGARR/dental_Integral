import '../../domain/entities/patient.dart';
import '../../domain/repositories/patient_repository.dart';
import '../datasources/patient_firestore_data_source.dart';

class PatientRepositoryImpl implements PatientRepository {
  PatientRepositoryImpl(this._dataSource);
  final PatientFirestoreDataSource _dataSource;

  @override
  Stream<List<Patient>> observeAll() => _dataSource.observeAll();

  @override
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
  }) {
    return _dataSource.create(
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

  @override
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
  }) {
    return _dataSource.update(
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
