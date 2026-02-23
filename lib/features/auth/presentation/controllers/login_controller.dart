import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../auth/domain/usecases/sign_in_with_email_password.dart';

class LoginController extends ChangeNotifier {
  LoginController(this._signInWithEmailPassword);

  final SignInWithEmailPassword _signInWithEmailPassword;

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> signIn({required String email, required String password}) async {
    _errorMessage = null;
    _isLoading = true;
    notifyListeners();

    try {
      await _signInWithEmailPassword(email: email, password: password);
      return true;
    } on AppException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = 'No se pudo iniciar sesión.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}