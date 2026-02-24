import '../entities/module_permission.dart';
import '../repositories/user_management_repository.dart';

class CreateStaffUser {
  CreateStaffUser(this._repository);

  final UserManagementRepository _repository;

  Future<void> call({
    required String email,
    required String password,
    required String displayName,
    required String role,
    required List<ModulePermission> modules,
  }) {
    return _repository.createUser(
      email: email,
      password: password,
      displayName: displayName,
      role: role,
      modules: modules,
    );
  }
}
