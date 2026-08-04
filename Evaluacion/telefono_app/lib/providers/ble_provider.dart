import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ble/ble_client.dart';
import '../ble/estado_conexion_ble.dart';

/// Instancia única de [BleClient] para toda la app. Arranca el ciclo de
/// escaneo/conexión apenas se crea y se limpia sola al hacer dispose del
/// `ProviderScope`.
final bleClientProvider = Provider<BleClient>((ref) {
  final client = BleClient();
  client.iniciar();
  ref.onDispose(client.dispose);
  return client;
});

/// Estado de conexión BLE en vivo, para pintar [ConnectionBadge] y decidir
/// si el botón de control tiene sentido mostrarse.
final estadoConexionProvider = StreamProvider<EstadoConexionBle>((ref) {
  final client = ref.watch(bleClientProvider);
  return client.estadoConexion;
});
