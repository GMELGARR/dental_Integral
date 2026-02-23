import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/firebase/firebase_initializer.dart';
import '../../features/admin_users/presentation/pages/admin_user_management_page.dart';
import '../../features/auth/presentation/controllers/auth_session_controller.dart';
import '../../features/auth/presentation/pages/auth_loading_page.dart';
import '../../features/auth/presentation/pages/firebase_unavailable_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../di/service_locator.dart';
import '../../features/home/presentation/pages/home_page.dart';

class AppRouter {
  AppRouter();

  FirebaseInitStatus get _firebaseStatus => getIt<FirebaseInitStatus>();
  AuthSessionController get _authSession => getIt<AuthSessionController>();

  late final GoRouter router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: _authSession,
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const AuthLoadingPage(),
      ),
      GoRoute(
        path: '/firebase-unavailable',
        name: 'firebase-unavailable',
        builder: (context, state) => const FirebaseUnavailablePage(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/admin/users',
        name: 'admin-users',
        builder: (context, state) => const AdminUserManagementPage(),
      ),
    ],
    redirect: (context, state) {
      final location = state.matchedLocation;

      if (!_firebaseStatus.isSuccess) {
        return location == '/firebase-unavailable' ? null : '/firebase-unavailable';
      }

      if (!_authSession.isInitialized) {
        return location == '/splash' ? null : '/splash';
      }

      final isAuthRoute = location == '/login' || location == '/forgot-password';

      if (!_authSession.isAuthenticated && !isAuthRoute) {
        return '/login';
      }

      if (location.startsWith('/admin') && !_authSession.isAdmin) {
        return '/';
      }

      if (_authSession.isAuthenticated &&
          (location == '/login' || location == '/forgot-password' || location == '/splash')) {
        return '/';
      }

      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Error de navegación')),
      body: Center(
        child: Text(state.error?.toString() ?? 'Ruta no encontrada'),
      ),
    ),
  );
}