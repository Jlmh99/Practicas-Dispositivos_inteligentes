import 'dart:async';
import 'dart:typed_data';

import 'package:ble_peripheral/ble_peripheral.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_ble/shared_ble.dart';

/// Periférico GATT con guardas de seguridad para evitar crashes en emuladores
/// o dispositivos sin soporte BLE periférico.
class GattPeripheral {
  GattPeripheral({required this.onComandoControl});

  final void Function(bool iniciar) onComandoControl;

  final _centralConectadoController = StreamController<bool>.broadcast();
  final _erroresController = StreamController<String>.broadcast();

  bool _advertising = false;

  /// Si es falso, no toca ningún método de `ble_peripheral` para evitar el crash nativo.
  bool _hardwareDisponible = true;

  bool get advertising => _advertising;
  Stream<bool> get centralConectado => _centralConectadoController.stream;
  Stream<String> get errores => _erroresController.stream;

  Future<void> iniciar() async {
    // 1. Verificar soporte nativo con un método seguro de solo lectura
    try {
      final isSupported = await BlePeripheral.isSupported();
      if (!isSupported) {
        _hardwareDisponible = false;
        _erroresController.add('Hardware BLE Periférico no soportado (Modo Emulador)');
        return;
      }
    } catch (e) {
      // Si la llamada falla en nativo, bloqueamos el uso del plugin por completo
      _hardwareDisponible = false;
      _erroresController.add('Incapaz de verificar BLE nativo: $e');
      return;
    }

    if (!_hardwareDisponible) return;

    // 2. Si el hardware existe (Dispositivo Físico Wear OS), procede de forma normal
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
      await BlePeripheral.startAdvertising(
        services: [kServiceUuid],
        localName: 'MindGames-Watch',
      );
      _advertising = true;
    } catch (e) {
      _advertising = false;
      _erroresController.add(e.toString());
    }
  }

  Future<void> detener() async {
    if (!_hardwareDisponible) {
      _advertising = false;
      return;
    }

    try {
      await BlePeripheral.stopAdvertising();
    } catch (e) {
      _erroresController.add(e.toString());
    } finally {
      _advertising = false;
    }
  }

  Future<void> notificar(SensorPayload payload) async {
    if (!_advertising || !_hardwareDisponible) return;

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