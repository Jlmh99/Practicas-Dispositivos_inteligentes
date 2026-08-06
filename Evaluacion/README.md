# Mind Games — Ecosistema de Dispositivos Inteligentes

Proyecto académico UTEQ, Desarrollo para Dispositivos Inteligentes, Evaluación 2.
Juan Luis Mendoza Hernandez · 2023371106

Tres apps sincronizadas por Firebase + un puente BLE:

- **`wearable_app`** (Flutter Wear OS) — periférico BLE, simula sensores de sesión.
- **`telefono_app`** (Flutter Android) — central BLE + Firebase, el único puente entre BLE y la nube.
- **`smart_pwa`** (HTML/CSS/JS vanilla) — TV 1920×1080, D-pad, lee el estado en vivo desde Firestore.
- **`shared_ble`** — paquete Dart con los UUIDs/formato de bytes, fuente de verdad del contrato BLE.

## Requisitos

Versiones verificadas en la máquina de desarrollo (`flutter --version` / `node --version`):

| Herramienta | Versión usada |
| --- | --- |
| Flutter | 3.44.0 (channel stable) |
| Dart SDK | 3.12.0 (viene con Flutter) |
| Node.js | 22.22.0 (solo para `scripts/seed_games.js`) |
| Python | 3.13.5 (solo para servir `smart_pwa` con `http.server`, cualquier 3.x sirve) |
| Android SDK / emulador | API 34+ para `telefono_app`, imagen Wear OS (round) para `wearable_app` |
| Navegador para la TV | Chrome/Edge recientes (BroadcastChannel, Service Worker, ES Modules) |

No hace falta el CLI de Firebase (`firebase-tools`) salvo que quieras usar
`flutterfire configure` de nuevo — los proyectos ya traen su configuración
generada (gitignorada, ver abajo).

## Configuración de Firebase

Todo el ecosistema comparte **un solo proyecto Firebase** (`mind-games-ddi`
en este repo, pero cualquier proyecto nuevo sirve). Pasos desde cero:

