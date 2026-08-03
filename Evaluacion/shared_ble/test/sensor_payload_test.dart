import 'dart:typed_data';

import 'package:shared_ble/sensor_payload.dart';
import 'package:test/test.dart';

void main() {
  group('heartRate (uint8)', () {
    test('round-trip', () {
      final bytes = SensorPayload.encodeHeartRate(85);
      expect(SensorPayload.decodeHeartRate(bytes), 85);
    });

    test('bytes corruptos devuelven null', () {
      expect(SensorPayload.decodeHeartRate(Uint8List(0)), isNull);
      expect(SensorPayload.decodeHeartRate(Uint8List(2)), isNull);
    });
  });

  group('sessionSeconds (uint32 LE)', () {
    test('round-trip', () {
      final bytes = SensorPayload.encodeSessionSeconds(1800);
      expect(SensorPayload.decodeSessionSeconds(bytes), 1800);
    });

    test('bytes corruptos devuelven null', () {
      expect(SensorPayload.decodeSessionSeconds(Uint8List(3)), isNull);
      expect(SensorPayload.decodeSessionSeconds(Uint8List(5)), isNull);
    });
  });

  group('moves (uint16 LE)', () {
    test('round-trip', () {
      final bytes = SensorPayload.encodeMoves(412);
      expect(SensorPayload.decodeMoves(bytes), 412);
    });

    test('bytes corruptos devuelven null', () {
      expect(SensorPayload.decodeMoves(Uint8List(1)), isNull);
      expect(SensorPayload.decodeMoves(Uint8List(3)), isNull);
    });
  });

  group('focusLevel (float32 LE)', () {
    test('round-trip', () {
      final bytes = SensorPayload.encodeFocusLevel(73.5);
      expect(SensorPayload.decodeFocusLevel(bytes), closeTo(73.5, 0.001));
    });

    test('bytes corruptos devuelven null', () {
      expect(SensorPayload.decodeFocusLevel(Uint8List(3)), isNull);
      expect(SensorPayload.decodeFocusLevel(Uint8List(5)), isNull);
    });
  });

  group('activityStatus (UTF-8)', () {
    test('round-trip', () {
      final bytes = SensorPayload.encodeActivityStatus('JUGANDO:SUDOKU');
      expect(SensorPayload.decodeActivityStatus(bytes), 'JUGANDO:SUDOKU');
    });

    test('bytes UTF-8 inválidos devuelven null', () {
      final invalid = Uint8List.fromList([0xFF, 0xFE, 0xFD]);
      expect(SensorPayload.decodeActivityStatus(invalid), isNull);
    });
  });

  group('SensorPayload', () {
    test('constructor guarda todos los campos', () {
      const payload = SensorPayload(
        heartRate: 85,
        sessionSeconds: 1800,
        moves: 412,
        focusLevel: 73.5,
        activityStatus: 'JUGANDO:SUDOKU',
      );
      expect(payload.heartRate, 85);
      expect(payload.sessionSeconds, 1800);
      expect(payload.moves, 412);
      expect(payload.focusLevel, 73.5);
      expect(payload.activityStatus, 'JUGANDO:SUDOKU');
    });
  });
}
