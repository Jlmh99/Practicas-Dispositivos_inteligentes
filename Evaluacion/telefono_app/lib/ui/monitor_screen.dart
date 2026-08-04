import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/activity_provider.dart';
import '../providers/ble_provider.dart';
import 'alert_banner.dart';
import 'colores.dart';
import 'connection_badge.dart';
import 'monitor_widget.dart';

/// Pantalla principal del teléfono: estado de conexión, banner de alertas,
/// métricas en vivo y control remoto del wearable.
class MonitorScreen extends ConsumerWidget {
  const MonitorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityStatus = ref.watch(activityProvider.select((s) => s.activityStatus));
    final corriendo = activityStatus != 'PAUSA' && activityStatus != 'INACTIVO';

    return Scaffold(
      backgroundColor: kGrisClaro,
      appBar: AppBar(
        title: const Text('Mind Games'),
        actions: [
          // Demo: fuerza sessionSeconds a 1795 para no esperar 30 min reales
          // a que se dispare la alerta de tiempo prolongado.
          IconButton(
            tooltip: 'Forzar umbral (demo)',
            icon: const Icon(Icons.bug_report_outlined),
            onPressed: () => ref.read(activityProvider.notifier).debugForzarUmbral(),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(child: ConnectionBadge()),
          ),
        ],
      ),
      body: Column(
        children: [
          const AlertBanner(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: const MonitorWidget(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: corriendo ? kRojoError : kVerdeExito,
        icon: Icon(corriendo ? Icons.stop : Icons.play_arrow),
        label: Text(corriendo ? 'Detener' : 'Iniciar'),
        onPressed: () => ref.read(bleClientProvider).enviarControl(!corriendo),
      ),
    );
  }
}
