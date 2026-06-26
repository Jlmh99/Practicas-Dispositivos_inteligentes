class Weather {
  final String city;
  final double temp;
  final String condition;
  final String description;
  final String unit;
  final int humidity;
  final double windSpeed;

  Weather({
    required this.city,
    required this.temp,
    required this.condition,
    required this.description,
    required this.unit,
    required this.humidity,
    required this.windSpeed,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    // Validaciones principales
    if (!json.containsKey('main') || !json.containsKey('weather')) {
      throw const FormatException('Respuesta API incompleta');
    }

    final weatherList = json['weather'];

    if (weatherList is! List || weatherList.isEmpty) {
      throw const FormatException('Sin datos de clima');
    }

    final tempValue = json['main']['temp'];

    if (tempValue is! num) {
      throw const FormatException('Temperatura inválida');
    }

    return Weather(
      city: json['name'] ?? 'Desconocido',
      temp: tempValue.toDouble(),
      condition: weatherList[0]['main'] ?? 'Desconocido',
      description: weatherList[0]['description'] ?? '',
      unit: '°C',
      humidity: (json['main']['humidity'] ?? 0) as int,
      windSpeed: ((json['wind']?['speed']) ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'city': city,
        'temperature': temp,
        'condition': condition,
        'description': description,
        'humidity': humidity,
        'windSpeed': windSpeed,
      };

  @override
  String toString() {
    return 'Weather(city: $city, temp: ${temp.toStringAsFixed(1)}°C, '
        'condition: $condition, humidity: $humidity%, '
        'wind: ${windSpeed.toStringAsFixed(1)} m/s)';
  }
}