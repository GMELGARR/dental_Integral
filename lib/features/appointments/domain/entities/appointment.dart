/// Possible states an appointment can be in.
abstract class AppointmentStatus {
  static const String programada = 'programada';
  static const String confirmada = 'confirmada';
  static const String enSala = 'en_sala';
  static const String enAtencion = 'en_atencion';
  static const String completada = 'completada';
  static const String cancelada = 'cancelada';
  static const String noAsistio = 'no_asistio';

  static const List<String> all = [
    programada,
    confirmada,
    enSala,
    enAtencion,
    completada,
    cancelada,
    noAsistio,
  ];

  /// Human-readable label.
  static String label(String status) {
    switch (status) {
      case programada:
        return 'Programada';
      case confirmada:
        return 'Confirmada';
      case enSala:
        return 'En sala';
      case enAtencion:
        return 'En atención';
      case completada:
        return 'Completada';
      case cancelada:
        return 'Cancelada';
      case noAsistio:
        return 'No asistió';
      default:
        return status;
    }
  }

  /// Whether the status is a "finished" state (no further action).
  static bool isTerminal(String status) =>
      status == completada || status == cancelada || status == noAsistio;

  /// Allowed next states from a given status.
  static List<String> nextStates(String current) {
    switch (current) {
      case programada:
        return [confirmada, cancelada];
      case confirmada:
        return [enSala, cancelada];
      case enSala:
        return [enAtencion, noAsistio];
      case enAtencion:
        return [completada];
      default:
        return [];
    }
  }
}

/// Whether the appointment is for a first-time or returning patient.
abstract class AppointmentType {
  static const String primeraConsulta = 'primera_consulta';
  static const String reconsulta = 'reconsulta';
}

class Appointment {
  const Appointment({
    required this.id,
    required this.tipo,
    required this.fecha,
    required this.hora,
    required this.estado,
    required this.odontologoId,
    required this.odontologoNombre,
    required this.pacienteNombre,
    required this.pacienteTelefono,
    this.duracionMinutos = 30,
    this.pacienteId,
    this.nombreTemporal,
    this.telefonoTemporal,
    this.motivo,
    this.tratamientoId,
    this.notas,
  });

  final String id;

  /// 'primera_consulta' | 'reconsulta'
  final String tipo;

  /// Date of the appointment (time-of-day stripped).
  final DateTime fecha;

  /// Time as "HH:mm" string.
  final String hora;

  /// Duration in minutes. Default 30.
  final int duracionMinutos;

  /// Current status (see [AppointmentStatus]).
  final String estado;

  // ── Odontólogo ────────────────────────────────────────────────
  final String odontologoId;
  final String odontologoNombre;

  // ── Paciente (reconsulta) ─────────────────────────────────────
  /// Firestore doc id from `pacientes`, set for reconsultas or after
  /// a first-time patient is registered in full.
  final String? pacienteId;

  // ── Paciente temporal (primera consulta) ──────────────────────
  final String? nombreTemporal;
  final String? telefonoTemporal;

  // ── Datos desnormalizados para visualización rápida ──────────
  final String pacienteNombre;
  final String pacienteTelefono;

  // ── Motivo / tratamiento ──────────────────────────────────────
  final String? motivo;
  final String? tratamientoId;
  final String? notas;

  // ── Helpers ───────────────────────────────────────────────────
  bool get esPrimeraConsulta => tipo == AppointmentType.primeraConsulta;
  bool get tieneExpediente => pacienteId != null;
  bool get isTerminal => AppointmentStatus.isTerminal(estado);

  // ── Firestore mapping ─────────────────────────────────────────

  factory Appointment.fromFirestore(String id, Map<String, dynamic> data) {
    return Appointment(
      id: id,
      tipo: data['tipo'] as String? ?? AppointmentType.primeraConsulta,
      fecha: (data['fecha'] as dynamic).toDate() as DateTime,
      hora: data['hora'] as String? ?? '',
      duracionMinutos: (data['duracionMinutos'] as int?) ?? 30,
      estado: data['estado'] as String? ?? AppointmentStatus.programada,
      odontologoId: data['odontologoId'] as String? ?? '',
      odontologoNombre: data['odontologoNombre'] as String? ?? '',
      pacienteNombre: data['pacienteNombre'] as String? ?? '',
      pacienteTelefono: data['pacienteTelefono'] as String? ?? '',
      pacienteId: data['pacienteId'] as String?,
      nombreTemporal: data['nombreTemporal'] as String?,
      telefonoTemporal: data['telefonoTemporal'] as String?,
      motivo: data['motivo'] as String?,
      tratamientoId: data['tratamientoId'] as String?,
      notas: data['notas'] as String?,
    );
  }
}
