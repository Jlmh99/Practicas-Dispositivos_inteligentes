import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../models/weather.dart';
import '../utils/text_styles.dart';

class WeatherCard extends StatelessWidget {
  final Weather weather;
  final bool isFocused;
  final VoidCallback? onTap;

  const WeatherCard({
    super.key,
    required this.weather,
    this.isFocused = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),

      transform: Matrix4.identity()
        ..scale(isFocused ? 1.02 : 1.0),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isFocused
              ? AppTheme.focusColor
              : Colors.white.withValues(alpha: 0.15),
          width: isFocused ? 3 : 2,
        ),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: AppTheme.focusColor.withValues(alpha: 0.35),
                  blurRadius: 20,
                  spreadRadius: 3,
                )
              ]
            : null,
      ),

      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,

        child: Padding(
          padding: const EdgeInsets.all(20),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                weather.city,
                style: TVTextStyles.city,
              ),
              const SizedBox(height: 12),
              Text(
                "${weather.temperature}°C",
                style: TVTextStyles.temperature,
              ),
              const SizedBox(height: 8),
              Text(
                weather.description,
                style: TVTextStyles.condition,
              ),
              const SizedBox(height: 12),
              Text(
                "Humedad: ${weather.humidity}%"
                "   |   "
                "Viento: ${weather.windSpeed.toStringAsFixed(1)} m/s",
                style: TVTextStyles.details,
              ),
            ],
          ),
        ),
      ),
    );
  }
}