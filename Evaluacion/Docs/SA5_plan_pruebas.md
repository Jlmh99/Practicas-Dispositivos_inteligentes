# SA.5 — Plan de Pruebas

Mind Games — Ecosistema de Dispositivos Inteligentes. Juan Luis Mendoza Hernandez · 2023371106

Este plan cubre los 8 elementos pedidos: (1) tabla de casos con formato fijo,
(2) mínimo 12 casos, (3–7) los 5 bloques obligatorios de la rúbrica (P2.5, P2.6,
P3.1–P3.4, offline, sincronización < 2 s), y (8) evidencias + firma.

Las columnas **Obtenido** y **Estado** reflejan lo realmente observado durante el
desarrollo de este proyecto (varias rondas de pruebas en vivo documentadas en
`README.md` y en el historial de trabajo). Donde no hay evidencia concreta
todavía, se marca **Pendiente** en vez de inventar un resultado — este documento
es para volver a correr antes de la entrega final, no una foto ya cerrada.

## Convenciones

- **Estado**: `Aprobado` (se verificó en vivo y pasó), `Aprobado (con nota)` (pasó,
  con una limitación conocida documentada), `Pendiente` (no se ha vuelto a correr
  con la build actual), `Fallido` (se corrió y no pasó).
- Umbrales de referencia (fuente de verdad: `activity_provider.dart`):
  `kUmbralSessionSeconds = 1800`, `kUmbralHeartRate = 120`, `kUmbralFocusLevelBajo = 30`.

## Tabla de casos de prueba

