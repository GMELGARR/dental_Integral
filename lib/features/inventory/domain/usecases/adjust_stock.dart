import '../repositories/inventory_repository.dart';

class AdjustStock {
  AdjustStock(this._repository);
  final InventoryRepository _repository;

  /// [delta] positive → entrada, negative → salida.
  Future<void> call({
    required String id,
    required int delta,
  }) {
    return _repository.adjustStock(id: id, delta: delta);
  }
}
