import 'package:flutter/material.dart';

import 'ble_server.dart';
import 'sensor_simulator.dart';

void main() {
  runApp(const WearableApp());
}

class WearableApp extends StatefulWidget {
  const WearableApp({super.key});

  @override
  State<WearableApp> createState() => _WearableAppState();
}

class _WearableAppState extends State<WearableApp> {
  late final SensorSimulator _sim;
  late final BleServer _server;

  int _steps = 0;
  int _heartRate = 72;
  int _calories = 0;
  String _status = 'reposo';

  bool _active = false;

  @override
  void initState() {
    super.initState();

    _sim = SensorSimulator();
    _server = BleServer(_sim);

    _subscribeStreams();
  }

  void _subscribeStreams() {
    _sim.stepsStream.listen((v) {
      setState(() => _steps = v);
    });

    _sim.heartRateStream.listen((v) {
      setState(() => _heartRate = v);
    });

    _sim.caloriesStream.listen((v) {
      setState(() => _calories = v);
    });

    _sim.statusStream.listen((v) {
      setState(() => _status = v);
    });
  }

  Future<void> _toggleActivity() async {
    setState(() => _active = !_active);

    if (_active) {
      _sim.start();
      await _server.startAdvertising();
    } else {
      _server.stop();
    }
  }

  @override
  void dispose() {
    _server.stop();
    _sim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          // Se añade SingleChildScrollView para absorber el crecimiento vertical de la columna
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$_heartRate',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: _heartRate > 120
                        ? Colors.red
                        : Colors.white,
                  ),
                ),
                const Text(
                  'bpm',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$_steps pasos',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.green,
                  ),
                ),
                Text(
                  '$_calories kcal',
                  style: const TextStyle(
                    color: Colors.amber,
                  ),
                ),
                Text(
                  _status,
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _toggleActivity,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _active ? Colors.red : Colors.green,
                  ),
                  child: Text(
                    _active ? 'Detener' : 'Iniciar',
                  ),
                ),
                if (_active)
                  const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Text(
                      'Enviando datos...',
                      style: TextStyle(
                        color: Colors.lightBlue,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}