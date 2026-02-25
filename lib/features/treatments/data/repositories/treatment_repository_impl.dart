import '../../domain/entities/treatment.dart';
import '../../domain/repositories/treatment_repository.dart';
import '../datasources/treatment_firestore_data_source.dart';

class TreatmentRepositoryImpl implements TreatmentRepository {
  TreatmentRepositoryImpl(this._dataSource);

  final TreatmentFirestoreDataSource _dataSource;

  @override
  Stream<List<Treatment>> observeAll() {
    return _dataSource.observeAll();
  }

  @override
  Future<void> create({
    required String nombre,
    required double monto,
    String? descripcion,
  }) {
    return _dataSource.create(
      nombre: nombre,
      monto: monto,
      descripcion: descripcion,
    );
  }

  @override
  Future<void> update({
    required String id,
    required String nombre,
    required double monto,
    required bool activo,
    String? descripcion,
  }) {
    return _dataSource.update(
      id: id,
      nombre: nombre,
      monto: monto,
      activo: activo,
      descripcion: descripcion,
    );
  }
}
