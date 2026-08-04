import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

const Color kAzulPrimario = Color(0xFF3A3AFF);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mind Games',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: kAzulPrimario),
      ),
      home: const PermissionGate(),
    );
  }
}

/// Solicita los permisos BLE necesarios para actuar como central (escanear y
/// conectarse al wearable) antes de mostrar la pantalla principal. Nunca deja
/// que una excepción a nivel nativo (común en emuladores sin Bluetooth real)
/// tumbe la app: si falla, cae a la pantalla de permisos denegados en vez de
/// crashear.
class PermissionGate extends StatefulWidget {
  const PermissionGate({super.key});

  @override
  State<PermissionGate> createState() => _PermissionGateState();
}

enum _EstadoPermiso { verificando, concedido, denegado }

class _PermissionGateState extends State<PermissionGate> {
  _EstadoPermiso _estado = _EstadoPermiso.verificando;

  // Central BLE: solo necesita escanear y conectarse, nunca anunciar.
  static const _permisosBle = [
    Permission.bluetoothScan,
    Permission.bluetoothConnect,
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
      setState(() => _estado = _EstadoPermiso.denegado);
    }
  }

  void _omitirParaPruebas() {
    setState(() => _estado = _EstadoPermiso.concedido);
  }

  @override
  Widget build(BuildContext context) {
    switch (_estado) {
      case _EstadoPermiso.verificando:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator(color: kAzulPrimario)),
        );
      case _EstadoPermiso.concedido:
        return const MyHomePage(title: 'Mind Games');
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
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bluetooth_disabled, size: 32),
                const SizedBox(height: 12),
                const Text(
                  'Se necesitan permisos de Bluetooth para conectarse '
                  'con el wearable.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: onReintentar,
                  style: ElevatedButton.styleFrom(backgroundColor: kAzulPrimario),
                  child: const Text('Reintentar'),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: onOmitir,
                  child: const Text('Omitir (modo emulador)'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
