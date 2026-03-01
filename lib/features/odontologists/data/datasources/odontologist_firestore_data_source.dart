import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/odontologist.dart';
import '../../domain/entities/specialty.dart';

class OdontologistFirestoreDataSource {
  OdontologistFirestoreDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('odontologos');

  Stream<List<Odontologist>> observeAll() {
    return _col.orderBy('nombre').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final d = doc.data();
        return Odontologist(
          id: doc.id,
          nombre: (d['nombre'] as String?) ?? '',
          especialidad:
              specialtyFromKey((d['especialidad'] as String?) ?? '') ??
                  Specialty.general,
          colegiadoActivo: (d['colegiadoActivo'] as String?) ?? '',
          telefono: (d['telefono'] as String?) ?? '',
          email: (d['email'] as String?) ?? '',
          activo: (d['activo'] as bool?) ?? true,
          userId: d['userId'] as String?,
          notas: d['notas'] as String?,
          horaInicio: (d['horaInicio'] as String?) ?? '08:00',
          horaFin: (d['horaFin'] as String?) ?? '17:00',
        );
      }).toList(growable: false);
    });
  }

  Future<void> create({
    required String nombre,
    required Specialty especialidad,
    required String colegiadoActivo,
    required String telefono,
    required String email,
    String? notas,
    String horaInicio = '08:00',
    String horaFin = '17:00',
  }) async {
    try {
      await _col.add({
        'nombre': nombre,
        'especialidad': especialidad.key,
        'colegiadoActivo': colegiadoActivo,
        'telefono': telefono,
        'email': email,
        'activo': true,
        'userId': null,
        'notas': notas ?? '',
        'horaInicio': horaInicio,
        'horaFin': horaFin,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      throw AppException(
        'No se pudo registrar al odontólogo.',
        cause: error,
      );
    }
  }

  Future<void> update({
    required String id,
    required String nombre,
    required Specialty especialidad,
    required String colegiadoActivo,
    required String telefono,
    required String email,
    required bool activo,
    String? notas,
    String? horaInicio,
    String? horaFin,
  }) async {
    try {
      final data = <String, dynamic>{
        'nombre': nombre,
        'especialidad': especialidad.key,
        'colegiadoActivo': colegiadoActivo,
        'telefono': telefono,
        'email': email,
        'activo': activo,
        'notas': notas ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (horaInicio != null) data['horaInicio'] = horaInicio;
      if (horaFin != null) data['horaFin'] = horaFin;
      await _col.doc(id).update(data);
    } catch (error) {
      throw AppException(
        'No se pudo actualizar al odontólogo.',
        cause: error,
      );
    }
  }

  Future<void> linkUser({
    required String odontologistId,
    required String? userId,
  }) async {
    try {
      await _col.doc(odontologistId).update({
        'userId': userId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      throw AppException(
        'No se pudo vincular el usuario.',
        cause: error,
      );
    }
  }
}
