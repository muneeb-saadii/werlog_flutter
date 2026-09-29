import 'package:flutter/material.dart';
import '../../../client/core/utils/shared_pref_helper.dart';
import 'core/routes/admin_routes.dart';
import 'core/theme/app_theme.dart';

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  static bool isSuperAdmin() {
    try {
      final data = SharedPrefHelper.getObject(SharedPrefHelper.loginData);
      if (data == null) return false;
      final meResponse = data['meResponse'] as Map<String, dynamic>?;
      if (meResponse == null) return false;
      final role   = meResponse['role']?.toString() ?? '';
      final result = role == 'ROLE_SUPER_ADMIN';
      debugPrint('[AdminApp] role=$role  isSuperAdmin=$result');
      return result;
    } catch (e) {
      debugPrint('[AdminApp] isSuperAdmin check error: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final startRoute = isSuperAdmin()
        ? AdminRoutes.dashboard
        : AdminRoutes.login;

    debugPrint('[AdminApp] initial route => $startRoute');

    return MaterialApp(
      title: 'Admin Panel',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      initialRoute: startRoute,
      onGenerateRoute: AdminRoutes.generateRoute,
      // Prevents back-pops past the root route from showing
      // "/admin" or "/" error pages in the parent navigator.
      navigatorObservers: [_AdminRootGuard()],
    );
  }
}

/// Intercepts back-navigation at the admin Navigator level.
/// When only one route remains (the root), it swallows the pop
/// so nothing bleeds through to the parent Navigator.
class _AdminRootGuard extends NavigatorObserver {
  @override
  Future<bool> didPopRoute() async {
    final nav = navigator;
    if (nav == null) return false;
    if (!nav.canPop()) return true; // swallow — nothing to pop
    return false;                   // let Navigator handle normally
  }
}
