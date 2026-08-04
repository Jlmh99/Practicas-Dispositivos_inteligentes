# Mind Games — Ecosistema de Dispositivos Inteligentes

Proyecto académico UTEQ, Desarrollo para Dispositivos Inteligentes, Evaluación 2.
Juan Luis Mendoza Hernandez · 2023371106

## Requisitos

## Configuración de Firebase

## Correr wearable_app

## Correr telefono_app

## Servir smart_pwa

## Emuladores

## Generar el APK

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
