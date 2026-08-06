// Capa de datos: catálogo de juegos (colección `games`) y estadísticas del
// usuario calculadas sumando `users/{uid}/sessions`. Todo con `onSnapshot`
// (tiempo real), nunca `getDocs` de una sola vez.
import { db, collection, query, orderBy, onSnapshot } from './firebase-init.js';

/**
 * Escucha `games` ordenado por `orden` y llama a `callback` con la lista
 * completa cada vez que cambia. Devuelve la función `unsubscribe`.
 */
export function escucharJuegos(callback, onError) {
  const juegosQuery = query(collection(db, 'games'), orderBy('orden'));
  return onSnapshot(
    juegosQuery,
    (snapshot) => {
      const juegos = snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
      callback(juegos);
    },
    (error) => {
      console.error('[firestore-service] Error escuchando games:', error);
      if (onError) onError(error);
    },
  );
}

/**
 * Escucha `users/{uid}/sessions` y llama a `callback` con las estadísticas
 * ya calculadas (partidas totales, tiempo total, juego más jugado).
 */
export function escucharEstadisticas(uid, callback, onError) {
  const sesionesQuery = query(collection(db, 'users', uid, 'sessions'));
  return onSnapshot(
    sesionesQuery,
    (snapshot) => {
      const sesiones = snapshot.docs.map((doc) => doc.data());
      callback(calcularEstadisticas(sesiones));
    },
    (error) => {
      console.error('[firestore-service] Error escuchando sessions:', error);
      if (onError) onError(error);
    },
  );
}

/** Pura, sin Firestore — así se puede probar aparte. */
export function calcularEstadisticas(sesiones) {
  const partidasTotales = sesiones.length;
  const tiempoTotalSeg = sesiones.reduce((acumulado, s) => acumulado + (s.sessionSeconds || 0), 0);

  const conteoPorJuego = new Map();
  for (const sesion of sesiones) {
    if (!sesion.gameId) continue;
    conteoPorJuego.set(sesion.gameId, (conteoPorJuego.get(sesion.gameId) || 0) + 1);
  }

  let juegoMasJugado = null;
  let maxConteo = 0;
  for (const [id, conteo] of conteoPorJuego) {
    if (conteo > maxConteo) {
      maxConteo = conteo;
      juegoMasJugado = id;
    }
  }

  return { partidasTotales, tiempoTotalSeg, juegoMasJugado };
}
