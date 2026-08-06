import 'package:flutter/material.dart';

import 'colores.dart';

const String _textoAviso = '''
Responsable: Mind Games — proyecto académico UTEQ (Juan Luis Mendoza Hernandez).

Datos que recabamos: correo electrónico, contraseña (cifrada por Firebase Authentication) y datos de sesión de juego capturados por el wearable (ritmo cardiaco, tiempo de sesión, movimientos, nivel de concentración).

Finalidad: identificarte dentro de la app, sincronizar tu sesión de juego entre el teléfono y la pantalla, y mostrarte tu historial de sesiones.

Estos datos NO se comparten con terceros ni se usan con fines comerciales. Es un proyecto académico sin fines de lucro.

Derechos ARCO: puedes solicitar Acceso, Rectificación, Cancelación u Oposición sobre tus datos personales escribiendo al responsable del proyecto. Puedes eliminar tu cuenta y tus datos en cualquier momento.

Retención: tus datos de sesión se conservan mientras tu cuenta exista. Al eliminar tu cuenta se eliminan también tus sesiones guardadas.
''';

/// Aviso de privacidad con aceptación obligatoria antes de completar el
/// registro (LFPDPPP: responsable, datos, finalidad, derechos ARCO).
class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key, required this.onAceptar});

  /// Se llama cuando el usuario acepta y presiona continuar. Si lanza, el
  /// error se muestra aquí mismo (ej. `AuthException` del registro).
  final Future<void> Function() onAceptar;

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  bool _aceptado = false;
  bool _procesando = false;
  String? _error;

  Future<void> _continuar() async {
    setState(() {
      _procesando = true;
      _error = null;
    });
    try {
      await widget.onAceptar();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aviso de privacidad')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    _textoAviso,
                    style: const TextStyle(fontSize: kTextoDetalle, height: 1.4),
                  ),
                ),
              ),
              CheckboxListTile(
                value: _aceptado,
                onChanged: (v) => setState(() => _aceptado = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: const Text('He leído y acepto el aviso de privacidad.'),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(_error!, style: const TextStyle(color: kRojoError)),
                ),
              ElevatedButton(
                onPressed: (_aceptado && !_procesando) ? _continuar : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kAzulPrimario,
                  foregroundColor: kGrisClaro,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _procesando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Continuar y crear cuenta'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
