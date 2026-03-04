import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../domain/entities/payment.dart';
import '../../domain/usecases/create_payment.dart';
import '../../domain/usecases/delete_payment.dart';
import '../../domain/usecases/observe_all_payments.dart';
import '../../domain/usecases/observe_payments_by_patient.dart';

class BillingController extends ChangeNotifier {
  BillingController({
    required ObserveAllPayments observeAll,
    required ObservePaymentsByPatient observeByPatient,
    required CreatePayment createPayment,
    required DeletePayment deletePayment,
  })  : _observeAll = observeAll,
        _observeByPatient = observeByPatient,
        _createPayment = createPayment,
        _deletePayment = deletePayment;

  final ObserveAllPayments _observeAll;
  final ObservePaymentsByPatient _observeByPatient;
  final CreatePayment _createPayment;
  final DeletePayment _deletePayment;

  // ── State ──────────────────────────────────────────────────────
  List<Payment> _payments = [];
  List<Payment> get payments => _payments;

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  StreamSubscription<List<Payment>>? _sub;

  // ── Observe all ────────────────────────────────────────────────
  void startObservingAll() {
    _sub?.cancel();
    _loading = true;
    _error = null;
    notifyListeners();

    _sub = _observeAll().listen(
      (list) {
        _payments = list;
        _loading = false;
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        _loading = false;
        notifyListeners();
      },
    );
  }

  // ── Observe by patient ─────────────────────────────────────────
  void startObservingByPatient(String pacienteId) {
    _sub?.cancel();
    _loading = true;
    _error = null;
    notifyListeners();

    _sub = _observeByPatient(pacienteId).listen(
      (list) {
        _payments = list;
        _loading = false;
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        _loading = false;
        notifyListeners();
      },
    );
  }

  // ── Create ─────────────────────────────────────────────────────
  Future<bool> addPayment({
    required String pacienteId,
    required String pacienteNombre,
    required double monto,
    required String metodoPago,
    String? registroClinicoId,
    String? recibidoPor,
    String? notas,
  }) async {
    try {
      await _createPayment(Payment(
        id: '',
        pacienteId: pacienteId,
        pacienteNombre: pacienteNombre,
        monto: monto,
        metodoPago: metodoPago,
        fecha: DateTime.now(),
        registroClinicoId: registroClinicoId,
        recibidoPor: recibidoPor,
        notas: notas,
      ));
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ── Delete ─────────────────────────────────────────────────────
  Future<bool> removePayment(String id) async {
    try {
      await _deletePayment(id);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ── Helpers ────────────────────────────────────────────────────
  double get totalCobrado =>
      _payments.fold(0.0, (sum, p) => sum + p.monto);

  /// Sum of payments for a specific patient from the current list.
  double totalByPatient(String pacienteId) =>
      _payments
          .where((p) => p.pacienteId == pacienteId)
          .fold(0.0, (sum, p) => sum + p.monto);

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
