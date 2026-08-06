// Orquesta toda la PWA: login, reloj del header, grilla de juegos + D-pad,
// fondo multimedia con crossfade, panel de estadísticas, indicador offline
// y los atajos de depuración de la safe zone (tecla "S") y cerrar sesión
// (tecla "L").
import { auth, onAuthStateChanged, signInWithEmailAndPassword, signOut } from './firebase-init.js';
import { escucharJuegos, escucharEstadisticas } from './firestore-service.js';
import { escucharSesionEnVivo } from './sync.js';
import { emitirToggleSafeZone, escucharToggleSafeZone } from './broadcast.js';
import { DpadNavigator } from './dpad.js';
import { registrarServiceWorker } from './sw-register.js';

registrarServiceWorker();

const loginScreen = document.getElementById('login-screen');
const loginForm = document.getElementById('login-form');
const loginEmail = document.getElementById('login-email');
const loginPassword = document.getElementById('login-password');
const loginError = document.getElementById('login-error');

const dashboard = document.getElementById('dashboard');
const safeZoneEl = document.getElementById('safe-zone');
const clockEl = document.getElementById('clock');
const dateEl = document.getElementById('date');
const gridEl = document.getElementById('games-grid');
const offlineEl = document.getElementById('offline-indicator');
const statPartidasEl = document.getElementById('stat-partidas');
const statTiempoEl = document.getElementById('stat-tiempo');
const statFavoritoEl = document.getElementById('stat-favorito');
const mediaA = document.getElementById('media-a');
const mediaB = document.getElementById('media-b');

const syncEstadoEl = document.getElementById('sync-estado');
const syncLatenciaEl = document.getElementById('sync-latencia');
const alertaSesionEl = document.getElementById('alerta-sesion');
const panelSesionVivoEl = document.getElementById('panel-sesion-vivo');
const sesionVivoJuegoEl = document.getElementById('sesion-vivo-juego');
const sesionVivoTiempoEl = document.getElementById('sesion-vivo-tiempo');
const sesionVivoHeartrateEl = document.getElementById('sesion-vivo-heartrate');
const sesionVivoMovesEl = document.getElementById('sesion-vivo-moves');
const sesionVivoFocusEl = document.getElementById('sesion-vivo-focus');

let dpad = null;
let unsubJuegos = null;
let unsubEstadisticas = null;
let unsubSync = null;
let todosLosJuegos = [];
let juegosActuales = [];
let relojIniciado = false;
let fondoActivoId = 'media-a';
let ultimoActualizadoEnMillis = null;
let tickerLatencia = null;
let gameIdSincronizado = null;

// ============================== AUTENTICACIÓN ==============================
// Firebase Auth persiste la sesión en IndexedDB: solo hace falta iniciar
// sesión una vez por navegador; en la demo ya arranca autenticada.

loginForm.addEventListener('submit', async (evento) => {
  evento.preventDefault();
  loginError.hidden = true;
  try {
    await signInWithEmailAndPassword(auth, loginEmail.value.trim(), loginPassword.value);
  } catch (error) {
    // El código crudo se queda en consola (nunca en pantalla) para poder
    // diagnosticar errores que traducirErrorAuth no reconoce todavía.
    console.error('[login] Error de Firebase Auth:', error.code, error.message);
    loginError.textContent = traducirErrorAuth(error.code);
    loginError.hidden = false;
  }
});

function traducirErrorAuth(code) {
  switch (code) {
    case 'auth/invalid-email':
      return 'El correo no tiene un formato válido.';
    case 'auth/user-not-found':
    case 'auth/wrong-password':
    case 'auth/invalid-credential':
      return 'Correo o contraseña incorrectos.';
    case 'auth/too-many-requests':
      return 'Demasiados intentos. Intenta de nuevo más tarde.';
    case 'auth/network-request-failed':
      return 'Sin conexión a internet.';
    default:
      return 'Ocurrió un error inesperado. Intenta de nuevo.';
  }
}

