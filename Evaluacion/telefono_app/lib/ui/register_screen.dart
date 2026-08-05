import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import 'colores.dart';
import 'privacy_screen.dart';

final _emailRegExp = RegExp(r'^[\w.\-]+@[\w\-]+\.[\w\-.]+$');

/// Registro: valida el formulario (correo, contraseña, confirmación,
/// campos obligatorios) y solo entonces pasa a [PrivacyScreen] — el aviso de
/// privacidad se acepta ANTES de crear la cuenta, no después.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmarCtrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmarCtrl.dispose();
    super.dispose();
  }

  void _irAPrivacidad() {
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PrivacyScreen(onAceptar: _completarRegistro)),
    );
  }

  Future<void> _completarRegistro() async {
    await ref.read(authRepositoryProvider).registrar(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          nombre: _nombreCtrl.text.trim(),
        );
    // authStateProvider ya emitió el nuevo usuario: AuthGate va a mostrar
    // TwoFactorScreen solo. Volvemos hasta la raíz para no dejar
    // LoginScreen/RegisterScreen/PrivacyScreen apiladas debajo.
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kGrisClaro,
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nombreCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'El nombre es obligatorio.' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Correo'),
                  validator: (v) {
                    final valor = v?.trim() ?? '';
                    if (valor.isEmpty) return 'El correo es obligatorio.';
                    if (!_emailRegExp.hasMatch(valor)) return 'Formato de correo inválido.';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Contraseña'),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'La contraseña es obligatoria.';
                    if (v.length < 6) return 'Mínimo 6 caracteres.';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmarCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Confirmar contraseña'),
                  validator: (v) =>
                      v != _passwordCtrl.text ? 'Las contraseñas no coinciden.' : null,
                ),
                const SizedBox(height: 20),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: kRojoError),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ElevatedButton(
                  onPressed: _irAPrivacidad,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kAzulPrimario,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Continuar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
