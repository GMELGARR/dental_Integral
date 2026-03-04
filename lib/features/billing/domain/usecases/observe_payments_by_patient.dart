import '../entities/payment.dart';
import '../repositories/payment_repository.dart';

class ObservePaymentsByPatient {
  ObservePaymentsByPatient(this._repo);
  final PaymentRepository _repo;

  Stream<List<Payment>> call(String pacienteId) =>
      _repo.observeByPatient(pacienteId);
}
