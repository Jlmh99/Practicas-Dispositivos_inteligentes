// Orquesta toda la PWA: login, reloj del header, grilla de juegos + D-pad,
// fondo multimedia con crossfade, panel de estadísticas, indicador offline
// y el atajo de depuración de la safe zone (tecla "S").
import { auth, onAuthStateChanged, signInWithEmailAndPassword } from './firebase-init.js';
import { escucharJuegos, escucharEstadisticas } from './firestore-service.js';
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

let dpad = null;
let unsubJuegos = null;
let unsubEstadisticas = null;
let todosLosJuegos = [];
let juegosActuales = [];
let relojIniciado = false;
let fondoActivoId = 'media-a';

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

onAuthStateChanged(auth, (usuario) => {
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

// ============================== DEBUG: SAFE ZONE (tecla "S") ==============================

document.addEventListener('keydown', (evento) => {
  const campoDeTexto =
    document.activeElement && ['INPUT', 'TEXTAREA'].includes(document.activeElement.tagName);
  if (campoDeTexto) return;

  if (evento.key === 's' || evento.key === 'S') {
    safeZoneEl.classList.toggle('mostrar-safe-zone');
  }
});
