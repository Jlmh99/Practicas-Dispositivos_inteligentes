import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wearable_app/main.dart';

void main() {
  testWidgets('MindGamesWatchApp arranca y muestra el gate de permisos', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MindGamesWatchApp());
    await tester.pump();

    expect(find.byType(PermissionGate), findsOneWidget);
    // Mientras se resuelven los permisos (async), se muestra un loader.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
