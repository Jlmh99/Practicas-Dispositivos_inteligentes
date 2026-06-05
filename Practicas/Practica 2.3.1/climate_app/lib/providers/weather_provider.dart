import 'package:flutter_riverpod/legacy.dart';

import '../models/weather.dart';

class WeatherNotifier extends StateNotifier<Weather> {
  WeatherNotifier()
      : super(
          Weather(
            city: 'Querétaro',
            temp: 24.0,
            condition: 'Despejado',
            unit: 'C',
            humidity: 65,
          ),
        );

  void updateWeather(Weather newWeather) {
    state = newWeather;
  }

  Future<void> loadWeather(String city) async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      state = Weather(
        city: city,
        temp: 24.0,
        condition: 'cloudy',
        unit: state.unit, 
        humidity: 65,
      );
    } catch (e) {
      print('Error loading weather: $e');
    }
  }
    void toggleTemperatureUnit() {
      final isCurrentCelsius = state.unit == 'C';
      final nextUnit = isCurrentCelsius ? 'F' : 'C';
      double nextTemp;

      if (isCurrentCelsius) {
        // De Celsius a Fahrenheit: (C * 9 / 5) + 32
        nextTemp = (state.temp * 9 / 5) + 32;
      } else {
        // De Fahrenheit a Celsius: (F - 32) * 5 / 9
        nextTemp = (state.temp - 32) * 5 / 9;
      }

      // Actualizamos el estado con la nueva temperatura calculada y la nueva unidad
      state = Weather(
        city: state.city,
        temp: nextTemp,
        condition: state.condition,
        unit: nextUnit,
        humidity: state.humidity,
      );
    }

  void updateTemperature(int newTemp) {
    state = Weather(
      city: state.city,
      temp: newTemp.toDouble(), 
      condition: state.condition,
      unit: state.unit,
      humidity: state.humidity,
    );
  }
}

final weatherProvider = StateNotifierProvider<WeatherNotifier, Weather>((ref) {
  return WeatherNotifier();
});