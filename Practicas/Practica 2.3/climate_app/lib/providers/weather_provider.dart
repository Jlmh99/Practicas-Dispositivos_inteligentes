import 'package:flutter_riverpod/legacy.dart';

import '../models/weather.dart';

class WeatherNotifier extends StateNotifier<Weather> {
  WeatherNotifier() : super(Weather(
    city: 'Querétaro',
    temp: 24.0,
    condition: 'Despejado',
    unit: 'C',
  ));

  // Método para actualizar el estado por uno nuevo
  void updateWeather(Weather newWeather) {
    state = newWeather;
  }
}

final weatherProvider = StateNotifierProvider<WeatherNotifier, Weather>((ref) {
  return WeatherNotifier();
});