1. **Crear el proyecto** en [Firebase Console](https://console.firebase.google.com/)
   con el plan **Spark (gratuito)** — no se necesita Blaze para este alcance.
2. **Authentication** → Sign-in method → habilitar **Correo electrónico/contraseña**.
   (La verificación en dos pasos que pide CLAUDE.md se implementa en la app,
   no es un ajuste de la consola.)
3. **Firestore Database** → crear en modo producción, cualquier región cercana.
4. **Publicar las reglas** de este repo (ya escritas en `firestore.rules`):
   ```bash
   # Con firebase-tools instalado y logueado:
   firebase deploy --only firestore:rules --project <tu-project-id>
   # o pegar el contenido de firestore.rules directamente en
   # Firestore → Reglas, en la consola.
   ```
5. **Generar `firebase_options.dart`** para `telefono_app` (esto también crea
   `google-services.json` y registra la app Android + la app Web):
   ```bash
   dart pub global activate flutterfire_cli
   cd telefono_app
   flutterfire configure --project=<tu-project-id>
   ```
   Selecciona Android **y** Web (la Web es la que reutiliza `smart_pwa`).
6. **Copiar la config al PWA**: `telefono_app/lib/firebase_options.dart` ya
   tiene un bloque `web` con `apiKey`/`authDomain`/etc. — copia esos mismos
   valores a `smart_pwa/js/firebase-config.js` (crear a partir de la
   plantilla, ver siguiente punto). Es el mismo proyecto, no hace falta
   registrar una segunda app web.
7. **Crear los dos archivos de config reales** (ninguno se commitea — ver
   `.gitignore`):
   ```bash
   cp telefono_app/lib/firebase_options.example.dart telefono_app/lib/firebase_options.dart
   cp smart_pwa/js/firebase-config.example.js smart_pwa/js/firebase-config.js
   ```
   (El paso 5 ya genera el de `telefono_app` automáticamente; el `cp` de
   arriba solo aplica si prefieres llenarlo a mano.)
8. **Correr el seed** del catálogo de juegos (colección `games`), con una
   *service account* de Firebase Admin (Consola → Configuración del proyecto
   → Cuentas de servicio → Generar nueva clave privada; guárdala **fuera**
   del repo, ej. `~/.secrets/mindgames-admin.json`):
   ```bash
   npm install          # una sola vez, instala firebase-admin
   # PowerShell:
   $env:GOOGLE_APPLICATION_CREDENTIALS="$HOME\.secrets\mindgames-admin.json"
   node scripts/seed_games.js
   ```

## Correr wearable_app

```bash
cd wearable_app
flutter pub get
flutter emulators --launch Wear_OS_Large_Round   # o un reloj físico por adb
flutter run
```

No usa Firebase — es puro periférico BLE (GATT server), no necesita ningún
paso de configuración adicional.

## Correr telefono_app

```bash
cd telefono_app
flutter pub get
flutter emulators --launch Pixel_8               # o un teléfono físico
flutter run
```

Requiere `lib/firebase_options.dart` (paso 5/7 de arriba) y permisos de
Bluetooth/ubicación otorgados en tiempo de ejecución (la app los pide sola
al abrir, vía `permission_handler`).

## Servir smart_pwa

Es HTML/CSS/JS puro, sin build step — cualquier servidor estático local
sirve, mientras sea `http://localhost` (no `file://`, porque los Service
Workers y los módulos ES no funcionan con ese esquema):

```bash
cd smart_pwa
python -m http.server 8080
# abrir http://localhost:8080/index.html
```

Requiere `js/firebase-config.js` (paso 7 de arriba).

### Emular la TV en Chrome DevTools

1. Abrir `http://localhost:8080/index.html` en Chrome/Edge.
2. DevTools (F12) → icono de "Toggle device toolbar" (Ctrl+Shift+M).
3. Dimensiones personalizadas: **1920 × 1080**, zoom al 50-60% para que
   quepa en pantalla.
4. Navegar con las flechas del teclado + Enter simula el D-pad; tecla **"S"**
   (fuera de campos de texto) muestra el borde punteado de la safe zone.
5. DevTools → Application → Service Workers / Manifest para verificar el
   cacheo offline y la instalabilidad.
6. DevTools → Network → "Offline" simula el modo sin conexión (el banner
   rojo debe aparecer sin necesidad de recargar).

## Emuladores

```bash
flutter emulators
#  Pixel_8               • Android (teléfono)
#  Wear_OS_Large_Round   • Wear OS (reloj)
flutter emulators --launch <id>
```

Con ambos emuladores + la PWA abiertos a la vez, el flujo completo de sync
(wearable → teléfono BLE → Firestore → TV) se puede demostrar sin hardware
físico. Si la máquina no tiene RAM para los dos emuladores simultáneos, un
dispositivo físico (teléfono o reloj Wear OS reales) reemplaza a cualquiera
de los dos sin cambiar nada del flujo — la app no distingue emulador de
hardware real.

## Generar el APK

No se usa un keystore propio: `telefono_app/android/app/build.gradle.kts` ya
firma el `buildType release` con la clave de debug de Flutter
(`signingConfig = signingConfigs.getByName("debug")`), suficiente para este
entregable.

```bash
cd telefono_app
flutter build apk --release
```

APK resultante:

```
telefono_app/build/app/outputs/flutter-apk/app-release.apk
```

(~50 MB. Verificado: build exitoso con Gradle `assembleRelease` en ~172 s.)

## Orden de arranque para la demo (5 minutos)

Pensado para minimizar tiempos muertos (BLE advertising, cold start de
Firebase Auth) durante la presentación:

1. **Antes de empezar** (fuera de cámara): levantar `smart_pwa` con
   `python -m http.server 8080` y dejar la pestaña abierta ya logueada
   (Firebase Auth persiste la sesión — no hace falta re-loguear cada vez).
2. **(0:00–0:30)** Abrir `wearable_app` en el reloj/emulador — arranca
   anunciando por BLE automáticamente (`INACTIVO`).
3. **(0:30–1:00)** Abrir `telefono_app` — el escaneo detecta
   "MindGames-Watch" solo (ver la tarjeta de conexión pasar a "Conectado").
   Mostrar el diálogo de bonding de Android si aparece, es normal (ver
   Troubleshooting).
4. **(1:00–1:30)** En la TV, mostrar el catálogo de 4 juegos + D-pad
   (flechas + Enter), y la tecla "S" para la safe zone.
5. **(1:30–2:30)** En el teléfono: seleccionar un juego, pulsar "Iniciar" —
   el wearable empieza a notificar métricas simuladas. En la TV, la tarjeta
   del juego activo debe resaltarse con el borde verde pulsante en menos de
   2 s (mirar el número de latencia discreto en el header — esa es la
   evidencia numérica del requisito SA.5), y el panel "Sesión en curso" debe
   llenarse con tiempo/ritmo cardiaco/movimientos/concentración en vivo.
6. **(2:30–3:00)** Pulsar "Forzar umbral (demo)" en el AppBar del teléfono
   (icono de bug) — salta `sessionSeconds` a 1795 para no esperar 30 min
   reales; a los pocos segundos debe dispararse la alerta: banner en el
   teléfono, notificación local, y el banner rojo grande en la TV
   ("Tiempo de juego prolongado, toma un descanso").
7. **(3:00–3:30)** Pulsar "Detener" (desde el teléfono o el botón físico del
   reloj, cualquiera de los dos) — se guarda la sesión en
   `users/{uid}/sessions` y el panel de estadísticas de la TV se actualiza
   solo (onSnapshot, sin recargar).
8. **(3:30–4:00)** DevTools → Network → Offline en la pestaña de la TV: debe
   aparecer el banner "Sin conexión — mostrando últimos datos" sin perder la
   estructura.
9. **(4:00–5:00)** Preguntas / mostrar el APK instalado en un dispositivo
   físico si hay uno a la mano.

## Troubleshooting

### Error SSL al compilar Android (`SunCertPathBuilderException` / `certificate_unknown`)

Sucede al descargar dependencias de Maven/Firebase (`firebase-bom`, `gson`,
`androidx.media`, etc.) en redes con proxy corporativo o antivirus que hacen
inspección SSL sin que el JDK de Gradle confíe en ese certificado.

Ya aplicado en el repo (`telefono_app/android/gradle.properties`,
`org.gradle.jvmargs`): `-Dcom.sun.net.ssl.checkRevocation=false`.

**Falta un paso manual por máquina** (no se puede commitear, es específico del
entorno de cada quien): define la variable de entorno `GRADLE_OPTS` con

```
-Djavax.net.ssl.trustStoreType=WINDOWS-ROOT
```

para que Gradle use el almacén de certificados raíz de Windows en vez del
`cacerts` propio del JDK. Sin esto, en Windows con proxy/antivirus con
inspección SSL, `flutter build apk` / `flutter run` fallan al resolver
dependencias aunque el proyecto esté bien configurado.

### `Failed to find Platform SDK with path: platforms;android-35`

`flutter_local_notifications` trae `compileSdk 35` hardcodeado en su propio
`build.gradle`, independiente del `compileSdk` de la app. Si esa plataforma no
está instalada, ya está resuelto a nivel de proyecto: `telefono_app/android/build.gradle.kts`
fuerza `compileSdk = 34` en todos los módulos de librería (los plugins) vía un
`subprojects { afterEvaluate { ... } }`, sin tocar el `compileSdk` del módulo
`:app`. No requiere ninguna acción adicional.

### `CheckAarMetadataWorkAction` / error de desugaring

`flutter_local_notifications` requiere Java 8+ core library desugaring. Ya
habilitado en `telefono_app/android/app/build.gradle.kts`:
`isCoreLibraryDesugaringEnabled = true` + dependencia
`coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")`.

### Instalación de APK colgada en el emulador (`Installing...` sin avanzar)

Visto con el emulador Wear OS (`Wear_OS_Large_Round`, API 36, `sdk_gwear_x86_64`):
`adb install` se queda colgado indefinidamente (proceso con 0% CPU, no es
lentitud). `adb kill-server && adb start-server` no lo resuelve de forma
confiable. Sin solución encontrada todavía desde la línea de comandos; si
vuelve a pasar, probar con otra imagen de sistema Wear OS (round API 30/33 en
vez de la 36) o instalar/correr directamente desde Android Studio.

### `telefono_app` escanea pero nunca encuentra al wearable

Con los dos emuladores corriendo simultáneamente (teléfono `emulator-5554` +
Wear OS `emulator-5556`), `telefono_app` completaba ciclos de
`startScan`/`stopScan` con backoff sin error, pero jamás detectaba
"MindGames-Watch". No era un problema del emulador ni del Bluetooth virtual
(Netsim) — eran dos bugs reales en `wearable_app/lib/ble/gatt_peripheral.dart`,
encontrados comparando logcat de ambos emuladores y el código nativo de
`ble_peripheral` contra un ejemplo previo que sí funcionaba. Los dos ya están
arreglados en el repo:

1. **`BlePeripheral.isSupported()` lanzaba excepción y bloqueaba todo antes de
   intentar anunciar.** Internamente llama a
   `bluetoothAdapter.isMultipleAdvertisementSupported` (Android), que en este
   emulador lanza `UnsupportedOperationException` aunque `startAdvertising()`
   sí funcione ahí. El código defensivo original la atrapaba correctamente
   (no crasheaba) pero nunca llegaba a anunciar — cero logs nativos de BLE,
   ni siquiera un intento. Fix: se quitó esa guarda previa; ahora se intenta
   anunciar directamente y solo se reporta error si `initialize`/
   `addService`/`startAdvertising` fallan de verdad.

2. **`"Data too large"` al anunciar.** Con la guarda anterior fuera, el
   advertising fallaba con ese error. Causa confirmada en el código nativo de
   `ble_peripheral` (`BlePeripheralPlugin.kt`): el `localName` y el
   `SERVICE_UUID` (128 bits) se empaquetan juntos en el mismo paquete de
   advertising, y juntos exceden el límite físico de 31 bytes de un paquete
   BLE clásico — esto pasaría igual en hardware real, no es cosa del
   emulador. Como `telefono_app` descubre por `SERVICE_UUID` y nunca lee el
   nombre anunciado, se quitó `localName: 'MindGames-Watch'` del
   `startAdvertising()` para que el UUID quepa solo.

**Confirmado en vivo tras el fix:** wearable muestra "● Conectado"; logcat del
teléfono muestra `connect → SUCCESS`, `discoverServices → 8 services
GATT_SUCCESS`, y las 5 características de datos con `setNotifyValue`/
`onDescriptorWrite → GATT_SUCCESS` cada una.

Nota aparte: al conectar puede aparecer un diálogo del sistema Android
*"Pairing request... Tap to pair with MindGames-Watch"* sobre la app del
teléfono. No bloquea nada — la conexión GATT y las suscripciones NOTIFY ya
tuvieron éxito antes de que aparezca. Es el flujo estándar de bonding de
Android; solo hay que tocarlo (Pair & connect o Cancel) para quitarlo de
encima.

### La PWA no inicia sesión aunque el correo/contraseña sean correctos

Dos causas reales encontradas durante las pruebas de este proyecto, ambas ya
arregladas en el repo:

1. **CSP bloqueando la infraestructura interna de Firebase Auth.** `getAuth()`
   siempre inicializa su `AuthEventManager` (incluso solo con
   email/password) para sincronizar sesión entre pestañas — eso carga
   `apis.google.com/js/api.js` y abre un iframe hacia el `authDomain` del
   proyecto. Sin `script-src https://apis.google.com` y
   `frame-src https://<tu-proyecto>.firebaseapp.com` en la CSP de
   `index.html`, `signInWithEmailAndPassword` nunca resuelve.
2. **El atributo `hidden` silenciosamente anulado por CSS.** `[hidden] { display: none }`
   (regla del navegador) tiene la misma especificidad que cualquier regla
   propia que fije `display` en ese mismo elemento (ej.
   `.login-screen { display: flex }`) — si esa segunda regla carga después,
   gana y anula `hidden` sin ningún error visible. Ya resuelto en
   `css/reset.css` con `[hidden] { display: none !important; }`.

Si la PWA se ve "atascada" en el login después de cambiar código, primero
sospechar de una versión vieja cacheada por el Service Worker antes que de
un bug nuevo: sube `CACHE_VERSION` en `sw.js` y haz Ctrl+Shift+R una vez.

### El teléfono y el wearable dicen "JUGANDO:SUDOKU" sin importar el juego elegido

El wearable no tiene ninguna forma de saber qué juego se seleccionó en el
teléfono — `CHAR_CONTROL` original solo era iniciar/detener (1 byte), y
`SensorSimulator._juego` traía "SUDOKU" hardcodeado sin que nada lo
actualizara. Esto era visible en `MonitorWidget` del teléfono, en la propia
pantalla del reloj, y (aunque ahí no se notaba, porque la PWA usa
`sessionState.gameId` en vez de parsear `activityStatus`) también viajaba
así hasta Firestore.

Arreglado extendiendo el contrato BLE: nueva característica
`CHAR_GAME_SELECT` (WRITE, UTF-8) — el teléfono escribe ahí el id del juego
cada vez que el usuario toca una tarjeta en `GamesList`
(`firestore_provider.dart` → `JuegoSeleccionadoNotifier.seleccionar()`), el
wearable la recibe en su `_onWriteRequest` y llama
`SensorSimulator.setJuego()`, que ya existía pero nunca se conectaba a
nada. Además, `telefono_app` reconstruye el sufijo de `activityStatus` con
el juego real elegido (`activity_provider.dart` → `_conJuegoReal()`) como
salvaguarda extra por si el WRITE BLE no llegó a tiempo.

También se corrigió, en el mismo lote: el wearable acumulaba
`sessionSeconds` entre sesiones distintas en vez de reiniciar en cada
"Iniciar" (`SensorSimulator.reset()` existía pero nunca se llamaba) — lo que
además rompía el botón "Forzar umbral (demo)" del teléfono, porque el
siguiente tick real de BLE (~1/s) sobrescribía el valor forzado casi de
inmediato. El botón ahora aplica un desfase sobre el valor real en vez de
reemplazarlo directo, así que sobrevive a los ticks siguientes. Además, ese
mismo botón ahora empuja el salto de tiempo al wearable vía
`CHAR_SESSION_TIME_OVERRIDE` (tercera característica agregada al contrato
BLE en esta ronda), para que los tres relojes se vean consistentes en la
demo — puramente cosmético, el wearable no necesita mostrar la alerta.

### La PWA sigue mostrando los datos de la cuenta anterior tras iniciar sesión con otra

No es una fuga de datos entre cuentas — es que no hay botón de "cerrar
sesión" visible en el dashboard (a propósito: es una TV, se diseñó para
arrancar siempre ya autenticada gracias a la persistencia de Firebase Auth
en IndexedDB). Sin logout, la única cuenta activa sigue siendo la primera
con la que se inició sesión, sin importar qué credenciales se vuelvan a
escribir en un formulario que ya no está visible. Solución: tecla **"L"**
(fuera de campos de texto) hace `signOut()` y regresa al login. Verificado
en vivo con dos cuentas reales: cada una muestra sus propias estadísticas
correctamente una vez que el cambio de sesión ocurre de verdad.

