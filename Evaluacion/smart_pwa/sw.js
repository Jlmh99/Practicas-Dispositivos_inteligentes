// Service Worker de Mind Games TV.
// - Cache First para el app shell (html/css/js/iconos/media): responde
//   desde cache al instante, y si no está, va a red y la guarda.
// - Network First (con fallback a cache) para firestore.googleapis.com:
//   intenta la red primero (datos en vivo), y si no hay red, sirve la
//   última respuesta guardada. Una versión anterior de esto SIN el mensaje
//   'invalidar-cache-firestore' de abajo tenía un riesgo real de cruzar
//   datos entre cuentas si la red fallaba justo al cambiar de sesión — se
//   quitó por completo en esa ronda, y ahora vuelve pero cerrando el hueco
//   de raíz: app.js manda ese mensaje en CADA transición de
//   onAuthStateChanged (login Y logout), así que ninguna respuesta cacheada
//   de una cuenta puede sobrevivir para la siguiente.

const CACHE_VERSION = 'mind-games-tv-v12';

const APP_SHELL = [
  './',
  './index.html',
  './manifest.json',
  './css/reset.css',
  './css/tv.css',
  './js/app.js',
  './js/dpad.js',
  './js/firebase-init.js',
  './js/firebase-config.js',
  './js/firestore-service.js',
  './js/sync.js',
  './js/broadcast.js',
  './js/sw-register.js',
  './js/vendor/firebase-app.js',
  './js/vendor/firebase-auth.js',
  './js/vendor/firebase-firestore.js',
  './assets/icons/icon-192.png',
  './assets/icons/icon-512.png',
  './assets/media/Logo.png',
  './assets/media/fallback.png',
  './assets/media/ahorcado.png',
  './assets/media/crucigrama.png',
  './assets/media/sopa-letras.png',
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches
      .open(CACHE_VERSION)
      .then((cache) => cache.addAll(APP_SHELL))
      .catch((error) => {
        // Si un solo recurso del precache falla (ej. falta un ícono),
        // no queremos que TODO el install truene sin explicación.
        console.error('[sw] Falló el precache del app shell:', error);
      }),
  );
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches
      .keys()
      .then((nombres) =>
        Promise.all(
          nombres
            .filter((nombre) => nombre !== CACHE_VERSION)
            .map((nombre) => caches.delete(nombre)),
        ),
      )
      .then(() => self.clients.claim()),
  );
});

self.addEventListener('fetch', (event) => {
  const url = new URL(event.request.url);

  if (event.request.method !== 'GET') return;

  // Datos en vivo de Firestore: red primero, cache como respaldo offline.
  // Seguro porque app.js purga esta parte de la caché en cada cambio de
  // sesión (ver el listener de 'message' más abajo) — nunca sobrevive una
  // respuesta de la cuenta anterior para la siguiente.
  if (url.hostname === 'firestore.googleapis.com') {
    event.respondWith(networkFirst(event.request));
    return;
  }

  // Todo lo demás que sea de nuestro propio origen: cache primero.
  if (url.origin === self.location.origin) {
    event.respondWith(cacheFirst(event.request));
  }
});

// app.js manda esto en CADA transición de onAuthStateChanged (login y
// logout), antes de suscribir los listeners de la cuenta nueva — así
// ninguna respuesta de Firestore cacheada de la cuenta anterior puede
// quedar disponible para que networkFirst() la sirva por error si la red
// falla justo después de cambiar de sesión.
self.addEventListener('message', (event) => {
  if (!event.data || event.data.tipo !== 'invalidar-cache-firestore') return;
  event.waitUntil(
    caches.open(CACHE_VERSION).then(async (cache) => {
      const requests = await cache.keys();
      await Promise.all(
        requests
          .filter((req) => new URL(req.url).hostname === 'firestore.googleapis.com')
          .map((req) => cache.delete(req)),
      );
    }),
  );
});

async function cacheFirst(request) {
  const cacheado = await caches.match(request);
  if (cacheado) return cacheado;

  const respuesta = await fetch(request);
  if (respuesta.ok) {
    const cache = await caches.open(CACHE_VERSION);
    cache.put(request, respuesta.clone());
  }
  return respuesta;
}

async function networkFirst(request) {
  try {
    const respuesta = await fetch(request);
    if (respuesta.ok) {
      const cache = await caches.open(CACHE_VERSION);
      cache.put(request, respuesta.clone());
    }
    return respuesta;
  } catch (error) {
    const cacheado = await caches.match(request);
    if (cacheado) return cacheado;
    throw error;
  }
}
