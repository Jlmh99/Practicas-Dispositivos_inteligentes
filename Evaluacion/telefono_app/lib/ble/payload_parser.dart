import 'dart:typed_data';

import 'package:shared_ble/shared_ble.dart';

/// Decodifica los bytes de cada característica GATT del wearable.
///
/// Es un adaptador delgado sobre los codecs de `shared_ble`: existe para que
/// `ble_client.dart` no dependa de los detalles de `SensorPayload` y para
/// tener un lugar propio en `telefono_app` donde probar la decodificación
/// (bytes truncados, etc.) del lado del central. Nunca lanza: ante bytes de
/// longitud incorrecta devuelve `null`.
class PayloadParser {
  const PayloadParser._();

  static int? heartRate(Uint8List bytes) => SensorPayload.decodeHeartRate(bytes);

  static int? sessionSeconds(Uint8List bytes) => SensorPayload.decodeSessionSeconds(bytes);

  static int? moves(Uint8List bytes) => SensorPayload.decodeMoves(bytes);

  static double? focusLevel(Uint8List bytes) => SensorPayload.decodeFocusLevel(bytes);

  static String? activityStatus(Uint8List bytes) => SensorPayload.decodeActivityStatus(bytes);
}
