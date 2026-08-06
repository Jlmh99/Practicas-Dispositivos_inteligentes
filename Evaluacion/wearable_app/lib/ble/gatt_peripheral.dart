import 'dart:async';
import 'dart:typed_data';

import 'package:ble_peripheral/ble_peripheral.dart';
import 'package:shared_ble/shared_ble.dart';

/// Periférico GATT con guardas de seguridad para evitar crashes en emuladores
/// o dispositivos sin soporte BLE periférico.
class GattPeripheral {
  GattPeripheral({required this.onComandoControl, required this.onJuegoSeleccionado});

  final void Function(bool iniciar) onComandoControl;

  /// Llega por CHAR_GAME_SELECT (WRITE) cada vez que el teléfono cambia el
  /// juego elegido — el wearable no tiene otra forma de saberlo.
  final void Function(String juego) onJuegoSeleccionado;

  final _centralConectadoController = StreamController<bool>.broadcast();
  final _erroresController = StreamController<String>.broadcast();

  bool _advertising = false;

  bool get advertising => _advertising;
  Stream<bool> get centralConectado => _centralConectadoController.stream;
  Stream<String> get errores => _erroresController.stream;

  Future<void> iniciar() async {
    // Nota: `BlePeripheral.isSupported()` (que llama a
    // `bluetoothAdapter.isMultipleAdvertisementSupported` en Android) LANZA
    // excepción y reporta "no soportado" en varios emuladores aunque
    // `startAdvertising` sí funcione ahí (confirmado empíricamente). Por eso
    // no se usa como guarda previa: se intenta anunciar directamente y solo
    // se reporta error si `initialize`/`addService`/`startAdvertising`
    // fallan de verdad.
    try {
      await BlePeripheral.initialize();

      BlePeripheral.setAdvertisingStatusUpdateCallback((advertising, error) {
        _advertising = advertising;
        if (error != null) {
          _erroresController.add(error);
        }
      });

      BlePeripheral.setConnectionStateChangeCallback((deviceId, connected) {
        _centralConectadoController.add(connected);
      });

      BlePeripheral.setWriteRequestCallback(_onWriteRequest);

      await BlePeripheral.addService(_construirServicio());
      // Sin `localName`: el paquete de advertising BLE clásico tiene un
      // límite físico de 31 bytes. Nuestro SERVICE_UUID de 128 bits (16
      // bytes) ya ocupa la mayor parte; sumarle "MindGames-Watch" hace que
      // `ble_peripheral` intente meter ambos en el mismo paquete (ver su
      // BlePeripheralPlugin.kt: `setIncludeDeviceName` + `addServiceUuid` en
      // el mismo AdvertiseData.Builder) y falla con
      // ADVERTISE_FAILED_DATA_TOO_LARGE ("Data too large"), confirmado en
      // vivo. `telefono_app` filtra y descubre por SERVICE_UUID, nunca lee
      // el nombre anunciado, así que se prioriza que el UUID quepa.
      await BlePeripheral.startAdvertising(services: [kServiceUuid]);
      _advertising = true;
    } catch (e) {
      _advertising = false;
      _erroresController.add(e.toString());
    }
  }

  Future<void> detener() async {
    try {
      await BlePeripheral.stopAdvertising();
    } catch (e) {
      _erroresController.add(e.toString());
    } finally {
      _advertising = false;
    }
  }

  Future<void> notificar(SensorPayload payload) async {
    if (!_advertising) return;

    try {
      await BlePeripheral.updateCharacteristic(
        characteristicId: kCharHeartRateUuid,
        value: SensorPayload.encodeHeartRate(payload.heartRate),
      );
      await BlePeripheral.updateCharacteristic(
        characteristicId: kCharSessionTimeUuid,
        value: SensorPayload.encodeSessionSeconds(payload.sessionSeconds),
      );
      await BlePeripheral.updateCharacteristic(
        characteristicId: kCharMovesUuid,
        value: SensorPayload.encodeMoves(payload.moves),
      );
      await BlePeripheral.updateCharacteristic(
        characteristicId: kCharFocusUuid,
        value: SensorPayload.encodeFocusLevel(payload.focusLevel),
      );
      await BlePeripheral.updateCharacteristic(
        characteristicId: kCharStatusUuid,
        value: SensorPayload.encodeActivityStatus(payload.activityStatus),
      );
    } catch (e) {
      _erroresController.add(e.toString());
    }
  }

  WriteRequestResult? _onWriteRequest(
    String deviceId,
    String characteristicId,
    int offset,
    Uint8List? value,
  ) {
    if (characteristicId.toUpperCase() == kCharControlUuid.toUpperCase() &&
        value != null &&
        value.isNotEmpty) {
      onComandoControl(value[0] == 0x01);
    } else if (characteristicId.toUpperCase() == kCharGameSelectUuid.toUpperCase() &&
        value != null) {
      final juego = SensorPayload.decodeGameSelect(value);
      if (juego != null) onJuegoSeleccionado(juego);
    }
    return null;
  }

  BleService _construirServicio() {
    return BleService(
      uuid: kServiceUuid,
      primary: true,
      characteristics: [
        _characteristicaNotify(kCharHeartRateUuid),
        _characteristicaNotify(kCharSessionTimeUuid),
        _characteristicaNotify(kCharMovesUuid),
        _characteristicaNotify(kCharFocusUuid),
        _characteristicaNotify(kCharStatusUuid),
        BleCharacteristic(
          uuid: kCharControlUuid,
          properties: [CharacteristicProperties.write.index],
          permissions: [AttributePermissions.writeable.index],
        ),
        BleCharacteristic(
          uuid: kCharGameSelectUuid,
          properties: [CharacteristicProperties.write.index],
          permissions: [AttributePermissions.writeable.index],
        ),
      ],
    );
  }

  BleCharacteristic _characteristicaNotify(String uuid) {
    return BleCharacteristic(
      uuid: uuid,
      properties: [
        CharacteristicProperties.notify.index,
        CharacteristicProperties.read.index,
      ],
      permissions: [AttributePermissions.readable.index],
    );
  }

  void dispose() {
    _centralConectadoController.close();
    _erroresController.close();
  }
}