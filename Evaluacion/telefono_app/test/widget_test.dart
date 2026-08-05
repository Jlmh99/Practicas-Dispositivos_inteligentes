import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:telefono_app/main.dart';
import 'package:telefono_app/providers/auth_provider.dart';
import 'package:telefono_app/ui/login_screen.dart';

void main() {
  testWidgets('MyApp muestra LoginScreen cuando no hay sesión', (
    WidgetTester tester,
  ) async {
    // Se sobreescribe authStateProvider para no tocar Firebase real: el
    // widget test no puede inicializar Firebase.initializeApp().
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(null)),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pump();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });
}
