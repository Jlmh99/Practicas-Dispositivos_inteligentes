import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

/// Notificación local de "tiempo de juego prolongado". Nunca lanza: si el
/// plugin o el permiso fallan (común en emuladores), simplemente no muestra
/// nada en vez de tumbar la app.
class NotificacionesService {
  NotificacionesService._();

  static final NotificacionesService instancia = NotificacionesService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _inicializado = false;

  static const _canalId = 'mind_games_alertas';

  Future<void> _asegurarInicializado() async {
    if (_inicializado) return;
    try {
      const configAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
      const config = InitializationSettings(android: configAndroid);
      await _plugin.initialize(config);
      _inicializado = true;
    } catch (e) {
      debugPrint('No se pudo inicializar notificaciones locales: $e');
    }
  }

  Future<void> mostrarAlertaTiempoProlongado() async {
    try {
      await _asegurarInicializado();
      if (!_inicializado) return;

      // Android 13+: sin este permiso el plugin no lanza, pero tampoco muestra nada.
      await Permission.notification.request();

      const detalles = NotificationDetails(
        android: AndroidNotificationDetails(
          _canalId,
          'Alertas de sesión',
          channelDescription: 'Avisos de tiempo de juego prolongado',
          importance: Importance.high,
          priority: Priority.high,
          color: Color(0xFFE53935),
        ),
      );
      await _plugin.show(
        1001,
        'Tiempo de juego prolongado',
        'Toma un descanso — llevas más de 30 minutos jugando.',
        detalles,
      );
    } catch (e) {
      debugPrint('No se pudo mostrar la notificación de alerta: $e');
    }
  }
}
