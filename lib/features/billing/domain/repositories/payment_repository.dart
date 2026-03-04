import '../../domain/entities/payment.dart';

/// Abstract repository for payments.
abstract class PaymentRepository {
  Stream<List<Payment>> observeAll();
  Stream<List<Payment>> observeByPatient(String pacienteId);
  Future<String> create(Payment payment);
  Future<void> delete(String id);
}
