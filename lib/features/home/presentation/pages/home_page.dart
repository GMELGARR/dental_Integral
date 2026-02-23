import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/service_locator.dart';
import '../../../auth/presentation/controllers/auth_session_controller.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authSession = getIt<AuthSessionController>();
    final email = authSession.currentUser?.email ?? 'usuario';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dental Integral'),
        actions: [
          IconButton(
            onPressed: () async {
              await authSession.signOut();
            },
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Bienvenido',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Text(
                'Sesión iniciada como: $email',
                textAlign: TextAlign.center,
              ),
              if (authSession.isAdmin) ...[
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => context.push('/admin/users'),
                  icon: const Icon(Icons.admin_panel_settings_outlined),
                  label: const Text('Administrar usuarios'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}