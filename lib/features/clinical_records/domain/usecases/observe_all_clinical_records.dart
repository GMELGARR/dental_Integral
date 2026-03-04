import '../entities/clinical_record.dart';
import '../repositories/clinical_record_repository.dart';

class ObserveAllClinicalRecords {
  ObserveAllClinicalRecords(this._repo);
  final ClinicalRecordRepository _repo;

  Stream<List<ClinicalRecord>> call() => _repo.observeAll();
}
