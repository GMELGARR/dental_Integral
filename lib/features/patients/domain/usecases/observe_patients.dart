import '../entities/patient.dart';
import '../repositories/patient_repository.dart';

class ObservePatients {
  ObservePatients(this._repository);
  final PatientRepository _repository;

  Stream<List<Patient>> call() => _repository.observeAll();
}
