import 'package:flutter_dotenv/flutter_dotenv.dart';
class AppConfig {
// Getters que leen del .env en tiempo de ejecucion
static String get apiKey =>
dotenv.env['OPENWEATHER_API_KEY'] ?? '';
static String get baseUrl =>
dotenv.env['OPENWEATHER_BASE_URL'] ??
'https://api.openweathermap.org/data/2.5/weather';
// Validar que las variables esten cargadas
static bool isConfigured() {
return apiKey.isNotEmpty && baseUrl.isNotEmpty;
}
}