// Purga la parte de la caché del SW que corresponde a Firestore (ver
// sw.js) antes de que se suscriba ningún listener de la cuenta que sea —
// así ninguna respuesta cacheada de una cuenta anterior puede quedar
// disponible para networkFirst() si la red falla justo tras el cambio.
function invalidarCacheFirestore() {
  if (navigator.serviceWorker.controller) {
    navigator.serviceWorker.controller.postMessage({ tipo: 'invalidar-cache-firestore' });
  }
}

onAuthStateChanged(auth, (usuario) => {
  invalidarCacheFirestore();

  if (usuario) {
    loginScreen.hidden = true;
    dashboard.hidden = false;
    iniciarReloj();

    if (unsubJuegos) unsubJuegos();
    unsubJuegos = escucharJuegos((juegos) => {
      todosLosJuegos = juegos;
      renderizarJuegos(juegos);
    });

    if (unsubEstadisticas) unsubEstadisticas();
    unsubEstadisticas = escucharEstadisticas(usuario.uid, (estadisticas) => {
      statPartidasEl.textContent = estadisticas.partidasTotales;
      statTiempoEl.textContent = formatearDuracion(estadisticas.tiempoTotalSeg);
      statFavoritoEl.textContent = estadisticas.juegoMasJugado
        ? nombreDeJuego(estadisticas.juegoMasJugado)
        : '—';
    });

    if (unsubSync) unsubSync();
    unsubSync = escucharSesionEnVivo(usuario.uid, {
      onCambio: onCambioSesionEnVivo,
      onSinSesion: ocultarSesionEnVivo,
      onError: (reintentando) => {
        syncEstadoEl.hidden = !reintentando;
      },
    });
    iniciarTickerLatencia();
  } else {
    loginScreen.hidden = false;
    dashboard.hidden = true;

    if (unsubJuegos) {
      unsubJuegos();
      unsubJuegos = null;
    }
    if (unsubEstadisticas) {
      unsubEstadisticas();
      unsubEstadisticas = null;
    }
    if (unsubSync) {
      unsubSync();
      unsubSync = null;
    }
    detenerTickerLatencia();
    ocultarSesionEnVivo();
    if (dpad) {
      dpad.desactivar();
      dpad = null;
    }
  }
});

function nombreDeJuego(id) {
  const juego = todosLosJuegos.find((j) => j.id === id);
  return juego ? juego.nombre : id;
}

function formatearDuracion(totalSegundos) {
  const horas = Math.floor(totalSegundos / 3600);
  const minutos = Math.floor((totalSegundos % 3600) / 60);
  if (horas > 0) return `${horas} h ${minutos} min`;
  return `${minutos} min`;
}

// ============================== RELOJ / FECHA ==============================

function iniciarReloj() {
  if (relojIniciado) return;
  relojIniciado = true;

  const formatoFecha = new Intl.DateTimeFormat('es-MX', {
    weekday: 'long',
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  });

  function actualizar() {
    const ahora = new Date();
    clockEl.textContent = ahora.toLocaleTimeString('es-MX', {
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
    });
    dateEl.textContent = formatoFecha.format(ahora);
  }

  actualizar();
  setInterval(actualizar, 1000);
}

// ============================== GRILLA 2×2 + D-PAD ==============================

