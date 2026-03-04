import '../entities/payment.dart';
import '../repositories/payment_repository.dart';

class ObserveAllPayments {
  ObserveAllPayments(this._repo);
  final PaymentRepository _repo;

  Stream<List<Payment>> call() => _repo.observeAll();
}
