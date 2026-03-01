import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/errors/error_reporter.dart';
import '../../core/firebase/firebase_initializer.dart';
import '../../core/theme/theme_controller.dart';
import '../../features/admin_users/data/datasources/user_management_firestore_data_source.dart';
import '../../features/admin_users/data/repositories/user_management_repository_impl.dart';
import '../../features/admin_users/domain/repositories/user_management_repository.dart';
import '../../features/admin_users/domain/usecases/create_staff_user.dart';
import '../../features/admin_users/domain/usecases/observe_managed_users.dart';
import '../../features/admin_users/domain/usecases/update_user_access.dart';
import '../../features/admin_users/presentation/controllers/user_management_controller.dart';
import '../../features/odontologists/data/datasources/odontologist_firestore_data_source.dart';
import '../../features/odontologists/data/repositories/odontologist_repository_impl.dart';
import '../../features/odontologists/domain/repositories/odontologist_repository.dart';
import '../../features/odontologists/domain/usecases/create_odontologist.dart';
import '../../features/odontologists/domain/usecases/link_odontologist_user.dart';
import '../../features/odontologists/domain/usecases/observe_odontologists.dart';
import '../../features/odontologists/domain/usecases/update_odontologist.dart';
import '../../features/odontologists/presentation/controllers/odontologist_controller.dart';
import '../../features/treatments/data/datasources/treatment_firestore_data_source.dart';
import '../../features/treatments/data/repositories/treatment_repository_impl.dart';
import '../../features/treatments/domain/repositories/treatment_repository.dart';
import '../../features/treatments/domain/usecases/create_treatment.dart';
import '../../features/treatments/domain/usecases/observe_treatments.dart';
import '../../features/treatments/domain/usecases/update_treatment.dart';
import '../../features/treatments/presentation/controllers/treatment_controller.dart';
import '../../features/inventory/data/datasources/inventory_firestore_data_source.dart';
import '../../features/inventory/data/repositories/inventory_repository_impl.dart';
import '../../features/inventory/domain/repositories/inventory_repository.dart';
import '../../features/inventory/domain/usecases/adjust_stock.dart';
import '../../features/inventory/domain/usecases/create_inventory_item.dart';
import '../../features/inventory/domain/usecases/observe_inventory.dart';
import '../../features/inventory/domain/usecases/update_inventory_item.dart';
import '../../features/inventory/presentation/controllers/inventory_controller.dart';
import '../../features/patients/data/datasources/patient_firestore_data_source.dart';
import '../../features/patients/data/repositories/patient_repository_impl.dart';
import '../../features/patients/domain/repositories/patient_repository.dart';
import '../../features/patients/domain/usecases/create_patient.dart';
import '../../features/patients/domain/usecases/observe_patients.dart';
import '../../features/patients/domain/usecases/update_patient.dart';
import '../../features/patients/presentation/controllers/patient_controller.dart';
import '../../features/appointments/data/datasources/appointment_firestore_data_source.dart';
import '../../features/appointments/data/repositories/appointment_repository_impl.dart';
import '../../features/appointments/domain/repositories/appointment_repository.dart';
import '../../features/appointments/domain/usecases/create_appointment.dart';
import '../../features/appointments/domain/usecases/observe_appointments.dart';
import '../../features/appointments/domain/usecases/update_appointment.dart';
import '../../features/appointments/presentation/controllers/appointment_controller.dart';
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

  if (!getIt.isRegistered<ThemeController>()) {
    final themeController = await ThemeController.create();
    getIt.registerSingleton<ThemeController>(themeController);
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

    if (!getIt.isRegistered<FirebaseFirestore>()) {
      getIt.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
    }

    if (!getIt.isRegistered<FirebaseAuthDataSource>()) {
      getIt.registerLazySingleton<FirebaseAuthDataSource>(
        () => FirebaseAuthDataSource(
          getIt<FirebaseAuth>(),
          getIt<FirebaseFirestore>(),
        ),
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

    if (!getIt.isRegistered<UserManagementFirestoreDataSource>()) {
      getIt.registerLazySingleton<UserManagementFirestoreDataSource>(
        () => UserManagementFirestoreDataSource(getIt<FirebaseFirestore>()),
      );
    }

    if (!getIt.isRegistered<UserManagementRepository>()) {
      getIt.registerLazySingleton<UserManagementRepository>(
        () => UserManagementRepositoryImpl(getIt<UserManagementFirestoreDataSource>()),
      );
    }

    if (!getIt.isRegistered<ObserveManagedUsers>()) {
      getIt.registerLazySingleton<ObserveManagedUsers>(
        () => ObserveManagedUsers(getIt<UserManagementRepository>()),
      );
    }

    if (!getIt.isRegistered<UpdateUserAccess>()) {
      getIt.registerLazySingleton<UpdateUserAccess>(
        () => UpdateUserAccess(getIt<UserManagementRepository>()),
      );
    }

    if (!getIt.isRegistered<CreateStaffUser>()) {
      getIt.registerLazySingleton<CreateStaffUser>(
        () => CreateStaffUser(getIt<UserManagementRepository>()),
      );
    }

    if (!getIt.isRegistered<UserManagementController>()) {
      getIt.registerFactory<UserManagementController>(
        () => UserManagementController(
          observeManagedUsers: getIt<ObserveManagedUsers>(),
          updateUserAccess: getIt<UpdateUserAccess>(),
          createStaffUser: getIt<CreateStaffUser>(),
        ),
      );
    }

    // ── Odontologists ──────────────────────────────────────────
    if (!getIt.isRegistered<OdontologistFirestoreDataSource>()) {
      getIt.registerLazySingleton<OdontologistFirestoreDataSource>(
        () => OdontologistFirestoreDataSource(getIt<FirebaseFirestore>()),
      );
    }

    if (!getIt.isRegistered<OdontologistRepository>()) {
      getIt.registerLazySingleton<OdontologistRepository>(
        () => OdontologistRepositoryImpl(getIt<OdontologistFirestoreDataSource>()),
      );
    }

    if (!getIt.isRegistered<ObserveOdontologists>()) {
      getIt.registerLazySingleton<ObserveOdontologists>(
        () => ObserveOdontologists(getIt<OdontologistRepository>()),
      );
    }

    if (!getIt.isRegistered<CreateOdontologist>()) {
      getIt.registerLazySingleton<CreateOdontologist>(
        () => CreateOdontologist(getIt<OdontologistRepository>()),
      );
    }

    if (!getIt.isRegistered<UpdateOdontologist>()) {
      getIt.registerLazySingleton<UpdateOdontologist>(
        () => UpdateOdontologist(getIt<OdontologistRepository>()),
      );
    }

    if (!getIt.isRegistered<LinkOdontologistUser>()) {
      getIt.registerLazySingleton<LinkOdontologistUser>(
        () => LinkOdontologistUser(getIt<OdontologistRepository>()),
      );
    }

    if (!getIt.isRegistered<OdontologistController>()) {
      getIt.registerFactory<OdontologistController>(
        () => OdontologistController(
          observeOdontologists: getIt<ObserveOdontologists>(),
          createOdontologist: getIt<CreateOdontologist>(),
          updateOdontologist: getIt<UpdateOdontologist>(),
          linkOdontologistUser: getIt<LinkOdontologistUser>(),
        ),
      );
    }

    // ── Treatments ─────────────────────────────────────────────
    if (!getIt.isRegistered<TreatmentFirestoreDataSource>()) {
      getIt.registerLazySingleton<TreatmentFirestoreDataSource>(
        () => TreatmentFirestoreDataSource(getIt<FirebaseFirestore>()),
      );
    }

    if (!getIt.isRegistered<TreatmentRepository>()) {
      getIt.registerLazySingleton<TreatmentRepository>(
        () => TreatmentRepositoryImpl(getIt<TreatmentFirestoreDataSource>()),
      );
    }

    if (!getIt.isRegistered<ObserveTreatments>()) {
      getIt.registerLazySingleton<ObserveTreatments>(
        () => ObserveTreatments(getIt<TreatmentRepository>()),
      );
    }

    if (!getIt.isRegistered<CreateTreatment>()) {
      getIt.registerLazySingleton<CreateTreatment>(
        () => CreateTreatment(getIt<TreatmentRepository>()),
      );
    }

    if (!getIt.isRegistered<UpdateTreatment>()) {
      getIt.registerLazySingleton<UpdateTreatment>(
        () => UpdateTreatment(getIt<TreatmentRepository>()),
      );
    }

    if (!getIt.isRegistered<TreatmentController>()) {
      getIt.registerFactory<TreatmentController>(
        () => TreatmentController(
          observeTreatments: getIt<ObserveTreatments>(),
          createTreatment: getIt<CreateTreatment>(),
          updateTreatment: getIt<UpdateTreatment>(),
        ),
      );
    }

    // ── Inventory ──────────────────────────────────────────────
    if (!getIt.isRegistered<InventoryFirestoreDataSource>()) {
      getIt.registerLazySingleton<InventoryFirestoreDataSource>(
        () => InventoryFirestoreDataSource(getIt<FirebaseFirestore>()),
      );
    }

    if (!getIt.isRegistered<InventoryRepository>()) {
      getIt.registerLazySingleton<InventoryRepository>(
        () => InventoryRepositoryImpl(getIt<InventoryFirestoreDataSource>()),
      );
    }

    if (!getIt.isRegistered<ObserveInventory>()) {
      getIt.registerLazySingleton<ObserveInventory>(
        () => ObserveInventory(getIt<InventoryRepository>()),
      );
    }

    if (!getIt.isRegistered<CreateInventoryItem>()) {
      getIt.registerLazySingleton<CreateInventoryItem>(
        () => CreateInventoryItem(getIt<InventoryRepository>()),
      );
    }

    if (!getIt.isRegistered<UpdateInventoryItem>()) {
      getIt.registerLazySingleton<UpdateInventoryItem>(
        () => UpdateInventoryItem(getIt<InventoryRepository>()),
      );
    }

    if (!getIt.isRegistered<AdjustStock>()) {
      getIt.registerLazySingleton<AdjustStock>(
        () => AdjustStock(getIt<InventoryRepository>()),
      );
    }

    if (!getIt.isRegistered<InventoryController>()) {
      getIt.registerFactory<InventoryController>(
        () => InventoryController(
          observeInventory: getIt<ObserveInventory>(),
          createInventoryItem: getIt<CreateInventoryItem>(),
          updateInventoryItem: getIt<UpdateInventoryItem>(),
          adjustStock: getIt<AdjustStock>(),
        ),
      );
    }

    // ── Patients ─────────────────────────────────────────────────
    if (!getIt.isRegistered<PatientFirestoreDataSource>()) {
      getIt.registerLazySingleton<PatientFirestoreDataSource>(
        () => PatientFirestoreDataSource(getIt<FirebaseFirestore>()),
      );
    }

    if (!getIt.isRegistered<PatientRepository>()) {
      getIt.registerLazySingleton<PatientRepository>(
        () => PatientRepositoryImpl(getIt<PatientFirestoreDataSource>()),
      );
    }

    if (!getIt.isRegistered<ObservePatients>()) {
      getIt.registerLazySingleton<ObservePatients>(
        () => ObservePatients(getIt<PatientRepository>()),
      );
    }

    if (!getIt.isRegistered<CreatePatient>()) {
      getIt.registerLazySingleton<CreatePatient>(
        () => CreatePatient(getIt<PatientRepository>()),
      );
    }

    if (!getIt.isRegistered<UpdatePatient>()) {
      getIt.registerLazySingleton<UpdatePatient>(
        () => UpdatePatient(getIt<PatientRepository>()),
      );
    }

    if (!getIt.isRegistered<PatientController>()) {
      getIt.registerFactory<PatientController>(
        () => PatientController(
          observePatients: getIt<ObservePatients>(),
          createPatient: getIt<CreatePatient>(),
          updatePatient: getIt<UpdatePatient>(),
        ),
      );
    }

    // ── Appointments ─────────────────────────────────────────────
    if (!getIt.isRegistered<AppointmentFirestoreDataSource>()) {
      getIt.registerLazySingleton<AppointmentFirestoreDataSource>(
        () => AppointmentFirestoreDataSource(getIt<FirebaseFirestore>()),
      );
    }

    if (!getIt.isRegistered<AppointmentRepository>()) {
      getIt.registerLazySingleton<AppointmentRepository>(
        () => AppointmentRepositoryImpl(getIt<AppointmentFirestoreDataSource>()),
      );
    }

    if (!getIt.isRegistered<ObserveAppointments>()) {
      getIt.registerLazySingleton<ObserveAppointments>(
        () => ObserveAppointments(getIt<AppointmentRepository>()),
      );
    }

    if (!getIt.isRegistered<CreateAppointment>()) {
      getIt.registerLazySingleton<CreateAppointment>(
        () => CreateAppointment(getIt<AppointmentRepository>()),
      );
    }

    if (!getIt.isRegistered<UpdateAppointment>()) {
      getIt.registerLazySingleton<UpdateAppointment>(
        () => UpdateAppointment(getIt<AppointmentRepository>()),
      );
    }

    if (!getIt.isRegistered<AppointmentController>()) {
      getIt.registerFactory<AppointmentController>(
        () => AppointmentController(
          observeAppointments: getIt<ObserveAppointments>(),
          createAppointment: getIt<CreateAppointment>(),
          updateAppointment: getIt<UpdateAppointment>(),
          repository: getIt<AppointmentRepository>(),
        ),
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