function renderizarJuegos(juegos) {
  juegosActuales = juegos.slice(0, 4); // grid fijo de 2×2 = 4 tarjetas
  gridEl.innerHTML = '';

  juegosActuales.forEach((juego) => {
    const tarjeta = document.createElement('div');
    tarjeta.className = 'game-card' + (juego.estado !== 'disponible' ? ' proximamente' : '');
    tarjeta.setAttribute('role', 'listitem');

    if (juego.estado !== 'disponible') {
      const badge = document.createElement('span');
      badge.className = 'card-badge';
      badge.textContent = 'Próximamente';
      tarjeta.appendChild(badge);
    }

    const nombre = document.createElement('div');
    nombre.className = 'card-nombre';
    nombre.textContent = juego.nombre;

    const dificultad = document.createElement('div');
    dificultad.className = 'card-dificultad';
    dificultad.textContent = juego.dificultad;

    const jugadas = document.createElement('div');
    jugadas.className = 'card-jugadas';
    jugadas.textContent = `${juego.jugadas} jugadas`;

    tarjeta.append(nombre, dificultad, jugadas);
    gridEl.appendChild(tarjeta);
  });

  if (dpad) {
    dpad.reajustar();
  } else {
    iniciarDpad();
  }

  marcarTarjetaSincronizada(gameIdSincronizado); // el re-render de arriba borró el ::after pulsante
}

function iniciarDpad() {
  dpad = new DpadNavigator({
    contarItems: () => juegosActuales.length,
    onFoco: (indice) => {
      const tarjetas = gridEl.querySelectorAll('.game-card');
      tarjetas.forEach((el, i) => el.classList.toggle('enfocada', i === indice));
    },
    onSeleccionar: (indice) => {
      const juego = juegosActuales[indice];
      if (juego) establecerFondo(juego.mediaUrl);
    },
  });
  dpad.activar();
}

// ============================== SYNC EN VIVO (sessionState/{uid}) ==============================
// Corazón del ecosistema: lo que llega aquí viene de js/sync.js (onSnapshot,
// sin polling) y debe reflejarse en la TV en < 2 s (SA.5) — de ahí la
// latencia pintada en el header, calculada con cada tick del ticker de abajo.

function onCambioSesionEnVivo(datos, fromCache) {
  syncEstadoEl.hidden = !fromCache;
  ultimoActualizadoEnMillis = datos.actualizadoEn ? datos.actualizadoEn.toMillis() : null;
  actualizarLatencia();

  const activo = typeof datos.activityStatus === 'string' && datos.activityStatus.startsWith('JUGANDO');

  marcarTarjetaSincronizada(activo ? datos.gameId : null);

  if (activo) {
    panelSesionVivoEl.hidden = false;
    sesionVivoJuegoEl.textContent = datos.gameId ? nombreDeJuego(datos.gameId) : '—';
    sesionVivoTiempoEl.textContent = formatearMMSS(datos.sessionSeconds || 0);
    sesionVivoHeartrateEl.textContent = `${datos.heartRate || 0} bpm`;
    sesionVivoMovesEl.textContent = `${datos.moves || 0}`;
    sesionVivoFocusEl.textContent = `${Math.round(datos.focusLevel || 0)}%`;
  } else {
    panelSesionVivoEl.hidden = true;
  }

  // Clase, no [hidden]: la alerta debe seguir reservando su lugar en el
  // flujo aunque no esté activa, para que el alto de .main (y por lo tanto
  // el de la card de al lado) nunca cambie según su estado — ver tv.css.
  alertaSesionEl.classList.toggle('activa', Boolean(datos.alertaActiva));
}

function ocultarSesionEnVivo() {
  panelSesionVivoEl.hidden = true;
  alertaSesionEl.classList.remove('activa');
  marcarTarjetaSincronizada(null);
  ultimoActualizadoEnMillis = null;
  actualizarLatencia();
}

function marcarTarjetaSincronizada(gameId) {
  gameIdSincronizado = gameId; // recordado para reaplicar tras un re-render de renderizarJuegos()
  const indice = gameId ? juegosActuales.findIndex((j) => j.id === gameId) : -1;
  gridEl.querySelectorAll('.game-card').forEach((el, i) => {
    el.classList.toggle('sync-activo', i === indice);
  });
}

function formatearMMSS(totalSegundos) {
  const minutos = Math.floor(totalSegundos / 60);
  const segundos = totalSegundos % 60;
  return `${String(minutos).padStart(2, '0')}:${String(segundos).padStart(2, '0')}`;
}

