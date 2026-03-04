import '../entities/report_data.dart';
import '../repositories/reports_repository.dart';

class GenerateReport {
  GenerateReport(this._repository);

  final ReportsRepository _repository;

  Future<ReportData> call({
    required DateTime from,
    required DateTime to,
  }) {
    return _repository.generate(from: from, to: to);
  }
}
