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
      );
}
