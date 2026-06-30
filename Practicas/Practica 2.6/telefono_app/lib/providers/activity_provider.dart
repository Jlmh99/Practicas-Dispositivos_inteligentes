import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/activity_data.dart';
import '../services/ble_client.dart';

enum ConnectionStatus {
  disconnected,
  scanning,
  connected,
  error,
}

class ActivityState {
  final ActivityData data;
  final ConnectionStatus status;
  final String? errorMessage;

  const ActivityState({
    required this.data,
    required this.status,
    this.errorMessage,
  });

  ActivityState copyWith({
    ActivityData? data,
    ConnectionStatus? status,
    String? errorMessage,
  }) {
    return ActivityState(
      data: data ?? this.data,
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }
}

class ActivityNotifier extends Notifier<ActivityState> {
  final BleClient _client = BleClient();

  StreamSubscription<ActivityData>? _subscription;

  @override
  ActivityState build() {
    ref.onDispose(() {
      _subscription?.cancel();
      _client.dispose();
    });

    return ActivityState(
      data: ActivityData(
        steps: 0,
        heartRate: 0,
        calories: 0,
        status: 'sin datos',
        timestamp: DateTime.now(),
      ),
      status: ConnectionStatus.disconnected,
    );
  }

  Future<void> connect() async {
    state = state.copyWith(
      status: ConnectionStatus.scanning,
      errorMessage: null,
    );

    try {
      await _client.scanAndConnect();

      state = state.copyWith(
        status: ConnectionStatus.connected,
      );

      _subscription = _client.dataStream.listen((data) {
        state = state.copyWith(data: data);
      });
    } catch (e) {
      state = state.copyWith(
        status: ConnectionStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> disconnect() async {
    await _subscription?.cancel();
    await _client.disconnect();

    state = state.copyWith(
      status: ConnectionStatus.disconnected,
    );
  }
}

// ✅ ESTO VA FUERA DE LA CLASE
final activityProvider =
    NotifierProvider<ActivityNotifier, ActivityState>(
  ActivityNotifier.new,
);