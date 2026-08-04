import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/activity_provider.dart';
import '../widgets/metric_card.dart';

class MonitorScreen extends ConsumerWidget {
  const MonitorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(activityProvider);
    final notifier = ref.read(activityProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitor de Actividad'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              state.status == ConnectionStatus.connected
                  ? Icons.bluetooth_connected
                  : Icons.bluetooth_disabled,
            ),
            color: state.status == ConnectionStatus.connected
                ? Colors.blue
                : Colors.grey,
            onPressed: () {
              if (state.status == ConnectionStatus.connected) {
                notifier.disconnect();
              } else {
                notifier.connect();
              }
            },
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          // Escaneando
          if (state.status == ConnectionStatus.scanning) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Buscando wearable...'),
                ],
              ),
            );
          }

          // Error
          if (state.status == ConnectionStatus.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.errorMessage ?? 'Error desconocido',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: notifier.connect,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          // Desconectado
          if (state.status != ConnectionStatus.connected) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.watch,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Conecta tu wearable',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Asegúrate de que la app del wearable esté activa',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: notifier.connect,
                    icon: const Icon(Icons.bluetooth_searching),
                    label: const Text('Buscar wearable'),
                  ),
                ],
              ),
            );
          }

          final d = state.data;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (d.heartRate > 120)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning,
                          color: Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Ritmo cardiaco alto: ${d.heartRate} bpm',
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    d.status.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.1,
                  children: [
                    MetricCard(
                      label: 'PASOS',
                      value: '${d.steps}',
                      unit: 'pasos',
                      color: Colors.green,
                      icon: Icons.directions_walk,
                    ),
                    MetricCard(
                      label: 'RITMO CARDIACO',
                      value: '${d.heartRate}',
                      unit: 'bpm',
                      color: d.heartRate > 120
                          ? Colors.red
                          : Colors.pink,
                      icon: Icons.favorite,
                    ),
                    MetricCard(
                      label: 'CALORÍAS',
                      value: '${d.calories}',
                      unit: 'kcal',
                      color: Colors.orange,
                      icon: Icons.local_fire_department,
                    ),
                    MetricCard(
                      label: 'ZONA FC',
                      value: d.heartRateZone.split(' ').first,
                      unit: d.heartRateZone.contains(' ')
                          ? d.heartRateZone.split(' ').skip(1).join(' ')
                          : '',
                      color: Colors.purple,
                      icon: Icons.speed,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Text(
                  'Última actualización: '
                  '${d.timestamp.hour.toString().padLeft(2, '0')}:'
                  '${d.timestamp.minute.toString().padLeft(2, '0')}:'
                  '${d.timestamp.second.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}