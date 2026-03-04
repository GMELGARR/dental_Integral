import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/odontogram.dart';

/// Firestore data source for odontograms.
/// Collection: `odontogramas` — one document per patient (doc id = pacienteId).
class OdontogramFirestoreDataSource {
  OdontogramFirestoreDataSource({FirebaseFirestore? firestore})
      : _fs = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _fs;

  CollectionReference<Map<String, dynamic>> get _col =>
      _fs.collection('odontogramas');

  /// Get the odontogram for a patient (returns empty if none exists).
  Future<Odontogram> get(String pacienteId) async {
    final doc = await _col.doc(pacienteId).get();
    if (!doc.exists || doc.data() == null) {
      return Odontogram(pacienteId: pacienteId);
    }
    return Odontogram.fromFirestore(pacienteId, doc.data()!);
  }

  /// Stream the odontogram for a patient.
  Stream<Odontogram> observe(String pacienteId) {
    return _col.doc(pacienteId).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) {
        return Odontogram(pacienteId: pacienteId);
      }
      return Odontogram.fromFirestore(pacienteId, snap.data()!);
    });
  }

  /// Save the full odontogram (merge).
  Future<void> save(Odontogram odontogram) async {
    await _col
        .doc(odontogram.pacienteId)
        .set(odontogram.toMap(), SetOptions(merge: true));
  }
}
