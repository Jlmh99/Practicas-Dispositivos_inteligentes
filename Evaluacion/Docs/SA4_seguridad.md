# SA.4 — Seguridad y Protección de Datos Personales

Mind Games — Ecosistema de Dispositivos Inteligentes. Juan Luis Mendoza Hernandez · 2023371106

Este documento cubre los 6 puntos pedidos para SA.4. Todo el código citado es el
código real del repositorio (rutas y números de línea verificables al momento de
escribir esto); ningún fragmento es de relleno.

---

## 1. Validación de `event.origin` en BroadcastChannel

**Ubicación real:** `smart_pwa/js/broadcast.js`, función `escucharToggleSafeZone`.

```js
// smart_pwa/js/broadcast.js, líneas 10–26
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
```

La comparación exacta está en la **línea 20**.

### El riesgo real (honesto, sin exagerar)

`BroadcastChannel` con el mismo nombre de canal (`'mindgames'`, línea 4) **ya está
restringido por especificación a páginas del mismo origin** — a diferencia de
`window.postMessage`, no existe ningún mecanismo por el que una pestaña de
`https://atacante.com` pueda unirse al canal `'mindgames'` abierto por
`http://localhost:8080`. En ese sentido, para el uso actual (solo dos módulos de
`smart_pwa` hablando entre pestañas de sí mismo) la validación es defensa en
profundidad, no una mitigación de un ataque explotable hoy.

### Qué ataque previene (el escenario donde SÍ importa)

El valor real de la validación aparece si este mismo patrón de código se
reutiliza para un canal que **sí** puede cruzar orígenes — el caso típico es
`window.addEventListener('message', ...)` para comunicarse con un `<iframe>`
embebido (algo que este proyecto ya hace indirectamente: Firebase Auth abre un
iframe hacia `mind-games-ddi.firebaseapp.com`, documentado en la CSP de
`index.html`). Sin la validación de origen, un documento controlado por un atacante
podría:

1. Enviar un mensaje falso con `{ tipo: 'toggle-safe-zone', mostrar: true }` para
   manipular la UI (menor, en este caso).
2. En un canal con más superficie (ej. si en el futuro se usa para propagar
   `sessionState` entre pestañas sin pasar por Firestore), inyectar datos falsos
   que la TV trate como si vinieran de una sesión legítima — un *spoofing* de
   estado de aplicación.

La línea 20 es la guarda que, si el canal cambia de naturaleza más adelante, ya
está puesta y no depende de que alguien se acuerde de agregarla bajo presión de
tiempo.

---

## 2. LFPDPPP — Datos personales tratados

Ley Federal de Protección de Datos Personales en Posesión de los Particulares
(México). Tabla de los datos reales que el ecosistema trata, con su finalidad y
base legal:

| Dato | Dónde vive (real) | Finalidad | Base legal (LFPDPPP) | ¿Sensible? |
| --- | --- | --- | --- | --- |
| Nombre | `users/{uid}.nombre` (`auth_repository.dart:50`) | Identificar al usuario en la UI | Art. 8 — consentimiento del titular (tácito, al registrarse) | No |
| Correo electrónico | `users/{uid}.email` + gestionado internamente por Firebase Auth | Autenticación, identificación de cuenta | Art. 8 — consentimiento del titular | No |
| Contraseña | **Nunca en nuestro Firestore** — gestionada y hasheada íntegramente por Firebase Auth (Identity Platform) | Autenticación | Art. 8; además Firebase la trata bajo su propia política de seguridad (hash, nunca en texto plano, ni siquiera nosotros la vemos) | No (pero de alta criticidad) |
| Código de verificación (2FA) | `users/{uid}/verificacion/actual.codigo` (`auth_repository.dart:89-106`), expira en 5 min | Segundo factor de autenticación | Art. 8 — consentimiento del titular | No |
| Ritmo cardiaco (`heartRate`) | `sessionState/{uid}.heartRate`, `users/{uid}/sessions/{id}.heartRatePromedio` | Mostrar métricas de sesión, disparar alerta de umbral | **Art. 8 + Art. 9 — consentimiento EXPRESO** (dato de salud) | **Sí — dato de salud** |
| Tiempo de sesión, movimientos, concentración | `sessionState/{uid}`, `users/{uid}/sessions/{id}` | Estadísticas de uso, panel "Sesión en curso" | Art. 8 — consentimiento del titular | No |

**Nota importante sobre el ritmo cardiaco:** aunque en este proyecto el valor lo
genera `SensorSimulator` (wearable, dato sintético, no un sensor real de
hardware), el **campo en sí** es un dato de salud por naturaleza. La LFPDPPP no
distingue "dato real" de "dato simulado" — clasifica por el TIPO de información
que el campo representa. Por eso el ecosistema lo trata como sensible: es la
única razón detrás de exigir consentimiento expreso (Art. 9) en el aviso de
privacidad (sección 4) para ese campo en particular, y no solo el consentimiento
tácito que basta para nombre/correo/tiempos.

