import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/patient.dart';
import '../../domain/usecases/create_patient.dart';
import '../../domain/usecases/observe_patients.dart';
import '../../domain/usecases/update_patient.dart';

class PatientController extends ChangeNotifier {
  PatientController({
    required ObservePatients observePatients,
    required CreatePatient createPatient,
    required UpdatePatient updatePatient,
  })  : _observePatients = observePatients,
        _createPatient = createPatient,
        _updatePatient = updatePatient {
    _subscription = _observePatients().listen((list) {
      _patients = list;
      _isLoading = false;
      notifyListeners();
    });
  }

  final ObservePatients _observePatients;
  final CreatePatient _createPatient;
  final UpdatePatient _updatePatient;
  StreamSubscription<List<Patient>>? _subscription;

  List<Patient> _patients = const [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  String? _updatingId;

  List<Patient> get patients => _patients;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String? get updatingId => _updatingId;

  Future<bool> create({
    required String nombre,
    required String dpi,
    required DateTime? fechaNacimiento,
    required String genero,
    required String telefono,
    String? telefonoEmergencia,
    String? contactoEmergencia,
    String? direccion,
    String? email,
    String? alergias,
    String? enfermedadesSistemicas,
    String? medicamentosActuales,
    String? notasClinicas,
  }) async {
    _errorMessage = null;
    _isSaving = true;
    notifyListeners();

    try {
      await _createPatient(
        nombre: nombre,
        dpi: dpi,
        fechaNacimiento: fechaNacimiento,
        genero: genero,
        telefono: telefono,
        telefonoEmergencia: telefonoEmergencia,
        contactoEmergencia: contactoEmergencia,
        direccion: direccion,
        email: email,
        alergias: alergias,
        enfermedadesSistemicas: enfermedadesSistemicas,
        medicamentosActuales: medicamentosActuales,
        notasClinicas: notasClinicas,
      );
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'No se pudo registrar al paciente.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> update({
    required String id,
    required String nombre,
    required String dpi,
    required DateTime? fechaNacimiento,
    required String genero,
    required String telefono,
    required bool activo,
    String? telefonoEmergencia,
    String? contactoEmergencia,
    String? direccion,
    String? email,
    String? alergias,
    String? enfermedadesSistemicas,
    String? medicamentosActuales,
    String? notasClinicas,
  }) async {
    _errorMessage = null;
    _updatingId = id;
    notifyListeners();

    try {
      await _updatePatient(
        id: id,
        nombre: nombre,
        dpi: dpi,
        fechaNacimiento: fechaNacimiento,
        genero: genero,
        telefono: telefono,
        activo: activo,
        telefonoEmergencia: telefonoEmergencia,
        contactoEmergencia: contactoEmergencia,
        direccion: direccion,
        email: email,
        alergias: alergias,
        enfermedadesSistemicas: enfermedadesSistemicas,
        medicamentosActuales: medicamentosActuales,
        notasClinicas: notasClinicas,
      );
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'No se pudo actualizar al paciente.';
      return false;
    } finally {
      _updatingId = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
