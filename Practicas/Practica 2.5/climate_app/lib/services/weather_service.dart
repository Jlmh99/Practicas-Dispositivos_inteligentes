import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/weather.dart';

class WeatherService {
  static const Duration _timeout = Duration(seconds: 10);
  
  // Reutilizar el cliente HTTP es una buena práctica para mejorar el rendimiento
  final http.Client _httpClient;

  WeatherService({http.Client? httpClient}) : _httpClient = httpClient ?? http.Client();

  /// Obtiene el clima actual de una ciudad específica.
  Future<Weather> getWeather(String city) async {
    final cleanCity = city.trim();
    
    // 1. Validaciones previas
    if (cleanCity.isEmpty) {
      throw ArgumentError('La ciudad no puede estar vacía');
    }

    if (!AppConfig.isConfigured()) {
      throw Exception('API key no configurada. Revisa el archivo .env');
    }

    // 2. Construir la URL de forma segura usando Uri (evita problemas con espacios y caracteres especiales)
    final uri = Uri.parse(AppConfig.baseUrl).replace(
      queryParameters: {
        'q': cleanCity,
        'appid': AppConfig.apiKey,
        'units': 'metric',
        'lang': 'es',
      },
    );

    try {
      // 3. Ejecutar la petición HTTP
      final response = await _httpClient.get(uri).timeout(_timeout);

      // 4. Manejar códigos de respuesta
      return _handleResponse(response, cleanCity);
      
    } on SocketException {
      throw const HttpException('Sin conexión a internet');
    } on TimeoutException {
      throw TimeoutException('Tiempo de espera agotado. Intenta de nuevo');
    } on FormatException catch (e) {
      throw FormatException('Respuesta inesperada de la API: $e');
    }
  }

  /// Consulta el clima de varias ciudades en paralelo.
  Future<List<Weather>> getWeatherForCities(List<String> cities) async {
    final futures = cities.map((city) => getWeather(city));
    return Future.wait(futures);
  }

  /// Manejo estructurado de las respuestas HTTP
  Weather _handleResponse(http.Response response, String city) {
    switch (response.statusCode) {
      case 200:
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return Weather.fromJson(json);
      case 401:
        throw const HttpException('API key inválida o no activada aún');
      case 404:
        throw HttpException('Ciudad "$city" no encontrada');
      case 429:
        throw const HttpException('Límite de llamadas excedido. Espera un momento');
      default:
        throw HttpException('Error del servidor: ${response.statusCode}');
    }
  }

  void dispose() {
  _httpClient.close();
}
}