---

## 3. La `apiKey` de Firebase — por qué no es un secreto (y por qué igual la sacamos del repo)

Este es un punto que se malinterpreta seguido, así que vale la pena ser preciso:

### La apiKey web de Firebase es pública por diseño

`smart_pwa/js/firebase-config.js` y el bloque `web` de
`telefono_app/lib/firebase_options.dart` contienen una `apiKey`. Esa llave
**viaja dentro del bundle que se le sirve al navegador/dispositivo** — cualquiera
que abra DevTools → Network o descompile el APK puede leerla. Google lo dice
explícitamente en su propia documentación: la apiKey de un proyecto Firebase
identifica al proyecto ante la API de Google, **no autentica ni autoriza nada por
sí sola**. No es equivalente a una API key de, por ejemplo, un proveedor de pagos.

### La protección real son las Firestore Security Rules

Lo que de verdad decide quién puede leer o escribir qué es `firestore.rules`
(ver sección siguiente, comentada línea por línea). Aunque alguien tuviera la
`apiKey` de este proyecto, sin una sesión de Firebase Auth válida las reglas le
niegan todo acceso a `users/{uid}`, `sessionState/{uid}` y a escribir en `games`.

### Entonces, ¿por qué la mantenemos fuera del repositorio?

Tres razones, ninguna es "porque es secreta":

1. **Buena práctica general**: aunque no sea explotable por sí sola, publicarla
   en un repo público facilita reconocimiento del proyecto/fingerprinting y
   simplifica ataques de fuerza bruta o abuso de cuota si se combinan con OTRAS
   fallas (ej. reglas mal escritas en el futuro).
2. **Requisito explícito de esta evaluación** (CLAUDE.md, regla 1): nunca
   commitear `firebase_options.dart`, `google-services.json`,
   `js/firebase-config.js` — siempre archivo real + plantilla `.example`.
3. **Rotación más simple**: si el proyecto cambia de dueño o se reconfigura, no
   hay que reescribir historial de git para "sacar" una llave que nunca estuvo
   ahí.

Auditoría real corrida sobre este repo (ver `README.md`, sección de troubleshooting/
auditoría, y el historial de esta conversación): `git log --all -p | grep
"AIza[0-9A-Za-z_-]{35}"` → **0 coincidencias**. `git ls-files | grep
"firebase-config.js"` → solo `firebase-config.example.js` (la plantilla).

### `firestore.rules` comentadas línea por línea

```javascript
rules_version = '2';                                    // L1: sintaxis v2 (obligatoria desde 2019)

service cloud.firestore {
  match /databases/{database}/documents {                // L4: aplica a toda la base de datos

    // games: catálogo de juegos, solo lectura para usuarios autenticados.
    // La escritura se hace desde el script de seed (Admin SDK), nunca desde el cliente.
    match /games/{gameId} {                               // L8: colección `games`, cualquier documento
      allow read: if request.auth != null;                // L9: cualquier usuario CON sesión puede leer el catálogo
      allow write: if false;                               // L10: NADIE escribe desde cliente — ni con sesión.
    }                                                       //      El Admin SDK (seed_games.js) se salta las reglas
                                                             //      por diseño (usa credenciales de servicio, no
                                                             //      pasa por este archivo). Evita que un usuario
                                                             //      malicioso modifique precios/dificultad/catálogo.

    // users/{uid}: perfil propio del usuario, y su subcolección de sesiones.
    match /users/{uid} {
      allow read, write: if request.auth != null           // L15: solo el DUEÑO del uid puede leer/escribir
          && request.auth.uid == uid;                       //      su propio documento de perfil — nadie más,
                                                             //      ni siquiera otro usuario autenticado.

      match /{document=**} {                                // L17: comodín recursivo — cualquier subcolección
        allow read, write: if request.auth != null           //      futura bajo users/{uid} hereda la MISMA regla
            && request.auth.uid == uid;                      //      de propiedad, sin tener que declararla a mano.
      }
      match /sessions/{sessionId} {                          // L20: redundante con el comodín de arriba, pero
        allow read, write: if request.auth != null           //      explícito a propósito — deja claro en el
            && request.auth.uid == uid;                      //      archivo que las sesiones guardadas son
      }                                                       //      privadas por diseño, no un descuido.

      match /verificacion/{docId} {                          // L24: el código de 2FA (sección 2) — mismo dueño,
        allow read, write: if request.auth != null           //      mismo criterio. Importante: esto NO evita que
            && request.auth.uid == uid;                      //      el propio usuario lea su código sin haberlo
      }                                                       //      "recibido" por otro canal — es la limitación
                                                              //      ya documentada de no tener Cloud Functions
                                                              //      (plan Spark) para enviarlo por correo real.
    }

    // sessionState/{uid}: estado en vivo de la sesión, corazón del sync teléfono-TV.
    match /sessionState/{uid} {                              // L31: un documento por usuario, id = su propio uid
      allow read, write: if request.auth != null             // L32: MISMA cuenta lee y escribe — el teléfono
          && request.auth.uid == uid;                        //      escribe cada 2s, la TV (logueada con LA MISMA
    }                                                         //      cuenta) lee vía onSnapshot. Ningún otro uid
                                                              //      puede ver el estado en vivo de otra persona.
  }
}
```

