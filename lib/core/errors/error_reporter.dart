import 'dart:developer';

import 'package:flutter/foundation.dart';

class AppErrorReporter {
  AppErrorReporter._();

  static final AppErrorReporter instance = AppErrorReporter._();

  void recordFlutterError(FlutterErrorDetails details) {
    recordError(details.exception, details.stack);
  }

  void recordError(Object error, StackTrace? stackTrace) {
    log(
      'Unhandled app error',
      error: error,
      stackTrace: stackTrace,
      name: 'AppErrorReporter',
    );
  }
}