(De paso, mientras se investigaba esto se encontró y corrigió un riesgo real
en `sw.js`: cacheaba las respuestas de `firestore.googleapis.com` por URL
completa para el modo offline, pero el canal de datos en tiempo real de
Firestore usa una ruta GET fija para cualquier cuenta — existía el riesgo de
servir una respuesta vieja de OTRA sesión si la red fallaba justo al cambiar
de cuenta. Quitado: Firestore ya no pasa por el Service Worker, y el
indicador de "sin conexión, mostrando últimos datos" sigue funcionando igual
porque en realidad siempre dependió del propio SDK, no del SW.)

### Restaurar sesión de Firebase Auth estando offline puede fallar

Con la estructura de la PWA ya cacheada (offline funcionando: banner rojo +
últimos datos), un *reload completo* sin conexión puede no restaurar la
sesión ya persistida y devolver a la pantalla de login. Sospecha: la misma
infraestructura de iframe/gapi de `AuthEventManager` (ver punto anterior)
intenta inicializarse en cada carga de página, y sin red ese intento puede
demorar o interferir con que `onAuthStateChanged` confirme el usuario ya
guardado en IndexedDB. El requisito central (estructura + indicador desde
cache, sin recargar) sí está confirmado funcionando — este caso más extremo
(reload en frío completamente offline) queda anotado como limitación
conocida del SDK, no de la lógica de la app.
