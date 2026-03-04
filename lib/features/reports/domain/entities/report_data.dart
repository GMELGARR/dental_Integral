/// Data model for the aggregated report results.
class ReportData {
  const ReportData({
    required this.from,
    required this.to,
    required this.totalIngresos,
    required this.ingresosPorDia,
    required this.ingresosPorMetodo,
    required this.totalCitas,
    required this.citasPorEstado,
    required this.citasPorDia,
    required this.tratamientosFrecuentes,
    required this.productividadPorOdontologo,
    required this.totalPacientes,
    required this.totalRegistrosClinicos,
  });

  final DateTime from;
  final DateTime to;

  // ── Financiero ──
  final double totalIngresos;

  /// key = date as 'yyyy-MM-dd', value = monto
  final Map<String, double> ingresosPorDia;

  /// key = 'efectivo' | 'tarjeta' | 'transferencia', value = total
  final Map<String, double> ingresosPorMetodo;

  // ── Citas ──
  final int totalCitas;

  /// key = estado, value = count
  final Map<String, int> citasPorEstado;

  /// key = date as 'yyyy-MM-dd', value = count
  final Map<String, int> citasPorDia;

  // ── Tratamientos ──
  /// name → count (sorted descending)
  final Map<String, int> tratamientosFrecuentes;

  // ── Productividad ──
  /// odontólogo name → { citas: int, ingresos: double }
  final Map<String, OdontologistStats> productividadPorOdontologo;

  // ── Generales ──
  final int totalPacientes;
  final int totalRegistrosClinicos;
}

class OdontologistStats {
  const OdontologistStats({
    this.citas = 0,
    this.ingresos = 0.0,
  });

  final int citas;
  final double ingresos;

  OdontologistStats copyWith({int? citas, double? ingresos}) {
    return OdontologistStats(
      citas: citas ?? this.citas,
      ingresos: ingresos ?? this.ingresos,
    );
  }
}
