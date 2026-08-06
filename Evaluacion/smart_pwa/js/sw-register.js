// Registra el Service Worker. localhost cuenta como contexto seguro para
// esto (no hace falta HTTPS real).
export function registrarServiceWorker() {
  if (!('serviceWorker' in navigator)) return;

  window.addEventListener('load', () => {
    navigator.serviceWorker
      .register('./sw.js')
      .then((registro) => {
        console.log('[sw-register] Service Worker registrado:', registro.scope);
      })
      .catch((error) => {
        console.error('[sw-register] Falló el registro del Service Worker:', error);
      });
  });
}
