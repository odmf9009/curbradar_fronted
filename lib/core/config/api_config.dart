/// Configuración de conexión al backend de CurbRadar.
///
/// Dominio del proyecto: curbradar.tech
///
/// Para cambiar entorno al compilar:
///   flutter build apk --dart-define=ENVIRONMENT=production
///   flutter run --dart-define=ENVIRONMENT=development
class ApiConfig {
  static const String _environment =
      String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');

  // ── URLs del backend ───────────────────────────────────────────────────────
  // Producción: Nginx en el VPS con curbradar.tech
  static const String _prodBaseUrl = 'https://api.curbradar.tech/api';

  // Desarrollo: IP del VPS directa o localhost
  // Mientras configuras Nginx: http://<IP_DEL_VPS>:3000/api
  static const String _devBaseUrl = 'https://api.curbradar.tech/api';

  static String get baseUrl =>
      _environment == 'production' ? _prodBaseUrl : _devBaseUrl;

  // ── WebSocket (Socket.io) ─────────────────────────────────────────────────
  // Producción:  wss://api.curbradar.tech  (SSL via Nginx)
  // Desarrollo:  ws://localhost:3000
  static String get wsUrl =>
      _environment == 'production'
          ? 'wss://api.curbradar.tech'
          : 'wss://api.curbradar.tech';

  // ── Timeouts ──────────────────────────────────────────────────────────────
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // ── Endpoints ─────────────────────────────────────────────────────────────
  static const String authVerify = '/auth/verify';
  static const String authLogout = '/auth/logout';
  static const String objects    = '/objects';
  static const String users      = '/users';
  static const String chat       = '/chat';
  static const String alerts     = '/alerts';
  static const String requests   = '/requests';
  static const String admin      = '/admin';
  static const String upload     = '/upload';
}
