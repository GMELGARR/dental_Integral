import '../../domain/entities/managed_user.dart';
import '../../domain/entities/module_permission.dart';
import '../../domain/repositories/user_management_repository.dart';
import '../datasources/user_management_firestore_data_source.dart';

class UserManagementRepositoryImpl implements UserManagementRepository {
  UserManagementRepositoryImpl(this._dataSource);

  final UserManagementFirestoreDataSource _dataSource;

  @override
  Stream<List<ManagedUser>> observeUsers() {
    return _dataSource.observeUsers();
  }

  @override
  Future<void> updateUserAccess({
    required String uid,
    required bool active,
    required List<ModulePermission> modules,
  }) {
    return _dataSource.updateUserAccess(
      uid: uid,
      active: active,
      modules: modules,
    );
  }

  @override
  Future<void> createUser({
    required String email,
    required String password,
    required String displayName,
    required String role,
    required List<ModulePermission> modules,
  }) {
    return _dataSource.createUser(
      email: email,
      password: password,
      displayName: displayName,
      role: role,
      modules: modules,
    );
  }
}