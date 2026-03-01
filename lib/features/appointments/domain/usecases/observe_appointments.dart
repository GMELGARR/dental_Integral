import '../entities/appointment.dart';
import '../repositories/appointment_repository.dart';

class ObserveAppointments {
  const ObserveAppointments(this._repo);
  final AppointmentRepository _repo;

  Stream<List<Appointment>> call(DateTime start, DateTime end) =>
      _repo.observeByDateRange(start, end);
}
