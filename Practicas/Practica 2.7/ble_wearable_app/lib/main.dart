import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

void main() {
  runApp(const BleWearableApp());
}

class BleWearableApp extends StatelessWidget {
  const BleWearableApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BLE Wearable',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
      ),
      home: const BleInspectorScreen(),
    );
  }
}

class BleInspectorScreen extends StatefulWidget {
  const BleInspectorScreen({super.key});

  @override
  State<BleInspectorScreen> createState() => _BleInspectorScreenState();
}

class _BleInspectorScreenState extends State<BleInspectorScreen> {
  final List<ScanResult> _scanResults = [];

  BluetoothDevice? _connectedDevice;

  List<BluetoothService> _services = [];

  bool _isScanning = false;

  StreamSubscription<List<ScanResult>>? _scanSubscription;

  // UUIDs Bluetooth SIG
  static const String batteryService = "180f";
  static const String batteryCharacteristic = "2a19";

  static const String heartRateService = "180d";
  static const String heartRateCharacteristic = "2a37";

  @override
  void initState() {
    super.initState();

    FlutterBluePlus.adapterState.listen((state) {
      if (state == BluetoothAdapterState.off) {
        _showMessage(
          "Bluetooth apagado",
          Colors.orange,
        );
      }
    });
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    super.dispose();
  }

