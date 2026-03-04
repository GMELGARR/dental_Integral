import '../entities/payment.dart';
import '../repositories/payment_repository.dart';

class CreatePayment {
  CreatePayment(this._repo);
  final PaymentRepository _repo;

  Future<String> call(Payment payment) => _repo.create(payment);
}
