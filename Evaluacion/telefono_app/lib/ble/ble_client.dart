import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_ble/shared_ble.dart';

import 'estado_conexion_ble.dart';
import 'payload_parser.dart';

/// Central BLE: escanea, se conecta al wearable, se suscribe a las 5
/// características de datos vía NOTIFY y puede escribir en CHAR_CONTROL.
///
/// Defensivo por diseño: ninguna excepción (BLE nativo o del wearable
/// desconectándose a media sesión) debe escapar sin capturar. Ante fallas,
/// publica `EstadoErrorBle`/`EstadoDesconectado` y reintenta con backoff en
/// vez de dejar una excepción sin manejar.
class BleClient {
  BleClient();

  static const _backoffSegundos = [2, 4, 8, 16, 30];
  static const _timeoutEscaneo = Duration(seconds: 15);
  static const _timeoutConexion = Duration(seconds: 15);

  final _estadoController = StreamController<EstadoConexionBle>.broadcast();
  final _heartRateController = StreamController<int>.broadcast();
  final _sessionSecondsController = StreamController<int>.broadcast();
  final _movesController = StreamController<int>.broadcast();
  final _focusLevelController = StreamController<double>.broadcast();
  final _activityStatusController = StreamController<String>.broadcast();

  EstadoConexionBle _estadoActual = const EstadoInactivo();
  BluetoothDevice? _dispositivo;
  BluetoothCharacteristic? _controlChar;
  BluetoothCharacteristic? _gameSelectChar;
  BluetoothCharacteristic? _timeOverrideChar;
  final List<StreamSubscription> _subsCaracteristicas = [];
  StreamSubscription<BluetoothConnectionState>? _subConexion;
  Timer? _reconexionTimer;
  int _intentoReconexion = 0;
  bool _detenido = true;

  /// Estado de conexión actual, con el último valor repetido a quien se
  /// suscriba después (para que `StreamProvider` no se quede "cargando"
  /// eternamente si nadie escuchaba cuando se emitió).
  Stream<EstadoConexionBle> get estadoConexion async* {
    yield _estadoActual;
    yield* _estadoController.stream;
  }

  Stream<int> get heartRate => _heartRateController.stream;
  Stream<int> get sessionSeconds => _sessionSecondsController.stream;
  Stream<int> get moves => _movesController.stream;
  Stream<double> get focusLevel => _focusLevelController.stream;
  Stream<String> get activityStatus => _activityStatusController.stream;

  void _emitirEstado(EstadoConexionBle nuevo) {
    _estadoActual = nuevo;
    if (!_estadoController.isClosed) _estadoController.add(nuevo);
  }

  /// Arranca el ciclo escanear → conectar → (si se cae) reconectar con backoff.
  Future<void> iniciar() async {
    _detenido = false;
    _intentoReconexion = 0;
    unawaited(_escanearYConectar());
  }

  Future<void> _escanearYConectar() async {
    if (_detenido) return;
    try {
      final dispositivo = await escanear();
      if (_detenido) return;
      if (dispositivo == null) {
        _emitirEstado(const EstadoErrorBle('No se encontró el wearable'));
        _programarReconexion();
        return;
      }
      await conectar(dispositivo);
    } catch (e) {
      if (_detenido) return;
      _emitirEstado(EstadoErrorBle(e.toString()));
      _programarReconexion();
    }
  }

  /// Escanea filtrando por `SERVICE_UUID` con timeout de 15 s. Devuelve el
  /// primer dispositivo encontrado, o `null` si no apareció ninguno.
  Future<BluetoothDevice?> escanear() async {
    _emitirEstado(const EstadoBuscando());
    final completer = Completer<BluetoothDevice?>();

    final sub = FlutterBluePlus.scanResults.listen(
      (resultados) {
        if (resultados.isNotEmpty && !completer.isCompleted) {
          completer.complete(resultados.first.device);
        }
      },
      onError: (Object _) {
        if (!completer.isCompleted) completer.complete(null);
      },
    );

    try {
      await FlutterBluePlus.startScan(
        withServices: [Guid(kServiceUuid)],
        timeout: _timeoutEscaneo,
      );
      return await completer.future.timeout(
        _timeoutEscaneo,
        onTimeout: () => null,
      );
    } catch (_) {
      return null;
    } finally {
      await sub.cancel();
      if (FlutterBluePlus.isScanningNow) {
        try {
          await FlutterBluePlus.stopScan();
        } catch (_) {
          // El adaptador ya pudo haberse desconectado; no es fatal.
        }
      }
    }
  }

  /// Se conecta, descubre servicios y activa NOTIFY en las 5 características
  /// de datos (todas menos CHAR_CONTROL, que se guarda para `enviarControl`).
  Future<void> conectar(BluetoothDevice dispositivo) async {
    _emitirEstado(const EstadoConectando());
    _dispositivo = dispositivo;

    await _subConexion?.cancel();
    _subConexion = dispositivo.connectionState.listen(_onCambioConexion);

    try {
      // License.nonprofit: proyecto académico UTEQ, uso no comercial.
      await dispositivo.connect(
        license: License.nonprofit,
        timeout: _timeoutConexion,
      );

      final servicios = await dispositivo.discoverServices();
      final servicio = servicios.firstWhere(
        (s) => s.uuid == Guid(kServiceUuid),
        orElse: () => throw StateError('Servicio no encontrado en el wearable'),
      );

      await _limpiarSuscripcionesCaracteristicas();
      for (final caracteristica in servicio.characteristics) {
        if (caracteristica.uuid == Guid(kCharControlUuid)) {
          _controlChar = caracteristica;
          continue;
        }
        if (caracteristica.uuid == Guid(kCharGameSelectUuid)) {
          _gameSelectChar = caracteristica;
          continue;
        }
        if (caracteristica.uuid == Guid(kCharSessionTimeOverrideUuid)) {
          _timeOverrideChar = caracteristica;
          continue;
        }
        await caracteristica.setNotifyValue(true);
        _subsCaracteristicas.add(
          caracteristica.onValueReceived.listen(
            (bytes) => _procesarBytes(caracteristica.uuid, Uint8List.fromList(bytes)),
          ),
        );
      }

      _intentoReconexion = 0;
      _emitirEstado(const EstadoConectado());
    } catch (e) {
      if (_detenido) return;
      _emitirEstado(EstadoErrorBle(e.toString()));
      _programarReconexion();
    }
  }

