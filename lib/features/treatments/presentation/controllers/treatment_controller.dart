import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/treatment.dart';
import '../../domain/usecases/create_treatment.dart';
import '../../domain/usecases/observe_treatments.dart';
import '../../domain/usecases/update_treatment.dart';

class TreatmentController extends ChangeNotifier {
  TreatmentController({
    required ObserveTreatments observeTreatments,
    required CreateTreatment createTreatment,
    required UpdateTreatment updateTreatment,
  })  : _observeTreatments = observeTreatments,
        _createTreatment = createTreatment,
        _updateTreatment = updateTreatment {
    _subscription = _observeTreatments().listen((list) {
      _treatments = list;
      _isLoading = false;
      notifyListeners();
    });
  }

  final ObserveTreatments _observeTreatments;
  final CreateTreatment _createTreatment;
  final UpdateTreatment _updateTreatment;
  StreamSubscription<List<Treatment>>? _subscription;

  List<Treatment> _treatments = const [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  String? _updatingId;

  List<Treatment> get treatments => _treatments;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String? get updatingId => _updatingId;

  Future<bool> create({
    required String nombre,
    required double monto,
    String? descripcion,
  }) async {
    _errorMessage = null;
    _isSaving = true;
    notifyListeners();

    try {
      await _createTreatment(
        nombre: nombre,
        monto: monto,
        descripcion: descripcion,
      );
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'No se pudo registrar el tratamiento.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> update({
    required String id,
    required String nombre,
    required double monto,
    required bool activo,
    String? descripcion,
  }) async {
    _errorMessage = null;
    _updatingId = id;
    notifyListeners();

    try {
      await _updateTreatment(
        id: id,
        nombre: nombre,
        monto: monto,
        activo: activo,
        descripcion: descripcion,
      );
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'No se pudo actualizar el tratamiento.';
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
