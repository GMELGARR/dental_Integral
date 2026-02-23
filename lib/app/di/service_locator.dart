import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/errors/error_reporter.dart';
import '../../core/firebase/firebase_initializer.dart';
import '../../features/auth/data/datasources/firebase_auth_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/observe_auth_state.dart';
import '../../features/auth/domain/usecases/send_password_reset_email.dart';
import '../../features/auth/domain/usecases/sign_in_with_email_password.dart';
import '../../features/auth/domain/usecases/sign_out.dart';
import '../../features/auth/presentation/controllers/auth_session_controller.dart';
import '../../features/auth/presentation/controllers/login_controller.dart';
import '../../features/auth/presentation/controllers/password_reset_controller.dart';
import '../router/app_router.dart';

final getIt = GetIt.instance;

Future<void> setupDependencies() async {
  if (!getIt.isRegistered<AppErrorReporter>()) {
    getIt.registerLazySingleton<AppErrorReporter>(() => AppErrorReporter.instance);
  }

  if (!getIt.isRegistered<FirebaseInitializer>()) {
    getIt.registerLazySingleton<FirebaseInitializer>(FirebaseInitializer.new);
  }

  if (!getIt.isRegistered<FirebaseInitStatus>()) {
    final firebaseInitStatus = await getIt<FirebaseInitializer>().initialize();
    getIt.registerSingleton<FirebaseInitStatus>(firebaseInitStatus);
  }

  final firebaseStatus = getIt<FirebaseInitStatus>();

  if (firebaseStatus.isSuccess) {
    if (!getIt.isRegistered<FirebaseAuth>()) {
      getIt.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
    }

    if (!getIt.isRegistered<FirebaseAuthDataSource>()) {
      getIt.registerLazySingleton<FirebaseAuthDataSource>(
        () => FirebaseAuthDataSource(getIt<FirebaseAuth>()),
      );
    }

    if (!getIt.isRegistered<AuthRepository>()) {
      getIt.registerLazySingleton<AuthRepository>(
        () => AuthRepositoryImpl(getIt<FirebaseAuthDataSource>()),
      );
    }

    if (!getIt.isRegistered<ObserveAuthState>()) {
      getIt.registerLazySingleton<ObserveAuthState>(
        () => ObserveAuthState(getIt<AuthRepository>()),
      );
    }

    if (!getIt.isRegistered<SignInWithEmailPassword>()) {
      getIt.registerFactory<SignInWithEmailPassword>(
        () => SignInWithEmailPassword(getIt<AuthRepository>()),
      );
    }

    if (!getIt.isRegistered<SendPasswordResetEmail>()) {
      getIt.registerFactory<SendPasswordResetEmail>(
        () => SendPasswordResetEmail(getIt<AuthRepository>()),
      );
    }

    if (!getIt.isRegistered<SignOut>()) {
      getIt.registerLazySingleton<SignOut>(
        () => SignOut(getIt<AuthRepository>()),
      );
    }

    if (!getIt.isRegistered<AuthSessionController>()) {
      getIt.registerSingleton<AuthSessionController>(
        AuthSessionController.enabled(
          observeAuthState: getIt<ObserveAuthState>(),
          signOut: getIt<SignOut>(),
        ),
      );
    }

    if (!getIt.isRegistered<LoginController>()) {
      getIt.registerFactory<LoginController>(
        () => LoginController(getIt<SignInWithEmailPassword>()),
      );
    }

    if (!getIt.isRegistered<PasswordResetController>()) {
      getIt.registerFactory<PasswordResetController>(
        () => PasswordResetController(getIt<SendPasswordResetEmail>()),
      );
    }
  } else {
    if (!getIt.isRegistered<AuthSessionController>()) {
      getIt.registerSingleton<AuthSessionController>(AuthSessionController.disabled());
    }
  }

  if (!getIt.isRegistered<AppRouter>()) {
    getIt.registerLazySingleton<AppRouter>(AppRouter.new);
  }
}