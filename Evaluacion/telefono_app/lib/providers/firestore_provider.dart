import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/firestore_repository.dart';
import '../data/models/juego.dart';
import 'ble_provider.dart';

final firestoreRepositoryProvider = Provider<FirestoreRepository>((ref) => FirestoreRepository());

final juegosStreamProvider = StreamProvider<List<Juego>>((ref) {
  return ref.watch(firestoreRepositoryProvider).juegosStream();
});

/// Id del juego elegido en [GamesList] (juego "disponible" que el usuario
/// tocó), usado como `sessionState.gameId`.
class JuegoSeleccionadoNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  /// También avisa al wearable por BLE (CHAR_GAME_SELECT): sin esto, su
  /// propio CHAR_STATUS ("JUGANDO:...") se queda con el nombre local que
  /// trae hardcodeado, sin relación con lo que el usuario eligió aquí.
  void seleccionar(String id) {
    state = id;
    unawaited(ref.read(bleClientProvider).enviarJuegoSeleccionado(id));
  }
}

final juegoSeleccionadoProvider =
    NotifierProvider<JuegoSeleccionadoNotifier, String?>(JuegoSeleccionadoNotifier.new);
