import 'package:firebase_core/firebase_core.dart';

import '../../firebase_options.dart';

class FirebaseInitStatus {
  const FirebaseInitStatus._({
    required this.isSuccess,
    this.error,
    this.stackTrace,
  });

  final bool isSuccess;
  final Object? error;
  final StackTrace? stackTrace;

  factory FirebaseInitStatus.success() {
    return const FirebaseInitStatus._(isSuccess: true);
  }

  factory FirebaseInitStatus.failure(Object error, StackTrace stackTrace) {
    return FirebaseInitStatus._(
      isSuccess: false,
      error: error,
      stackTrace: stackTrace,
    );
  }
}

class FirebaseInitializer {
  Future<FirebaseInitStatus> initialize() async {
    if (Firebase.apps.isNotEmpty) {
      return FirebaseInitStatus.success();
    }

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      return FirebaseInitStatus.success();
    } catch (error, stackTrace) {
      return FirebaseInitStatus.failure(error, stackTrace);
    }
  }
}