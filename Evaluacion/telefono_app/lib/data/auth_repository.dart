import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Excepción con mensaje ya traducido a español, lista para mostrar en UI.
class AuthException implements Exception {
  const AuthException(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;
}

/// Autenticación por correo/contraseña + 2FA propio (sin costo).
///
/// El 2FA NO usa Identity Platform / `multiFactor` de Firebase — eso exige
/// plan Blaze con tarjeta y está fuera del alcance de este proyecto (plan
/// Spark). En su lugar: tras validar la contraseña, se genera un código de
/// 6 dígitos, se guarda en `users/{uid}/verificacion/actual` con expiración
/// de 5 minutos, y se muestra en pantalla (modo desarrollo).
class AuthRepository {
  AuthRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get usuarioActual => _auth.currentUser;

  Future<void> registrar({
    required String email,
    required String password,
    required String nombre,
  }) async {
    try {
      final credencial = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await credencial.user?.updateDisplayName(nombre);

      final uid = credencial.user?.uid;
      if (uid != null) {
        await _firestore.collection('users').doc(uid).set({
          'nombre': nombre,
          'email': email,
          'creadoEn': FieldValue.serverTimestamp(),
        });
      }
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mensajeErrorAuth(e.code));
    } on FirebaseException catch (e) {
      throw AuthException('No se pudo guardar tu perfil: ${_mensajeErrorFirestore(e.code)}');
    }
  }

  Future<void> iniciarSesion({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mensajeErrorAuth(e.code));
    }
  }

  Future<void> enviarCorreoRecuperacion(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mensajeErrorAuth(e.code));
    }
  }

  Future<void> cerrarSesion() => _auth.signOut();

  /// Genera un código de 6 dígitos y lo guarda con expiración de 5 minutos.
  /// Devuelve el código para mostrarlo en pantalla.
  ///
  /// TODO(producción): enviar el código por correo (Cloud Function +
  /// servicio de email) en vez de mostrarlo en pantalla. No se implementa
  /// aquí porque requiere Cloud Functions, que exigen plan Blaze.
  Future<String> generarCodigoVerificacion() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw const AuthException('No hay sesión activa.');

    final codigo = (Random().nextInt(900000) + 100000).toString();
    final expiraEn = DateTime.now().add(const Duration(minutes: 5));

    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('verificacion')
          .doc('actual')
          .set({
        'codigo': codigo,
        'expiraEn': Timestamp.fromDate(expiraEn),
        'verificado': false,
      });
    } on FirebaseException catch (e) {
      throw AuthException(_mensajeErrorFirestore(e.code));
    }

    return codigo;
  }

  /// Valida el código contra `users/{uid}/verificacion/actual`. `false` si
  /// no coincide, expiró, o no hay sesión — nunca lanza por eso.
  Future<bool> verificarCodigo(String codigoIngresado) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;

    final ref = _firestore.collection('users').doc(uid).collection('verificacion').doc('actual');

    try {
      final snap = await ref.get();
      if (!snap.exists) return false;

      final data = snap.data()!;
      final codigo = data['codigo'] as String?;
      final expiraEn = (data['expiraEn'] as Timestamp?)?.toDate();

      if (codigo == null || expiraEn == null) return false;
      if (DateTime.now().isAfter(expiraEn)) return false;
      if (codigo != codigoIngresado.trim()) return false;

      await ref.update({'verificado': true});
      return true;
    } on FirebaseException catch (e) {
      throw AuthException(_mensajeErrorFirestore(e.code));
    }
  }

  String _mensajeErrorAuth(String code) {
    switch (code) {
      case 'invalid-email':
        return 'El correo no tiene un formato válido.';
      case 'user-disabled':
        return 'Esta cuenta fue deshabilitada.';
      case 'user-not-found':
        return 'No existe una cuenta con ese correo.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Correo o contraseña incorrectos.';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con ese correo.';
      case 'weak-password':
        return 'La contraseña es demasiado débil (mínimo 6 caracteres).';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta de nuevo más tarde.';
      case 'network-request-failed':
        return 'Sin conexión a internet.';
      default:
        return 'Ocurrió un error inesperado. Intenta de nuevo.';
    }
  }

  String _mensajeErrorFirestore(String code) {
    switch (code) {
      case 'permission-denied':
        return 'No tienes permiso para hacer esto.';
      case 'unavailable':
        return 'Sin conexión con el servidor. Intenta de nuevo.';
      default:
        return 'Ocurrió un error inesperado. Intenta de nuevo.';
    }
  }
}
