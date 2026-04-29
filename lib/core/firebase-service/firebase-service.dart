import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../firebase_options.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  /// 🔹 Initialize Firebase & Local Notifications
  // static Future<void> initialize() async {
  //   // Initialize Firebase
  //   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  //
  //   // Request notification permissions
  //   await _requestPermission();
  //
  //   // Initialize local notifications
  //   const AndroidInitializationSettings androidInitSettings =
  //   AndroidInitializationSettings('@mipmap/ic_launcher');
  //
  //   const InitializationSettings initSettings =
  //   InitializationSettings(android: androidInitSettings);
  //
  //   await _flutterLocalNotificationsPlugin.initialize(initSettings);
  //
  //   // Set background message handler
  //   FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  //
  //   // Foreground messages
  //   FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  //     _showNotification(message);
  //   });
  //
  //   // When app is opened by tapping on the notification
  //   FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
  //     debugPrint('🔔 Notification clicked: ${message.notification?.title}');
  //   });
  // }

  static Future<void> initialize() async {
    // Initialize Firebase
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    // Request notification permissions
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      debugPrint('❌ Notification permission denied');
      return;
    }
    debugPrint('✅ Notification permission granted');

    // Initialize local notifications (Android + iOS)
    const AndroidInitializationSettings androidInitSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosInitSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings =
    InitializationSettings(android: androidInitSettings, iOS: iosInitSettings);

    await _flutterLocalNotificationsPlugin.initialize(initSettings);

    // Wait for APNs registration to complete
    String? fcmToken = await _messaging.getToken();
    if (fcmToken != null) {
      debugPrint('🔑 FCM Token: $fcmToken');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', fcmToken);
    } else {
      debugPrint('⚠️ APNs token not ready yet, listening for token refresh...');
    }

    // Listen for token refresh (iOS important)
    _messaging.onTokenRefresh.listen((newToken) async {
      debugPrint('🔄 FCM Token refreshed: $newToken');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', newToken);
    });

    // Background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showNotification(message);
    });

    // When app is opened via notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('🔔 Notification clicked: ${message.notification?.title}');
    });
  }


  /// 🔹 Background Message Handler
  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    debugPrint('📩 Background message: ${message.notification?.title}');
  }

  /// 🔹 Request Notification Permissions (for iOS & Android 13+)
  static Future<void> _requestPermission() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('✅ Notification permission granted');
    } else {
      debugPrint('❌ Notification permission denied');
    }
  }

  /// 🔹 Get FCM Token
  static Future<void> getToken() async {
    String? token = await _messaging.getToken();
    debugPrint('🔑 FCM Token: $token');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcm_token', token!);
  }

  /// 🔹 Show Local Notification
  static Future<void> _showNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'default_channel',
        'General Notifications',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const NotificationDetails platformDetails =
      NotificationDetails(android: androidDetails);

      await _flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        platformDetails,
      );
    }
  }
}
