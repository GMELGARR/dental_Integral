import '../entities/managed_user.dart';
import '../entities/module_permission.dart';

abstract class UserManagementRepository {
  Stream<List<ManagedUser>> observeUsers();

  Future<void> updateUserAccess({
    required String uid,
    required bool active,
    required List<ModulePermission> modules,
  });

  Future<void> createUser({
    required String email,
    required String password,
    required String displayName,
    required String role,
    required List<ModulePermission> modules,
  });
}