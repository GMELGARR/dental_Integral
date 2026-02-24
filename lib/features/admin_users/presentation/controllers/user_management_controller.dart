import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/managed_user.dart';
import '../../domain/entities/module_permission.dart';
import '../../domain/usecases/create_staff_user.dart';
import '../../domain/usecases/observe_managed_users.dart';
import '../../domain/usecases/update_user_access.dart';

class UserManagementController extends ChangeNotifier {
  UserManagementController({
    required ObserveManagedUsers observeManagedUsers,
    required UpdateUserAccess updateUserAccess,
    required CreateStaffUser createStaffUser,
  })  : _observeManagedUsers = observeManagedUsers,
        _updateUserAccess = updateUserAccess,
        _createStaffUser = createStaffUser {
    _subscription = _observeManagedUsers().listen((users) {
      _users = users;
      _isLoading = false;
      notifyListeners();
    });
  }

  final ObserveManagedUsers _observeManagedUsers;
  final UpdateUserAccess _updateUserAccess;
  final CreateStaffUser _createStaffUser;
  StreamSubscription<List<ManagedUser>>? _subscription;

  List<ManagedUser> _users = const [];
  bool _isLoading = true;
  bool _isCreating = false;
  String? _errorMessage;
  String? _updatingUserUid;

  List<ManagedUser> get users => _users;
  bool get isLoading => _isLoading;
  bool get isCreating => _isCreating;
  String? get errorMessage => _errorMessage;
  String? get updatingUserUid => _updatingUserUid;

  Future<bool> updateAccess({
    required String uid,
    required bool active,
    required List<ModulePermission> modules,
  }) async {
    _errorMessage = null;
    _updatingUserUid = uid;
    notifyListeners();

    try {
      await _updateUserAccess(
        uid: uid,
        active: active,
        modules: modules,
      );
      return true;
    } on AppException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = 'No se pudo actualizar el usuario.';
      return false;
    } finally {
      _updatingUserUid = null;
      notifyListeners();
    }
  }

  Future<bool> createUser({
    required String email,
    required String password,
    required String displayName,
    required String role,
    required List<ModulePermission> modules,
  }) async {
    _errorMessage = null;
    _isCreating = true;
    notifyListeners();

    try {
      await _createStaffUser(
        email: email,
        password: password,
        displayName: displayName,
        role: role,
        modules: modules,
      );
      return true;
    } on AppException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = 'No se pudo crear el usuario.';
      return false;
    } finally {
      _isCreating = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}