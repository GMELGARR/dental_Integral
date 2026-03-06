import '../repositories/appointment_repository.dart';

class UpdateAppointment {
  const UpdateAppointment(this._repo);
  final AppointmentRepository _repo;

  Future<void> call({
    required String id,
    String? estado,
    String? hora,
    String? motivo,
    String? notas,
    String? pacienteId,
    String? pacienteNombre,
    String? pacienteTelefono,
    DateTime? fecha,
    String? odontologoId,
    String? odontologoNombre,
    int? duracionMinutos,
    String? tipo,
    String? nombreTemporal,
    String? telefonoTemporal,
  }) =>
      _repo.update(
        id: id,
        estado: estado,
        hora: hora,
        motivo: motivo,
        notas: notas,
        pacienteId: pacienteId,
        pacienteNombre: pacienteNombre,
        pacienteTelefono: pacienteTelefono,
        fecha: fecha,
        odontologoId: odontologoId,
        odontologoNombre: odontologoNombre,
        duracionMinutos: duracionMinutos,
        tipo: tipo,
        nombreTemporal: nombreTemporal,
        telefonoTemporal: telefonoTemporal,
      );
}
