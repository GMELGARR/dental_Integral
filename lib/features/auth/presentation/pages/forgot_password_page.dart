import 'package:flutter/material.dart';

import '../../../../app/di/service_locator.dart';
import '../../../../core/theme/theme_mode_button.dart';
import '../controllers/password_reset_controller.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  late final PasswordResetController _controller;

  @override
  void initState() {
    super.initState();
    _controller = getIt<PasswordResetController>();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final success = await _controller.sendResetEmail(email: _emailController.text.trim());
    if (!mounted) {
      return;
    }

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Si el correo existe, recibirás un enlace para restablecer contraseña.'),
        ),
      );
      Navigator.of(context).pop();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_controller.errorMessage ?? 'No se pudo enviar el correo.')),
    );
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      filled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        actions: const [ThemeModeButton()],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: theme.colorScheme.tertiaryContainer,
                              child: Icon(
                                Icons.mark_email_unread_outlined,
                                color: theme.colorScheme.onTertiaryContainer,
                                size: 30,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Restablecer contraseña',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Ingresa tu correo y te enviaremos un enlace de recuperación.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: _fieldDecoration(
                                label: 'Correo',
                                icon: Icons.alternate_email,
                              ),
                              validator: (value) {
                                final email = value?.trim() ?? '';
                                if (email.isEmpty) {
                                  return 'Ingresa tu correo.';
                                }
                                if (!email.contains('@')) {
                                  return 'Correo inválido.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            FilledButton(
                              onPressed: _controller.isLoading ? null : _sendResetLink,
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: _controller.isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text('Enviar enlace'),
                            ),
                            const SizedBox(height: 6),
                            TextButton(
                              onPressed: _controller.isLoading ? null : () => Navigator.of(context).pop(),
                              child: const Text('Volver al inicio de sesión'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}