| ID | Módulo | Precondiciones | Pasos | Esperado | Obtenido | Estado |
| --- | --- | --- | --- | --- | --- | --- |
| P2.5a | telefono_app / Firestore | Cuenta con sesión iniciada, `games` sembrada (`scripts/seed_games.js`) | 1. Abrir `telefono_app`. 2. Observar `GamesList`. | El catálogo real de `games` (Sudoku, Crucigrama, Sopa de Letras, Memorama, Ahorcado, Torres de Hanói) se muestra vía `juegosStreamProvider` (StreamProvider sobre `juegosStream()`), sin datos de relleno. | Catálogo real mostrado correctamente en varias rondas de prueba. | Aprobado |
| P2.5b | telefono_app / Firestore | Sesión iniciada, `GamesList` cargado | 1. Desactivar la red del dispositivo/emulador. 2. Pull-to-refresh o `ref.invalidate(juegosStreamProvider)`. | `juegosAsync.when(error: ...)` muestra el ícono de error + botón "Reintentar" (`games_list.dart:24-43`), sin crash. | No se ha vuelto a ejecutar este caso específico (corte de red real en el dispositivo) con la build actual. | Pendiente |
| P2.6 | telefono_app ↔ wearable_app / BLE | Ambos emuladores corriendo, `wearable_app` anunciando | 1. `telefono_app` escanea y conecta (`BleClient.conectar`). 2. Iniciar sesión desde el reloj o el teléfono. 3. Observar `MonitorWidget`. | Las 5 características NOTIFY (`CHAR_HEART_RATE`...`CHAR_STATUS`) llegan al teléfono en ~1 s y se reflejan en `MonitorWidget` sin retraso perceptible. | Confirmado en logcat: `connect → SUCCESS`, `discoverServices → 8 services GATT_SUCCESS`, 5 características con `setNotifyValue`/`onDescriptorWrite → GATT_SUCCESS`. | Aprobado |
| P3.1 | smart_pwa / D-pad | Dashboard de la TV cargado, 4 tarjetas de juego | Presionar flecha ↑ repetidamente desde distintas posiciones del grid 2×2. | El foco sube una fila cuando existe destino válido; en la fila superior, `_mover()` no mueve el índice (`dpad.js:87-92`) — nunca "envuelve" a la fila inferior. | Verificado programáticamente (`window.__dpad.indiceActual()`) y en vivo con teclado. | Aprobado |
| P3.2 | smart_pwa / D-pad | Igual que P3.1 | Presionar flecha ↓ repetidamente. | Baja una fila cuando hay destino; en la fila inferior no se mueve. | Igual que P3.1. | Aprobado |
| P3.3 | smart_pwa / D-pad | Igual que P3.1 | Presionar ← y → desde columna 0 y columna 1. | `_moverHorizontal()` (`dpad.js:96-106`) nunca cruza el límite de columna: en col. 0, ← no mueve; en la última col., → no mueve. | Verificado. | Aprobado |
| P3.4 | smart_pwa / D-pad | Igual que P3.1 | Presionar Enter/OK sobre una tarjeta "disponible" y sobre una "Próximamente". | `onSeleccionar` llama `establecerFondo(juego.mediaUrl)` con crossfade; en tarjetas no disponibles, la tecla no debería tener efecto visual distinto del solo-foco (el D-pad no filtra por disponibilidad — ver nota de mejora abajo). | Selección y crossfade de fondo funcionan; no se validó específicamente el comportamiento en tarjetas "Próximamente". | Aprobado (con nota) |
| OFF.1 | smart_pwa / Service Worker | App cargada al menos una vez (SW instalado, `CACHE_VERSION` actual `mind-games-tv-v12`) | 1. DevTools → Network → Offline. 2. Sin recargar, observar el indicador. | Banner rojo "Sin conexión — mostrando últimos datos" aparece sin recargar (`navigator.onLine` vía `actualizarIndicadorOffline()`, `app.js`). | Confirmado con evento `offline` simulado (`navigator.onLine` sobrescrito) vía Playwright y en vivo por el usuario. | Aprobado |
| OFF.2 | smart_pwa / Service Worker | Igual que OFF.1 | 3. Con la red aún desactivada, recargar la página (F5). | La estructura de la app (HTML/CSS/JS/iconos) carga desde `cacheFirst()` (`sw.js`); el estado de sesión debería restaurarse desde IndexedDB de Firebase Auth. | Limitación conocida y documentada en `README.md`: un reload en frío completamente offline puede no restaurar la sesión a tiempo (dependencia de la inicialización de red de `AuthEventManager` de Firebase Auth). La estructura sí carga desde caché. | Aprobado (con nota) |
| SYNC.1 | telefono_app → Firestore → smart_pwa | Sesión activa con un juego, TV con la misma cuenta logueada | 1. Cambiar una métrica en el teléfono (ej. iniciar un juego). 2. Cronometrar hasta que la TV refleje el cambio, leyendo el indicador de latencia del header (`app.js`, función `actualizarLatencia`, línea 311: `Date.now() - ultimoActualizadoEnMillis`). | Propagación **< 2000 ms** (umbral en `app.js:314`, clase `.latencia-alta` si se excede). | **Dos condiciones medidas, con resultados MUY distintos.** (a) Escritura directa a Firestore desde una sola pestaña, sin los emuladores corriendo: **501 ms**. (b) Con los 3 dispositivos corriendo a la vez (2 emuladores Android + Chrome DevTools, `docs/evidencias/capturapr1.png` y `capturapr4.png`): **27.7–28.1 s**, muy por encima del umbral — el indicador correctamente se pintó en rojo (`.latencia-alta`), es decir el código detectó y reportó bien la degradación, pero el número real no cumple el requisito bajo esa carga. | **Fallido bajo carga real — ver nota** |
| P.UMB | telefono_app + wearable_app + smart_pwa / Umbral crítico | Sesión activa, `activityStatus` = "JUGANDO:..." | 1. Presionar el ícono de bug ("Forzar umbral (demo)") en el AppBar. 2. Observar teléfono, wearable y TV. | `sessionSeconds` salta a 1795 y sube; al cruzar 1800, aparece: banner en el teléfono (`AlertBanner`), notificación local (`NotificacionesService`), `sessionState.alertaActiva = true`, y banner rojo en la TV ("Tiempo de juego prolongado, toma un descanso"). El wearable debe mostrar el mismo salto de tiempo (`CHAR_SESSION_TIME_OVERRIDE`). | Se encontraron y corrigieron 2 bugs reales en este flujo (desfase local duplicaba el tiempo; alerta no revisaba `activityStatus`) — pendiente re-confirmar en vivo con la build corregida. | Pendiente |
| P.DISC | wearable_app ↔ telefono_app / BLE | Conexión BLE activa, sesión en curso | Apagar el Bluetooth del emulador/dispositivo del wearable a media sesión. | `BleClient._onCambioConexion` detecta `disconnected`, emite `EstadoDesconectado`, limpia `_controlChar`/`_gameSelectChar`/`_timeOverrideChar`, y reintenta con backoff (2/4/8/16/30 s) sin crash de la app. | No se ha ejecutado explícitamente este caso (desconexión forzada a media sesión) en esta ronda. | Pendiente |
| P.2FA-OK | telefono_app / Auth | Contraseña validada correctamente | 1. Ingresar el código de 6 dígitos mostrado en pantalla (modo desarrollo, `two_factor_screen.dart`). 2. Confirmar antes de que pasen 5 min. | `AuthRepository.verificarCodigo()` retorna `true`, navega al `HomeScreen`. | Verificado en rondas anteriores de prueba. | Aprobado |
| P.2FA-ERR | telefono_app / Auth | Igual que P.2FA-OK | Ingresar un código incorrecto o esperar a que pasen los 5 min (`_duracionCodigo`) antes de confirmar. | `verificarCodigo()` retorna `false` sin lanzar excepción; la UI muestra el error correspondiente y permite reintentar/reenviar. | No se ha probado explícitamente el caso de código incorrecto ni el de expiración. | Pendiente |
| P.APK | telefono_app / Build | — | `flutter build apk --release` en `telefono_app`, luego `adb install` en el emulador Pixel_8. | Build exitoso, APK instala y abre sin errores (firmado con la clave de debug de Flutter, ver `README.md`). | Build exitoso confirmado (`assembleRelease` en ~172 s), instalación confirmada en dispositivo físico y emulador. | Aprobado |
| P.JUEGO | telefono_app + wearable_app + smart_pwa / CHAR_GAME_SELECT | Los 3 dispositivos conectados/logueados | Elegir un juego distinto a Sudoku (ej. Crucigrama) desde `GamesList` en el teléfono. | Teléfono (`MonitorWidget`), wearable (pantalla del reloj) y TV (panel "Sesión en curso") deben mostrar "CRUCIGRAMA"/"Crucigrama" de forma consistente. | Confirmado con captura real de los 3 dispositivos a la vez, todos mostrando "Crucigrama" con los mismos valores (90 bpm, 29 mov, 00:40, 67%) — ver `docs/evidencias/capturapr1.png`, `capturapr2.png`, `capturapr3.png`. | Aprobado |
| P.LOGOUT | smart_pwa / Auth | Dos cuentas de prueba distintas | 1. Iniciar sesión con la cuenta A. 2. Presionar tecla "L". 3. Iniciar sesión con la cuenta B. | Cada cuenta muestra únicamente sus propias estadísticas — sin arrastrar datos de la sesión anterior. | Verificado con dos cuentas reales vía Playwright: cuenta A mostró 6 partidas/2h 6min/Sopa de Letras; cuenta B mostró 7 partidas/48min/Crucigrama — datos correctamente distintos. | Aprobado |

