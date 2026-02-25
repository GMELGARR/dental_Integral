import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/treatment.dart';

class TreatmentFirestoreDataSource {
  TreatmentFirestoreDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('tratamientos');

  Stream<List<Treatment>> observeAll() {
    return _col.orderBy('nombre').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final d = doc.data();
        return Treatment(
          id: doc.id,
          nombre: (d['nombre'] as String?) ?? '',
          monto: (d['monto'] as num?)?.toDouble() ?? 0,
          activo: (d['activo'] as bool?) ?? true,
          descripcion: d['descripcion'] as String?,
        );
      }).toList(growable: false);
    });
  }

  Future<void> create({
    required String nombre,
    required double monto,
    String? descripcion,
  }) async {
    try {
      await _col.add({
        'nombre': nombre,
        'monto': monto,
        'activo': true,
        'descripcion': descripcion ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      throw AppException(
        'No se pudo registrar el tratamiento.',
        cause: error,
      );
    }
  }

  Future<void> update({
    required String id,
    required String nombre,
    required double monto,
    required bool activo,
    String? descripcion,
  }) async {
    try {
      await _col.doc(id).update({
        'nombre': nombre,
        'monto': monto,
        'activo': activo,
        'descripcion': descripcion ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      throw AppException(
        'No se pudo actualizar el tratamiento.',
        cause: error,
      );
    }
  }
}
