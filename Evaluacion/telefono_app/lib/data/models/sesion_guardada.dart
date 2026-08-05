import 'package:cloud_firestore/cloud_firestore.dart';

/// Resumen de una sesión terminada, escrito en `users/{uid}/sessions` al
/// detener la generación de datos en el wearable.
class SesionGuardada {
  const SesionGuardada({
    required this.gameId,
    required this.sessionSeconds,
    required this.heartRatePromedio,
    required this.moves,
    required this.focusPromedio,
    required this.alertasDisparadas,
    required this.finalizadoEn,
  });

  final String? gameId;
  final int sessionSeconds;
  final double heartRatePromedio;
  final int moves;
  final double focusPromedio;
  final List<String> alertasDisparadas;
  final DateTime finalizadoEn;

  Map<String, dynamic> toFirestore() => {
        'gameId': gameId,
        'sessionSeconds': sessionSeconds,
        'heartRatePromedio': heartRatePromedio,
        'moves': moves,
        'focusPromedio': focusPromedio,
        'alertasDisparadas': alertasDisparadas,
        'finalizadoEn': Timestamp.fromDate(finalizadoEn),
      };
}
