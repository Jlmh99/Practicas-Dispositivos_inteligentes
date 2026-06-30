class BleConstants {
  BleConstants._();

  // Servicio principal de actividad física
  static const String serviceUUID =
      '12345678-1234-1234-1234-123456789abc';

  // Característica: pasos (int32)
  static const String stepsUUID =
      'aaaaaaaa-0001-1234-1234-123456789abc';

  // Característica: ritmo cardíaco (uint8)
  static const String heartRateUUID =
      'aaaaaaaa-0002-1234-1234-123456789abc';

  // Característica: calorías (uint16)
  static const String caloriesUUID =
      'aaaaaaaa-0003-1234-1234-123456789abc';

  // Característica: estado de actividad
  static const String statusUUID =
      'aaaaaaaa-0004-1234-1234-123456789abc';
}