import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../domain/entities/odontogram.dart';
import '../../domain/usecases/observe_odontogram.dart';
import '../../domain/usecases/save_odontogram.dart';

class OdontogramController extends ChangeNotifier {
  OdontogramController({
    required ObserveOdontogram observeOdontogram,
    required SaveOdontogram saveOdontogram,
  })  : _observeOdontogram = observeOdontogram,
        _saveOdontogram = saveOdontogram;

  final ObserveOdontogram _observeOdontogram;
  final SaveOdontogram _saveOdontogram;

  StreamSubscription<Odontogram>? _sub;
  Odontogram? _odontogram;
  bool _loading = false;
  String? _error;

  // ── Selected tool ────────────────────────────────────────────
  ToothCondition _selectedCondition = ToothCondition.caries;

  // ── Getters ──────────────────────────────────────────────────
  Odontogram? get odontogram => _odontogram;
  bool get loading => _loading;
  String? get error => _error;
  ToothCondition get selectedCondition => _selectedCondition;

  void selectCondition(ToothCondition condition) {
    _selectedCondition = condition;
    notifyListeners();
  }

  // ── Start observing ──────────────────────────────────────────
  void startObserving(String pacienteId) {
    _loading = true;
    _error = null;
    notifyListeners();

    _sub?.cancel();
    _sub = _observeOdontogram(pacienteId).listen(
      (odontogram) {
        _odontogram = odontogram;
        _loading = false;
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        _loading = false;
        notifyListeners();
      },
    );
  }

  // ── Apply condition to a face ────────────────────────────────
  Future<void> applyToFace({
    required String toothNumber,
    required ToothFace face,
    required String modifiedBy,
  }) async {
    if (_odontogram == null) return;

    final condition = _selectedCondition;
    final tooth = _odontogram!.toothState(toothNumber).copyWith(
      clearWholeTooth: true,
    );

    // If applying "sano", remove the face condition
    if (condition == ToothCondition.sano) {
      tooth.faces.remove(face);
    } else {
      tooth.faces[face] = condition;
    }

    // If condition applies to whole tooth, set it there instead
    if (condition.appliesToWholeTooth) {
      tooth.faces.clear();
      tooth.wholeTooth = condition;
    }

    _odontogram!.dientes[toothNumber] = tooth;

    // Add history entry
    _odontogram!.historial.insert(
      0,
      OdontogramChange(
        fecha: DateTime.now(),
        modificadoPor: modifiedBy,
        diente: toothNumber,
        descripcion: condition.appliesToWholeTooth
            ? '${condition.label} en pieza $toothNumber'
            : '${condition.label} en cara ${face.name} de pieza $toothNumber',
      ),
    );

    notifyListeners();

    try {
      await _saveOdontogram(_odontogram!);
    } catch (e) {
      _error = 'Error al guardar: $e';
      notifyListeners();
    }
  }

  // ── Apply condition to whole tooth ───────────────────────────
  Future<void> applyToWholeTooth({
    required String toothNumber,
    required String modifiedBy,
  }) async {
    if (_odontogram == null) return;

    final condition = _selectedCondition;
    final tooth = _odontogram!.toothState(toothNumber).copyWith(
      clearWholeTooth: true,
    );

    if (condition == ToothCondition.sano) {
      tooth.faces.clear();
      tooth.wholeTooth = null;
    } else {
      tooth.faces.clear();
      tooth.wholeTooth = condition;
    }

    _odontogram!.dientes[toothNumber] = tooth;

    _odontogram!.historial.insert(
      0,
      OdontogramChange(
        fecha: DateTime.now(),
        modificadoPor: modifiedBy,
        diente: toothNumber,
        descripcion: condition == ToothCondition.sano
            ? 'Pieza $toothNumber marcada como sana'
            : '${condition.label} en pieza $toothNumber (completa)',
      ),
    );

    notifyListeners();

    try {
      await _saveOdontogram(_odontogram!);
    } catch (e) {
      _error = 'Error al guardar: $e';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
