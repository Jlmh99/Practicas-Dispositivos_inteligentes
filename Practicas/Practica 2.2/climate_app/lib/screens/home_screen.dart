import 'package:flutter/material.dart';

import 'search_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clima Actual'),
        centerTitle: true,
      ),
      body: OrientationBuilder(
        builder: (context, orientation) {
          return orientation == Orientation.portrait
              ? _buildPortraitLayout(context)
              : _buildLandscapeLayout(context);
        },
      ),
    );
  }

  // --- DISEÑO VERTICAL (Tu diseño original intacto) ---
  Widget _buildPortraitLayout(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '24°C',
                style: TextStyle(fontSize: 72, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
              const SizedBox(height: 16),
              const Text(
                'Santiago de Querétaro',
                style: TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 32),
              const Icon(Icons.cloud, size: 120, color: Colors.blue),
              const SizedBox(height: 32),
              const Text('Humedad: 65% | Viento: 12 km/h'),
              const SizedBox(height: 40),
              _buildSearchButton(context),
            ],
          ),
        ),
      ),
    );
  }

  // --- DISEÑO HORIZONTAL (Responsivo y estilizado) ---
  Widget _buildLandscapeLayout(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Lado izquierdo: Información del texto
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '24°C',
                      style: TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                    const Text(
                      'Santiago de Querétaro',
                      style: TextStyle(fontSize: 22),
                    ),
                    const SizedBox(height: 8),
                    const Text('Humedad: 65% | Viento: 12 km/h'),
                  ],
                ),
              ),
              // Lado derecho: Ícono y Acción
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(Icons.cloud, size: 90, color: Colors.blue),
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

  // Widget auxiliar para no duplicar la lógica del botón
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