import 'package:flutter/material.dart';

import '../../../../app/di/service_locator.dart';
import '../../../../core/theme/theme_mode_button.dart';
import '../../domain/entities/managed_user.dart';
import '../../domain/entities/module_permission.dart';
import '../controllers/user_management_controller.dart';

class AdminUserManagementPage extends StatefulWidget {
  const AdminUserManagementPage({super.key});

  @override
  State<AdminUserManagementPage> createState() => _AdminUserManagementPageState();
}

class _AdminUserManagementPageState extends State<AdminUserManagementPage> {
  late final UserManagementController _controller;

  @override
  void initState() {
    super.initState();
    _controller = getIt<UserManagementController>();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _editUser(ManagedUser user) async {
    var active = user.active;
    final selectedModules = {...user.modules};

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Editar acceso: ${user.displayName}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Usuario activo'),
                      value: active,
                      onChanged: (value) {
                        setModalState(() {
                          active = value;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    const Text('Permisos de página/módulo'),
                    const SizedBox(height: 6),
                    ...ModulePermission.values.map(
                      (permission) => CheckboxListTile(
                        value: selectedModules.contains(permission),
                        contentPadding: EdgeInsets.zero,
                        title: Text(permission.label),
                        onChanged: (checked) {
                          setModalState(() {
                            if (checked == true) {
                              selectedModules.add(permission);
                            } else {
                              selectedModules.remove(permission);
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: selectedModules.isEmpty
                                ? null
                                : () => Navigator.of(context).pop(true),
                            child: const Text('Guardar cambios'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final success = await _controller.updateAccess(
      uid: user.uid,
      active: active,
      modules: selectedModules.toList(),
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Usuario actualizado correctamente.'
              : (_controller.errorMessage ?? 'No se pudo actualizar el usuario.'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de usuarios'),
        actions: const [ThemeModeButton()],
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Creación de usuarios (modo sin costo)',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 8),
                          Text('La creación de cuentas se realiza con el script local:'),
                          SizedBox(height: 6),
                          Text('scripts/admin/create_staff_user.js'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_controller.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_controller.users.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No hay usuarios registrados en la colección users.'),
                      ),
                    )
                  else
                    ..._controller.users.map(
                      (user) => Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(user.displayName.isNotEmpty ? user.displayName[0] : '?'),
                          ),
                          title: Text(user.displayName),
                          subtitle: Text(
                            '${user.email}\nRol: ${user.role} • Estado: ${user.active ? 'Activo' : 'Inactivo'}',
                          ),
                          isThreeLine: true,
                          trailing: _controller.updatingUserUid == user.uid
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : IconButton(
                                  onPressed: () => _editUser(user),
                                  icon: const Icon(Icons.edit_outlined),
                                  tooltip: 'Editar acceso',
                                ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}