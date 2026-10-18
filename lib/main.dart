import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'client/core/app_navigator.dart';
import 'client/core/firebase-service/firebase-service.dart';
import 'client/core/remote_config/remote_config_service.dart'; // ← new
import 'client/core/utils/shared_pref_helper.dart';
import 'client/core/widgets/restart_widget.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SharedPrefHelper.init();

  // 1. Initialise Firebase first
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 2. Fetch Remote Config and resolve APP_BASE_URL before the app renders
  //    This ensures ApiService.baseUrl and AdminApiService.baseUrl are correct
  //    from the very first API call.
  await RemoteConfigService.init();

  // 3. Push notifications (device only)
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    await NotificationService.initialize();
    await NotificationService.getToken();
  }

  runApp(
    RestartWidget(
      key: RestartWidget.my_key,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Werlog',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      home: AppNavigator(),
      initialRoute: '/splash',
    );
  }
}