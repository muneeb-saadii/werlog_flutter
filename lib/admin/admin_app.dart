import 'package:flutter/material.dart';
import 'core/routes/admin_routes.dart';
import 'core/theme/app_theme.dart';

/// Root widget for the admin panel: applies [AppTheme] and wires up
/// navigation via [AdminRoutes].
class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin Panel',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      initialRoute: AdminRoutes.dashboard,
      onGenerateRoute: AdminRoutes.generateRoute,
    );
  }
}
