import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../auth/domain/entities/auth_user.dart';
import '../../../auth/domain/usecases/observe_auth_state.dart';
import '../../../auth/domain/usecases/sign_out.dart';

class AuthSessionController extends ChangeNotifier {
  AuthSessionController.enabled({
    required ObserveAuthState observeAuthState,
    required SignOut signOut,
  }) : _signOut = signOut {
    _subscription = observeAuthState().listen((user) {
      _currentUser = user;
      _isInitialized = true;
      notifyListeners();
    });
  }

  AuthSessionController.disabled()
      : _signOut = null {
    _isInitialized = true;
  }

  final SignOut? _signOut;
  StreamSubscription<AuthUser?>? _subscription;

  bool _isInitialized = false;
  AuthUser? _currentUser;

  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  AuthUser? get currentUser => _currentUser;

  Future<void> signOut() async {
    if (_signOut == null) {
      return;
    }
    await _signOut.call();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}