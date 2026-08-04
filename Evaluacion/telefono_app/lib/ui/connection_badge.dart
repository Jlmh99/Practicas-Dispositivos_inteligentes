import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ble/estado_conexion_ble.dart';
import '../providers/ble_provider.dart';
import 'colores.dart';

/// Chip con color y texto explícito según el estado de conexión BLE.
class ConnectionBadge extends ConsumerWidget {
  const ConnectionBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncEstado = ref.watch(estadoConexionProvider);

    final (Color color, String texto) = asyncEstado.when(
      data: _textoYColorPara,
      loading: () => (kGrisOscuro, 'Buscando wearable…'),
      error: (error, _) => (kRojoError, 'Error: $error'),
    );

    return Chip(
      avatar: CircleAvatar(backgroundColor: color),
      label: Text(texto, style: const TextStyle(fontSize: kTextoDetalle)),
      backgroundColor: color.withValues(alpha: 0.12),
      side: BorderSide(color: color.withValues(alpha: 0.4)),
    );
  }

  (Color, String) _textoYColorPara(EstadoConexionBle estado) {
    return switch (estado) {
      EstadoInactivo() => (kGrisOscuro, 'Inactivo'),
      EstadoBuscando() => (kAzulSecundario, 'Buscando wearable…'),
      EstadoConectando() => (kAzulSecundario, 'Conectando…'),
      EstadoConectado() => (kVerdeExito, 'Conectado'),
      EstadoErrorBle(:final mensaje) => (kRojoError, 'Error: $mensaje'),
      EstadoDesconectado() => (kGrisOscuro, 'Desconectado'),
    };
  }
}
