import '../entities/clinical_record.dart';
import '../repositories/clinical_record_repository.dart';

class ObserveClinicalRecordsByPatient {
  ObserveClinicalRecordsByPatient(this._repo);
  final ClinicalRecordRepository _repo;

  Stream<List<ClinicalRecord>> call(String pacienteId) =>
      _repo.observeByPatient(pacienteId);
}
