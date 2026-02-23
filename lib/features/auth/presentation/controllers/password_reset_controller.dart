import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../auth/domain/usecases/send_password_reset_email.dart';

class PasswordResetController extends ChangeNotifier {
  PasswordResetController(this._sendPasswordResetEmail);

  final SendPasswordResetEmail _sendPasswordResetEmail;

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> sendResetEmail({required String email}) async {
    _errorMessage = null;
    _isLoading = true;
    notifyListeners();

    try {
      await _sendPasswordResetEmail(email: email);
      return true;
    } on AppException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = 'No se pudo enviar el correo de restablecimiento.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}