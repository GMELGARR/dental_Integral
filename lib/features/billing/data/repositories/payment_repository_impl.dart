import '../../domain/entities/payment.dart';
import '../../domain/repositories/payment_repository.dart';
import '../datasources/payment_firestore_data_source.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  PaymentRepositoryImpl(this._dataSource);

  final PaymentFirestoreDataSource _dataSource;

  @override
  Stream<List<Payment>> observeAll() => _dataSource.observeAll();

  @override
  Stream<List<Payment>> observeByPatient(String pacienteId) =>
      _dataSource.observeByPatient(pacienteId);

  @override
  Future<String> create(Payment payment) => _dataSource.create(payment);

  @override
  Future<void> delete(String id) => _dataSource.delete(id);
}
