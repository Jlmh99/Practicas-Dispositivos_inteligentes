import 'package:flutter/material.dart';

import 'weather_icon.dart';

class TemperatureCard extends StatelessWidget {
  final String day;
  final String temperature;
  final String condition;

  const TemperatureCard({
    Key? key,
    required this.day,
    required this.temperature,
    required this.condition,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          day,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          temperature,
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 8),
        WeatherIcon(
          condition: condition,
          size: 32,
        ),
      ],
    );
  }
}