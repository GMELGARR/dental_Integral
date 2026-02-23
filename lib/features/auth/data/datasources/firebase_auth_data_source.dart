import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/auth_user.dart';

class FirebaseAuthDataSource {
  FirebaseAuthDataSource(this._firebaseAuth);

  final FirebaseAuth _firebaseAuth;

  Stream<AuthUser?> observeAuthState() {
    return _firebaseAuth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) {
        return null;
      }

      final idTokenResult = await firebaseUser.getIdTokenResult();
      final role = idTokenResult.claims?['role'] as String?;

      return AuthUser(
        id: firebaseUser.uid,
        email: firebaseUser.email,
        isAdmin: role == 'admin',
      );
    });
  }

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      throw AppException(
        _mapAuthErrorCodeToMessage(error.code),
        code: error.code,
        cause: error,
      );
    } catch (error) {
      throw AppException('No se pudo iniciar sesión.', cause: error);
    }
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (error) {
      throw AppException(
        _mapAuthErrorCodeToMessage(error.code),
        code: error.code,
        cause: error,
      );
    } catch (error) {
      throw AppException('No se pudo enviar el correo de restablecimiento.', cause: error);
    }
  }

  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (error) {
      throw AppException('No se pudo cerrar sesión.', cause: error);
    }
  }

  String _mapAuthErrorCodeToMessage(String code) {
    switch (code) {
      case 'invalid-email':
        return 'El correo no tiene un formato válido.';
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Correo o contraseña incorrectos.';
      case 'user-disabled':
        return 'Tu cuenta está deshabilitada. Contacta al administrador.';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta nuevamente en unos minutos.';
      case 'network-request-failed':
        return 'Sin conexión. Revisa tu internet e intenta de nuevo.';
      default:
        return 'Ocurrió un error de autenticación.';
    }
  }
}