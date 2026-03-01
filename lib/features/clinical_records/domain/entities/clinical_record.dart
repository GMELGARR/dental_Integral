import 'tratamiento_realizado.dart';

/// A clinical record created when an appointment is completed.
class ClinicalRecord {
  const ClinicalRecord({
    required this.id,
    required this.citaId,
    required this.pacienteId,
    required this.pacienteNombre,
    required this.odontologoId,
    required this.odontologoNombre,
    required this.fecha,
    required this.tratamientos,
    required this.subtotal,
    required this.descuentoMonto,
    required this.cargoExtra,
    required this.costoTotal,
    this.diagnostico,
    this.notasClinicas,
    this.indicaciones,
    this.proximaCitaSugerida,
    this.notaCargoExtra,
    this.piezasDentales,
  });

  final String id;

  /// Appointment that originated this record (1:1).
  final String citaId;

  // ── Patient ──────────────────────────────────────────────────
  final String pacienteId;
  final String pacienteNombre;

  // ── Odontologist ─────────────────────────────────────────────
  final String odontologoId;
  final String odontologoNombre;

  /// Date of the consultation.
  final DateTime fecha;

  // ── Clinical data ────────────────────────────────────────────
  final String? diagnostico;
  final String? piezasDentales;
  final String? notasClinicas;
  final String? indicaciones;
  final String? proximaCitaSugerida;

  // ── Treatment cart ───────────────────────────────────────────
  final List<TratamientoRealizado> tratamientos;

  /// Sum of tratamiento subtotals before discount/extra.
  final double subtotal;

  /// Discount amount (absolute Q).
  final double descuentoMonto;

  /// Extra charge amount (absolute Q).
  final double cargoExtra;

  /// Optional note explaining the extra charge.
  final String? notaCargoExtra;

  /// Final total: (subtotal − descuentoMonto) + cargoExtra.
  final double costoTotal;

  // ── Firestore mapping ────────────────────────────────────────

  factory ClinicalRecord.fromFirestore(
      String id, Map<String, dynamic> data) {
    final items = (data['tratamientos'] as List<dynamic>?)
            ?.map((e) =>
                TratamientoRealizado.fromMap(e as Map<String, dynamic>))
            .toList() ??
        const [];

    return ClinicalRecord(
      id: id,
      citaId: data['citaId'] as String? ?? '',
      pacienteId: data['pacienteId'] as String? ?? '',
      pacienteNombre: data['pacienteNombre'] as String? ?? '',
      odontologoId: data['odontologoId'] as String? ?? '',
      odontologoNombre: data['odontologoNombre'] as String? ?? '',
      fecha: (data['fecha'] as dynamic).toDate() as DateTime,
      diagnostico: data['diagnostico'] as String?,
      piezasDentales: data['piezasDentales'] as String?,
      notasClinicas: data['notasClinicas'] as String?,
      indicaciones: data['indicaciones'] as String?,
      proximaCitaSugerida: data['proximaCitaSugerida'] as String?,
      tratamientos: items,
      subtotal: (data['subtotal'] as num?)?.toDouble() ?? 0,
      descuentoMonto:
          (data['descuentoMonto'] as num?)?.toDouble() ?? 0,
      cargoExtra: (data['cargoExtra'] as num?)?.toDouble() ?? 0,
      notaCargoExtra: data['notaCargoExtra'] as String?,
      costoTotal: (data['costoTotal'] as num?)?.toDouble() ?? 0,
    );
  }
}
