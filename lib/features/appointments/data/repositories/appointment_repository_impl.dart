import '../../domain/entities/appointment.dart';
import '../../domain/repositories/appointment_repository.dart';
import '../datasources/appointment_firestore_data_source.dart';

class AppointmentRepositoryImpl implements AppointmentRepository {
  const AppointmentRepositoryImpl(this._ds);
  final AppointmentFirestoreDataSource _ds;

  @override
  Stream<List<Appointment>> observeByDateRange(
    DateTime start,
    DateTime end,
  ) =>
      _ds.observeByDateRange(start, end);

  @override
  Future<List<Appointment>> getByOdontologoAndDate(
    String odontologoId,
    DateTime date,
  ) =>
      _ds.getByOdontologoAndDate(odontologoId, date);

  @override
  Future<void> create({
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
      _ds.create(
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

  @override
  Future<void> update({
    required String id,
    String? estado,
    String? hora,
    String? motivo,
    String? notas,
    String? pacienteId,
    String? pacienteNombre,
    String? pacienteTelefono,
  }) =>
      _ds.update(
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
