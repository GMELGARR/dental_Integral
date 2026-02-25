import '../repositories/inventory_repository.dart';

class CreateInventoryItem {
  CreateInventoryItem(this._repository);
  final InventoryRepository _repository;

  Future<void> call({
    required String nombre,
    required String categoria,
    required String unidad,
    required int stockActual,
    required int stockMinimo,
    required double costoUnitario,
    String? descripcion,
  }) {
    return _repository.create(
      nombre: nombre,
      categoria: categoria,
      unidad: unidad,
      stockActual: stockActual,
      stockMinimo: stockMinimo,
      costoUnitario: costoUnitario,
      descripcion: descripcion,
    );
  }
}
