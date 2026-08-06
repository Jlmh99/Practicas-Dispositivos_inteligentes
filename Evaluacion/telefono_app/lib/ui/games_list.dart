import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/juego.dart';
import '../providers/firestore_provider.dart';
import 'colores.dart';

/// Consume `juegosStream()` con estados de carga, error (con Reintentar) y
/// vacío. Tocar una tarjeta "disponible" la selecciona como
/// `sessionState.gameId`.
class GamesList extends ConsumerWidget {
  const GamesList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final juegosAsync = ref.watch(juegosStreamProvider);
    final seleccionado = ref.watch(juegoSeleccionadoProvider);

    return juegosAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: kRojoError, size: 32),
            const SizedBox(height: 8),
            Text(
              'No se pudieron cargar los juegos.\n$error',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: kTextoDetalle),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => ref.invalidate(juegosStreamProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: kAzulPrimario,
                foregroundColor: kGrisClaro,
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
      data: (juegos) {
        if (juegos.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Text('No hay juegos disponibles todavía.', textAlign: TextAlign.center),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Juegos',
                style: TextStyle(
                  fontSize: kTextoSecundario,
                  fontWeight: FontWeight.bold,
                  color: kGrisOscuro,
                ),
              ),
            ),
            const SizedBox(height: 8),
            for (final juego in juegos)
              _TarjetaJuego(
                juego: juego,
                seleccionado: juego.id == seleccionado,
                onTap: juego.disponible
                    ? () => ref.read(juegoSeleccionadoProvider.notifier).seleccionar(juego.id)
                    : null,
              ),
          ],
        );
      },
    );
  }
}

class _TarjetaJuego extends StatelessWidget {
  const _TarjetaJuego({required this.juego, required this.seleccionado, required this.onTap});

  final Juego juego;
  final bool seleccionado;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: seleccionado ? kAzulPrimario.withValues(alpha: 0.08) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: seleccionado ? const BorderSide(color: kAzulPrimario, width: 1.5) : BorderSide.none,
      ),
      child: ListTile(
        enabled: juego.disponible,
        onTap: onTap,
        leading: Icon(
          seleccionado ? Icons.check_circle : Icons.videogame_asset,
          color: juego.disponible ? kAzulPrimario : kGrisOscuro,
        ),
        title: Text(
          juego.nombre,
          style: const TextStyle(fontSize: kTextoCuerpo, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${juego.dificultad} · ${juego.jugadas} jugadas',
          style: const TextStyle(fontSize: kTextoDetalle),
        ),
        trailing: juego.disponible
            ? null
            : const Text('Próximamente', style: TextStyle(fontSize: 12, color: kGrisOscuro)),
      ),
    );
  }
}
