import '../repositories/inventory_repository.dart';

class UpdateInventoryItem {
  UpdateInventoryItem(this._repository);
  final InventoryRepository _repository;

  Future<void> call({
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
    return _repository.update(
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
}
