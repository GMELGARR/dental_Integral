import '../entities/inventory_item.dart';
import '../repositories/inventory_repository.dart';

class ObserveInventory {
  ObserveInventory(this._repository);
  final InventoryRepository _repository;

  Stream<List<InventoryItem>> call() => _repository.observeAll();
}
