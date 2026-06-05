import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/weather.dart';
import '../providers/weather_provider.dart';
import '../utils/weather_utils.dart';
import 'search_screen.dart';

//Cambiamos StatelessWidget por ConsumerWidget
class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weather = ref.watch(weatherProvider);//Escuchamos el estado del clima usando ref.watch

    final List<Map<String, dynamic>> randomClimates = [
      {'city': 'Santiago de Querétaro', 'temp': 24.0, 'condition': 'Despejado', 'humidity': 40},
      {'city': 'Monterrey', 'temp': 36.5, 'condition': 'Tormenta', 'humidity': 70},
      {'city': 'Ciudad de México', 'temp': 19.2, 'condition': 'Nublado', 'humidity': 60},
      {'city': 'Guadalajara', 'temp': 28.0, 'condition': 'Soleado', 'humidity': 50},
      {'city': 'Toluca', 'temp': 12.5, 'condition': 'Lluvia', 'humidity': 80},
      {'city': 'Cancún', 'temp': 31.0, 'condition': 'Soleado', 'humidity': 75},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clima Actual'),
        centerTitle: true,
        // agrego boton cambio de temperatura
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: const Icon(Icons.casino_rounded, size: 28, color: Colors.blue), // Ícono de dado para representar el cambio aleatorio
              tooltip: 'Clima Aleatorio',
              onPressed: () {
                final random = Random();
                final nextClimate = randomClimates[random.nextInt(randomClimates.length)];

                // Actualiza el Provider con los datos aleatorios
                ref.read(weatherProvider.notifier).updateWeather(
                  Weather(
                    city: nextClimate['city'],
                    temp: nextClimate['temp'],
                    condition: nextClimate['condition'],
                    unit: weather.unit,
                    humidity: nextClimate['humidity'],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: OrientationBuilder(
        builder: (context, orientation) {
          
          return orientation == Orientation.portrait
              ? _buildPortraitLayout(context, ref, weather)
              : _buildLandscapeLayout(context, ref, weather);
        },
      ),
    );
  }

  // DISEÑO VERTICAL
  Widget _buildPortraitLayout(BuildContext context, WidgetRef ref, Weather weather) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                formatTemperature(weather.temp, weather.unit),
                style: const TextStyle(fontSize: 72, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
              const SizedBox(height: 16),
              // Ciudad dinámica
              Text(
                weather.city,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 32),
              // Ícono dinámico según la condición
              Icon(
                getWeatherIcon(weather.condition), 
                size: 120, 
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              // Texto de condición 
              Text(
                weather.condition,
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Text('Humedad: ${weather.humidity}% | Viento: 12 km/h'),
              const SizedBox(height: 32),

              ElevatedButton.icon(
                onPressed: () => ref.read(weatherProvider.notifier).toggleTemperatureUnit(),
                icon: const Icon(Icons.thermostat_rounded),
                label: const Text('Cambiar Unidad (°C / °F)'),
              ),
              const SizedBox(height: 16),
              _buildSearchButton(context),
            ],
          ),
        ),
      ),
    );
  }

  //  DISEÑO HORIZONTAL
  Widget _buildLandscapeLayout(BuildContext context, WidgetRef ref, Weather weather) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Lado izquierdo
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatTemperature(weather.temp, weather.unit),
                      style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                    Text(
                      weather.city,
                      style: const TextStyle(fontSize: 22),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      weather.condition,
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text('Humedad: ${weather.humidity}% | Viento: 12 km/h'),
                  ],
                ),
              ),
              // Lado derecho
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(getWeatherIcon(weather.condition), size: 70, color: Colors.blue),
                    const SizedBox(height: 16),
                    // Botón para cambiar unidad en horizontal
                    OutlinedButton(
                      onPressed: () => ref.read(weatherProvider.notifier).toggleTemperatureUnit(),
                      child: const Text('°C / °F'),
                    ),
                    const SizedBox(height: 16),
                    _buildSearchButton(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget para no duplicar la lógica del botón
  Widget _buildSearchButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SearchScreen()),
        );
      },
      child: const Text('Buscar Ciudades'),
    );
  }
}