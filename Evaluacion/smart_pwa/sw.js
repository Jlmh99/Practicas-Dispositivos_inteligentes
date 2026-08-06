// Service Worker de Mind Games TV.
// - Cache First para el app shell (html/css/js/iconos/media): responde
//   desde cache al instante, y si no está, va a red y la guarda.
// - firestore.googleapis.com: SIN intervención del Service Worker (ver nota
//   en el listener de "fetch" más abajo — hubo una versión anterior que sí
//   lo cacheaba, pero exponía un riesgo real de cruzar datos entre cuentas).

const CACHE_VERSION = 'mind-games-tv-v8';

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

  // Firestore: dejarlo pasar sin tocar. Su canal de datos en tiempo real
  // (WebChannel) hace GET de long-polling contra la MISMA ruta
  // (".../Listen/channel") para sesiones de CUENTAS distintas — solo cambia
  // el query string (SID de la conexión). Una versión anterior de este
  // Service Worker cacheaba estas respuestas por Request (Cache API, que
  // por defecto compara la URL completa) pensando que así sobrevivía el
  // modo offline — pero si la red fallaba justo al cambiar de cuenta, existía
  // el riesgo real de servir una respuesta vieja de OTRA sesión ya
  // cacheada. Quitado por seguridad: además resultó innecesario, porque el
  // indicador "sin conexión, mostrando últimos datos" ya funciona solo con
  // el comportamiento nativo del SDK — cada `onSnapshot` activo se queda
  // pintando su último valor en memoria aunque la red se caiga, sin que el
  // Service Worker tenga que guardar ni servir nada.
  if (url.hostname === 'firestore.googleapis.com') return;

  // Todo lo demás que sea de nuestro propio origen: cache primero.
  if (url.origin === self.location.origin) {
    event.respondWith(cacheFirst(event.request));
  }
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
