import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/activity_provider.dart';
import 'colores.dart';

/// Tarjetas grandes con las métricas en vivo del wearable: heartRate,
/// sessionSeconds (mm:ss) y moves como valores; focusLevel como barra de
/// progreso; activityStatus como texto.
class MonitorWidget extends ConsumerWidget {
  const MonitorWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(activityProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _TarjetaMetrica(
                icono: Icons.favorite,
                etiqueta: 'Ritmo cardiaco',
                valor: '${estado.heartRate}',
                unidad: 'bpm',
                colorAlerta: estado.heartRate > kUmbralHeartRate,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TarjetaMetrica(
                icono: Icons.timer,
                etiqueta: 'Tiempo de sesión',
                valor: _mmss(estado.sessionSeconds),
                unidad: '',
                colorAlerta: estado.sessionSeconds > kUmbralSessionSeconds,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _TarjetaMetrica(
          icono: Icons.touch_app,
          etiqueta: 'Movimientos',
          valor: '${estado.moves}',
          unidad: '',
          colorAlerta: false,
        ),
        const SizedBox(height: 12),
        _TarjetaFocusLevel(focusLevel: estado.focusLevel),
        const SizedBox(height: 12),
        _TarjetaActivityStatus(activityStatus: estado.activityStatus),
      ],
    );
  }

  String _mmss(int totalSegundos) {
    final m = totalSegundos ~/ 60;
    final s = totalSegundos % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class _TarjetaMetrica extends StatelessWidget {
  const _TarjetaMetrica({
    required this.icono,
    required this.etiqueta,
    required this.valor,
    required this.unidad,
    required this.colorAlerta,
  });

  final IconData icono;
  final String etiqueta;
  final String valor;
  final String unidad;
  final bool colorAlerta;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icono, size: 18, color: kAzulPrimario),
                const SizedBox(width: 6),
                Text(
                  etiqueta,
                  style: const TextStyle(fontSize: kTextoDetalle, color: kGrisOscuro),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text.rich(
              TextSpan(
                text: valor,
                style: TextStyle(
                  fontSize: kTextoPrincipal,
                  fontWeight: FontWeight.bold,
                  color: colorAlerta ? kRojoError : kGrisOscuro,
                ),
                children: [
                  if (unidad.isNotEmpty)
                    TextSpan(
                      text: ' $unidad',
                      style: const TextStyle(fontSize: kTextoDetalle, fontWeight: FontWeight.normal),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaFocusLevel extends StatelessWidget {
  const _TarjetaFocusLevel({required this.focusLevel});

  final double focusLevel;

  @override
  Widget build(BuildContext context) {
    final bajo = focusLevel < kUmbralFocusLevelBajo;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.psychology, size: 18, color: kAzulPrimario),
                    SizedBox(width: 6),
                    Text('Concentración', style: TextStyle(fontSize: kTextoDetalle, color: kGrisOscuro)),
                  ],
                ),
                Text(
                  '${focusLevel.round()}%',
                  style: TextStyle(
                    fontSize: kTextoSecundario,
                    fontWeight: FontWeight.bold,
                    color: bajo ? kRojoError : kGrisOscuro,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (focusLevel / 100).clamp(0, 1),
                minHeight: 10,
                backgroundColor: kGrisClaro,
                color: bajo ? kRojoError : kAzulPrimario,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaActivityStatus extends StatelessWidget {
  const _TarjetaActivityStatus({required this.activityStatus});

  final String activityStatus;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.videogame_asset, size: 18, color: kAzulPrimario),
            const SizedBox(width: 8),
            Text(
              activityStatus,
              style: const TextStyle(fontSize: kTextoCuerpo, color: kGrisOscuro),
            ),
          ],
        ),
      ),
    );
  }
}
