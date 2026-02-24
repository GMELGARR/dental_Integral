import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/service_locator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/widgets/dental_logo.dart';
import '../../../../core/widgets/glass_card.dart';
import '../controllers/login_controller.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late final LoginController _loginController;
  late final AnimationController _animController;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loginController = getIt<LoginController>();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.15),
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
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await _loginController.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted || success) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _loginController.errorMessage ?? 'No se pudo iniciar sesión.',
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
          // ── Full background gradient ──────────────────────
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: isDark
                    ? AppColors.darkGradient
                    : AppColors.primaryGradient,
              ),
            ),
          ),

          // ── Decorative circles ────────────────────────────
          Positioned(
            top: -60,
            right: -40,
            child: _decorCircle(200, 0.07),
          ),
          Positioned(
            top: 100,
            left: -50,
            child: _decorCircle(120, 0.05),
          ),
          Positioned(
            bottom: -30,
            right: 40,
            child: _decorCircle(90, 0.04),
          ),
          Positioned(
            bottom: 80,
            left: 20,
            child: _decorCircle(50, 0.06),
          ),

          // ── Theme toggle ──────────────────────────────────
          Positioned(
            top: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(right: 8, top: 4),
                child: IconButton(
                  onPressed: () {
                    getIt<ThemeController>().toggleLightDark();
                  },
                  icon: Icon(
                    isDark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ),
          ),

          // ── Main content ──────────────────────────────────
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
                        // ── Logo ────────────────────────────
                        const DentalLogo(size: 68, light: true),
                        const SizedBox(height: 10),
                        Text(
                          'Gestión clínica dental inteligente',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxxl),

                        // ── Login card ─────────────────────
                        AnimatedBuilder(
                          animation: _loginController,
                          builder: (context, _) {
                            return GlassCard(
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      'Iniciar sesión',
                                      style: theme.textTheme.headlineMedium,
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      'Ingresa tus credenciales para continuar',
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                    const SizedBox(height: AppSpacing.xxl),

                                    // Email
                                    TextFormField(
                                      controller: _emailController,
                                      keyboardType:
                                          TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
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
                                    const SizedBox(height: AppSpacing.lg),

                                    // Password
                                    TextFormField(
                                      controller: _passwordController,
                                      obscureText: _obscurePassword,
                                      textInputAction: TextInputAction.done,
                                      onFieldSubmitted: (_) => _submit(),
                                      decoration: InputDecoration(
                                        labelText: 'Contraseña',
                                        prefixIcon:
                                            const Icon(Icons.lock_outline),
                                        suffixIcon: IconButton(
                                          onPressed: () => setState(() =>
                                              _obscurePassword =
                                                  !_obscurePassword),
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_outlined
                                                : Icons
                                                    .visibility_off_outlined,
                                          ),
                                        ),
                                      ),
                                      validator: (v) {
                                        if ((v ?? '').isEmpty) {
                                          return 'Ingresa tu contraseña.';
                                        }
                                        return null;
                                      },
                                    ),

                                    // Forgot password link
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: _loginController.isLoading
                                            ? null
                                            : () =>
                                                context.push('/forgot-password'),
                                        child: const Text(
                                            '¿Olvidaste tu contraseña?'),
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.sm),

                                    // Submit button
                                    SizedBox(
                                      height: 52,
                                      child: FilledButton(
                                        onPressed: _loginController.isLoading
                                            ? null
                                            : _submit,
                                        child: _loginController.isLoading
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
                                                  Text('Ingresar'),
                                                  SizedBox(width: 8),
                                                  Icon(
                                                    Icons
                                                        .arrow_forward_rounded,
                                                    size: 18,
                                                  ),
                                                ],
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: AppSpacing.xxl),
                        Text(
                          '© 2026 Dental Integral',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 12,
                          ),
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

  Widget _decorCircle(double size, double opacity) {
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