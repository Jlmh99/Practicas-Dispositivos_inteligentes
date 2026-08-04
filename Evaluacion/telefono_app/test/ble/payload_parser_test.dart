import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ble/shared_ble.dart';
import 'package:telefono_app/ble/payload_parser.dart';

void main() {
  group('PayloadParser.heartRate (int)', () {
    test('decodifica bytes válidos', () {
      final bytes = SensorPayload.encodeHeartRate(85);
      expect(PayloadParser.heartRate(bytes), 85);
    });

    test('bytes truncados devuelven null', () {
      expect(PayloadParser.heartRate(Uint8List(0)), isNull);
    });
  });

  group('PayloadParser.sessionSeconds (int)', () {
    test('decodifica bytes válidos', () {
      final bytes = SensorPayload.encodeSessionSeconds(1800);
      expect(PayloadParser.sessionSeconds(bytes), 1800);
    });

    test('bytes truncados devuelven null', () {
      expect(PayloadParser.sessionSeconds(Uint8List(2)), isNull);
    });
  });

  group('PayloadParser.moves (int)', () {
    test('decodifica bytes válidos', () {
      final bytes = SensorPayload.encodeMoves(412);
      expect(PayloadParser.moves(bytes), 412);
    });

    test('bytes truncados devuelven null', () {
      expect(PayloadParser.moves(Uint8List(1)), isNull);
    });
  });

  group('PayloadParser.focusLevel (float)', () {
    test('decodifica bytes válidos', () {
      final bytes = SensorPayload.encodeFocusLevel(73.5);
      expect(PayloadParser.focusLevel(bytes), closeTo(73.5, 0.001));
    });

    test('bytes truncados devuelven null', () {
      expect(PayloadParser.focusLevel(Uint8List(3)), isNull);
    });
  });

  group('PayloadParser.activityStatus (string)', () {
    test('decodifica bytes válidos', () {
      final bytes = SensorPayload.encodeActivityStatus('JUGANDO:SUDOKU');
      expect(PayloadParser.activityStatus(bytes), 'JUGANDO:SUDOKU');
    });

    test('bytes UTF-8 inválidos devuelven null', () {
      final invalidos = Uint8List.fromList([0xFF, 0xFE, 0xFD]);
      expect(PayloadParser.activityStatus(invalidos), isNull);
    });
  });
}
