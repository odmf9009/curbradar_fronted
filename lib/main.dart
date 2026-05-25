import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/config/routes.dart';
import 'core/theme/app_theme.dart';
import 'core/services/notification_service.dart';
import 'core/services/language_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Manejador de mensajes FCM en segundo plano (fire-and-forget).
/// El token se envía al backend via /auth/verify, no hay Firestore aquí.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('[FCM Background] Mensaje recibido: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase — solo Auth y Messaging (sin Firestore)
  await Firebase.initializeApp();

  // Idioma
  await LanguageService().init();

  // Notificaciones
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await NotificationService().init();

  runApp(const CurbRadarApp());
}

class CurbRadarApp extends StatelessWidget {
  const CurbRadarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LanguageService(),
      builder: (context, _) {
        return MaterialApp(
          title: 'CurbRadar',
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          initialRoute: AppRoutes.splash,
          routes: AppRoutes.routes,
          locale: Locale(LanguageService().currentLanguage),
        );
      },
    );
  }
}
