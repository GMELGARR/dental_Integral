import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'di/service_locator.dart';
import '../core/errors/error_reporter.dart';

Future<void> bootstrap() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('es');

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      AppErrorReporter.instance.recordFlutterError(details);
    };

    PlatformDispatcher.instance.onError = (error, stackTrace) {
      AppErrorReporter.instance.recordError(error, stackTrace);
      return true;
    };

    ErrorWidget.builder = (details) {
      return Material(
        child: Center(
          child: Text('Ocurrió un error inesperado: ${details.exceptionAsString()}'),
        ),
      );
    };

    await setupDependencies();
    runApp(const DentalIntegralApp());
  },
    AppErrorReporter.instance.recordError,
  );
}