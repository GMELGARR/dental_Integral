import '../entities/auth_user.dart';

abstract class AuthRepository {
  Stream<AuthUser?> observeAuthState();
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  });
  Future<void> sendPasswordResetEmail({required String email});
  Future<void> signOut();
}