import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_ble/shared_ble.dart';

import '../ble/gatt_peripheral.dart';
import '../core/sensor_simulator.dart';
import '../main.dart' show kFondoOscuro, kAzulPrimario;

const Color kVerdeExito = Color(0xFF4CAF50);
const Color kRojoError = Color(0xFFE53935);

// Mismo umbral que `kUmbralSessionSeconds` en
// telefono_app/lib/providers/activity_provider.dart (fuente de verdad:
// CLAUDE.md). No vive en shared_ble porque ese paquete es solo para UUIDs y
// formato de bytes, no para umbrales de negocio — pero es el mismo número.
const int _kUmbralSessionSeconds = 1800;

/// Pantalla principal del wearable, diseñada para una esfera redonda de
/// 384×384. Todo el contenido vive dentro de un lienzo cuadrado de ese mismo
/// tamaño que se escala con [FittedBox], así que nunca hay scroll ni overflow
/// sin importar la resolución real del emulador Wear OS.
class WatchHomeScreen extends StatefulWidget {
  const WatchHomeScreen({super.key});

  @override
  State<WatchHomeScreen> createState() => _WatchHomeScreenState();
}

class _WatchHomeScreenState extends State<WatchHomeScreen> {
  late final SensorSimulator _simulador;
  late final GattPeripheral _periferico;

  StreamSubscription<SensorPayload>? _subPayload;
  StreamSubscription<bool>? _subConectado;
  StreamSubscription<String>? _subErrores;

  late SensorPayload _payload;
  bool _conectado = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _simulador = SensorSimulator();
    _payload = _simulador.ultimo;
    _periferico = GattPeripheral(
      onComandoControl: _onComandoControl,
      onJuegoSeleccionado: _simulador.setJuego,
      onSessionSecondsOverride: _simulador.forzarSessionSeconds,
    );

    _subPayload = _simulador.stream.listen((payload) {
      setState(() => _payload = payload);
      // Evita que un error en la notificación tire la app en el emulador
      try {
        _periferico.notificar(payload);
      } catch (e) {
        debugPrint('Error al notificar BLE (posible emulador): $e');
      }
    });

    _subConectado = _periferico.centralConectado.listen((conectado) {
      setState(() => _conectado = conectado);
    });

    _subErrores = _periferico.errores.listen((mensaje) {
      setState(() => _error = mensaje);
    });

    _iniciarBleSeguro();
  }

  /// Inicia el periférico GATT protegiendo el hilo principal contra
  /// excepciones nativas en dispositivos/emuladores sin adaptador Bluetooth.
  Future<void> _iniciarBleSeguro() async {
    try {
      await _periferico.iniciar();
    } catch (e) {
      debugPrint('No se pudo iniciar el periférico BLE (Emulador sin BLE): $e');
      if (mounted) {
        setState(() {
          _error = 'BLE no disponible en emulador';
        });
      }
    }
  }

  void _onComandoControl(bool iniciar) {
    if (iniciar) {
      // reset() antes de start(): cada "iniciar" es una sesión NUEVA, no una
      // reanudación. Sin esto, sessionSeconds seguía sumando desde la última
      // vez que corrió el simulador (incluso entre juegos distintos), y el
      // botón "Forzar umbral" del teléfono terminaba sobrescrito de
      // inmediato por el valor real ya acumulado del wearable.
      _simulador.reset();
      _simulador.start();
    } else {
      _simulador.stop();
    }
  }

  void _alternarSimulador() {
    if (_simulador.running) {
      _simulador.stop();
    } else {
      _simulador.reset();
      _simulador.start();
    }
  }

  @override
  void dispose() {
    _subPayload?.cancel();
    _subConectado?.cancel();
    _subErrores?.cancel();
    _simulador.dispose();
    try {
      _periferico.detener();
      _periferico.dispose();
    } catch (e) {
      debugPrint('Error al cerrar periférico BLE: $e');
    }
    super.dispose();
  }

  String _mmss(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kFondoOscuro,
      body: SafeArea(
        child: Center(
          child: AspectRatio(
            aspectRatio: 1,
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: 384,
                height: 384,
                child: _buildLienzo(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLienzo() {
    final corriendo = _simulador.running;
    return Stack(
      children: [
        // Indicador de central conectado (o error), arriba, lejos del borde.
        Align(
          alignment: const Alignment(0, -0.85),
          child: _IndicadorConexion(conectado: _conectado, error: _error),
        ),

        // Métrica principal: tiempo de sesión, al centro. Alerta pequeña:
        // se pinta de rojo al cruzar el umbral (mismo criterio que el
        // banner del teléfono y de la TV) — no hay espacio para un banner
        // completo en una esfera de 384px, así que este es el aviso visual
        // más chico posible sin agregar layout nuevo.
        Align(
          alignment: const Alignment(0, -0.05),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'SESIÓN',
                style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1),
              ),
              Text(
                _mmss(_payload.sessionSeconds),
                style: TextStyle(
                  color: _payload.sessionSeconds > _kUmbralSessionSeconds
                      ? kRojoError
                      : Colors.white,
                  fontSize: 44,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),

        // Las otras 4 métricas alrededor, en las diagonales.
        Align(
          alignment: const Alignment(-0.55, -0.55),
          child: _MetricChip(
            icon: Icons.favorite,
            valor: '${_payload.heartRate}',
            etiqueta: 'BPM',
          ),
        ),
        Align(
          alignment: const Alignment(0.55, -0.55),
          child: _MetricChip(
            icon: Icons.touch_app,
            valor: '${_payload.moves}',
            etiqueta: 'MOV',
          ),
        ),
        Align(
          alignment: const Alignment(-0.55, 0.55),
          child: _MetricChip(
            icon: Icons.psychology,
            valor: '${_payload.focusLevel.round()}',
            etiqueta: 'FOCO',
          ),
        ),
        Align(
          alignment: const Alignment(0.55, 0.55),
          child: _MetricChip(
            icon: Icons.videogame_asset,
            valor: _payload.activityStatus,
            etiqueta: null,
            valorFontSize: 11,
          ),
        ),

        // Botón grande Iniciar/Detener, abajo.
        Align(
          alignment: const Alignment(0, 0.8),
          child: ElevatedButton(
            onPressed: _alternarSimulador,
            style: ElevatedButton.styleFrom(
              backgroundColor: corriendo ? kRojoError : kVerdeExito,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: const StadiumBorder(),
            ),
            child: Text(
              corriendo ? 'Detener' : 'Iniciar',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}

class _IndicadorConexion extends StatelessWidget {
  const _IndicadorConexion({required this.conectado, required this.error});

  final bool conectado;
  final String? error;

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return SizedBox(
        width: 140,
        child: Text(
          error!,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: kRojoError, fontSize: 11),
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: conectado ? kVerdeExito : Colors.white24,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          conectado ? 'Conectado' : 'Sin conexión',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.icon,
    required this.valor,
    required this.etiqueta,
    this.valorFontSize = 14,
  });

  final IconData icon;
  final String valor;
  final String? etiqueta;
  final double valorFontSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: kAzulPrimario, size: 16),
          const SizedBox(height: 2),
          Text(
            valor,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: valorFontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (etiqueta != null)
            Text(
              etiqueta!,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
        ],
      ),
    );
  }
}
