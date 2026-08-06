import 'package:flutter/material.dart';

import 'aviso_privacidad_texto.dart';
import 'colores.dart';

/// Muestra el aviso de privacidad para consulta libre (ej. desde un enlace
/// de ajustes), sin el flujo de aceptación obligatoria que sí tiene
/// [PrivacyScreen] durante el registro — mismo texto, fuente única en
/// `aviso_privacidad_texto.dart`.
class AvisoPrivacidadView extends StatelessWidget {
  const AvisoPrivacidadView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aviso de privacidad')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Text(
            avisoPrivacidadTexto,
            style: const TextStyle(fontSize: kTextoDetalle, height: 1.4),
          ),
        ),
      ),
    );
  }
}
