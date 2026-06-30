import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../ble_constants.dart';
import '../models/activity_data.dart';

class BleClient {
  BluetoothDevice? _device;

  final List<StreamSubscription> _subs = [];

  final _dataCtrl = StreamController<ActivityData>.broadcast();

  Stream<ActivityData> get dataStream => _dataCtrl.stream;

  bool _connected = false;

  bool get isConnected => _connected;

  ActivityData _current = ActivityData(
    steps: 0,
    heartRate: 0,
    calories: 0,
    status: 'sin datos',
    timestamp: DateTime.now(),
  );

  Future<void> scanAndConnect() async {
    print('[BleClient] Escaneando...');

    final completer = Completer<BluetoothDevice>();

    final scanSub = FlutterBluePlus.scanResults.listen((results) {
      for (final result in results) {
        final uuids = result.advertisementData.serviceUuids
            .map((e) => e.toString().toLowerCase());

        if (uuids.contains(BleConstants.serviceUUID.toLowerCase())) {
          if (!completer.isCompleted) {
            completer.complete(result.device);
          }
        }
      }
    });

    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 15),
    );

    try {
      _device = await completer.future.timeout(
        const Duration(seconds: 16),
      );
    } finally {
      await FlutterBluePlus.stopScan();
      await scanSub.cancel();
    }

    await _connect();
  }

  Future<void> _connect() async {
    await _device!.connect(license: License.nonprofit,);

    _connected = true;

    _device!.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        _connected = false;
      }
    });

    await _discoverAndSubscribe();
  }

  Future<void> _discoverAndSubscribe() async {
    final services = await _device!.discoverServices();

    for (final service in services) {
      if (service.uuid.toString().toLowerCase() !=
          BleConstants.serviceUUID.toLowerCase()) {
        continue;
      }

      for (final characteristic in service.characteristics) {
        final uuid = characteristic.uuid.toString().toLowerCase();

        if (characteristic.properties.notify) {
          await characteristic.setNotifyValue(true);
        }

        final sub = characteristic.lastValueStream.listen((value) {
          _handleValue(uuid, value);
        });

        _subs.add(sub);
      }
    }
  }

  void _handleValue(String uuid, List<int> bytes) {
    if (bytes.isEmpty) return;

    try {
      if (uuid == BleConstants.stepsUUID.toLowerCase()) {
        final bd = ByteData.sublistView(Uint8List.fromList(bytes));

        _current = _current.copyWith(
          steps: bd.getInt32(0, Endian.little),
        );
      } else if (uuid == BleConstants.heartRateUUID.toLowerCase()) {
        _current = _current.copyWith(
          heartRate: bytes.first,
        );
      } else if (uuid == BleConstants.caloriesUUID.toLowerCase()) {
        final bd = ByteData.sublistView(Uint8List.fromList(bytes));

        _current = _current.copyWith(
          calories: bd.getInt16(0, Endian.little),
        );
      } else if (uuid == BleConstants.statusUUID.toLowerCase()) {
        _current = _current.copyWith(
          status: utf8.decode(bytes),
        );
      }

      _dataCtrl.add(_current);
    } catch (e) {
      print(e);
    }
  }

  Future<void> disconnect() async {
    for (final sub in _subs) {
      await sub.cancel();
    }

    _subs.clear();

    await _device?.disconnect();

    _connected = false;
  }

  void dispose() {
    _dataCtrl.close();
  }
}