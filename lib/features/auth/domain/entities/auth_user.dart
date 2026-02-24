import '../../../admin_users/domain/entities/module_permission.dart';

class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.isAdmin,
    required this.active,
    required this.modules,
  });

  final String id;
  final String? email;
  final bool isAdmin;
  final bool active;
  final List<ModulePermission> modules;

  bool hasModule(ModulePermission module) {
    return modules.contains(module);
  }
}