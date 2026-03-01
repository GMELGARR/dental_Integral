import '../entities/clinical_record.dart';
import '../repositories/clinical_record_repository.dart';

class GetClinicalRecordByAppointment {
  GetClinicalRecordByAppointment(this._repo);
  final ClinicalRecordRepository _repo;

  Future<ClinicalRecord?> call(String citaId) =>
      _repo.getByAppointment(citaId);
}
