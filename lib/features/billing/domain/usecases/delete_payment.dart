import '../repositories/payment_repository.dart';

class DeletePayment {
  DeletePayment(this._repo);
  final PaymentRepository _repo;

  Future<void> call(String id) => _repo.delete(id);
}
