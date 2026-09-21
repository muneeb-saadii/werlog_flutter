import 'package:flutter/material.dart';
import '../models/admin_user.dart';
import '../../ui/screens/dashboard_screen.dart';
import '../../ui/screens/users_list_screen.dart';
import '../../ui/screens/user_detail_screen.dart';
import '../../ui/screens/ocr_jobs_screen.dart';
import '../../ui/screens/invoices_screen.dart';
import '../../ui/screens/more_screen.dart';

class AdminRoutes {
  AdminRoutes._();

  static const String dashboard  = '/admin/dashboard';
  static const String usersList  = '/admin/users';
  static const String userDetail = '/admin/users/detail';
  static const String ocrJobs    = '/admin/ocr-jobs';
  static const String invoices   = '/admin/invoices';
  static const String more       = '/admin/more';
  // Sub-screens opened from More (pushed, not replaced)
  static const String reviewQueue  = '/admin/review-queue';
  static const String plansBilling = '/admin/plans';
  static const String auditLog     = '/admin/audit-log';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case dashboard:
        return MaterialPageRoute(
            builder: (_) => const DashboardScreen(), settings: settings);
      case usersList:
        return MaterialPageRoute(
            builder: (_) => const UsersListScreen(), settings: settings);
      case userDetail:
        final user = settings.arguments as AdminUser;
        return MaterialPageRoute(
            builder: (_) => UserDetailScreen(user: user), settings: settings);
      case ocrJobs:
        return MaterialPageRoute(
            builder: (_) => const OcrJobsScreen(), settings: settings);
      case invoices:
        return MaterialPageRoute(
            builder: (_) => const InvoicesScreen(), settings: settings);
      case more:
        return MaterialPageRoute(
            builder: (_) => const MoreScreen(), settings: settings);
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
              body: Center(
                  child: Text('No route for ${settings.name}'))),
          settings: settings,
        );
    }
  }
}
