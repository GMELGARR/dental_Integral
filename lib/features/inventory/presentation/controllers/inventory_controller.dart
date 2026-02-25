import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/inventory_item.dart';
import '../../domain/usecases/adjust_stock.dart';
import '../../domain/usecases/create_inventory_item.dart';
import '../../domain/usecases/observe_inventory.dart';
import '../../domain/usecases/update_inventory_item.dart';

class InventoryController extends ChangeNotifier {
  InventoryController({
    required ObserveInventory observeInventory,
    required CreateInventoryItem createInventoryItem,
    required UpdateInventoryItem updateInventoryItem,
    required AdjustStock adjustStock,
  })  : _observeInventory = observeInventory,
        _createInventoryItem = createInventoryItem,
        _updateInventoryItem = updateInventoryItem,
        _adjustStock = adjustStock {
    _subscription = _observeInventory().listen((list) {
      _items = list;
      _isLoading = false;
      notifyListeners();
    });
  }

  final ObserveInventory _observeInventory;
  final CreateInventoryItem _createInventoryItem;
  final UpdateInventoryItem _updateInventoryItem;
  final AdjustStock _adjustStock;
  StreamSubscription<List<InventoryItem>>? _subscription;

  List<InventoryItem> _items = const [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  String? _updatingId;

  List<InventoryItem> get items => _items;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String? get updatingId => _updatingId;

  /// Number of items with low stock.
  int get lowStockCount =>
      _items.where((i) => i.activo && i.stockBajo).length;

  Future<bool> create({
    required String nombre,
    required String categoria,
    required String unidad,
    required int stockActual,
    required int stockMinimo,
    required double costoUnitario,
    String? descripcion,
  }) async {
    _errorMessage = null;
    _isSaving = true;
    notifyListeners();

    try {
      await _createInventoryItem(
        nombre: nombre,
        categoria: categoria,
        unidad: unidad,
        stockActual: stockActual,
        stockMinimo: stockMinimo,
        costoUnitario: costoUnitario,
        descripcion: descripcion,
      );
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'No se pudo registrar el producto.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> update({
    required String id,
    required String nombre,
    required String categoria,
    required String unidad,
    required int stockActual,
    required int stockMinimo,
    required double costoUnitario,
    required bool activo,
    String? descripcion,
  }) async {
    _errorMessage = null;
    _updatingId = id;
    notifyListeners();

    try {
      await _updateInventoryItem(
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
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'No se pudo actualizar el producto.';
      return false;
    } finally {
      _updatingId = null;
      notifyListeners();
    }
  }

  Future<bool> adjust({
    required String id,
    required int delta,
  }) async {
    _errorMessage = null;
    _updatingId = id;
    notifyListeners();

    try {
      await _adjustStock(id: id, delta: delta);
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'No se pudo ajustar el stock.';
      return false;
    } finally {
      _updatingId = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
