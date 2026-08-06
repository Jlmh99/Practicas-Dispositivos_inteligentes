/// Contrato BLE de Mind Games: UUIDs del servicio GATT y sus características.
///
/// Fuente de verdad única — wearable_app (periférico) y telefono_app (central)
/// deben importar estas constantes en lugar de declarar sus propios UUIDs.
library;

/// UUID del servicio GATT que expone el wearable.
const String kServiceUuid = '6d696e64-0001-1000-8000-00805f9b34fb';

/// UUID de la característica de ritmo cardiaco (NOTIFY, uint8, 60-130 bpm).
const String kCharHeartRateUuid = '6d696e64-0002-1000-8000-00805f9b34fb';

/// UUID de la característica de tiempo de sesión (NOTIFY, uint32 LE, segundos).
const String kCharSessionTimeUuid = '6d696e64-0003-1000-8000-00805f9b34fb';

/// UUID de la característica de movimientos (NOTIFY, uint16 LE).
const String kCharMovesUuid = '6d696e64-0004-1000-8000-00805f9b34fb';

/// UUID de la característica de nivel de concentración (NOTIFY, float32 LE, 0.0-100.0).
const String kCharFocusUuid = '6d696e64-0005-1000-8000-00805f9b34fb';

/// UUID de la característica de estado de actividad (NOTIFY, UTF-8).
const String kCharStatusUuid = '6d696e64-0006-1000-8000-00805f9b34fb';

/// UUID de la característica de control (WRITE, 0x01 iniciar / 0x00 detener).
const String kCharControlUuid = '6d696e64-0007-1000-8000-00805f9b34fb';

/// UUID de la característica de selección de juego (WRITE, UTF-8, ej.
/// "CRUCIGRAMA"). El wearable no tiene forma de saber qué juego se eligió
/// en el teléfono por ningún otro medio — CHAR_CONTROL es solo iniciar/
/// detener — así que el teléfono escribe aquí cada vez que el usuario elige
/// un juego, y el wearable usa ese valor para el sufijo de CHAR_STATUS
/// (`"JUGANDO:<lo último escrito aquí>"`).
const String kCharGameSelectUuid = '6d696e64-0008-1000-8000-00805f9b34fb';

/// Identifica cada característica del contrato BLE junto con su UUID.
enum CharacteristicType {
  heartRate(kCharHeartRateUuid),
  sessionTime(kCharSessionTimeUuid),
  moves(kCharMovesUuid),
  focus(kCharFocusUuid),
  status(kCharStatusUuid),
  control(kCharControlUuid),
  gameSelect(kCharGameSelectUuid);

  const CharacteristicType(this.uuid);

  /// UUID GATT asociado a esta característica.
  final String uuid;
}
