import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/weather.dart';
import '../services/weather_service.dart';

class WeatherNotifier extends AsyncNotifier<List<Weather>> {

  late final Timer _timer;

  @override
  Future<List<Weather>> build() async {

    ref.onDispose(() {
      _timer.cancel();
    });

    _timer = Timer.periodic(
      const Duration(minutes: 10),
      (_) => ref.invalidateSelf(),
    );

    final service = WeatherService();

    return service.fetchAllCities();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }

}

final weatherProvider =
AsyncNotifierProvider<WeatherNotifier,List<Weather>>(
  WeatherNotifier.new,
);