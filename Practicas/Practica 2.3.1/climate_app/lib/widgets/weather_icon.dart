import 'package:flutter/material.dart';

class WeatherIcon extends StatelessWidget {
  final String condition;
  final double size;
  final Color? color;

  const WeatherIcon({
    Key? key,
    required this.condition,
    this.size = 80,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    IconData iconData;
    Color iconColor = color ?? Colors.blue;

    switch (condition.toLowerCase()) {
      case 'sunny':
      case 'clear':
        iconData = Icons.wb_sunny;
        if (color == null) iconColor = Colors.orange;
        break;
      case 'rainy':
        iconData = Icons.umbrella;
        break;
      case 'cloudy':
      case 'cloud':
      default:
        iconData = Icons.cloud;
        break;
    }

    return Icon(
      iconData,
      size: size,
      color: iconColor,
    );
  }
}