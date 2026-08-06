import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/sesion_guardada.dart';
import '../providers/activity_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/ble_provider.dart';
import '../providers/firestore_provider.dart';
import '../providers/session_sync_provider.dart';
import 'alert_banner.dart';
import 'colores.dart';
import 'connection_badge.dart';
import 'games_list.dart';
import 'monitor_widget.dart';

/// Pantalla principal: AppBar con indicador de sync + estado BLE, monitor de
/// métricas en vivo, catálogo de juegos, banner de alertas superpuesto y
/// botón flotante para iniciar/detener remotamente el wearable.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Solo con observarlo una vez ya queda "vivo" (Riverpod mantiene el
    // NotifierProvider activo mientras algo lo escuche).
    ref.watch(sessionSyncProvider);

    // Guarda el resumen de la sesión en cuanto `activityStatus` pasa a
    // "PAUSA" — sin importar si el stop lo originó el botón del teléfono o
    // el botón físico del wearable, porque ambos llegan igual por BLE NOTIFY
    // y actualizan `activityProvider`. Antes esto solo pasaba si se detenía
    // desde el botón del teléfono, y se perdía al detener desde el reloj.
    ref.listen<String>(activityProvider.select((s) => s.activityStatus), (anterior, actual) {
      debugPrint('[HomeScreen] activityStatus: $anterior -> $actual');
      final seDetuvoAhora = anterior != null && anterior != 'PAUSA' && actual == 'PAUSA';
      if (seDetuvoAhora) {
        debugPrint('[HomeScreen] Detectado stop, guardando sesión...');
        unawaited(_guardarSesion(ref));
      }
    });

    final activityStatus = ref.watch(activityProvider.select((s) => s.activityStatus));
    final corriendo = activityStatus != 'PAUSA' && activityStatus != 'INACTIVO';

    return Scaffold(
      backgroundColor: kGrisClaro,
      appBar: AppBar(
        title: const Text('Mind Games'),
        actions: [
          IconButton(
            tooltip: 'Forzar umbral (demo)',
            icon: const Icon(Icons.bug_report_outlined),
            onPressed: () => ref.read(activityProvider.notifier).debugForzarUmbral(),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Center(child: _IndicadorSync()),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 4),
            child: Center(child: ConnectionBadge()),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authRepositoryProvider).cerrarSesion(),
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.only(top: 16, bottom: 96),
            children: const [
              Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: MonitorWidget()),
              SizedBox(height: 16),
              GamesList(),
            ],
          ),
          const Align(alignment: Alignment.topCenter, child: AlertBanner()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: corriendo ? kRojoError : kVerdeExito,
        foregroundColor: kGrisClaro,
        icon: Icon(corriendo ? Icons.stop : Icons.play_arrow),
        label: Text(corriendo ? 'Detener' : 'Iniciar'),
        onPressed: () => _alternarControl(ref, corriendo),
      ),
    );
  }

  Future<void> _alternarControl(WidgetRef ref, bool corriendo) {
    return ref.read(bleClientProvider).enviarControl(!corriendo);
  }

  /// Dispara con el `ref.listen` de arriba, sin importar qué dispositivo
  /// originó el "detener".
  Future<void> _guardarSesion(WidgetRef ref) async {
    final usuario = ref.read(authStateProvider).value;
    if (usuario == null) {
      debugPrint('[HomeScreen] _guardarSesion: sin usuario autenticado, se cancela.');
      return;
    }

    final actividad = ref.read(activityProvider);
    final gameId = ref.read(juegoSeleccionadoProvider);

    try {
      await ref.read(firestoreRepositoryProvider).guardarSesion(
            usuario.uid,
            SesionGuardada(
              gameId: gameId,
              sessionSeconds: actividad.sessionSeconds,
              heartRatePromedio: _promedio(actividad.heartRateHistorial),
              moves: actividad.moves,
              focusPromedio: _promedio(actividad.focusLevelHistorial),
              alertasDisparadas: actividad.alertasActivas.map((a) => a.tipo.name).toList(),
              finalizadoEn: DateTime.now(),
            ),
          );
      debugPrint('[HomeScreen] Sesión guardada en users/${usuario.uid}/sessions');
    } catch (e) {
      debugPrint('[HomeScreen] Error al guardar la sesión: $e');
    }
  }

  double _promedio(List<num> valores) {
    if (valores.isEmpty) return 0;
    // fold<num> en vez de reduce(): reduce() exige un combinador con el tipo
    // exacto del elemento (ej. `(int, int) => int` para List<int> en tiempo
    // de ejecución), y `(a, b) => a + b` se infiere como `(num, num) => num`
    // al tipar el parámetro como `List<num>` — lanza un TypeError al llamar
    // con heartRateHistorial/focusLevelHistorial reales. fold sí acepta un
    // tipo acumulador (`num`) distinto al del elemento (`int`/`double`).
    final suma = valores.fold<num>(0, (acumulado, v) => acumulado + v);
    return suma / valores.length;
  }
}

/// "Sincronizado hace Xs" — se refresca solo cada segundo (independiente de
/// cuándo llegue la próxima sincronización real).
class _IndicadorSync extends ConsumerStatefulWidget {
  const _IndicadorSync();

  @override
  ConsumerState<_IndicadorSync> createState() => _IndicadorSyncState();
}

class _IndicadorSyncState extends ConsumerState<_IndicadorSync> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ultimaSync = ref.watch(sessionSyncProvider.select((s) => s.ultimaSincronizacion));
    if (ultimaSync == null) {
      return const Text('Sin sincronizar', style: TextStyle(fontSize: 11, color: kGrisOscuro));
    }
    final segundos = DateTime.now().difference(ultimaSync).inSeconds;
    return Text('Sync hace ${segundos}s', style: const TextStyle(fontSize: 11, color: kGrisOscuro));
  }
}
