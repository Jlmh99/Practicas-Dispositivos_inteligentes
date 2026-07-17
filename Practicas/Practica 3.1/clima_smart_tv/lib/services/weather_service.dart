import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/weather.dart';
import '../utils/weather_constants.dart';

class WeatherService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: dotenv.env['OPENWEATHER_BASE_URL']!,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
    ),
  );

  Future<Weather> fetchWeather(String city) async {
    final response = await _dio.get(
      '',
      queryParameters: {
        'q': city.trim(),
        'appid': dotenv.env['OPENWEATHER_API_KEY'],
        'units': 'metric',
        'lang': 'es',
      },
    );

    return Weather.fromJson(response.data);
  }

  Future<List<Weather>> fetchAllCities() async {
    final futures = WeatherConstants.cities.map(fetchWeather);

    return Future.wait(futures);
  }
}