import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/report_data.dart';
import '../../domain/repositories/reports_repository.dart';
import '../datasources/reports_firestore_data_source.dart';

class ReportsRepositoryImpl implements ReportsRepository {
  ReportsRepositoryImpl(this._dataSource);

  final ReportsFirestoreDataSource _dataSource;

  static final _dayFmt = DateFormat('yyyy-MM-dd');

  @override
  Future<ReportData> generate({
    required DateTime from,
    required DateTime to,
  }) async {
    // Fetch data in parallel
    final results = await Future.wait([
      _dataSource.getPayments(from: from, to: to),
      _dataSource.getAppointments(from: from, to: to),
      _dataSource.getClinicalRecords(from: from, to: to),
      _dataSource.getTotalPatients(),
    ]);

    final payments = results[0] as List<Map<String, dynamic>>;
    final appointments = results[1] as List<Map<String, dynamic>>;
    final records = results[2] as List<Map<String, dynamic>>;
    final totalPatients = results[3] as int;

    // ── Ingresos ────────────────────────────────

    double totalIngresos = 0;
    final ingresosPorDia = <String, double>{};
    final ingresosPorMetodo = <String, double>{};

    for (final p in payments) {
      final monto = (p['monto'] as num?)?.toDouble() ?? 0;
      totalIngresos += monto;

      final fecha = (p['fecha'] as Timestamp).toDate();
      final key = _dayFmt.format(fecha);
      ingresosPorDia[key] = (ingresosPorDia[key] ?? 0) + monto;

      final metodo = (p['metodoPago'] as String?) ?? 'efectivo';
      ingresosPorMetodo[metodo] = (ingresosPorMetodo[metodo] ?? 0) + monto;
    }

    // ── Citas ───────────────────────────────────

    final citasPorEstado = <String, int>{};
    final citasPorDia = <String, int>{};

    for (final a in appointments) {
      final estado = (a['estado'] as String?) ?? 'programada';
      citasPorEstado[estado] = (citasPorEstado[estado] ?? 0) + 1;

      final fecha = (a['fecha'] as Timestamp).toDate();
      final key = _dayFmt.format(fecha);
      citasPorDia[key] = (citasPorDia[key] ?? 0) + 1;
    }

    // ── Tratamientos frecuentes ─────────────────

    final tratamientosFrecuentes = <String, int>{};
    for (final r in records) {
      final tratamientos = r['tratamientos'] as List<dynamic>? ?? [];
      for (final t in tratamientos) {
        final nombre = (t as Map<String, dynamic>)['nombre'] as String? ?? '?';
        final cantidad = (t['cantidad'] as num?)?.toInt() ?? 1;
        tratamientosFrecuentes[nombre] =
            (tratamientosFrecuentes[nombre] ?? 0) + cantidad;
      }
    }

    // Sort descending
    final sortedTratamientos = Map.fromEntries(
      tratamientosFrecuentes.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value)),
    );

    // ── Productividad por odontólogo ────────────

    final prod = <String, OdontologistStats>{};

    for (final r in records) {
      final name = (r['odontologoNombre'] as String?) ?? '?';
      final prev = prod[name] ?? const OdontologistStats();
      final costoTotal = (r['costoTotal'] as num?)?.toDouble() ?? 0;
      prod[name] = prev.copyWith(
        citas: prev.citas + 1,
        ingresos: prev.ingresos + costoTotal,
      );
    }

    // Sort by ingresos descending
    final sortedProd = Map.fromEntries(
      prod.entries.toList()
        ..sort((a, b) => b.value.ingresos.compareTo(a.value.ingresos)),
    );

    return ReportData(
      from: from,
      to: to,
      totalIngresos: totalIngresos,
      ingresosPorDia: ingresosPorDia,
      ingresosPorMetodo: ingresosPorMetodo,
      totalCitas: appointments.length,
      citasPorEstado: citasPorEstado,
      citasPorDia: citasPorDia,
      tratamientosFrecuentes: sortedTratamientos,
      productividadPorOdontologo: sortedProd,
      totalPacientes: totalPatients,
      totalRegistrosClinicos: records.length,
    );
  }
}
