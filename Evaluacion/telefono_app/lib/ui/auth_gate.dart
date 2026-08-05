import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import 'colores.dart';
import 'login_screen.dart';
import 'permission_gate.dart';
import 'two_factor_screen.dart';

/// Router declarativo de la app, según `(authState, verificacionCompletada)`:
/// sin sesión -> LoginScreen; con sesión pero sin 2FA verificado en esta
/// apertura -> TwoFactorScreen; con todo listo -> PermissionGate (BLE) ->
/// HomeScreen.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (usuario) {
        if (usuario == null) return const LoginScreen();
        final verificado = ref.watch(verificacionCompletadaProvider);
        return verificado ? const PermissionGate() : const TwoFactorScreen();
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: kAzulPrimario)),
      ),
      error: (error, _) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Error de autenticación: $error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: kRojoError),
            ),
          ),
        ),
      ),
    );
  }
}
