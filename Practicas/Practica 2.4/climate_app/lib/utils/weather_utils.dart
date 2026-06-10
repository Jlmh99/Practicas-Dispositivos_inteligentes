import 'package:flutter/material.dart';

String formatTemperature(double temp, String unit) {
  return '${temp.toStringAsFixed(1)}°$unit';
}

IconData getWeatherIcon(String condition) {
  switch (condition.toLowerCase()) {
    case 'sunny':
    case 'despejado':
    case 'soleado':
      return Icons.wb_sunny_rounded;
    case 'rainy':
    case 'lluvia':
    case 'lluvioso':
      return Icons.umbrella_rounded;
    case 'cloudy':
    case 'nubes':
    case 'nublado':
      return Icons.cloud_rounded;
    case 'tormenta':
      return Icons.thunderstorm_rounded;
    case 'snowy':
    case 'nieve':
      return Icons.ac_unit_rounded;
    default:
      return Icons.device_thermostat_rounded;
  }
}

class WeatherUtils {
  // Convierte Celsius a Fahrenheit
  static double celsiusToFahrenheit(int celsius) {
    return (celsius * 9 / 5) + 32;
  }

  // Convierte Fahrenheit a Celsius
  static int fahrenheitToCelsius(double fahrenheit) {
    return ((fahrenheit - 32) * 5 / 9).toInt();
  }

  // Obtiene ícono según condición
  static String getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'sunny':
        return '☀️';
      case 'cloudy':
        return '☁️';
      case 'rainy':
        return '🌧️';
      case 'snowy':
        return '❄️';
      default:
        return '🌡️';
    }
  }

  static bool isValidTemperature(int temp) {
    return temp >= -50 && temp <= 60;
  }
}