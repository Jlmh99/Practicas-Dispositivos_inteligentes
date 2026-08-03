import 'dart:convert';
import 'dart:typed_data';

/// Datos de una sesión de juego capturados por el wearable.
///
/// Los métodos `encode*`/`decode*` son estáticos y operan por característica
/// (un valor a la vez), reflejando que cada característica GATT se notifica
/// por separado. `decode*` nunca lanza: ante bytes de longitud incorrecta
/// devuelve `null` para que el llamador pueda ignorar la notificación corrupta.
class SensorPayload {
  const SensorPayload({
    required this.heartRate,
    required this.sessionSeconds,
    required this.moves,
    required this.focusLevel,
    required this.activityStatus,
  });

  final int heartRate;
  final int sessionSeconds;
  final int moves;
  final double focusLevel;
  final String activityStatus;

  /// CHAR_HEART_RATE — uint8, 60-130 bpm.
  static Uint8List encodeHeartRate(int bpm) {
    final bytes = ByteData(1)..setUint8(0, bpm);
    return bytes.buffer.asUint8List();
  }

  static int? decodeHeartRate(Uint8List bytes) {
    if (bytes.length != 1) return null;
    return ByteData.sublistView(bytes).getUint8(0);
  }

  /// CHAR_SESSION_TIME — uint32 LE, segundos.
  static Uint8List encodeSessionSeconds(int seconds) {
    final bytes = ByteData(4)..setUint32(0, seconds, Endian.little);
    return bytes.buffer.asUint8List();
  }

  static int? decodeSessionSeconds(Uint8List bytes) {
    if (bytes.length != 4) return null;
    return ByteData.sublistView(bytes).getUint32(0, Endian.little);
  }

  /// CHAR_MOVES — uint16 LE.
  static Uint8List encodeMoves(int moves) {
    final bytes = ByteData(2)..setUint16(0, moves, Endian.little);
    return bytes.buffer.asUint8List();
  }

  static int? decodeMoves(Uint8List bytes) {
    if (bytes.length != 2) return null;
    return ByteData.sublistView(bytes).getUint16(0, Endian.little);
  }

  /// CHAR_FOCUS — float32 LE, 0.0-100.0.
  static Uint8List encodeFocusLevel(double level) {
    final bytes = ByteData(4)..setFloat32(0, level, Endian.little);
    return bytes.buffer.asUint8List();
  }

  static double? decodeFocusLevel(Uint8List bytes) {
    if (bytes.length != 4) return null;
    return ByteData.sublistView(bytes).getFloat32(0, Endian.little);
  }

  /// CHAR_STATUS — UTF-8, ej. "JUGANDO:SUDOKU" | "PAUSA" | "INACTIVO".
  static Uint8List encodeActivityStatus(String status) {
    return Uint8List.fromList(utf8.encode(status));
  }

  static String? decodeActivityStatus(Uint8List bytes) {
    try {
      return utf8.decode(bytes);
    } on FormatException {
      return null;
    }
  }
}
