import 'module_permission.dart';

class ManagedUser {
  const ManagedUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    required this.active,
    required this.modules,
  });

  final String uid;
  final String email;
  final String displayName;
  final String role;
  final bool active;
  final List<ModulePermission> modules;
}