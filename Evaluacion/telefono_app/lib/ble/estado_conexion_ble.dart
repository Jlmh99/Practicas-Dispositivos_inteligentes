/// Estado de la conexión BLE de `BleClient` con el wearable.
///
/// Sealed class en vez de un enum simple porque `EstadoErrorBle` necesita
/// llevar el mensaje del error consigo.
sealed class EstadoConexionBle {
  const EstadoConexionBle();
}

/// Estado inicial, antes de llamar a `iniciar()`.
class EstadoInactivo extends EstadoConexionBle {
  const EstadoInactivo();
}

/// Escaneando por `SERVICE_UUID`.
class EstadoBuscando extends EstadoConexionBle {
  const EstadoBuscando();
}

/// Wearable encontrado, conectando y descubriendo servicios/características.
class EstadoConectando extends EstadoConexionBle {
  const EstadoConectando();
}

/// Conectado y suscrito a las 5 características de datos.
class EstadoConectado extends EstadoConexionBle {
  const EstadoConectado();
}

/// Error de escaneo, conexión o descubrimiento de servicios.
class EstadoErrorBle extends EstadoConexionBle {
  const EstadoErrorBle(this.mensaje);

  final String mensaje;
}

/// El wearable se desconectó (perdido a media sesión o `disconnect()` explícito).
class EstadoDesconectado extends EstadoConexionBle {
  const EstadoDesconectado();
}
