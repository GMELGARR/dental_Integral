import '../repositories/appointment_repository.dart';

class CreateAppointment {
  const CreateAppointment(this._repo);
  final AppointmentRepository _repo;

  Future<void> call({
    required String tipo,
    required DateTime fecha,
    required String hora,
    required String odontologoId,
    required String odontologoNombre,
    required String pacienteNombre,
    required String pacienteTelefono,
    int duracionMinutos = 30,
    String? pacienteId,
    String? nombreTemporal,
    String? telefonoTemporal,
    String? motivo,
    String? tratamientoId,
    String? notas,
  }) =>
      _repo.create(
        tipo: tipo,
        fecha: fecha,
        hora: hora,
        odontologoId: odontologoId,
        odontologoNombre: odontologoNombre,
        pacienteNombre: pacienteNombre,
        pacienteTelefono: pacienteTelefono,
        duracionMinutos: duracionMinutos,
        pacienteId: pacienteId,
        nombreTemporal: nombreTemporal,
        telefonoTemporal: telefonoTemporal,
        motivo: motivo,
        tratamientoId: tratamientoId,
        notas: notas,
      );
}
