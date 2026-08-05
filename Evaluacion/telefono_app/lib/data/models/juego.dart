/// Un juego del catálogo (colección `games`).
class Juego {
  const Juego({
    required this.id,
    required this.nombre,
    required this.dificultad,
    required this.jugadas,
    required this.tiempoPromedioSeg,
    required this.mediaUrl,
    required this.estado,
    required this.orden,
  });

  /// Id del documento de Firestore (ej. "sudoku"), no un campo del propio
  /// documento — se necesita para `sessionState.gameId`.
  final String id;
  final String nombre;
  final String dificultad;
  final int jugadas;
  final int tiempoPromedioSeg;
  final String mediaUrl;
  final String estado;
  final int orden;

  bool get disponible => estado == 'disponible';

  factory Juego.fromFirestore(String id, Map<String, dynamic> data) {
    return Juego(
      id: id,
      nombre: data['nombre'] as String? ?? '',
      dificultad: data['dificultad'] as String? ?? '',
      jugadas: (data['jugadas'] as num?)?.toInt() ?? 0,
      tiempoPromedioSeg: (data['tiempoPromedioSeg'] as num?)?.toInt() ?? 0,
      mediaUrl: data['mediaUrl'] as String? ?? '',
      estado: data['estado'] as String? ?? 'disponible',
      orden: (data['orden'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'nombre': nombre,
        'dificultad': dificultad,
        'jugadas': jugadas,
        'tiempoPromedioSeg': tiempoPromedioSeg,
        'mediaUrl': mediaUrl,
        'estado': estado,
        'orden': orden,
      };
}
