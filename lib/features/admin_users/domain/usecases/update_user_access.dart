import '../entities/module_permission.dart';
import '../repositories/user_management_repository.dart';

class UpdateUserAccess {
  UpdateUserAccess(this._repository);

  final UserManagementRepository _repository;

  Future<void> call({
    required String uid,
    required bool active,
    required List<ModulePermission> modules,
  }) {
    return _repository.updateUserAccess(
      uid: uid,
      active: active,
      modules: modules,
    );
  }
}