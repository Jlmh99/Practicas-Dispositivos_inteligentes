import 'package:flutter/material.dart';

import 'aviso_privacidad_texto.dart';
import 'colores.dart';

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
                    avisoPrivacidadTexto,
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
