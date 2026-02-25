import '../../domain/entities/inventory_item.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../datasources/inventory_firestore_data_source.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  InventoryRepositoryImpl(this._dataSource);
  final InventoryFirestoreDataSource _dataSource;

  @override
  Stream<List<InventoryItem>> observeAll() => _dataSource.observeAll();

  @override
  Future<void> create({
    required String nombre,
    required String categoria,
    required String unidad,
    required int stockActual,
    required int stockMinimo,
    required double costoUnitario,
    String? descripcion,
  }) {
    return _dataSource.create(
      nombre: nombre,
      categoria: categoria,
      unidad: unidad,
      stockActual: stockActual,
      stockMinimo: stockMinimo,
      costoUnitario: costoUnitario,
      descripcion: descripcion,
    );
  }

  @override
  Future<void> update({
    required String id,
    required String nombre,
    required String categoria,
    required String unidad,
    required int stockActual,
    required int stockMinimo,
    required double costoUnitario,
    required bool activo,
    String? descripcion,
  }) {
    return _dataSource.update(
      id: id,
      nombre: nombre,
      categoria: categoria,
      unidad: unidad,
      stockActual: stockActual,
      stockMinimo: stockMinimo,
      costoUnitario: costoUnitario,
      activo: activo,
      descripcion: descripcion,
    );
  }

  @override
  Future<void> adjustStock({
    required String id,
    required int delta,
  }) {
    return _dataSource.adjustStock(id: id, delta: delta);
  }
}
