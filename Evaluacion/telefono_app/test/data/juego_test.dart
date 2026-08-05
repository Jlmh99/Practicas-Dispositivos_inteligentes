import 'package:flutter_test/flutter_test.dart';
import 'package:telefono_app/data/models/juego.dart';

void main() {
  group('Juego.fromFirestore', () {
    test('lee el id del documento, no de los campos', () {
      final juego = Juego.fromFirestore('sudoku', const {
        'nombre': 'Sudoku',
        'dificultad': 'Media',
        'jugadas': 128,
        'tiempoPromedioSeg': 412,
        'mediaUrl': 'assets/media/sudoku.jpg',
        'estado': 'disponible',
        'orden': 1,
      });

      expect(juego.id, 'sudoku');
      expect(juego.nombre, 'Sudoku');
      expect(juego.disponible, isTrue);
    });

    test('juego "proximamente" no está disponible', () {
      final juego = Juego.fromFirestore('hanoi', const {
        'nombre': 'Torres de Hanói',
        'dificultad': 'Difícil',
        'jugadas': 20,
        'tiempoPromedioSeg': 600,
        'mediaUrl': 'assets/media/hanoi.jpg',
        'estado': 'proximamente',
        'orden': 6,
      });

      expect(juego.disponible, isFalse);
    });

    test('campos faltantes no lanzan, caen a valores por defecto', () {
      final juego = Juego.fromFirestore('incompleto', const {});

      expect(juego.id, 'incompleto');
      expect(juego.nombre, '');
      expect(juego.jugadas, 0);
    });
  });

  group('Juego.toFirestore', () {
    test('round-trip preserva los campos (el id no va dentro del mapa)', () {
      const original = Juego(
        id: 'memorama',
        nombre: 'Memorama',
        dificultad: 'Fácil',
        jugadas: 141,
        tiempoPromedioSeg: 180,
        mediaUrl: 'assets/media/memorama.jpg',
        estado: 'disponible',
        orden: 4,
      );

      final mapa = original.toFirestore();
      final reconstruido = Juego.fromFirestore(original.id, mapa);

      expect(reconstruido.id, original.id);
      expect(reconstruido.nombre, original.nombre);
      expect(reconstruido.dificultad, original.dificultad);
      expect(reconstruido.jugadas, original.jugadas);
      expect(reconstruido.tiempoPromedioSeg, original.tiempoPromedioSeg);
      expect(reconstruido.mediaUrl, original.mediaUrl);
      expect(reconstruido.estado, original.estado);
      expect(reconstruido.orden, original.orden);
      expect(mapa.containsKey('id'), isFalse);
    });
  });
}
