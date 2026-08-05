// PLANTILLA — el archivo real `firebase_options.dart` (generado por
// `flutterfire configure` contra el proyecto Firebase "mind-games-ddi")
// está en .gitignore y nunca se commitea. Para regenerarlo:
//   dart pub global activate flutterfire_cli
//   flutterfire configure
//
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// [FirebaseOptions] de ejemplo — placeholders, no funcionales.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // apiKey            clave pública de la Web API del proyecto Firebase.
  // appId             id de la app registrada: "1:PROYECTO:plataforma:HASH".
  // messagingSenderId id numérico del proyecto (Cloud Messaging sender ID).
  // projectId         id del proyecto Firebase (ej. "mind-games-ddi").
  // authDomain        dominio de Firebase Auth: "PROYECTO.firebaseapp.com"
  //                   (no aplica en Android/iOS nativos).
  // storageBucket     bucket de Cloud Storage: "PROYECTO.firebasestorage.app".
  // iosBundleId       Bundle ID de Xcode (solo iOS/macOS).

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'REEMPLAZA_CON_TU_API_KEY',
    appId: '1:000000000000:web:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'tu-proyecto-firebase',
    authDomain: 'tu-proyecto-firebase.firebaseapp.com',
    storageBucket: 'tu-proyecto-firebase.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'REEMPLAZA_CON_TU_API_KEY',
    appId: '1:000000000000:android:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'tu-proyecto-firebase',
    storageBucket: 'tu-proyecto-firebase.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REEMPLAZA_CON_TU_API_KEY',
    appId: '1:000000000000:ios:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'tu-proyecto-firebase',
    storageBucket: 'tu-proyecto-firebase.firebasestorage.app',
    iosBundleId: 'com.tuempresa.tuapp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'REEMPLAZA_CON_TU_API_KEY',
    appId: '1:000000000000:ios:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'tu-proyecto-firebase',
    storageBucket: 'tu-proyecto-firebase.firebasestorage.app',
    iosBundleId: 'com.tuempresa.tuapp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'REEMPLAZA_CON_TU_API_KEY',
    appId: '1:000000000000:web:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'tu-proyecto-firebase',
    authDomain: 'tu-proyecto-firebase.firebaseapp.com',
    storageBucket: 'tu-proyecto-firebase.firebasestorage.app',
  );
}
