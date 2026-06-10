class Weather {
  final String city;
  final double temp; 
  final String condition;
  final String unit; 
  final int humidity; 

  // Constructor actualizado
  Weather({
    required this.city,
    required this.temp,
    required this.condition,
    required this.unit,
    required this.humidity,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    if (!json.containsKey('main')) {
      throw const FormatException('Missing main field in weather data');
    }
    final tempValue = json['main']['temp'];
    if (tempValue is! num) {
      throw const FormatException('Temperature must be number');
    }
    return Weather(
      city: json['name'] ?? 'Unknown',
      temp: tempValue.toDouble(), // Lo convertimos a tu double seguro
      condition: (json['weather'] as List?)?.isNotEmpty == true
          ? json['weather'][0]['main'] ?? 'unknown'
          : 'unknown',
      unit: 'C', // Tu unidad por defecto
      humidity: json['main']['humidity'] ?? 0,
    );
  }

  // Convertir Weather a JSON usando tus variables
  Map<String, dynamic> toJson() => {
        'city': city,
        'temperature': temp.toInt(),
        'condition': condition,
        'humidity': humidity,
      };

  @override
  String toString() {
    return 'Weather(city: $city, temp: ${temp.toInt()}°C, condition: $condition, humidity: $humidity%)';
  }
}