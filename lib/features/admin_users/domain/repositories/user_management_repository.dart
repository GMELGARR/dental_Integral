import '../entities/managed_user.dart';
import '../entities/module_permission.dart';

abstract class UserManagementRepository {
  Stream<List<ManagedUser>> observeUsers();

  Future<void> updateUserAccess({
    required String uid,
    required bool active,
    required List<ModulePermission> modules,
  });
}