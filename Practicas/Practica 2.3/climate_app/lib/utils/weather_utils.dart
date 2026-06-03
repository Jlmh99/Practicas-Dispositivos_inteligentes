import 'package:flutter/material.dart';

String formatTemperature(double temp, String unit) {
  // .toStringAsFixed(1) asegura que solo muestre un decimal
  return '${temp.toStringAsFixed(1)}°$unit';
}

IconData getWeatherIcon(String condition) {
  // Convertimos a minúsculas para evitar errores si viene como "Despejado" o "DESPEJADO"
  switch (condition.toLowerCase()) {
    case 'despejado':
    case 'soleado':
      return Icons.wb_sunny_rounded;
    case 'lluvia':
    case 'lluvioso':
      return Icons.umbrella_rounded;
    case 'nubes':
    case 'nublado':
      return Icons.cloud_rounded;
    case 'tormenta':
      return Icons.thunderstorm_rounded;
    case 'nieve':
      return Icons.ac_unit_rounded;
    default:
      // Un ícono neutral por si el estado no coincide con ninguno de los anteriores
      return Icons.device_thermostat_rounded;
  }
}