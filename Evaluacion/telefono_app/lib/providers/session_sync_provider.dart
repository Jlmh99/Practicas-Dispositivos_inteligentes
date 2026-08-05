import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/session_state.dart';
import 'activity_provider.dart';
import 'auth_provider.dart';
import 'firestore_provider.dart';

// juegoSeleccionadoProvider vive en firestore_provider.dart.

class SessionSyncState {
  const SessionSyncState({this.ultimaSincronizacion});

  final DateTime? ultimaSincronizacion;

  SessionSyncState copyWith({DateTime? ultimaSincronizacion}) =>
      SessionSyncState(ultimaSincronizacion: ultimaSincronizacion ?? this.ultimaSincronizacion);
}

/// Cada 2 s toma el estado de [activityProvider] y lo publica en
/// `sessionState/{uid}`. Con debounce (no escribe si nada cambió, para
/// ahorrar cuota del plan gratuito) y reintento silencioso si falla — el
/// siguiente tick de 2 s lo vuelve a intentar solo.
class SessionSyncNotifier extends Notifier<SessionSyncState> {
  Timer? _timer;
  SessionState? _ultimoPublicado;

  @override
  SessionSyncState build() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _sincronizar());
    ref.onDispose(() => _timer?.cancel());
    return const SessionSyncState();
  }

  Future<void> _sincronizar() async {
    final usuario = ref.read(authStateProvider).value;
    if (usuario == null) return;

    final actividad = ref.read(activityProvider);
    final gameId = ref.read(juegoSeleccionadoProvider);

    final actual = SessionState(
      gameId: gameId,
      heartRate: actividad.heartRate,
      sessionSeconds: actividad.sessionSeconds,
      moves: actividad.moves,
      focusLevel: actividad.focusLevel,
      activityStatus: actividad.activityStatus,
      alertaActiva: actividad.sessionSeconds > kUmbralSessionSeconds,
      actualizadoEn: DateTime.now(),
    );

    if (_ultimoPublicado != null && actual.tieneMismosDatosQue(_ultimoPublicado!)) {
      return; // Debounce: nada cambió, no gastamos cuota.
    }

    try {
      await ref.read(firestoreRepositoryProvider).publicarEstadoSesion(usuario.uid, actual);
      _ultimoPublicado = actual;
      state = state.copyWith(ultimaSincronizacion: DateTime.now());
    } catch (_) {
      // Reintento silencioso: el próximo tick de 2 s lo vuelve a intentar.
    }
  }
}

final sessionSyncProvider =
    NotifierProvider<SessionSyncNotifier, SessionSyncState>(SessionSyncNotifier.new);
