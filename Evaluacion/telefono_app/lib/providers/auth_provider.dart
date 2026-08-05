import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());

/// Enrutado: `null` = sin sesión, `User` = con sesión (pendiente o no de 2FA).
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// Solo `true` cuando el código de 2FA ya se verificó en esta apertura de la
/// app. Vive en memoria (no persiste) y se reinicia solo a `false` cada vez
/// que `authStateProvider` emite un usuario distinto (nuevo login/registro),
/// así que cada apertura de la app vuelve a pedir el código aunque Firebase
/// mantenga la sesión activa — es una verificación de sesión, no de MFA.
class VerificacionCompletadaNotifier extends Notifier<bool> {
  @override
  bool build() {
    ref.watch(authStateProvider);
    return false;
  }

  void marcarCompletada() => state = true;
}

final verificacionCompletadaProvider =
    NotifierProvider<VerificacionCompletadaNotifier, bool>(VerificacionCompletadaNotifier.new);
