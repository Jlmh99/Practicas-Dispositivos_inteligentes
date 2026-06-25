import 'package:flutter/material.dart';

import '../widgets/temperature_card.dart';
class DetailScreen extends StatelessWidget {
  final String city;

  const DetailScreen({Key? key, required this.city}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$city - 5 Días'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                TemperatureCard(day: 'Lun', temperature: '24°C', condition: 'sunny'),
                TemperatureCard(day: 'Mar', temperature: '26°C', condition: 'sunny'),
                TemperatureCard(day: 'Mié', temperature: '20°C', condition: 'rainy'),
                TemperatureCard(day: 'Jue', temperature: '25°C', condition: 'cloudy'),
                TemperatureCard(day: 'Vie', temperature: '28°C', condition: 'sunny'),
              ],
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Volver'),
            ),
          ],
        ),
      ),
    );
  }
}