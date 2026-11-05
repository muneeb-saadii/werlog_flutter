import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../firebase_options.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // Request notification permissions
    final NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final granted =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional;

    if (!granted) {
      debugPrint('❌ Notification permission denied');
      return;
    }
    debugPrint('✅ Notification permission granted');

    // Local notifications (Android + iOS)
    const AndroidInitializationSettings androidInitSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosInitSettings =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const InitializationSettings initSettings = InitializationSettings(
      android: androidInitSettings,
      iOS: iosInitSettings,
    );
    await _flutterLocalNotificationsPlugin.initialize(initSettings);

    // iOS: show notifications while app is in foreground
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Token (safe on iOS)
    final String? fcmToken = await _getTokenSafely();
    if (fcmToken != null) {
      debugPrint('🔑 FCM Token: $fcmToken');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', fcmToken);
    } else {
      debugPrint('⚠️ Token not ready yet, will arrive via onTokenRefresh');
    }

    // Token refresh
    _messaging.onTokenRefresh.listen((newToken) async {
      debugPrint('🔄 FCM Token refreshed: $newToken');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', newToken);
    });

    // Background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showNotification(message);
    });

    // App opened via notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('🔔 Notification clicked: ${message.notification?.title}');
    });
  }

  @pragma('vm:entry-point')
  static Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    debugPrint('📩 Background message: ${message.notification?.title}');
  }

  static Future<String?> _getTokenSafely() async {
    try {
      if (Platform.isIOS) {
        String? apns = await _messaging.getAPNSToken();
        int tries = 0;
        while (apns == null && tries < 5) {
          await Future.delayed(const Duration(seconds: 1));
          apns = await _messaging.getAPNSToken();
          tries++;
        }
        if (apns == null) return null; // simulator / capability missing
      }
      return await _messaging.getToken();
    } catch (e) {
      debugPrint('FCM token error: $e');
      return null;
    }
  }

  /// 🔹 Get FCM Token
  static Future<void> getToken() async {
    final token = await _getTokenSafely();
    if (token == null) return;
    debugPrint('🔑 FCM Token: $token');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcm_token', token);
  }

  /// 🔹 Show Local Notification (Android only; iOS shows it natively)
  static Future<void> _showNotification(RemoteMessage message) async {
    final RemoteNotification? notification = message.notification;

    if (Platform.isAndroid && notification != null) {
      const AndroidNotificationDetails androidDetails =
      AndroidNotificationDetails(
        'default_channel',
        'General Notifications',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      await _flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(android: androidDetails),
      );
    }
  }
}