  Future<void> startScan() async {
    _scanResults.clear();

    setState(() {
      _isScanning = true;
    });

    _scanSubscription?.cancel();

    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      if (!mounted) return;

      setState(() {
        _scanResults
          ..clear()
          ..addAll(
            results.where(
              (r) => r.device.platformName.isNotEmpty,
            ),
          );
      });
    });

    try {
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 6),
      );

      await FlutterBluePlus.isScanning.where((e) => e == false).first;
    } catch (e) {
      _showMessage(
        e.toString(),
        Colors.red,
      );
    }

    if (mounted) {
      setState(() {
        _isScanning = false;
      });
    }
  }

  Future<void> connect(BluetoothDevice device) async {
    try {
      _showMessage(
        "Conectando a ${device.platformName}",
        Colors.blue,
      );

      await device.connect(license: License.nonprofit,);

      _connectedDevice = device;

      setState(() {});

      await discoverServices();

      _showMessage(
        "Conectado",
        Colors.green,
      );
    } catch (e) {
      _showMessage(
        e.toString(),
        Colors.red,
      );
    }
  }

  Future<void> disconnect() async {
    if (_connectedDevice == null) return;

    await _connectedDevice!.disconnect();

    setState(() {
      _connectedDevice = null;
      _services.clear();
    });
  }

  Future<void> discoverServices() async {
    if (_connectedDevice == null) return;

    try {
      _services = await _connectedDevice!.discoverServices();

      setState(() {});
    } catch (e) {
      _showMessage(
        e.toString(),
        Colors.red,
      );
    }
  }

  void _showMessage(
    String text,
    Color color,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        content: Text(text),
      ),
    );
  }

    Future<void> readBattery(BluetoothService service) async {
    for (final characteristic in service.characteristics) {
      final uuid = characteristic.uuid
          .toString()
          .toLowerCase();

      if (uuid.contains(batteryCharacteristic)) {
        try {
          final value = await characteristic.read();

          if (value.isNotEmpty) {
            final battery = value.first;
            _showMessage(
              "🔋 Batería: $battery%",
              Colors.indigo,
            );
          }
        } catch (e) {
          _showMessage(
            "Error leyendo batería: $e",
            Colors.red,
          );
        }
      }
    }
  }

  Future<void> subscribeHeartRate(
      BluetoothService service,
      ) async {
    for (final characteristic in service.characteristics) {
      final uuid = characteristic.uuid
          .toString()
          .toLowerCase();
      if (uuid.contains(heartRateCharacteristic)) {
        try {
          await characteristic.setNotifyValue(true);
          characteristic.lastValueStream.listen(
            (value) {
              if (value.isEmpty) return;
              int bpm;
              // Formato estándar BLE Heart Rate
              if ((value[0] & 0x01) == 0) {
                bpm = value[1];
              } else {
                bpm =
                    value[1] |
                    (value[2] << 8);
              }
              _showMessage(
                "❤️ Frecuencia cardíaca: $bpm BPM",
                Colors.redAccent,
              );
            },
          );
          _showMessage(
            "Sensor cardíaco activo",
            Colors.green,
          );
        } catch (e) {
          _showMessage(
            "No se pudo activar el sensor cardíaco: $e",
            Colors.orange,
          );

        }
      }
    }
  }

  Future<void> analyzeService(
      BluetoothService service,
      ) async {
    final uuid = service.uuid
        .toString()
        .toLowerCase();
    if (uuid.contains(batteryService)) {
      await readBattery(service);
    }
    if (uuid.contains(heartRateService)) {
      await subscribeHeartRate(service);
    }
  }

  String shortUuid(Guid uuid) {
    final text = uuid.toString();
    if (text.length > 12) {
      return "${text.substring(0, 12)}...";
    }
    return text;
  }

    @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _connectedDevice == null
              ? "Escáner BLE"
              : "Wearable conectado",
        ),
        backgroundColor: Colors.teal.shade100,
        actions: [
          if (_connectedDevice != null)
            IconButton(
              icon: const Icon(
                Icons.power_settings_new,
                color: Colors.red,
              ),
              onPressed: disconnect,
            ),
        ],
      ),

      body: _connectedDevice == null
          ? _buildScannerView()
          : _buildDeviceView(),


      floatingActionButton: _connectedDevice == null
          ? FloatingActionButton(
              backgroundColor: Colors.teal,
              onPressed: _isScanning
                  ? null
                  : startScan,
              child: Icon(
                _isScanning
                    ? Icons.bluetooth_searching
                    : Icons.search,
                color: Colors.white,
              ),
            )
          : null,
    );
  }

  Widget _buildScannerView() {
    if (_scanResults.isEmpty) {
      return const Center(
        child: Text(
          "Pulsa buscar para encontrar dispositivos BLE",
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      itemCount: _scanResults.length,

      itemBuilder: (context, index) {
        final result = _scanResults[index];
        final device = result.device;

        return Card(
          margin: const EdgeInsets.all(8),
          child: ListTile(
            leading: const Icon(
              Icons.watch,
              size: 35,
            ),
            title: Text(
              device.platformName.isEmpty
                  ? "Dispositivo desconocido"
                  : device.platformName,
            ),
            subtitle: Text(
              device.remoteId.toString(),
            ),
            trailing: ElevatedButton(
              child: const Text(
                "Conectar",
              ),
              onPressed: () {
                connect(device);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildDeviceView() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding:
              const EdgeInsets.all(16),
          color: Colors.teal.shade50,
          child: Text(

            "Conectado a:\n"
            "${_connectedDevice!.platformName}\n\n"
            "ID:\n"
            "${_connectedDevice!.remoteId}",

            style: const TextStyle(
              fontWeight: FontWeight.bold,

            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Servicios GATT",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _services.length,
            itemBuilder: (context,index){
              final service = _services[index];
              final uuid = service.uuid
                  .toString()
                  .toLowerCase();
              final isBattery =
                  uuid.contains(batteryService);
              final isHeart =
                  uuid.contains(heartRateService);
              return Card(
                margin:
                    const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                child: ExpansionTile(
                  title: Text(
                    shortUuid(
                      service.uuid,
                    ),
                  ),
                  subtitle: Text(
                    service.uuid.toString(),
                  ),
                  trailing:
                      (isBattery || isHeart)
                          ? const Icon(
                              Icons.play_circle,
                              color: Colors.teal,
                            )
                          : null,
                  onExpansionChanged:
                      (open) {
                    if (!open) return;
                    if (isBattery) {
                      analyzeService(
                        service,
                      );
                    }
                    if (isHeart) {
                      analyzeService(
                        service,
                      );
                    }
                  },
                  children: service
                      .characteristics
                      .map(
                    (characteristic) {
                      return ListTile(
                        title: Text(
                          shortUuid(
                            characteristic.uuid,
                          ),
                        ),
                        subtitle: Text(
                          "Read: "
                          "${characteristic.properties.read}\n"
                          "Write: "
                          "${characteristic.properties.write}\n"
                          "Notify: "
                          "${characteristic.properties.notify}",
                        ),
                      );
                    },
                  ).toList(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}