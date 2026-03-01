import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/clinical_record.dart';
import '../../domain/entities/tratamiento_realizado.dart';

class ClinicalRecordFirestoreDataSource {
  ClinicalRecordFirestoreDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('registros_clinicos');

  /// Real-time stream of records for a patient, newest first.
  Stream<List<ClinicalRecord>> observeByPatient(String pacienteId) {
    return _col
        .where('pacienteId', isEqualTo: pacienteId)
        .orderBy('fecha', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ClinicalRecord.fromFirestore(d.id, d.data()))
            .toList());
  }

  /// One-shot fetch by citaId.
  Future<ClinicalRecord?> getByAppointment(String citaId) async {
    final snap =
        await _col.where('citaId', isEqualTo: citaId).limit(1).get();
    if (snap.docs.isEmpty) return null;
    final d = snap.docs.first;
    return ClinicalRecord.fromFirestore(d.id, d.data());
  }

  Future<void> create({
    required String citaId,
    required String pacienteId,
    required String pacienteNombre,
    required String odontologoId,
    required String odontologoNombre,
    required DateTime fecha,
    required List<TratamientoRealizado> tratamientos,
    required double subtotal,
    required double descuentoMonto,
    required double cargoExtra,
    required double costoTotal,
    String? diagnostico,
    String? piezasDentales,
    String? notasClinicas,
    String? indicaciones,
    String? proximaCitaSugerida,
    String? notaCargoExtra,
  }) async {
    try {
      await _col.add({
        'citaId': citaId,
        'pacienteId': pacienteId,
        'pacienteNombre': pacienteNombre,
        'odontologoId': odontologoId,
        'odontologoNombre': odontologoNombre,
        'fecha': Timestamp.fromDate(
            DateTime(fecha.year, fecha.month, fecha.day)),
        'diagnostico': diagnostico,
        'piezasDentales': piezasDentales,
        'notasClinicas': notasClinicas,
        'indicaciones': indicaciones,
        'proximaCitaSugerida': proximaCitaSugerida,
        'tratamientos': tratamientos.map((t) => t.toMap()).toList(),
        'subtotal': subtotal,
        'descuentoMonto': descuentoMonto,
        'cargoExtra': cargoExtra,
        'notaCargoExtra': notaCargoExtra,
        'costoTotal': costoTotal,
        'creadoEn': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      throw AppException(
        'No se pudo crear el registro clínico.',
        cause: error,
      );
    }
  }
}
