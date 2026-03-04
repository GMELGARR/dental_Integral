import '../entities/report_data.dart';

/// Contract for the reports repository.
abstract class ReportsRepository {
  /// Generate aggregated report data for the given date range.
  Future<ReportData> generate({
    required DateTime from,
    required DateTime to,
  });
}
