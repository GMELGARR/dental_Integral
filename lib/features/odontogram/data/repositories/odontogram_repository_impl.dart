import '../../domain/entities/odontogram.dart';
import '../../domain/repositories/odontogram_repository.dart';
import '../datasources/odontogram_firestore_data_source.dart';

class OdontogramRepositoryImpl implements OdontogramRepository {
  OdontogramRepositoryImpl(this._dataSource);
  final OdontogramFirestoreDataSource _dataSource;

  @override
  Future<Odontogram> get(String pacienteId) => _dataSource.get(pacienteId);

  @override
  Stream<Odontogram> observe(String pacienteId) =>
      _dataSource.observe(pacienteId);

  @override
  Future<void> save(Odontogram odontogram) => _dataSource.save(odontogram);
}
