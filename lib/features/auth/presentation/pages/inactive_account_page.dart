import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/service_locator.dart';
import '../../../../core/theme/theme_mode_button.dart';
import '../controllers/auth_session_controller.dart';

class InactiveAccountPage extends StatelessWidget {
  const InactiveAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = getIt<AuthSessionController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cuenta inactiva'),
        actions: const [ThemeModeButton()],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Tu cuenta está inactiva. Contacta al administrador para habilitar acceso.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  await session.signOut();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
                child: const Text('Cerrar sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}