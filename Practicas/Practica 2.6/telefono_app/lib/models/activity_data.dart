import 'package:flutter/material.dart';

class ActivityData {
  final int steps;
  final int heartRate;
  final int calories;
  final String status;
  final DateTime timestamp;

  const ActivityData({
    required this.steps,
    required this.heartRate,
    required this.calories,
    required this.status,
    required this.timestamp,
  });

  ActivityData copyWith({
    int? steps,
    int? heartRate,
    int? calories,
    String? status,
  }) {
    return ActivityData(
      steps: steps ?? this.steps,
      heartRate: heartRate ?? this.heartRate,
      calories: calories ?? this.calories,
      status: status ?? this.status,
      timestamp: DateTime.now(),
    );
  }

  String get heartRateZone {
    if (heartRate < 60) return 'Muy baja';
    if (heartRate < 90) return 'Reposo';
    if (heartRate < 120) return 'Moderada';
    if (heartRate < 150) return 'Alta';
    return 'Máxima';
  }

  Color get heartRateColor {
    if (heartRate < 90) {
      return const Color(0xFF4CAF50);
    }

    if (heartRate < 120) {
      return const Color(0xFFFFC107);
    }

    return const Color(0xFFF44336);
  }
}