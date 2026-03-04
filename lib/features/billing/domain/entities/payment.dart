/// Represents a single payment made by (or on behalf of) a patient.
class Payment {
  const Payment({
    required this.id,
    required this.pacienteId,
    required this.pacienteNombre,
    required this.monto,
    required this.metodoPago,
    required this.fecha,
    this.registroClinicoId,
    this.recibidoPor,
    this.notas,
  });

  final String id;

  /// Patient who made the payment.
  final String pacienteId;
  final String pacienteNombre;

  /// Optionally linked to a specific clinical record.
  final String? registroClinicoId;

  /// Amount paid in Quetzales.
  final double monto;

  /// Payment method key: efectivo | tarjeta | transferencia.
  final String metodoPago;

  /// Date & time the payment was recorded.
  final DateTime fecha;

  /// Name of the user who received the payment.
  final String? recibidoPor;

  /// Optional notes.
  final String? notas;

  // ── Firestore mapping ────────────────────────────────────────

  factory Payment.fromFirestore(String id, Map<String, dynamic> data) {
    return Payment(
      id: id,
      pacienteId: data['pacienteId'] as String? ?? '',
      pacienteNombre: data['pacienteNombre'] as String? ?? '',
      registroClinicoId: data['registroClinicoId'] as String?,
      monto: (data['monto'] as num?)?.toDouble() ?? 0,
      metodoPago: data['metodoPago'] as String? ?? 'efectivo',
      fecha: data['fecha'] != null
          ? (data['fecha'] as dynamic).toDate() as DateTime
          : DateTime.now(),
      recibidoPor: data['recibidoPor'] as String?,
      notas: data['notas'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pacienteId': pacienteId,
      'pacienteNombre': pacienteNombre,
      if (registroClinicoId != null) 'registroClinicoId': registroClinicoId,
      'monto': monto,
      'metodoPago': metodoPago,
      'fecha': fecha,
      if (recibidoPor != null) 'recibidoPor': recibidoPor,
      if (notas != null && notas!.isNotEmpty) 'notas': notas,
    };
  }

  /// Human‐readable label for the payment method.
  static String metodoPagoLabel(String key) {
    switch (key) {
      case 'efectivo':
        return 'Efectivo';
      case 'tarjeta':
        return 'Tarjeta';
      case 'transferencia':
        return 'Transferencia';
      default:
        return key;
    }
  }
}
