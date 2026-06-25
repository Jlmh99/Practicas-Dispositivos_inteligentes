import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BLEService {
  StreamController<List<ScanResult>>? _scanResultController;

  BLEService();

  // Paso 6: Método scanForDevices() corregido para la versión 1.31.0
  Stream<List<ScanResult>> scanForDevices() {
    _scanResultController?.close();
    _scanResultController = StreamController<List<ScanResult>>.broadcast();

    Timer(const Duration(seconds: 2), () {
      if (_scanResultController != null && !_scanResultController!.isClosed) {
        
        // 1. Usamos DeviceIdentifier en lugar de DeviceId
        final mockDevice = BluetoothDevice(
          remoteId: const DeviceIdentifier("00:11:22:33:44:55"),
        );

        // 2. Ajustamos AdvertisementData usando advName en lugar de localName
        final mockScanResult = ScanResult(
          device: mockDevice,
          advertisementData: AdvertisementData(
            advName: "Reloj_Prueba_BLE", 
            txPowerLevel: -60,
            connectable: true,
            serviceUuids: const [], // Si quieres puedes dejar const en las listas vacías, o quitarlo por completo
            serviceData: const {},
            manufacturerData: const {}, appearance: null,
          ),
          rssi: -60,
          timeStamp: DateTime.now(),
        );

        _scanResultController?.add([mockScanResult]);
      }
    });

    return _scanResultController!.stream;
  }

  // Paso 7: Implementar el método connect(deviceId) adaptado para emulador
  Future<bool> connect(String deviceId) async {
    // Simulamos un retraso de 2 segundos para representar el proceso de handshake/conexión BLE
    await Future.delayed(const Duration(seconds: 2));
    return true;
  }

  // Paso 8: Adaptación para descubrir servicios sin usar el constructor restringido
  // Devolvemos un mapa con los UUIDs simulados para que tu Provider los consuma fácilmente
  Future<List<String>> discoverServices(String deviceId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Retornamos el UUID del servicio que simula los datos del reloj
    return ["0000180a-0000-1000-8000-00805f9b34fb"];
  }

  // Paso 9: Busca una característica específica (UUID) y lee su valor simulado
  Future<List<int>> readCharacteristic(String serviceUuid, String characteristicUuid) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Simulamos bytes de respuesta GATT. Por ejemplo, el entero 24 (una temperatura de 24°C para tu clima)
    // Representado en una lista de enteros (bytes) como pide el estándar BLE
    return [24];
  }
}