import 'package:cloud_firestore/cloud_firestore.dart';

import 'models/juego.dart';
import 'models/sesion_guardada.dart';
import 'models/session_state.dart';

/// Acceso a Firestore: catálogo de juegos, estado de sesión en vivo
/// (`sessionState/{uid}`, el corazón del sync con la TV) e historial de
/// sesiones (`users/{uid}/sessions`).
class FirestoreRepository {
  FirestoreRepository({FirebaseFirestore? firestore}) : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Stream<List<Juego>> juegosStream() {
    return _db.collection('games').orderBy('orden').snapshots().map(
          (snap) => snap.docs.map((doc) => Juego.fromFirestore(doc.id, doc.data())).toList(),
        );
  }

  /// Escribe `sessionState/{uid}` con merge — la TV lo escucha con
  /// `onSnapshot`. Requisito: propagación < 2 s.
  Future<void> publicarEstadoSesion(String uid, SessionState estado) {
    return _db.collection('sessionState').doc(uid).set(estado.toFirestore(), SetOptions(merge: true));
  }

  /// Agrega un resumen a `users/{uid}/sessions` cuando se detiene la sesión.
  Future<void> guardarSesion(String uid, SesionGuardada sesion) {
    return _db.collection('users').doc(uid).collection('sessions').add(sesion.toFirestore());
  }
}
