import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/patient.dart';

class PatientFirestoreDataSource {
  PatientFirestoreDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('pacientes');

  Stream<List<Patient>> observeAll() {
    return _col.orderBy('nombre').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Patient.fromFirestore(doc.id, doc.data());
      }).toList(growable: false);
    });
  }

  Future<void> create({
    required String nombre,
    required String dpi,
    required DateTime? fechaNacimiento,
    required String genero,
    required String telefono,
    String? telefonoEmergencia,
    String? contactoEmergencia,
    String? direccion,
    String? email,
    String? alergias,
    String? enfermedadesSistemicas,
    String? medicamentosActuales,
    String? notasClinicas,
  }) async {
    try {
      await _col.add({
        'nombre': nombre,
        'dpi': dpi,
        'fechaNacimiento': fechaNacimiento != null
            ? Timestamp.fromDate(fechaNacimiento)
            : null,
        'genero': genero,
        'telefono': telefono,
        'activo': true,
        'telefonoEmergencia': telefonoEmergencia ?? '',
        'contactoEmergencia': contactoEmergencia ?? '',
        'direccion': direccion ?? '',
        'email': email ?? '',
        'alergias': alergias ?? '',
        'enfermedadesSistemicas': enfermedadesSistemicas ?? '',
        'medicamentosActuales': medicamentosActuales ?? '',
        'notasClinicas': notasClinicas ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      throw AppException(
        'No se pudo registrar al paciente.',
        cause: error,
      );
    }
  }

  Future<void> update({
    required String id,
    required String nombre,
    required String dpi,
    required DateTime? fechaNacimiento,
    required String genero,
    required String telefono,
    required bool activo,
    String? telefonoEmergencia,
    String? contactoEmergencia,
    String? direccion,
    String? email,
    String? alergias,
    String? enfermedadesSistemicas,
    String? medicamentosActuales,
    String? notasClinicas,
  }) async {
    try {
      await _col.doc(id).update({
        'nombre': nombre,
        'dpi': dpi,
        'fechaNacimiento': fechaNacimiento != null
            ? Timestamp.fromDate(fechaNacimiento)
            : null,
        'genero': genero,
        'telefono': telefono,
        'activo': activo,
        'telefonoEmergencia': telefonoEmergencia ?? '',
        'contactoEmergencia': contactoEmergencia ?? '',
        'direccion': direccion ?? '',
        'email': email ?? '',
        'alergias': alergias ?? '',
        'enfermedadesSistemicas': enfermedadesSistemicas ?? '',
        'medicamentosActuales': medicamentosActuales ?? '',
        'notasClinicas': notasClinicas ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      throw AppException(
        'No se pudo actualizar al paciente.',
        cause: error,
      );
    }
  }
}
