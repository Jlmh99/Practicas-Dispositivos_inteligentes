import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/firestore_repository.dart';
import '../data/models/juego.dart';

final firestoreRepositoryProvider = Provider<FirestoreRepository>((ref) => FirestoreRepository());

final juegosStreamProvider = StreamProvider<List<Juego>>((ref) {
  return ref.watch(firestoreRepositoryProvider).juegosStream();
});

/// Id del juego elegido en [GamesList] (juego "disponible" que el usuario
/// tocó), usado como `sessionState.gameId`.
class JuegoSeleccionadoNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void seleccionar(String id) => state = id;
}

final juegoSeleccionadoProvider =
    NotifierProvider<JuegoSeleccionadoNotifier, String?>(JuegoSeleccionadoNotifier.new);
