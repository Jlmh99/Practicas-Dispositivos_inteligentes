// Capa de datos del sync teléfono→TV: escucha `sessionState/{uid}` con
// onSnapshot (sin polling, es el corazón del ecosistema — CLAUDE.md). Solo
// Firestore aquí, ningún DOM (igual que firestore-service.js); el
// renderizado vive en app.js.
import { db, doc, onSnapshot } from './firebase-init.js';

const REINTENTO_MS = 3000;
const VIGIA_INTERVALO_MS = 4000;
// Si pasa más de esto SIN NINGÚN evento (ni de metadata) MIENTRAS debería
// haber una sesión activa escribiendo cada ~2s, se asume colgado y se
// fuerza una reconexión — visto en vivo bajo carga de los 3 dispositivos:
// el indicador de latencia se quedaba subiendo sin límite, sin disparar el
// callback de error ni el aviso de "Reconectando" (onSnapshot no siempre
// nota su propio cuelgue bajo presión de CPU). 15s da margen de sobra para
// que una reconexión genuinamente lenta bajo carga (~2-5s típico) no se
// confunda con un cuelgue real y dispare reconexiones de más.
const VIGIA_UMBRAL_MS = 15000;

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
  let vigiaIntervalo = null;
  let ultimoEventoMillis = Date.now();
  // Gatea el vigía: si la ÚLTIMA sesión conocida no estaba "JUGANDO", el
  // teléfono legítimamente puede no escribir nada por rato (debounce en
  // session_sync_provider.dart — no escribe si nada cambió), y eso NO es un
  // cuelgue. Sin este gate, el vigía dispararía reconexiones de más cada
  // vez que el usuario esté inactivo, no solo cuando de verdad esté colgado.
  let sesionActivaConocida = false;

  function suscribir() {
    ultimoEventoMillis = Date.now();
    unsubscribe = onSnapshot(
      ref,
      { includeMetadataChanges: true },
      (snapshot) => {
        ultimoEventoMillis = Date.now();
        if (snapshot.exists()) {
          const datos = snapshot.data();
          sesionActivaConocida =
            typeof datos.activityStatus === 'string' && datos.activityStatus.startsWith('JUGANDO');
          onCambio(datos, snapshot.metadata.fromCache);
        } else if (onSinSesion) {
          sesionActivaConocida = false;
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

  // Vigía: onSnapshot no siempre nota su propio cuelgue (visto en vivo bajo
  // carga de los 3 dispositivos — el indicador de latencia se quedaba
  // subiendo sin límite, sin error ni "Reconectando"). Si pasan
  // VIGIA_UMBRAL_MS sin NINGÚN evento (ni siquiera uno de metadata), se
  // fuerza una resuscripción desde cero.
  vigiaIntervalo = setInterval(() => {
    if (cancelado || !sesionActivaConocida) return;
    if (Date.now() - ultimoEventoMillis > VIGIA_UMBRAL_MS) {
      console.warn(
        `[sync] Sin eventos de Firestore en ${VIGIA_UMBRAL_MS}ms — forzando reconexión.`,
      );
      if (onError) onError(true);
      if (unsubscribe) unsubscribe();
      suscribir();
    }
  }, VIGIA_INTERVALO_MS);

  return () => {
    cancelado = true;
    if (timeoutReintento) clearTimeout(timeoutReintento);
    if (vigiaIntervalo) clearInterval(vigiaIntervalo);
    if (unsubscribe) unsubscribe();
  };
}
