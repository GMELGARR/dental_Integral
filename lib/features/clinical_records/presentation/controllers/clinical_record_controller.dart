import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/clinical_record.dart';
import '../../domain/entities/tratamiento_realizado.dart';
import '../../domain/usecases/create_clinical_record.dart';
import '../../domain/usecases/get_clinical_record_by_appointment.dart';
import '../../domain/usecases/observe_clinical_records_by_patient.dart';

class ClinicalRecordController extends ChangeNotifier {
  ClinicalRecordController({
    required CreateClinicalRecord createClinicalRecord,
    required ObserveClinicalRecordsByPatient observeByPatient,
    required GetClinicalRecordByAppointment getByAppointment,
  })  : _createClinicalRecord = createClinicalRecord,
        _observeByPatient = observeByPatient,
        _getByAppointment = getByAppointment;

  final CreateClinicalRecord _createClinicalRecord;
  final ObserveClinicalRecordsByPatient _observeByPatient;
  final GetClinicalRecordByAppointment _getByAppointment;

  StreamSubscription<List<ClinicalRecord>>? _sub;

  List<ClinicalRecord> _records = const [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  List<ClinicalRecord> get records => _records;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  // ── Observe by patient ───────────────────────────────────────

  void loadByPatient(String pacienteId) {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _sub?.cancel();
    _sub = _observeByPatient(pacienteId).listen(
      (list) {
        _records = list;
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

  // ── Get by appointment (one-shot) ────────────────────────────

  Future<ClinicalRecord?> getByAppointment(String citaId) async {
    try {
      return await _getByAppointment(citaId);
    } catch (_) {
      return null;
    }
  }

  // ── Create ───────────────────────────────────────────────────

  Future<bool> create({
    required String citaId,
    required String pacienteId,
    required String pacienteNombre,
    required String odontologoId,
    required String odontologoNombre,
    required DateTime fecha,
    required List<TratamientoRealizado> tratamientos,
    required double subtotal,
    required double descuentoMonto,
    required double cargoExtra,
    required double costoTotal,
    String? diagnostico,
    String? piezasDentales,
    String? notasClinicas,
    String? indicaciones,
    String? proximaCitaSugerida,
    String? notaCargoExtra,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _createClinicalRecord(
        citaId: citaId,
        pacienteId: pacienteId,
        pacienteNombre: pacienteNombre,
        odontologoId: odontologoId,
        odontologoNombre: odontologoNombre,
        fecha: fecha,
        tratamientos: tratamientos,
        subtotal: subtotal,
        descuentoMonto: descuentoMonto,
        cargoExtra: cargoExtra,
        costoTotal: costoTotal,
        diagnostico: diagnostico,
        piezasDentales: piezasDentales,
        notasClinicas: notasClinicas,
        indicaciones: indicaciones,
        proximaCitaSugerida: proximaCitaSugerida,
        notaCargoExtra: notaCargoExtra,
      );
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Error inesperado al guardar el registro clínico.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
