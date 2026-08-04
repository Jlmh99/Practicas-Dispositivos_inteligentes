import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'ui/watch_home_screen.dart';

const Color kFondoOscuro = Color(0xFF0F0F1A);
const Color kAzulPrimario = Color(0xFF3A3AFF);

void main() {
  runApp(const MindGamesWatchApp());
}

class MindGamesWatchApp extends StatelessWidget {
  const MindGamesWatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mind Games Watch',
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: kFondoOscuro,
        colorScheme: ColorScheme.fromSeed(
          seedColor: kAzulPrimario,
          brightness: Brightness.dark,
        ),
      ),
      home: const PermissionGate(),
    );
  }
}

/// Solicita los permisos BLE necesarios para actuar como periférico antes de
/// mostrar la pantalla principal. Si el usuario los niega o el entorno no soporta
/// Bluetooth, maneja el estado sin cerrar la app.
class PermissionGate extends StatefulWidget {
  const PermissionGate({super.key});

  @override
  State<PermissionGate> createState() => _PermissionGateState();
}

enum _EstadoPermiso { verificando, concedido, denegado }

class _PermissionGateState extends State<PermissionGate> {
  _EstadoPermiso _estado = _EstadoPermiso.verificando;

  static const _permisosBle = [
    Permission.bluetoothAdvertise,
    Permission.bluetoothConnect,
    Permission.bluetoothScan,
  ];

  @override
  void initState() {
    super.initState();
    _solicitarPermisos();
  }

  Future<void> _solicitarPermisos() async {
    if (!mounted) return;
    setState(() => _estado = _EstadoPermiso.verificando);

    try {
      final resultados = await _permisosBle.request();

      // Comprobar si los permisos esenciales fueron concedidos
      final concedidos = resultados.values.every(
        (status) => status.isGranted || status.isLimited,
      );

      if (!mounted) return;
      setState(() {
        _estado = concedidos ? _EstadoPermiso.concedido : _EstadoPermiso.denegado;
      });
    } catch (e) {
      debugPrint('Error al solicitar permisos BLE (posible emulador sin Bluetooth): $e');
      if (!mounted) return;

      // Evita el crash asignando el estado denegado
      setState(() {
        _estado = _EstadoPermiso.denegado;
      });
    }
  }

  void _omitirParaPruebas() {
    setState(() {
      _estado = _EstadoPermiso.concedido;
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_estado) {
      case _EstadoPermiso.verificando:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator(color: kAzulPrimario)),
        );
      case _EstadoPermiso.concedido:
        return const WatchHomeScreen();
      case _EstadoPermiso.denegado:
        return _PermisosDenegadosScreen(
          onReintentar: _solicitarPermisos,
          onOmitir: _omitirParaPruebas,
        );
    }
  }
}

class _PermisosDenegadosScreen extends StatelessWidget {
  const _PermisosDenegadosScreen({
    required this.onReintentar,
    required this.onOmitir,
  });

  final VoidCallback onReintentar;
  final VoidCallback onOmitir;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.bluetooth_disabled,
                    color: Colors.white70,
                    size: 28,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Se necesitan permisos de Bluetooth para transmitir datos de sesión.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: onReintentar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kAzulPrimario,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: const Text('Reintentar', style: TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: onOmitir,
                    child: const Text(
                      'Omitir (Modo Emulador)',
                      style: TextStyle(color: Colors.white54, fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