**Total de casos: 16** (mínimo requerido: 12).

## Evidencias

Las 6 capturas requeridas, tomadas en vivo con los 3 dispositivos corriendo
(`docs/evidencias/`):

1. ![Los 3 dispositivos juntos](evidencias/capturapr1.png)
   Los 3 dispositivos a la vez — wearable (Wear OS Large Round), teléfono
   (Pixel 8) y TV, todos sincronizados en "Crucigrama" con los mismos
   valores en vivo. Es también la evidencia de SA.3 #4 (los 3 dispositivos
   simultáneos).
2. ![Wearable solo](evidencias/capturapr2.png)
   Wearable solo, pantalla de sesión en curso (90→104 bpm, 131 mov, 01:56,
   100% concentración, "JUGANDO:CRUCIGRAMA").
3. ![Teléfono solo](evidencias/capturapr3.png)
   Teléfono solo, `MonitorWidget` con las 5 métricas en vivo + badge
   "Conectado" + indicador de sync.
4. ![TV sola con consola](evidencias/capturapr4.png)
   TV (smart_pwa) sola, dashboard completo con panel "Sesión en curso" y
   estadísticas — consola de DevTools abierta (ver la nota de latencia en
   SYNC.1: esta captura es la evidencia del caso "bajo carga real").
5. ![Service Workers activo](evidencias/capturapr5.png)
   DevTools → Application → Service Workers: `sw.js` activo y ejecutando
   (versión #8913 en esa corrida).
6. ![Modo offline](evidencias/capturapr6.png)
   Modo offline (DevTools → Network → Sin conexión): banner rojo "Sin
   conexión — mostrando últimos datos" + indicador "Reconectando…" +
   panel de Network confirmando la intercepción del Service Worker.

*(También existen 3 capturas previas — `pruebas.png`, `pruebas2.png`,
`preubas1.png` — de rondas de prueba anteriores de la TV sola; se dejan en
la carpeta como respaldo pero no se listan aquí porque las 6 de arriba ya
cubren el requisito completo.)*

## Firma

Nombre: Juan Luis Mendoza Hernandez
Matrícula: 2023371106
Fecha: 07/08/2026

Firma: *(se agrega al convertir este documento a PDF para la entrega —
pendiente, no aplica al `.md` de trabajo)*
