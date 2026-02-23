// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:tema_oscuro/app/app.dart';
import 'package:tema_oscuro/app/di/service_locator.dart';
import 'package:tema_oscuro/core/firebase/firebase_initializer.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await setupDependencies();
  });

  testWidgets('App routes according to Firebase/Auth state', (WidgetTester tester) async {
    await tester.pumpWidget(const DentalIntegralApp());
    await tester.pumpAndSettle();

    final status = getIt<FirebaseInitStatus>();

    if (status.isSuccess) {
      expect(find.text('Iniciar sesión'), findsOneWidget);
      expect(find.text('Dental Integral'), findsOneWidget);
    } else {
      expect(find.text('Configurar Firebase'), findsOneWidget);
      expect(
        find.text('Firebase todavía no está configurado para este proyecto.'),
        findsOneWidget,
      );
    }
  });
}
