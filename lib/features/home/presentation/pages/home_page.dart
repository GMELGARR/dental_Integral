import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/service_locator.dart';
import '../../../../core/theme/theme_mode_button.dart';
import '../../../admin_users/domain/entities/module_permission.dart';
import '../../../auth/presentation/controllers/auth_session_controller.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authSession = getIt<AuthSessionController>();
    final email = authSession.currentUser?.email ?? 'usuario';
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
        actions: [
          const ThemeModeButton(),
          IconButton(
            onPressed: () async {
              final success = await authSession.signOut();
              if (!context.mounted) {
                return;
              }
              if (!success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No se pudo cerrar sesión. Intenta de nuevo.')),
                );
              }
              context.go('/login');
            },
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Icon(
                            Icons.medical_services_outlined,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bienvenido a Dental Integral',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Sesión iniciada como: $email',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Acciones rápidas',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (authSession.isAdmin)
                          FilledButton.icon(
                            onPressed: () => context.push('/admin/users'),
                            icon: const Icon(Icons.admin_panel_settings_outlined),
                            label: const Text('Administrar usuarios'),
                          ),
                        if (authSession.isAdmin || authSession.hasModule(ModulePermission.patients)) ...[
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: () => context.push('/patients'),
                            icon: const Icon(Icons.groups_outlined),
                            label: const Text('Módulo Pacientes'),
                          ),
                        ],
                        if (!authSession.isAdmin &&
                            !authSession.hasModule(ModulePermission.patients))
                          Text(
                            'Tu cuenta está activa. Los módulos disponibles se mostrarán aquí según tus permisos.',
                            style: theme.textTheme.bodyMedium,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}