import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../admin_users/domain/entities/managed_user.dart';
import '../../domain/entities/odontologist.dart';
import '../../domain/entities/specialty.dart';
import '../../domain/usecases/create_odontologist.dart';
import '../../domain/usecases/link_odontologist_user.dart';
import '../../domain/usecases/observe_odontologists.dart';
import '../../domain/usecases/update_odontologist.dart';

class OdontologistController extends ChangeNotifier {
  OdontologistController({
    required ObserveOdontologists observeOdontologists,
    required CreateOdontologist createOdontologist,
    required UpdateOdontologist updateOdontologist,
    required LinkOdontologistUser linkOdontologistUser,
  })  : _observeOdontologists = observeOdontologists,
        _createOdontologist = createOdontologist,
        _updateOdontologist = updateOdontologist,
        _linkOdontologistUser = linkOdontologistUser {
    _subscription = _observeOdontologists().listen((list) {
      _odontologists = list;
      _isLoading = false;
      notifyListeners();
    });
  }

  final ObserveOdontologists _observeOdontologists;
  final CreateOdontologist _createOdontologist;
  final UpdateOdontologist _updateOdontologist;
  final LinkOdontologistUser _linkOdontologistUser;
  StreamSubscription<List<Odontologist>>? _subscription;

  List<Odontologist> _odontologists = const [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  String? _updatingId;

  List<Odontologist> get odontologists => _odontologists;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String? get updatingId => _updatingId;

  Future<bool> create({
    required String nombre,
    required Specialty especialidad,
    required String colegiadoActivo,
    required String telefono,
    required String email,
    String? notas,
  }) async {
    _errorMessage = null;
    _isSaving = true;
    notifyListeners();

    try {
      await _createOdontologist(
        nombre: nombre,
        especialidad: especialidad,
        colegiadoActivo: colegiadoActivo,
        telefono: telefono,
        email: email,
        notas: notas,
      );
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'No se pudo registrar al odontólogo.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> update({
    required String id,
    required String nombre,
    required Specialty especialidad,
    required String colegiadoActivo,
    required String telefono,
    required String email,
    required bool activo,
    String? notas,
  }) async {
    _errorMessage = null;
    _updatingId = id;
    notifyListeners();

    try {
      await _updateOdontologist(
        id: id,
        nombre: nombre,
        especialidad: especialidad,
        colegiadoActivo: colegiadoActivo,
        telefono: telefono,
        email: email,
        activo: activo,
        notas: notas,
      );
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'No se pudo actualizar al odontólogo.';
      return false;
    } finally {
      _updatingId = null;
      notifyListeners();
    }
  }

  Future<bool> linkUser({
    required String odontologistId,
    required String? userId,
  }) async {
    _errorMessage = null;
    _updatingId = odontologistId;
    notifyListeners();

    try {
      await _linkOdontologistUser(
        odontologistId: odontologistId,
        userId: userId,
      );
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'No se pudo vincular el usuario.';
      return false;
    } finally {
      _updatingId = null;
      notifyListeners();
    }
  }

  /// Returns users with role == 'odontologo' who are NOT already linked
  /// to another odontologist record (except the one being edited).
  List<ManagedUser> availableUsersForLinking({
    required List<ManagedUser> allUsers,
    String? currentOdontologistId,
  }) {
    final linkedUserIds = _odontologists
        .where((o) => o.userId != null && o.id != currentOdontologistId)
        .map((o) => o.userId)
        .toSet();

    return allUsers
        .where((u) =>
            u.role == 'odontologo' &&
            u.active &&
            !linkedUserIds.contains(u.uid))
        .toList();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
