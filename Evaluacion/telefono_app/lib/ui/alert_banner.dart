import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/activity_provider.dart';
import 'colores.dart';

/// Banner rojo que se desliza desde arriba cuando hay una alerta activa
/// (umbral principal primero, luego ritmo cardiaco, luego concentración).
/// Descartable: el botón de cerrar oculta ese mensaje puntual, no apaga la
/// evaluación de umbrales — si aparece una alerta distinta, se vuelve a mostrar.
class AlertBanner extends ConsumerStatefulWidget {
  const AlertBanner({super.key});

  @override
  ConsumerState<AlertBanner> createState() => _AlertBannerState();
}

class _AlertBannerState extends ConsumerState<AlertBanner> {
  String? _mensajeDescartado;

  @override
  Widget build(BuildContext context) {
    final alertas = ref.watch(activityProvider.select((s) => s.alertasActivas));
    final alerta = alertas.isEmpty ? null : alertas.first;
    final visible = alerta != null && alerta.mensaje != _mensajeDescartado;

    return AnimatedSlide(
      offset: visible ? Offset.zero : const Offset(0, -1.2),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      child: Material(
        color: kRojoError,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    alerta?.mensaje ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: kTextoDetalle,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: alerta == null
                      ? null
                      : () => setState(() => _mensajeDescartado = alerta.mensaje),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
