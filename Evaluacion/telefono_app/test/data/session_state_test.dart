import 'package:flutter_test/flutter_test.dart';
import 'package:telefono_app/data/models/session_state.dart';

SessionState _crear({
  String? gameId = 'sudoku',
  int heartRate = 85,
  int sessionSeconds = 120,
  int moves = 5,
  double focusLevel = 70,
  String activityStatus = 'JUGANDO:SUDOKU',
  bool alertaActiva = false,
}) {
  return SessionState(
    gameId: gameId,
    heartRate: heartRate,
    sessionSeconds: sessionSeconds,
    moves: moves,
    focusLevel: focusLevel,
    activityStatus: activityStatus,
    alertaActiva: alertaActiva,
    actualizadoEn: DateTime(2026, 1, 1, 12),
  );
}

void main() {
  group('SessionState round-trip', () {
    test('toFirestore/fromFirestore preserva los campos', () {
      final original = _crear();
      final reconstruido = SessionState.fromFirestore(original.toFirestore());

      expect(reconstruido.gameId, original.gameId);
      expect(reconstruido.heartRate, original.heartRate);
      expect(reconstruido.sessionSeconds, original.sessionSeconds);
      expect(reconstruido.moves, original.moves);
      expect(reconstruido.focusLevel, original.focusLevel);
      expect(reconstruido.activityStatus, original.activityStatus);
      expect(reconstruido.alertaActiva, original.alertaActiva);
    });
  });

  group('SessionState.tieneMismosDatosQue (debounce del sync)', () {
    test('true si solo cambia actualizadoEn', () {
      final a = _crear();
      final b = SessionState(
        gameId: a.gameId,
        heartRate: a.heartRate,
        sessionSeconds: a.sessionSeconds,
        moves: a.moves,
        focusLevel: a.focusLevel,
        activityStatus: a.activityStatus,
        alertaActiva: a.alertaActiva,
        actualizadoEn: DateTime(2030),
      );

      expect(a.tieneMismosDatosQue(b), isTrue);
    });

    test('false si cambia una métrica', () {
      final a = _crear(heartRate: 85);
      final b = _crear(heartRate: 86);

      expect(a.tieneMismosDatosQue(b), isFalse);
    });
  });
}
