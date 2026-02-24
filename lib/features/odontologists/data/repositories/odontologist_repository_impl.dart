import '../../domain/entities/odontologist.dart';
import '../../domain/entities/specialty.dart';
import '../../domain/repositories/odontologist_repository.dart';
import '../datasources/odontologist_firestore_data_source.dart';

class OdontologistRepositoryImpl implements OdontologistRepository {
  OdontologistRepositoryImpl(this._dataSource);

  final OdontologistFirestoreDataSource _dataSource;

  @override
  Stream<List<Odontologist>> observeAll() {
    return _dataSource.observeAll();
  }

  @override
  Future<void> create({
    required String nombre,
    required Specialty especialidad,
    required String colegiadoActivo,
    required String telefono,
    required String email,
    String? notas,
  }) {
    return _dataSource.create(
      nombre: nombre,
      especialidad: especialidad,
      colegiadoActivo: colegiadoActivo,
      telefono: telefono,
      email: email,
      notas: notas,
    );
  }

  @override
  Future<void> update({
    required String id,
    required String nombre,
    required Specialty especialidad,
    required String colegiadoActivo,
    required String telefono,
    required String email,
    required bool activo,
    String? notas,
  }) {
    return _dataSource.update(
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

  @override
  Future<void> linkUser({
    required String odontologistId,
    required String? userId,
  }) {
    return _dataSource.linkUser(
      odontologistId: odontologistId,
      userId: userId,
    );
  }
}
