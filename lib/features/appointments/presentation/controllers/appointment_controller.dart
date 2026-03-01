import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/appointment.dart';
import '../../domain/repositories/appointment_repository.dart';
import '../../domain/usecases/create_appointment.dart';
import '../../domain/usecases/observe_appointments.dart';
import '../../domain/usecases/update_appointment.dart';

class AppointmentController extends ChangeNotifier {
  AppointmentController({
    required ObserveAppointments observeAppointments,
    required CreateAppointment createAppointment,
    required UpdateAppointment updateAppointment,
    required AppointmentRepository repository,
  })  : _observeAppointments = observeAppointments,
        _createAppointment = createAppointment,
        _updateAppointment = updateAppointment,
        _repository = repository {
    // Default: observe today's appointments.
    setDateRange(_selectedDate, _selectedDate);
  }

  final ObserveAppointments _observeAppointments;
  final CreateAppointment _createAppointment;
  final UpdateAppointment _updateAppointment;
  final AppointmentRepository _repository;

  StreamSubscription<List<Appointment>>? _subscription;

  List<Appointment> _appointments = const [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  String? _updatingId;
  DateTime _selectedDate = DateTime.now();

  List<Appointment> get appointments => _appointments;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String? get updatingId => _updatingId;
  DateTime get selectedDate => _selectedDate;

  // ── Date navigation ───────────────────────────────────────────

  void setDateRange(DateTime start, DateTime end) {
    _isLoading = true;
    notifyListeners();

    _subscription?.cancel();
    _subscription = _observeAppointments(
      DateTime(start.year, start.month, start.day),
      DateTime(end.year, end.month, end.day, 23, 59, 59),
    ).listen(
      (list) {
        _appointments = list;
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        _isLoading = false;
        _errorMessage = error.toString();
        notifyListeners();
      },
    );
  }

  void selectDate(DateTime date) {
    _selectedDate = date;
    setDateRange(date, date);
  }

  // ── Create ────────────────────────────────────────────────────

  Future<bool> create({
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
  }) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _createAppointment(
        tipo: tipo,
        fecha: fecha,
        hora: hora,
        odontologoId: odontologoId,
        odontologoNombre: odontologoNombre,
        pacienteNombre: pacienteNombre,
        pacienteTelefono: pacienteTelefono,
        duracionMinutos: duracionMinutos,
        estado: estado,
        pacienteId: pacienteId,
        nombreTemporal: nombreTemporal,
        telefonoTemporal: telefonoTemporal,
        motivo: motivo,
        tratamientoId: tratamientoId,
        notas: notas,
      );
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Error inesperado al crear la cita.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // ── Update (generic) ──────────────────────────────────────────

  Future<bool> update({
    required String id,
    String? estado,
    String? hora,
    String? motivo,
    String? notas,
    String? pacienteId,
    String? pacienteNombre,
    String? pacienteTelefono,
  }) async {
    _updatingId = id;
    _errorMessage = null;
    notifyListeners();
    try {
      await _updateAppointment(
        id: id,
        estado: estado,
        hora: hora,
        motivo: motivo,
        notas: notas,
        pacienteId: pacienteId,
        pacienteNombre: pacienteNombre,
        pacienteTelefono: pacienteTelefono,
      );
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Error inesperado al actualizar la cita.';
      return false;
    } finally {
      _updatingId = null;
      notifyListeners();
    }
  }

  // ── Shorthand: change status ──────────────────────────────────

  Future<bool> changeStatus(String id, String newStatus) =>
      update(id: id, estado: newStatus);

  // ── Link patient to first-time appointment ────────────────────

  Future<bool> linkPatient({
    required String appointmentId,
    required String pacienteId,
    required String pacienteNombre,
    required String pacienteTelefono,
  }) =>
      update(
        id: appointmentId,
        pacienteId: pacienteId,
        pacienteNombre: pacienteNombre,
        pacienteTelefono: pacienteTelefono,
      );

  // ── Helpers ───────────────────────────────────────────────────

  /// Appointments for a specific odontologist on the current date.
  List<Appointment> appointmentsFor(String odontologoId) =>
      _appointments.where((a) => a.odontologoId == odontologoId).toList();

  /// One-shot fetch: appointments for a specific odontólogo on a given date.
  Future<List<Appointment>> getByOdontologoAndDate(
    String odontologoId,
    DateTime date,
  ) =>
      _repository.getByOdontologoAndDate(odontologoId, date);

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
