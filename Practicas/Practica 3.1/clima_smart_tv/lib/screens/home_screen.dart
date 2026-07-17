import 'package:clima_smart_tv/providers/weather_provider.dart';
import 'package:clima_smart_tv/widgets/weather_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/navigation_provider.dart';
import '../widgets/header_widget.dart';
import '../widgets/weather_background.dart'; 

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final FocusNode _focusNode;

  // ❌ AQUÍ BORRAMOS LA LISTA VIEJA 'weatherList = const [...]' PORQUE YA NO LA QUEREMOS.

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final navigation = ref.watch(navigationProvider);
    
    // 📍 CAMBIO 1: Agregamos la lectura del proveedor de clima real aquí mismo
    final weatherAsync = ref.watch(weatherProvider);
    
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (event) {
        if (event is! KeyDownEvent) return;

        final navigationNotifier = ref.read(navigationProvider.notifier);

        switch (event.logicalKey) {
          case LogicalKeyboardKey.arrowUp:
            navigationNotifier.moveUp();
            break;
          case LogicalKeyboardKey.arrowDown:
            navigationNotifier.moveDown();
            break;
          case LogicalKeyboardKey.arrowLeft:
            navigationNotifier.moveLeft();
            break;
          case LogicalKeyboardKey.arrowRight:
            navigationNotifier.moveRight();
            break;
          case LogicalKeyboardKey.enter:
          case LogicalKeyboardKey.select:
          case LogicalKeyboardKey.space:
            navigationNotifier.select();
            break;
        }
      },
      child: Stack(
        children: [
          // 📍 Ojo aquí: El fondo animado necesita la condición del clima real una vez cargue.
            weatherAsync.when(
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
              data: (weather) {
                return WeatherBackground(
                  condition: weather[navigation.focusedIndex].condition,
                );
              },
            ),

          Container(
            color: Colors.black.withValues(alpha: 0.45),
          ),

          Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: Column(
                children: [
                  // El Header también lee el nombre de la ciudad real una vez que carga
                  weatherAsync.when(
                    loading: () => const HeaderWidget(
                      city: "Cargando...",
                    ),
                    error: (_, __) => const HeaderWidget(
                      city: "Sin conexión",
                    ),
                    data: (weather) {
                      return HeaderWidget(
                        city: weather[navigation.focusedIndex].city,
                      );
                    },
                  ),

                  // 📍 CAMBIO 2: Reemplazamos todo el Expanded viejo por el que te dio el ayudante
                  Expanded(
                    child: weatherAsync.when(
                      // Mientras descarga el clima de internet:
                      loading: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      
                      // Si falla el internet o la API key:
                      error: (e, _) => Center(
                        child: Text(
                          e.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                          ),
                        ),
                      ),
                      
                      // Cuando los datos de OpenWeather llegan perfectos:
                      data: (weatherList) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 96,
                            vertical: 20,
                          ),
                          child: GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: weatherList.length,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 32,
                              mainAxisSpacing: 24,
                              childAspectRatio: 1.9, // Mantén el 1.4 para que no se desborden tus textos
                            ),
                            itemBuilder: (context, index) {
                              return WeatherCard(
                                weather: weatherList[index],
                                isFocused: navigation.focusedIndex == index,
                                onTap: () {
                                  ref.read(navigationProvider.notifier).select();
                                },
                              );
                            },
                          ),
                        );
                      },
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}