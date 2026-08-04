import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/notificaciones_service.dart';
import 'ble_provider.dart';

/// Umbrales de alerta (fuente de verdad: CLAUDE.md).
const int kUmbralSessionSeconds = 1800;
const int kUmbralHeartRate = 120;
const double kUmbralFocusLevelBajo = 30;

const int kHistorialMaximo = 60;

enum TipoAlerta { tiempoProlongado, ritmoCardiacoElevado, concentracionBaja }

class Alerta {
  const Alerta(this.tipo, this.mensaje);

  final TipoAlerta tipo;
  final String mensaje;

  @override
  bool operator ==(Object other) =>
      other is Alerta && other.tipo == tipo && other.mensaje == mensaje;

  @override
  int get hashCode => Object.hash(tipo, mensaje);
}

/// Estado acumulado de la sesión: valores actuales, histórico (máx. 60
/// puntos por métrica) y alertas activas según los umbrales.
class ActivityState {
  const ActivityState({
    required this.heartRate,
    required this.sessionSeconds,
    required this.moves,
    required this.focusLevel,
    required this.activityStatus,
    required this.heartRateHistorial,
    required this.sessionSecondsHistorial,
    required this.movesHistorial,
    required this.focusLevelHistorial,
    required this.alertasActivas,
    required this.umbralPrincipalNotificado,
  });

  factory ActivityState.inicial() => const ActivityState(
        heartRate: 0,
        sessionSeconds: 0,
        moves: 0,
        focusLevel: 0,
        activityStatus: 'INACTIVO',
        heartRateHistorial: [],
        sessionSecondsHistorial: [],
        movesHistorial: [],
        focusLevelHistorial: [],
        alertasActivas: [],
        umbralPrincipalNotificado: false,
      );

  final int heartRate;
  final int sessionSeconds;
  final int moves;
  final double focusLevel;
  final String activityStatus;

  final List<int> heartRateHistorial;
  final List<int> sessionSecondsHistorial;
  final List<int> movesHistorial;
  final List<double> focusLevelHistorial;

  final List<Alerta> alertasActivas;

  /// Evita relanzar la notificación del umbral principal en cada tick: solo
  /// la primera vez que se cruza `kUmbralSessionSeconds` en la sesión.
  final bool umbralPrincipalNotificado;

  ActivityState copyWith({
    int? heartRate,
    int? sessionSeconds,
    int? moves,
    double? focusLevel,
    String? activityStatus,
    List<int>? heartRateHistorial,
    List<int>? sessionSecondsHistorial,
    List<int>? movesHistorial,
    List<double>? focusLevelHistorial,
    List<Alerta>? alertasActivas,
    bool? umbralPrincipalNotificado,
  }) {
    return ActivityState(
      heartRate: heartRate ?? this.heartRate,
      sessionSeconds: sessionSeconds ?? this.sessionSeconds,
      moves: moves ?? this.moves,
      focusLevel: focusLevel ?? this.focusLevel,
      activityStatus: activityStatus ?? this.activityStatus,
      heartRateHistorial: heartRateHistorial ?? this.heartRateHistorial,
      sessionSecondsHistorial: sessionSecondsHistorial ?? this.sessionSecondsHistorial,
      movesHistorial: movesHistorial ?? this.movesHistorial,
      focusLevelHistorial: focusLevelHistorial ?? this.focusLevelHistorial,
      alertasActivas: alertasActivas ?? this.alertasActivas,
      umbralPrincipalNotificado: umbralPrincipalNotificado ?? this.umbralPrincipalNotificado,
    );
  }
}

List<T> _conLimite<T>(List<T> historial, T nuevo) {
  final actualizado = [...historial, nuevo];
  if (actualizado.length <= kHistorialMaximo) return actualizado;
  return actualizado.sublist(actualizado.length - kHistorialMaximo);
}

/// Acumula las métricas que llegan por BLE, mantiene su histórico y evalúa
/// los umbrales de alerta de CLAUDE.md en cada actualización.
class ActivityNotifier extends Notifier<ActivityState> {
  final List<StreamSubscription> _subs = [];

  @override
  ActivityState build() {
    final client = ref.watch(bleClientProvider);

    _subs.add(client.heartRate.listen(_onHeartRate));
    _subs.add(client.sessionSeconds.listen(_onSessionSeconds));
    _subs.add(client.moves.listen(_onMoves));
    _subs.add(client.focusLevel.listen(_onFocusLevel));
    _subs.add(client.activityStatus.listen(_onActivityStatus));

    ref.onDispose(() {
      for (final sub in _subs) {
        sub.cancel();
      }
    });

    return ActivityState.inicial();
  }

  void _onHeartRate(int valor) {
    state = state.copyWith(
      heartRate: valor,
      heartRateHistorial: _conLimite(state.heartRateHistorial, valor),
    );
    _evaluarUmbrales();
  }

  void _onSessionSeconds(int valor) {
    state = state.copyWith(
      sessionSeconds: valor,
      sessionSecondsHistorial: _conLimite(state.sessionSecondsHistorial, valor),
    );
    _evaluarUmbrales();
  }

  void _onMoves(int valor) {
    state = state.copyWith(
      moves: valor,
      movesHistorial: _conLimite(state.movesHistorial, valor),
    );
  }

  void _onFocusLevel(double valor) {
    state = state.copyWith(
      focusLevel: valor,
      focusLevelHistorial: _conLimite(state.focusLevelHistorial, valor),
    );
    _evaluarUmbrales();
  }

  void _onActivityStatus(String valor) {
    state = state.copyWith(activityStatus: valor);
  }

  void _evaluarUmbrales() {
    final alertas = <Alerta>[];
    final principalActivo = state.sessionSeconds > kUmbralSessionSeconds;

    if (principalActivo) {
      alertas.add(
        const Alerta(
          TipoAlerta.tiempoProlongado,
          'Tiempo de juego prolongado, toma un descanso',
        ),
      );
    }
    if (state.heartRate > kUmbralHeartRate) {
      alertas.add(const Alerta(TipoAlerta.ritmoCardiacoElevado, 'Ritmo cardiaco elevado'));
    }
    if (state.focusLevel < kUmbralFocusLevelBajo) {
      alertas.add(const Alerta(TipoAlerta.concentracionBaja, 'Concentración baja'));
    }

    state = state.copyWith(alertasActivas: alertas);

    if (principalActivo && !state.umbralPrincipalNotificado) {
      state = state.copyWith(umbralPrincipalNotificado: true);
      unawaited(NotificacionesService.instancia.mostrarAlertaTiempoProlongado());
    }
  }

  /// Salta `sessionSeconds` a 1795 para poder demostrar la alerta del umbral
  /// principal en la demo sin esperar 30 minutos reales: el wearable sigue
  /// incrementando +1/s, así que cruza los 1800 a los pocos segundos.
  void debugForzarUmbral() {
    state = state.copyWith(sessionSeconds: 1795);
    _evaluarUmbrales();
  }
}

final activityProvider = NotifierProvider<ActivityNotifier, ActivityState>(ActivityNotifier.new);