**Patrón de fondo en todo el archivo**: cero reglas usan `allow read, write: if
true` en ninguna colección con datos de usuario. La única regla permisiva
(`games`) es de solo lectura y para un catálogo sin datos personales.

---

## 4. Aviso de privacidad completo

Versión completa (para consulta legal/evaluación). La versión corta que se
muestra dentro de las apps está en `docs/aviso_privacidad.md` y en
`telefono_app/lib/ui/privacy_screen.dart` / `smart_pwa` (sección 4 de ese
documento tiene el detalle de implementación).

> **AVISO DE PRIVACIDAD — MIND GAMES**
>
> **Responsable del tratamiento**
> Juan Luis Mendoza Hernandez, matrícula 2023371106, proyecto académico
> desarrollado para la Universidad Tecnológica de Querétaro (UTEQ), materia
> Desarrollo para Dispositivos Inteligentes. Contacto: a través de la
> plataforma institucional de la UTEQ.
>
> **Datos personales que se recaban**
> Nombre, correo electrónico, contraseña (gestionada por Firebase
> Authentication, nunca almacenada en texto plano por esta aplicación), y
> — mientras usas una sesión de juego con el wearable conectado — datos de
> ritmo cardiaco, tiempo de sesión, movimientos y nivel de concentración. El
> ritmo cardiaco se trata como **dato sensible** (dato de salud) conforme al
> artículo 3, fracción VI de la LFPDPPP.
>
> **Finalidades**
> (a) Crear y autenticar tu cuenta; (b) sincronizar tu sesión de juego entre
> el reloj, el teléfono y la pantalla de TV en tiempo real; (c) mostrarte
> estadísticas de tus propias sesiones; (d) enviarte una alerta si tu tiempo
> de juego continuo supera 30 minutos, tu ritmo cardiaco supera 120 lpm, o tu
> nivel de concentración cae por debajo de 30%. Ninguna finalidad es
> publicitaria ni se comparten datos con terceros ajenos a la infraestructura
> técnica necesaria para operar la app (ver siguiente punto).
>
> **Transferencias**
> Tus datos se almacenan y procesan mediante **Google LLC / Firebase**
> (Firebase Authentication y Cloud Firestore), cuya infraestructura puede
> ubicarse en servidores dentro de **Estados Unidos**. Esta transferencia es
> necesaria para la prestación del servicio (LFPDPPP Art. 37, fracción II) y
> está sujeta a los mecanismos de protección de datos de Google
> (https://cloud.google.com/terms/data-processing-terms). No se realizan
> otras transferencias a terceros.
>
> **Derechos ARCO**
> Puedes ejercer tus derechos de **Acceso, Rectificación, Cancelación y
> Oposición** sobre tus datos personales en cualquier momento. Para Acceso y
> Rectificación de nombre/correo, puedes hacerlo directamente desde la app
> (edición de perfil). Para Cancelación (borrado de cuenta) u Oposición,
> contacta al responsable por el medio indicado arriba.
>
> **Procedimiento y plazo de respuesta**
> Al recibir una solicitud ARCO, el responsable confirmará su identidad,
> resolverá la solicitud en un plazo máximo de **20 días hábiles** (conforme
> al artículo 32 de la LFPDPPP), y en caso de proceder, la hará efectiva
> dentro de los **15 días hábiles** siguientes. Para solicitudes de
> cancelación de cuenta, el procedimiento técnico exacto está documentado en
> la sección 5 (Plan de retención) de este documento.
>
> **Cambios a este aviso**
> Cualquier cambio sustancial a este aviso se notificará dentro de la propia
> aplicación antes de que surta efecto.

---

## 5. Plan de retención

| Dato | Dónde | Se conserva | Procedimiento técnico de eliminación |
| --- | --- | --- | --- |
| Perfil (`nombre`, `email`) | `users/{uid}` | Mientras la cuenta exista | Borrado del documento Firestore + `FirebaseAuth.instance.currentUser.delete()` (equivalente a `deleteUser` de Admin SDK) |
| Sesiones guardadas | `users/{uid}/sessions/*` | Mientras la cuenta exista (histórico de estadísticas) | Borrado en cascada: como no hay Cloud Functions (plan Spark) para borrado automático de subcolecciones, se hace con un **batch delete** manual antes de borrar el documento padre — Firestore NO borra subcolecciones solas al borrar el documento contenedor |
| Código de verificación 2FA | `users/{uid}/verificacion/actual` | 5 minutos lógicos (campo `expiraEn`), pero el DOCUMENTO en sí no se autoelimina de Firestore — **limitación conocida**, requeriría un Cloud Function programado (plan Blaze) para purga real | Se sobrescribe en cada nuevo login (mismo `docId: 'actual'`, `set()` no `add()`) — nunca acumula histórico de códigos viejos, aunque el último sí persiste más allá de sus 5 minutos de validez lógica |
| Estado en vivo de sesión | `sessionState/{uid}` | Mientras la cuenta exista; se sobrescribe cada 2 s | Borrado del documento único al eliminar la cuenta |
| Sesión de Firebase Auth (token) | Almacenamiento interno de Firebase Auth SDK (Android: interno de la app, no accesible directamente; PWA: IndexedDB del navegador) | Hasta `signOut()` explícito | `AuthRepository.cerrarSesion()` (teléfono) / tecla **"L"** → `signOut(auth)` (PWA, `smart_pwa/js/app.js`) — limpia el token persistido |
| Caché del Service Worker (PWA) | Cache Storage del navegador, bajo la clave `CACHE_VERSION` (actualmente `mind-games-tv-v11`) | Hasta la siguiente activación de una versión nueva | Automático: `sw.js`, evento `activate` — `caches.keys().then(...).filter(n => n !== CACHE_VERSION).map(caches.delete)` borra toda caché de versiones anteriores sin intervención del usuario |
| Métricas del wearable | **No se guardan en el wearable** — `SensorSimulator` las mantiene solo en memoria del proceso (`_sessionSeconds`, etc.), se pierden al cerrar la app | N/A (no hay persistencia) | N/A |

**Nota de transparencia**: este proyecto NO usa `shared_preferences` en
`telefono_app` (se verificó que el paquete no está entre las dependencias) — la
única persistencia local relevante es la interna del SDK de Firebase Auth
(token de sesión), que ya se cubre en la fila correspondiente de la tabla.

---

## 6. Checklist de seguridad de la PWA

| Control | Estado | Detalle real |
| --- | --- | --- |
| **CSP** | ✅ Implementado | `smart_pwa/index.html`: `default-src 'self'; script-src 'self' https://apis.google.com; frame-src https://mind-games-ddi.firebaseapp.com; connect-src 'self' https://firestore.googleapis.com https://identitytoolkit.googleapis.com https://securetoken.googleapis.com wss://firestore.googleapis.com; object-src 'none'; base-uri 'self'; frame-ancestors 'none';` — las dos excepciones a `'self'` (`apis.google.com`, `mind-games-ddi.firebaseapp.com`) son mínimas y documentadas en el propio HTML: son requisito interno de Firebase Auth (`AuthEventManager`), encontrado en vivo durante las pruebas de esta evaluación. |
| **HTTPS** | ⚠️ Contexto seguro local | La demo corre en `http://localhost:8080`. Esto **no es una vulnerabilidad**: los navegadores tratan `localhost` (y `127.0.0.1`) como *contexto seguro* aunque no use TLS — por eso Service Worker, `BroadcastChannel` y el resto de APIs que exigen contexto seguro funcionan sin problema. Un despliegue real a un dominio público SÍ requeriría HTTPS genuino (ej. Firebase Hosting lo da gratis y automático). |
| **SRI (Subresource Integrity)** | ➖ No aplica, por diseño | Los SDK de Firebase (`js/vendor/firebase-app.js`, `firebase-auth.js`, `firebase-firestore.js`) se descargaron una vez y se sirven desde `'self'`, no desde un CDN externo — SRI (`integrity="sha384-..."`) solo tiene sentido para recursos cargados desde un origen que no controlas, para detectar si el CDN fue comprometido. Servir los archivos localmente es **preferible** a CDN+SRI aquí: (1) la CSP puede quedar 100% en `'self'` para `script-src` de los SDK (nunca hay que confiar en que un CDN de terceros no sea comprometido), (2) la app funciona offline sin depender de que el CDN esté disponible, (3) no hay una petición de red extra en el camino crítico del login. |
| **Validación de origen** | ✅ Implementado | Ver sección 1 (BroadcastChannel) — único canal de mensajería entre contextos de la PWA, con `event.origin` validado. |
| **Reglas de acceso a datos** | ✅ Implementado | Ver sección 3 (`firestore.rules`) — todo acceso a datos de usuario exige `request.auth.uid == uid`. |
