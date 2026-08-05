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
        'actualizadoEn': Timestamp.fromDate(actualizadoEn),
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
