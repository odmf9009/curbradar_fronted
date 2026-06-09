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

  // ── CONFIGURACIÓN DE RED ──────────────────────────────────────────────────
  static const String _domain = 'api.curbradar.tech';
  static const String fallbackIP = '2.24.77.82'; // IP del VPS Hostinger

  // URLs principales (Dominio) - IMPORTANTE: Terminar en / para que Dio concatene bien
  static const String _baseUrl = 'https://$_domain/api/';
  static const String _wsUrl   = 'https://$_domain'; 

  // URLs de respaldo (IP directa)
  static const String fallbackBaseUrl = 'http://$fallbackIP:3000/api/';
  static const String fallbackWsUrl   = 'http://$fallbackIP:3000';

  static String get baseUrl => _baseUrl;
  static String get wsUrl   => _wsUrl;

  // ── Timeouts aumentados para evitar errores de red lenta ──────────────────
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // ── Endpoints (SIN barra inicial para que se unan correctamente a /api/) ──
  static const String authVerify = 'auth/verify';
  static const String authLogout = 'auth/logout';
  static const String objects    = 'objects';
  static const String users      = 'users';
  static const String chat       = 'chat';
  static const String alerts     = 'alerts';
  static const String requests   = 'requests';
  static const String admin      = 'admin';
  static const String upload     = 'upload';
  static const String stats      = 'stats';
  // Gamification endpoints
  static const String achievements         = 'achievements';
  static const String achievementsCheck    = 'achievements/check';
  static const String activity             = 'activity';
  static const String referrals            = 'referrals';
  static const String referralsCode        = 'referrals/code';
  static const String referralsValidate    = 'referrals/validate';
  static const String referralsProcess     = 'referrals/process';
  static const String referralsHistory     = 'referrals/history';
  static const String referralsTrackFirstPost  = 'referrals/track-first-post';
  static const String referralsTrackCollection = 'referrals/track-collection';
  static const String rewards              = 'rewards';
  static const String rewardsXpHistory     = 'rewards/xp-history';
  static const String rewardsRedeem        = 'rewards/redeem';
}
