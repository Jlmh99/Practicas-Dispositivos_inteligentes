// Capa de datos del sync teléfono→TV: escucha `sessionState/{uid}` con
// onSnapshot (sin polling, es el corazón del ecosistema — CLAUDE.md). Solo
// Firestore aquí, ningún DOM (igual que firestore-service.js); el
// renderizado vive en app.js.
import { db, doc, onSnapshot } from './firebase-init.js';

const REINTENTO_MS = 3000;

/**
 * @param {string} uid
 * @param {Object} callbacks
 * @param {(datos: object, fromCache: boolean) => void} callbacks.onCambio
 *   Datos crudos del documento en cada cambio. `fromCache` viene de
 *   `snapshot.metadata.fromCache` — es la señal real de "sin red ahora
 *   mismo, esto es lo último que se guardó localmente" (más confiable que
 *   esperar a que el callback de error dispare, que Firestore reserva para
 *   fallas duras como permisos, no para cortes de red transitorios: esos
 *   los reintenta solo, por dentro, sin avisar).
 * @param {() => void} [callbacks.onSinSesion] El documento no existe
 *   todavía (nunca se ha iniciado sesión desde el teléfono).
 * @param {(reintentando: boolean) => void} [callbacks.onError] El listener
 *   falló de verdad (ej. permisos). Dispara el reintento automático.
 * @returns {() => void} unsubscribe
 */
export function escucharSesionEnVivo(uid, { onCambio, onSinSesion, onError }) {
  const ref = doc(db, 'sessionState', uid);
  let cancelado = false;
  let unsubscribe = null;
  let timeoutReintento = null;

  function suscribir() {
    unsubscribe = onSnapshot(
      ref,
      { includeMetadataChanges: true },
      (snapshot) => {
        if (snapshot.exists()) {
          onCambio(snapshot.data(), snapshot.metadata.fromCache);
        } else if (onSinSesion) {
          onSinSesion();
        }
      },
      (error) => {
        console.error('[sync] Listener de sessionState se cayó:', error);
        if (onError) onError(true);
        // Reintento automático: Firestore ya reconecta solo en cortes
        // transitorios, pero si el listener llega a morir del todo (ej. el
        // token expiró y las reglas rechazan hasta que se refresca) esto lo
        // vuelve a levantar sin que el usuario tenga que recargar la TV.
        timeoutReintento = setTimeout(() => {
          if (!cancelado) suscribir();
        }, REINTENTO_MS);
      },
    );
  }

  suscribir();

  return () => {
    cancelado = true;
    if (timeoutReintento) clearTimeout(timeoutReintento);
    if (unsubscribe) unsubscribe();
  };
}
