import 'dart:async';
import 'dart:math';

import 'package:shared_ble/shared_ble.dart';

/// Simula los sensores de una sesión de juego en el wearable.
///
/// Emite un [SensorPayload] cada segundo mientras está corriendo. Los valores
/// no son aleatorios puros: se correlacionan entre sí para parecer una sesión
/// real (fatiga progresiva, ritmo cardiaco que reacciona a la concentración
/// y a los movimientos, etc.).
class SensorSimulator {
  SensorSimulator({Random? random}) : _random = random ?? Random();

  final Random _random;
  Timer? _timer;

  bool _running = false;
  bool get running => _running;

  String _juego = 'SUDOKU';

  int _sessionSeconds = 0;
  int _moves = 0;
  double _focusLevel = 70;
  double _focusVelocity = 0;
  double _heartRate = 70;
  int _lastMoveSessionSecond = 0;

  final _controller = StreamController<SensorPayload>.broadcast();

  /// Emite un nuevo [SensorPayload] en cada tick del simulador (1 s).
  Stream<SensorPayload> get stream => _controller.stream;

  /// Último payload calculado, útil para pintar la UI antes del primer tick.
  SensorPayload get ultimo => SensorPayload(
        heartRate: _heartRate.round().clamp(60, 130),
        sessionSeconds: _sessionSeconds,
        moves: _moves,
        focusLevel: _focusLevel.clamp(0, 100),
        activityStatus: _activityStatus(),
      );

  /// Cambia el juego reportado en `activityStatus`. Emite de inmediato (no
  /// espera al próximo tick de 1 s) para que la pantalla del wearable
  /// refleje la elección del teléfono sin retraso perceptible.
  void setJuego(String juego) {
    _juego = juego;
    _emit();
  }

  /// Inicia (o reanuda) la generación de datos cada segundo.
  void start() {
    if (_running) return;
    _running = true;
    _lastMoveSessionSecond = _sessionSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    _emit();
  }

  /// Detiene la generación de datos sin perder los contadores acumulados.
  void stop() {
    if (!_running) return;
    _running = false;
    _timer?.cancel();
    _timer = null;
    _emit();
  }

  /// Reinicia todos los contadores a su estado inicial. Detiene el simulador
  /// si estaba corriendo; hay que llamar a [start] de nuevo para reanudar.
  void reset() {
    stop();
    _sessionSeconds = 0;
    _moves = 0;
    _focusLevel = 70;
    _focusVelocity = 0;
    _heartRate = 70;
    _lastMoveSessionSecond = 0;
    _emit();
  }

  void dispose() {
    _timer?.cancel();
    _controller.close();
  }

  void _tick() {
    _sessionSeconds += 1;

    // moves: 0-3 por tick, más probable cuando la concentración es alta.
    final movesChance = (_focusLevel / 100) * 4;
    final movesThisTick = min(3, max(0, (_random.nextDouble() * movesChance).floor()));
    _moves += movesThisTick;
    if (movesThisTick > 0) {
      _lastMoveSessionSecond = _sessionSeconds;
    }

    // focusLevel: random walk con inercia (velocidad amortiguada) más una
    // deriva hacia abajo que crece con la duración de la sesión (fatiga).
    _focusVelocity += (_random.nextDouble() - 0.5) * 1.2;
    _focusVelocity *= 0.85;
    final fatiga = min(_sessionSeconds / 600, 1) * 0.15;
    _focusLevel = (_focusLevel + _focusVelocity - fatiga).clamp(0, 100);

    // heartRate: se acerca gradualmente a un objetivo que sube con la
    // concentración y con los movimientos recientes.
    final objetivo = 60 + (_focusLevel / 100) * 40 + movesThisTick * 5;
    _heartRate = (_heartRate + (objetivo - _heartRate) * 0.3).clamp(60, 130);

    _emit();
  }

  String _activityStatus() {
    if (!_running) return 'PAUSA';
    final segundosSinMoverse = _sessionSeconds - _lastMoveSessionSecond;
    if (segundosSinMoverse >= 30) return 'INACTIVO';
    return 'JUGANDO:$_juego';
  }

  void _emit() {
    if (_controller.isClosed) return;
    _controller.add(ultimo);
  }
}
