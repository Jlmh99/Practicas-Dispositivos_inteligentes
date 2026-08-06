// Sincroniza el toggle de la safe zone (tecla "S") entre pestañas de la
// misma PWA — útil si la TV se refleja en dos ventanas/monitores a la vez
// durante la demo: presionar "S" en una las mueve a todas.
const canal = new BroadcastChannel('mindgames');

export function emitirToggleSafeZone(mostrar) {
  canal.postMessage({ tipo: 'toggle-safe-zone', mostrar });
}

export function escucharToggleSafeZone(callback) {
  canal.onmessage = (evento) => {
    // BroadcastChannel ya restringe los mensajes al mismo origin por spec
    // — a diferencia de postMessage, ninguna pestaña de otro origin puede
    // unirse a este canal. Aun así validamos `origin` aquí por la misma
    // disciplina de defensa en profundidad que exige postMessage: si este
    // mismo patrón se reutiliza más adelante para comunicación cross-origin
    // (ej. un iframe embebido), la validación ya está puesta y evita que un
    // documento de otro origin inyecte mensajes falsos (spoofing) que la
    // TV trate como legítimos.
    if (evento.origin && evento.origin !== location.origin) return; // requisito SA.4

    if (evento.data && evento.data.tipo === 'toggle-safe-zone') {
      callback(evento.data.mostrar);
    }
  };
}
