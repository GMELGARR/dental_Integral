import '../entities/appointment.dart';

abstract class AppointmentRepository {
  /// Real-time stream of appointments for a given date range.
  Stream<List<Appointment>> observeByDateRange(DateTime start, DateTime end);

  /// Create a new appointment.
  Future<void> create({
    required String tipo,
    required DateTime fecha,
    required String hora,
    required String odontologoId,
    required String odontologoNombre,
    required String pacienteNombre,
    required String pacienteTelefono,
    int duracionMinutos = 30,
    String? estado,
    String? pacienteId,
    String? nombreTemporal,
    String? telefonoTemporal,
    String? motivo,
    String? tratamientoId,
    String? notas,
  });

  /// One-shot fetch for a specific odontólogo on a date.
  Future<List<Appointment>> getByOdontologoAndDate(
    String odontologoId,
    DateTime date,
  );

  /// Update an existing appointment (partial).
  Future<void> update({
    required String id,
    String? estado,
    String? hora,
    String? motivo,
    String? notas,
    String? pacienteId,
    String? pacienteNombre,
    String? pacienteTelefono,
  });
}
