import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/inventory_item.dart';

class InventoryFirestoreDataSource {
  InventoryFirestoreDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('inventario');

  Stream<List<InventoryItem>> observeAll() {
    return _col.orderBy('nombre').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final d = doc.data();
        return InventoryItem(
          id: doc.id,
          nombre: (d['nombre'] as String?) ?? '',
          categoria: (d['categoria'] as String?) ?? '',
          unidad: (d['unidad'] as String?) ?? 'unidades',
          stockActual: (d['stockActual'] as num?)?.toInt() ?? 0,
          stockMinimo: (d['stockMinimo'] as num?)?.toInt() ?? 0,
          costoUnitario: (d['costoUnitario'] as num?)?.toDouble() ?? 0,
          activo: (d['activo'] as bool?) ?? true,
          descripcion: d['descripcion'] as String?,
        );
      }).toList(growable: false);
    });
  }

  Future<void> create({
    required String nombre,
    required String categoria,
    required String unidad,
    required int stockActual,
    required int stockMinimo,
    required double costoUnitario,
    String? descripcion,
  }) async {
    try {
      await _col.add({
        'nombre': nombre,
        'categoria': categoria,
        'unidad': unidad,
        'stockActual': stockActual,
        'stockMinimo': stockMinimo,
        'costoUnitario': costoUnitario,
        'activo': true,
        'descripcion': descripcion ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      throw AppException(
        'No se pudo registrar el producto.',
        cause: error,
      );
    }
  }

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
  }) async {
    try {
      await _col.doc(id).update({
        'nombre': nombre,
        'categoria': categoria,
        'unidad': unidad,
        'stockActual': stockActual,
        'stockMinimo': stockMinimo,
        'costoUnitario': costoUnitario,
        'activo': activo,
        'descripcion': descripcion ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      throw AppException(
        'No se pudo actualizar el producto.',
        cause: error,
      );
    }
  }

  Future<void> adjustStock({
    required String id,
    required int delta,
  }) async {
    try {
      await _col.doc(id).update({
        'stockActual': FieldValue.increment(delta),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      throw AppException(
        'No se pudo ajustar el stock.',
        cause: error,
      );
    }
  }
}
