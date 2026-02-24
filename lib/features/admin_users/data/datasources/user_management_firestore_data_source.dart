import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../firebase_options.dart';
import '../../domain/entities/managed_user.dart';
import '../../domain/entities/module_permission.dart';

class UserManagementFirestoreDataSource {
  UserManagementFirestoreDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  Stream<List<ManagedUser>> observeUsers() {
    return _firestore.collection('users').orderBy('displayName').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        final modulesRaw = (data['modules'] as List<dynamic>? ?? <dynamic>[])
            .map((entry) => entry.toString())
            .toList();

        final modules = modulesRaw
            .map(modulePermissionFromKey)
            .whereType<ModulePermission>()
            .toList(growable: false);

        return ManagedUser(
          uid: doc.id,
          email: (data['email'] as String?) ?? '',
          displayName: (data['displayName'] as String?) ?? 'Sin nombre',
          role: (data['role'] as String?) ?? 'staff',
          active: (data['active'] as bool?) ?? true,
          modules: modules,
        );
      }).toList(growable: false);
    });
  }

  Future<void> updateUserAccess({
    required String uid,
    required bool active,
    required String role,
    required List<ModulePermission> modules,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'active': active,
        'role': role,
        'modules': modules.map((module) => module.key).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      throw AppException('No se pudo actualizar el acceso del usuario.', cause: error);
    }
  }

  /// Creates a new Firebase Auth user **without** affecting the current admin
  /// session by spinning up a short-lived secondary [FirebaseApp].
  ///
  /// After successful Auth creation, a Firestore profile document is written
  /// under `users/{uid}`.
  Future<void> createUser({
    required String email,
    required String password,
    required String displayName,
    required String role,
    required List<ModulePermission> modules,
  }) async {
    FirebaseApp? secondaryApp;

    try {
      // 1. Init a temporary secondary app with the same project config.
      secondaryApp = await Firebase.initializeApp(
        name: 'userCreation_${DateTime.now().millisecondsSinceEpoch}',
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // 2. Create the user via the secondary app's Auth instance.
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;

      // 3. Update display name on the Auth profile.
      await credential.user!.updateDisplayName(displayName);

      // 4. Sign out from the secondary instance (admin session untouched).
      await secondaryAuth.signOut();

      // 5. Write the Firestore user profile (uses the primary instance).
      await _firestore.collection('users').doc(uid).set({
        'email': email,
        'displayName': displayName,
        'role': role,
        'active': true,
        'modules': modules.map((m) => m.key).toList(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseAuthException catch (error) {
      throw AppException(
        _mapCreateUserError(error.code),
        code: error.code,
        cause: error,
      );
    } catch (error) {
      throw AppException('No se pudo crear el usuario.', cause: error);
    } finally {
      // Always clean up the temporary app.
      await secondaryApp?.delete();
    }
  }

  String _mapCreateUserError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Ya existe una cuenta con este correo electrónico.';
      case 'invalid-email':
        return 'El correo electrónico no es válido.';
      case 'weak-password':
        return 'La contraseña es demasiado débil (mínimo 6 caracteres).';
      case 'operation-not-allowed':
        return 'La creación de cuentas está deshabilitada.';
      default:
        return 'No se pudo crear el usuario.';
    }
  }
}