function iniciarTickerLatencia() {
  if (tickerLatencia) return;
  tickerLatencia = setInterval(actualizarLatencia, 1000);
}

function detenerTickerLatencia() {
  clearInterval(tickerLatencia);
  tickerLatencia = null;
  syncLatenciaEl.hidden = true;
  syncEstadoEl.hidden = true;
}

function actualizarLatencia() {
  if (ultimoActualizadoEnMillis == null) {
    syncLatenciaEl.hidden = true;
    return;
  }
  const ms = Date.now() - ultimoActualizadoEnMillis;
  syncLatenciaEl.hidden = false;
  syncLatenciaEl.textContent = `Sync: ${(ms / 1000).toFixed(1)}s`;
  syncLatenciaEl.classList.toggle('latencia-alta', ms > 2000);
}

// ============================== FONDO MULTIMEDIA (crossfade) ==============================

function establecerFondo(url) {
  const idActual = fondoActivoId;
  const idSiguiente = idActual === 'media-a' ? 'media-b' : 'media-a';
  const imgActual = idActual === 'media-a' ? mediaA : mediaB;
  const imgSiguiente = idSiguiente === 'media-a' ? mediaA : mediaB;

  const candidatos = [url, './assets/media/fallback.png'];
  let indice = 0;

  function intentarCargar() {
    if (indice >= candidatos.length) {
      // Ni la imagen del juego ni el fallback cargaron: degradado sólido,
      // nunca un hueco roto.
      imgSiguiente.removeAttribute('src');
      imgSiguiente.onload = null;
      imgSiguiente.onerror = null;
      imgSiguiente.style.background = 'linear-gradient(135deg, #0f0f1a, #1a1a3a)';
      hacerCrossfade();
      return;
    }
    imgSiguiente.onload = () => {
      imgSiguiente.style.background = '';
      hacerCrossfade();
    };
    imgSiguiente.onerror = () => {
      indice += 1;
      intentarCargar();
    };
    imgSiguiente.src = candidatos[indice];
  }

  function hacerCrossfade() {
    imgSiguiente.classList.add('activa');
    imgActual.classList.remove('activa');
    fondoActivoId = idSiguiente;
  }

  intentarCargar();
}

// ============================== OFFLINE ==============================

function actualizarIndicadorOffline() {
  offlineEl.hidden = navigator.onLine;
}
window.addEventListener('online', actualizarIndicadorOffline);
window.addEventListener('offline', actualizarIndicadorOffline);
actualizarIndicadorOffline();

// ============================== DEBUG: SAFE ZONE (tecla "S") / CERRAR SESIÓN (tecla "L") ==============================
// El toggle de safe zone se propaga por BroadcastChannel a otras pestañas de
// la misma PWA (ej. la TV reflejada en dos ventanas durante la demo).
//
// No hay botón de "cerrar sesión" visible en el dashboard a propósito — es
// una TV, no un teléfono, y Firebase Auth persiste la sesión en IndexedDB
// para que la demo arranque siempre ya autenticada. Pero probando con más
// de una cuenta (ej. para no arrastrar datos viejos de otra cuenta en las
// estadísticas) hace falta alguna forma de volver al login sin borrar el
// storage del navegador a mano — de ahí este atajo.
document.addEventListener('keydown', (evento) => {
  const campoDeTexto =
    document.activeElement && ['INPUT', 'TEXTAREA'].includes(document.activeElement.tagName);
  if (campoDeTexto) return;

  if (evento.key === 's' || evento.key === 'S') {
    const mostrar = safeZoneEl.classList.toggle('mostrar-safe-zone');
    emitirToggleSafeZone(mostrar);
  } else if (evento.key === 'l' || evento.key === 'L') {
    if (!dashboard.hidden) signOut(auth);
  }
});

escucharToggleSafeZone((mostrar) => {
  safeZoneEl.classList.toggle('mostrar-safe-zone', mostrar);
});