  void _onCambioConexion(BluetoothConnectionState estado) {
    if (estado == BluetoothConnectionState.disconnected) {
      unawaited(_limpiarSuscripcionesCaracteristicas());
      _controlChar = null;
      _gameSelectChar = null;
      _timeOverrideChar = null;
      if (_detenido) return;
      _emitirEstado(const EstadoDesconectado());
      _programarReconexion();
    }
  }

  void _procesarBytes(Guid uuid, Uint8List bytes) {
    if (uuid == Guid(kCharHeartRateUuid)) {
      final valor = PayloadParser.heartRate(bytes);
      if (valor != null) _heartRateController.add(valor);
    } else if (uuid == Guid(kCharSessionTimeUuid)) {
      final valor = PayloadParser.sessionSeconds(bytes);
      if (valor != null) _sessionSecondsController.add(valor);
    } else if (uuid == Guid(kCharMovesUuid)) {
      final valor = PayloadParser.moves(bytes);
      if (valor != null) _movesController.add(valor);
    } else if (uuid == Guid(kCharFocusUuid)) {
      final valor = PayloadParser.focusLevel(bytes);
      if (valor != null) _focusLevelController.add(valor);
    } else if (uuid == Guid(kCharStatusUuid)) {
      final valor = PayloadParser.activityStatus(bytes);
      if (valor != null) _activityStatusController.add(valor);
    }
  }

  /// Reconexión automática con backoff 2/4/8/16/30 s. Cancelable con
  /// `cancelarReconexion()` (y se cancela sola al llamar `dispose()`).
  void _programarReconexion() {
    if (_detenido) return;
    _reconexionTimer?.cancel();
    final indice = _intentoReconexion.clamp(0, _backoffSegundos.length - 1);
    final segundos = _backoffSegundos[indice];
    _intentoReconexion++;
    _reconexionTimer = Timer(Duration(seconds: segundos), () {
      if (!_detenido) unawaited(_escanearYConectar());
    });
  }

  void cancelarReconexion() {
    _reconexionTimer?.cancel();
    _reconexionTimer = null;
  }

  /// Escribe 0x01 (iniciar) o 0x00 (detener) en CHAR_CONTROL. Si el wearable
  /// ya no está conectado, no hace nada — nunca lanza.
  Future<void> enviarControl(bool iniciar) async {
    final caracteristica = _controlChar;
    if (caracteristica == null) return;
    try {
      await caracteristica.write([iniciar ? 0x01 : 0x00], withoutResponse: false);
    } catch (_) {
      // Defensivo: el wearable pudo desconectarse justo antes de escribir.
    }
  }

  /// Escribe el id del juego elegido en CHAR_GAME_SELECT, para que el
  /// wearable pueda reportarlo en su propio CHAR_STATUS. Si el wearable no
  /// está conectado todavía, no hace nada — nunca lanza (mismo criterio
  /// defensivo que `enviarControl`); cuando se conecte y el usuario vuelva a
  /// tocar un juego, se escribe entonces.
  Future<void> enviarJuegoSeleccionado(String gameId) async {
    final caracteristica = _gameSelectChar;
    if (caracteristica == null) return;
    try {
      await caracteristica.write(
        SensorPayload.encodeGameSelect(gameId.toUpperCase()),
        withoutResponse: false,
      );
    } catch (_) {
      // Defensivo: el wearable pudo desconectarse justo antes de escribir.
    }
  }

  /// Escribe en CHAR_SESSION_TIME_OVERRIDE para que el reloj del wearable
  /// salte al mismo valor que el botón "Forzar umbral (demo)" del teléfono,
  /// y siga sumando desde ahí. Puramente cosmético (el wearable no necesita
  /// mostrar la alerta), pero mantiene los tres relojes consistentes en la
  /// demo. Si el wearable no está conectado, no hace nada — nunca lanza.
  Future<void> enviarSessionSecondsOverride(int segundos) async {
    final caracteristica = _timeOverrideChar;
    if (caracteristica == null) return;
    try {
      await caracteristica.write(
        SensorPayload.encodeSessionSeconds(segundos),
        withoutResponse: false,
      );
    } catch (_) {
      // Defensivo: el wearable pudo desconectarse justo antes de escribir.
    }
  }

  Future<void> _limpiarSuscripcionesCaracteristicas() async {
    for (final sub in _subsCaracteristicas) {
      await sub.cancel();
    }
    _subsCaracteristicas.clear();
  }

  Future<void> dispose() async {
    _detenido = true;
    _reconexionTimer?.cancel();
    await _subConexion?.cancel();
    await _limpiarSuscripcionesCaracteristicas();
    try {
      final dispositivo = _dispositivo;
      if (dispositivo != null) {
        await dispositivo.disconnect();
      }
    } catch (_) {
      // Ya pudo estar desconectado; no es fatal durante el cierre.
    }
    await _estadoController.close();
    await _heartRateController.close();
    await _sessionSecondsController.close();
    await _movesController.close();
    await _focusLevelController.close();
    await _activityStatusController.close();
  }
}
