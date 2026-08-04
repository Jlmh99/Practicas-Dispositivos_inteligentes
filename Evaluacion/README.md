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
