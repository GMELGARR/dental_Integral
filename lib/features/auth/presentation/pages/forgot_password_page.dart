import 'package:flutter/material.dart';

import '../../../../app/di/service_locator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/glass_card.dart';
import '../controllers/password_reset_controller.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  late final PasswordResetController _controller;
  late final AnimationController _animController;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _controller = getIt<PasswordResetController>();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    if (!_formKey.currentState!.validate()) return;

    final success =
        await _controller.sendResetEmail(email: _emailController.text.trim());
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Si el correo existe, recibirás un enlace para restablecer tu contraseña.',
          ),
        ),
      );
      Navigator.of(context).pop();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _controller.errorMessage ?? 'No se pudo enviar el correo.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // ── Gradient bg ───────────────────────────────────
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: isDark
                    ? AppColors.darkGradient
                    : AppColors.primaryGradient,
              ),
            ),
          ),

          // ── Decorative ────────────────────────────────────
          Positioned(top: -40, left: -30, child: _circle(140, 0.06)),
          Positioned(bottom: 60, right: -20, child: _circle(100, 0.05)),

          // ── Back button ───────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            child: SafeArea(
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
            ),
          ),

          // ── Content ───────────────────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: AppSpacing.pagePadding,
                child: FadeTransition(
                  opacity: _fadeIn,
                  child: SlideTransition(
                    position: _slideUp,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icon
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.lock_reset_rounded,
                            size: 36,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Recuperar contraseña',
                          style: theme.textTheme.headlineLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Te enviaremos un enlace de recuperación\na tu correo electrónico',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxxl),

                        AnimatedBuilder(
                          animation: _controller,
                          builder: (context, _) {
                            return GlassCard(
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    TextFormField(
                                      controller: _emailController,
                                      keyboardType:
                                          TextInputType.emailAddress,
                                      decoration: const InputDecoration(
                                        labelText: 'Correo electrónico',
                                        prefixIcon:
                                            Icon(Icons.alternate_email),
                                      ),
                                      validator: (v) {
                                        final email = v?.trim() ?? '';
                                        if (email.isEmpty) {
                                          return 'Ingresa tu correo.';
                                        }
                                        if (!email.contains('@')) {
                                          return 'Correo inválido.';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: AppSpacing.xl),
                                    SizedBox(
                                      height: 52,
                                      child: FilledButton(
                                        onPressed: _controller.isLoading
                                            ? null
                                            : _sendResetLink,
                                        child: _controller.isLoading
                                            ? const SizedBox(
                                                height: 22,
                                                width: 22,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2.5,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : const Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.send_rounded,
                                                    size: 18,
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text('Enviar enlace'),
                                                ],
                                              ),
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    TextButton.icon(
                                      onPressed: _controller.isLoading
                                          ? null
                                          : () => Navigator.of(context).pop(),
                                      icon: const Icon(
                                        Icons.arrow_back_rounded,
                                        size: 16,
                                      ),
                                      label: const Text(
                                        'Volver al inicio de sesión',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circle(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}