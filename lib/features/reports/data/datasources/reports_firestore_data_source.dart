import 'package:cloud_firestore/cloud_firestore.dart';

/// Aggregation data source that reads from multiple collections
/// (pagos, citas, registros_clinicos) to produce report data.
class ReportsFirestoreDataSource {
  ReportsFirestoreDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  // ── Payments (Ingresos) ──────────────────────────────────────

  /// Fetch all payments within [from] – [to] date range.
  Future<List<Map<String, dynamic>>> getPayments({
    required DateTime from,
    required DateTime to,
  }) async {
    final snap = await _firestore
        .collection('pagos')
        .where('fecha', isGreaterThanOrEqualTo: from)
        .where('fecha', isLessThanOrEqualTo: to)
        .orderBy('fecha')
        .get();
    return snap.docs
        .map((d) => {'id': d.id, ...d.data()})
        .toList();
  }

  // ── Appointments (Citas) ─────────────────────────────────────

  /// Fetch all appointments within [from] – [to] date range.
  Future<List<Map<String, dynamic>>> getAppointments({
    required DateTime from,
    required DateTime to,
  }) async {
    final snap = await _firestore
        .collection('citas')
        .where('fecha', isGreaterThanOrEqualTo: from)
        .where('fecha', isLessThanOrEqualTo: to)
        .orderBy('fecha')
        .get();
    return snap.docs
        .map((d) => {'id': d.id, ...d.data()})
        .toList();
  }

  // ── Clinical records ─────────────────────────────────────────

  /// Fetch all clinical records within [from] – [to] date range.
  Future<List<Map<String, dynamic>>> getClinicalRecords({
    required DateTime from,
    required DateTime to,
  }) async {
    final snap = await _firestore
        .collection('registros_clinicos')
        .where('fecha', isGreaterThanOrEqualTo: from)
        .where('fecha', isLessThanOrEqualTo: to)
        .orderBy('fecha')
        .get();
    return snap.docs
        .map((d) => {'id': d.id, ...d.data()})
        .toList();
  }

  // ── Patients count ───────────────────────────────────────────

  Future<int> getTotalPatients() async {
    final snap = await _firestore.collection('pacientes').count().get();
    return snap.count ?? 0;
  }
}
