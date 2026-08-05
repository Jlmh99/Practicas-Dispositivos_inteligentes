import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import '../providers/auth_provider.dart';
import 'colores.dart';

const _duracionCodigo = Duration(minutes: 5);

/// 2FA sin costo: entrada del código de 6 dígitos generado por
/// `AuthRepository.generarCodigoVerificacion()`, con reenvío y temporizador.
///
/// El código se muestra en pantalla (modo desarrollo) porque enviarlo por
/// correo requeriría Cloud Functions (plan Blaze) — ver TODO en
/// `auth_repository.dart`. No usa MFA de Identity Platform.
class TwoFactorScreen extends ConsumerStatefulWidget {
  const TwoFactorScreen({super.key});

  @override
  ConsumerState<TwoFactorScreen> createState() => _TwoFactorScreenState();
}

class _TwoFactorScreenState extends ConsumerState<TwoFactorScreen> {
  final _controller = TextEditingController();
  Timer? _timer;
  Duration _restante = _duracionCodigo;

  String? _codigoDev;
  String? _error;
  bool _generando = true;
  bool _verificando = false;

  @override
  void initState() {
    super.initState();
    _generarCodigo();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _generarCodigo() async {
    setState(() {
      _generando = true;
      _error = null;
      _controller.clear();
    });
    try {
      final codigo = await ref.read(authRepositoryProvider).generarCodigoVerificacion();
      _iniciarTemporizador();
      if (!mounted) return;
      setState(() {
        _codigoDev = codigo;
        _generando = false;
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.mensaje;
        _generando = false;
      });
    }
  }

  void _iniciarTemporizador() {
    _timer?.cancel();
    _restante = _duracionCodigo;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_restante.inSeconds <= 0) {
        t.cancel();
        setState(() {});
        return;
      }
      setState(() => _restante -= const Duration(seconds: 1));
    });
  }

  Future<void> _verificar() async {
    setState(() {
      _verificando = true;
      _error = null;
    });
    try {
      final correcto = await ref.read(authRepositoryProvider).verificarCodigo(_controller.text);
      if (!mounted) return;
      if (correcto) {
        ref.read(verificacionCompletadaProvider.notifier).marcarCompletada();
      } else {
        setState(() => _error = 'Código incorrecto o expirado.');
      }
    } on AuthException catch (e) {
      setState(() => _error = e.mensaje);
    } finally {
      if (mounted) setState(() => _verificando = false);
    }
  }

  Future<void> _cerrarSesion() async {
    await ref.read(authRepositoryProvider).cerrarSesion();
  }

  @override
  Widget build(BuildContext context) {
    final expirado = _restante.inSeconds <= 0;
    final minutos = _restante.inMinutes;
    final segundos = _restante.inSeconds % 60;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificación en dos pasos'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'Cancelar / cerrar sesión',
            icon: const Icon(Icons.close),
            onPressed: _cerrarSesion,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Ingresa el código de 6 dígitos para confirmar tu identidad.',
                style: TextStyle(fontSize: kTextoCuerpo),
              ),
              const SizedBox(height: 16),
              if (_generando)
                const Center(child: CircularProgressIndicator())
              else if (_codigoDev != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kGrisClaro,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Modo desarrollo: en producción este código llegaría '
                        'por correo electrónico. Aquí se muestra directamente '
                        'para poder probar el flujo sin costo.',
                        style: TextStyle(fontSize: 12, color: kGrisOscuro),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _codigoDev!,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 8,
                          color: kAzulPrimario,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, letterSpacing: 8),
                  decoration: const InputDecoration(counterText: '', hintText: '••••••'),
                ),
                Text(
                  expirado
                      ? 'El código expiró.'
                      : 'Expira en $minutos:${segundos.toString().padLeft(2, '0')}',
                  style: TextStyle(color: expirado ? kRojoError : kGrisOscuro, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: kRojoError),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: (_verificando || expirado) ? null : _verificar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kAzulPrimario,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _verificando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Verificar'),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: _generando ? null : _generarCodigo,
                  child: const Text('Reenviar código'),
                ),
              ] else if (_error != null)
                Text(_error!, style: const TextStyle(color: kRojoError)),
            ],
          ),
        ),
      ),
    );
  }
}
