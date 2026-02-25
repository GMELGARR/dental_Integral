import '../entities/inventory_item.dart';

abstract class InventoryRepository {
  Stream<List<InventoryItem>> observeAll();

  Future<void> create({
    required String nombre,
    required String categoria,
    required String unidad,
    required int stockActual,
    required int stockMinimo,
    required double costoUnitario,
    String? descripcion,
  });

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
  });

  /// Atomically increment (positive) or decrement (negative) the stock.
  Future<void> adjustStock({
    required String id,
    required int delta,
  });
}
