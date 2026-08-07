import 'package:cloud_firestore/cloud_firestore.dart';

/// Estado en vivo de la sesión, escrito en `sessionState/{uid}` cada ~2 s.
/// Es el corazón del sync teléfono→TV (requisito: propagación < 2 s).
class SessionState {
  const SessionState({
    required this.gameId,
    required this.heartRate,
    required this.sessionSeconds,
    required this.moves,
    required this.focusLevel,
    required this.activityStatus,
    required this.alertaActiva,
    required this.actualizadoEn,
  });

  final String? gameId;
  final int heartRate;
  final int sessionSeconds;
  final int moves;
  final double focusLevel;
  final String activityStatus;

  /// `true` si el umbral principal (sessionSeconds > 1800) está activo.
  final bool alertaActiva;

  final DateTime actualizadoEn;

  factory SessionState.fromFirestore(Map<String, dynamic> data) {
    return SessionState(
      gameId: data['gameId'] as String?,
      heartRate: (data['heartRate'] as num?)?.toInt() ?? 0,
      sessionSeconds: (data['sessionSeconds'] as num?)?.toInt() ?? 0,
      moves: (data['moves'] as num?)?.toInt() ?? 0,
      focusLevel: (data['focusLevel'] as num?)?.toDouble() ?? 0,
      activityStatus: data['activityStatus'] as String? ?? '',
      alertaActiva: data['alertaActiva'] as bool? ?? false,
      actualizadoEn: (data['actualizadoEn'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'gameId': gameId,
        'heartRate': heartRate,
        'sessionSeconds': sessionSeconds,
        'moves': moves,
        'focusLevel': focusLevel,
        'activityStatus': activityStatus,
        'alertaActiva': alertaActiva,
        // FieldValue.serverTimestamp(), NO Timestamp.fromDate(actualizadoEn):
        // la TV resta su propio Date.now() contra este valor para medir la
        // latencia de sync (js/app.js, actualizarLatencia()). Con el reloj
        // del teléfono (DateTime.now()) esa resta incluye el drift entre el
        // reloj del emulador del teléfono y el de la TV — encontrado en vivo
        // (~40s de diferencia de hardware, nada que ver con latencia real de
        // red). serverTimestamp() lo pone el propio servidor de Firestore al
        // confirmar la escritura: mismo reloj autoritativo para cualquier
        // dispositivo que lea, sin importar qué tan desincronizado esté el
        // reloj de quien escribió.
        'actualizadoEn': FieldValue.serverTimestamp(),
      };

  /// Compara los campos que importan para el debounce del sync — ignora
  /// `actualizadoEn`, que siempre cambia.
  bool tieneMismosDatosQue(SessionState otro) {
    return gameId == otro.gameId &&
        heartRate == otro.heartRate &&
        sessionSeconds == otro.sessionSeconds &&
        moves == otro.moves &&
        focusLevel == otro.focusLevel &&
        activityStatus == otro.activityStatus &&
        alertaActiva == otro.alertaActiva;
  }
}
