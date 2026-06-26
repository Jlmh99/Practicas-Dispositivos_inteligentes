import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';

import '../models/weather.dart';
// 1. Importamos el servicio de BLE que creamos antes
import '../services/ble_service.dart';
import '../services/weather_service.dart';

class WeatherNotifier extends StateNotifier<Weather> {
  // Instanciamos el servicio BLE directamente aquí
  final BLEService _bleService = BLEService();
  final WeatherService _weatherService = WeatherService();

  // Variables de control de estado para el flujo BLE (Pasos 11, 12 y 13)
  List<String> discoveredDevices = [];
  bool isScanning = false;
  bool isLoadingConnection = false;
  String bleConnectionStatus = "Sin conexion BLE"; // Inicialización exigida por el paso 13
  //variable para manejar errores de la API
  bool isLoading = false;
  String? error;

  WeatherNotifier()
      : super(
          Weather(
            city: 'Querétaro',
            temp: 24.0,
            condition: 'Despejado',
            description: '',
            unit: 'C',
            humidity: 65,
            windSpeed: 0.0,
          ),
        );

  // Método auxiliar para evitar repetir la reconstrucción de Weather
  // cada vez que solo queremos notificar a la UI sin cambiar datos.
  void refresh() {
    state = Weather(
      city: state.city,
      temp: state.temp,
      condition: state.condition,
      description: state.description,
      unit: state.unit,
      humidity: state.humidity,
      windSpeed: state.windSpeed,
    );
  }

  // --- PASO 10: Método que llama al BLEService para leer datos del wearable ---
  Future<void> connectAndReadWearable(String deviceId) async {
    isLoadingConnection = true;
    bleConnectionStatus = "Vinculando...";
    // Notificamos a la UI actualizando con el mismo estado para que redibuje los loaders
    refresh();

    try {
      // 1. Llamamos al método connect (Paso 7)
      bool isConnected = await _bleService.connect(deviceId);

      if (isConnected) {
        // 2. Descubrimos servicios (Paso 8)
        List<String> services = await _bleService.discoverServices(deviceId);

        if (services.isNotEmpty) {
          // 3. Leemos la característica GATT (Paso 9)
          List<int> rawData = await _bleService.readCharacteristic(
            services.first,
            "00002a2b-0000-1000-8000-00805f9b34fb",
          );

          if (rawData.isNotEmpty) {
            int wearableTemperature = rawData.first;

            // Actualizamos la temperatura del clima con el dato del reloj usando tu lógica existente
            updateTemperature(wearableTemperature);
            
            bleConnectionStatus = "Conectado a $deviceId";
          }
        }
      } else {
        bleConnectionStatus = "Sin conexion BLE";
      }
    } catch (e) {
      print('Error al conectar con wearable: $e');
      bleConnectionStatus = "Sin conexion BLE";
    } finally {
      isLoadingConnection = false;
      // Forzamos actualización para refrescar la UI
      refresh();
    }
  }

  // Método auxiliar para el Paso 11 (Escaneo de la UI)
  Future<void> scanForBluetoothDevices() async {
    isScanning = true;
    discoveredDevices.clear();
    refresh();

    // Escuchamos el stream simulado del Paso 6
    _bleService.scanForDevices().listen((scanResults) {
      for (var result in scanResults) {
        // Obtenemos el nombre del advName que pusimos ("Reloj_Prueba_BLE")
        final name = result.advertisementData.advName.isNotEmpty 
            ? result.advertisementData.advName 
            : result.device.remoteId.str;
        
        if (!discoveredDevices.contains(name)) {
          discoveredDevices.add(name);
        }
      }
      isScanning = false;
      refresh();
    });
  }

  // Método auxiliar para el Paso 13 (Simular Desconexión)
  void disconnectWearable() {
    bleConnectionStatus = "Sin conexion BLE";
    refresh();
  }

  // --- Tus métodos existentes se quedan igual ---
  void updateWeather(Weather newWeather) {
    state = newWeather;
  }

  Future<void> loadWeather(String city) async {
    isLoading = true;
    error = null;

    refresh();

    try {
      final weather = await _weatherService.getWeather(city);
      // conservar la unidad elegida por el usuario
      state = Weather(city: weather.city,temp: weather.temp,
        condition: weather.condition,description: weather.description,
        unit: state.unit,humidity: weather.humidity,windSpeed: weather.windSpeed,
      );

    } catch (e) {
      error = e.toString().replaceFirst("Exception: ", "");
    } finally {

      isLoading = false;

      refresh();
    }
  }

  void toggleTemperatureUnit() {
    final isCurrentCelsius = state.unit == 'C';
    final nextUnit = isCurrentCelsius ? 'F' : 'C';
    double nextTemp;

    if (isCurrentCelsius) {
      nextTemp = (state.temp * 9 / 5) + 32;
    } else {
      nextTemp = (state.temp - 32) * 5 / 9;
    }

    state = Weather(
      city: state.city,
      temp: nextTemp,
      condition: state.condition,
      description: state.description,
      unit: nextUnit,
      humidity: state.humidity,
      windSpeed: state.windSpeed,
    );
  }

  void updateTemperature(int newTemp) {
    state = Weather(
      city: state.city,
      temp: newTemp.toDouble(), 
      condition: state.condition,
      description: state.description,
      unit: state.unit,
      humidity: state.humidity,
      windSpeed: state.windSpeed,
    );
  }
}

final weatherProvider = StateNotifierProvider<WeatherNotifier, Weather>((ref) {
  return WeatherNotifier();
});