import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'api_service.dart';
import '../config/api_config.dart';
import '../config/routes.dart';
import '../../main.dart'; // To access navigatorKey

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final ApiService _api = ApiService();

  /// Initialize notifications
  Future<void> init() async {
    // 1. Request permissions (iOS/Android 13+)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('Permisos de notificaciones concedidos');

      // 2. Get device token and save it to backend
      _saveDeviceToken();

      // 3. Setup Local Notifications (for Foreground)
      _initLocalNotifications();

      // 4. Listen to foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // 5. Handle app opening from notification
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        final objectId = message.data['objectId'];
        if (objectId != null) {
          _navigateToDetail(objectId);
        }
      });
    }
  }

  /// Subscribes the user to a specific city topic for remote alerts
  Future<void> subscribeToLocality(String locality) async {
    final topic = locality
        .toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '');
    if (topic.isNotEmpty) {
      await _fcm.subscribeToTopic('locality_$topic');
      print('Suscrito al tema: locality_$topic');
    }
  }

  /// Saves the device token to the backend
  Future<void> _saveDeviceToken() async {
    String? token = await _fcm.getToken();

    print('---------------------------------------------------------');
    print('TOKEN FCM PARA PRUEBAS: $token');
    print('---------------------------------------------------------');

    if (token != null && FirebaseAuth.instance.currentUser != null) {
      try {
        await _api.patch(
          '${ApiConfig.users}/me',
          data: {'fcmToken': token},
        );
      } catch (e) {
        print('[Notification] Error guardando token FCM: $e');
      }
    }
  }

  void _initLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: DarwinInitializationSettings(),
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        final String? objectId = response.payload;
        if (objectId != null && objectId.isNotEmpty) {
          _navigateToDetail(objectId);
        }
      },
    );

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'curb_alerts', // id
      'Alertas de Radar', // title
      description: 'Notificaciones de nuevos objetos encontrados cerca de ti',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      ledColor: Color(0xFFFF8A00),
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> _navigateToDetail(String objectId) async {
    try {
      final response = await _api.get('${ApiConfig.objects}/$objectId');
      // We navigate by pushing to objectDetail with the object data
      // The ObjectDetailScreen will re-fetch if needed
      navigatorKey.currentState?.pushNamed(
        AppRoutes.objectDetail,
        arguments: objectId, // Pass just the ID; screen fetches fresh data
      );
    } catch (e) {
      print('Error navegando al detalle desde notificación: $e');
    }
  }

  /// Sends a local notification immediately
  Future<void> showLocalAlert(String title, String body,
      {String? payload}) async {
    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      NotificationDetails(
        android: const AndroidNotificationDetails(
          'curb_alerts',
          'Alertas de CurbRadar',
          channelDescription: 'Objetos cercanos detectados',
          icon: '@mipmap/ic_launcher',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
          playSound: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final prefs = await SharedPreferences.getInstance();
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

    // 1. Don't show if the user is the actor
    final String? actorId = message.data['actorId'];
    if (actorId != null && actorId == currentUserId) {
      print('Notificación ignorada: El usuario actual es el autor.');
      return;
    }

    // 2. Respect user preferences
    final String? type = message.data['type'];
    bool isEnabled = true;

    if (type == 'nearby') isEnabled = prefs.getBool('notify_nearby') ?? true;
    if (type == 'chat') isEnabled = prefs.getBool('notify_chat') ?? true;
    if (type == 'points') isEnabled = prefs.getBool('notify_points') ?? true;
    if (type == 'new_post') isEnabled = prefs.getBool('notify_updates') ?? true;

    if (!isEnabled) {
      print('Notificación de tipo $type desactivada por el usuario.');
      return;
    }

    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const AndroidNotificationDetails(
          'curb_alerts',
          'Alertas de Radar',
          channelDescription: 'Nuevos objetos cerca',
          icon: '@mipmap/ic_launcher',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
        ).toNotificationDetails(),
        payload: message.data['objectId'],
      );
    }
  }
}

extension on AndroidNotificationDetails {
  NotificationDetails toNotificationDetails() =>
      NotificationDetails(android: this);
}
