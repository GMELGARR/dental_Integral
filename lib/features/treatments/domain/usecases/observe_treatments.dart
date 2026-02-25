import '../repositories/treatment_repository.dart';
import '../entities/treatment.dart';

class ObserveTreatments {
  ObserveTreatments(this._repository);

  final TreatmentRepository _repository;

  Stream<List<Treatment>> call() => _repository.observeAll();
}
