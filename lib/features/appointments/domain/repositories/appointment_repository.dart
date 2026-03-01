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
    String? pacienteId,
    String? nombreTemporal,
    String? telefonoTemporal,
    String? motivo,
    String? tratamientoId,
    String? notas,
  });

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
