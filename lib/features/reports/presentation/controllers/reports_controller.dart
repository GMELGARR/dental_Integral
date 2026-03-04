import 'package:flutter/material.dart';

import '../../domain/entities/report_data.dart';
import '../../domain/usecases/generate_report.dart';

/// Predefined period choices.
enum ReportPeriod { semana, mes, trimestre, anio, personalizado }

extension ReportPeriodLabel on ReportPeriod {
  String get label {
    switch (this) {
      case ReportPeriod.semana:
        return 'Última semana';
      case ReportPeriod.mes:
        return 'Último mes';
      case ReportPeriod.trimestre:
        return 'Último trimestre';
      case ReportPeriod.anio:
        return 'Último año';
      case ReportPeriod.personalizado:
        return 'Personalizado';
    }
  }
}

class ReportsController extends ChangeNotifier {
  ReportsController(GenerateReport generateReport)
      : _generateReport = generateReport;

  final GenerateReport _generateReport;

  // ── State ──
  ReportData? _data;
  ReportData? get data => _data;

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  ReportPeriod _period = ReportPeriod.mes;
  ReportPeriod get period => _period;

  DateTimeRange? _customRange;
  DateTimeRange? get customRange => _customRange;

  // ── Actions ──

  void selectPeriod(ReportPeriod p) {
    _period = p;
    notifyListeners();
    if (p != ReportPeriod.personalizado) refresh();
  }

  void setCustomRange(DateTimeRange range) {
    _customRange = range;
    _period = ReportPeriod.personalizado;
    notifyListeners();
    refresh();
  }

  DateTimeRange get _dateRange {
    if (_period == ReportPeriod.personalizado && _customRange != null) {
      return _customRange!;
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 23, 59, 59);
    switch (_period) {
      case ReportPeriod.semana:
        return DateTimeRange(
          start: today.subtract(const Duration(days: 7)),
          end: today,
        );
      case ReportPeriod.mes:
        return DateTimeRange(
          start: DateTime(now.year, now.month - 1, now.day),
          end: today,
        );
      case ReportPeriod.trimestre:
        return DateTimeRange(
          start: DateTime(now.year, now.month - 3, now.day),
          end: today,
        );
      case ReportPeriod.anio:
        return DateTimeRange(
          start: DateTime(now.year - 1, now.month, now.day),
          end: today,
        );
      case ReportPeriod.personalizado:
        return DateTimeRange(
          start: today.subtract(const Duration(days: 30)),
          end: today,
        );
    }
  }

  Future<void> refresh() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final range = _dateRange;
      _data = await _generateReport(from: range.start, to: range.end);
    } catch (e) {
      _error = 'Error generando reporte: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
