import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/payment.dart';

/// Firestore data source for the `pagos` collection.
class PaymentFirestoreDataSource {
  PaymentFirestoreDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('pagos');

  /// Stream of all payments (newest first, sorted locally).
  Stream<List<Payment>> observeAll() {
    return _col.snapshots().map((snap) {
      final list = snap.docs
          .map((d) => Payment.fromFirestore(d.id, d.data()))
          .toList()
        ..sort((a, b) => b.fecha.compareTo(a.fecha));
      return list;
    });
  }

  /// Stream of payments for a specific patient.
  Stream<List<Payment>> observeByPatient(String pacienteId) {
    return _col
        .where('pacienteId', isEqualTo: pacienteId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => Payment.fromFirestore(d.id, d.data()))
          .toList()
        ..sort((a, b) => b.fecha.compareTo(a.fecha));
      return list;
    });
  }

  /// Create a new payment document.
  Future<String> create(Payment payment) async {
    final doc = await _col.add(payment.toMap());
    return doc.id;
  }

  /// Delete a payment.
  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }
}
