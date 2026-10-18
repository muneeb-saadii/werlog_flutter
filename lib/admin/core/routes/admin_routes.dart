import 'package:flutter/material.dart';
import '../models/admin_user.dart';
import '../../ui/screens/admin_login_screen.dart';
import '../../ui/screens/dashboard_screen.dart';
import '../../ui/screens/users_list_screen.dart';
import '../../ui/screens/user_detail_screen.dart';
import '../../ui/screens/ocr_jobs_screen.dart';
import '../../ui/screens/invoices_screen.dart';
import '../../ui/screens/more_screen.dart';
import '../../ui/screens/review_queue_screen.dart';
import '../../ui/screens/plans_billing_screen.dart';
import '../../ui/screens/audit_log_screen.dart';

class AdminRoutes {
  AdminRoutes._();

  static const String login        = '/admin/login';
  static const String dashboard    = '/admin/dashboard';
  static const String usersList    = '/admin/users';
  static const String userDetail   = '/admin/users/detail';
  static const String ocrJobs      = '/admin/ocr-jobs';
  static const String invoices     = '/admin/invoices';   // still accessible from More
  static const String more         = '/admin/more';
  static const String reviewQueue  = '/admin/review-queue';
  static const String plansBilling = '/admin/plans';      // now tab 3 in bottom nav
  static const String auditLog     = '/admin/audit-log';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(
            builder: (_) => const AdminLoginScreen(), settings: settings);
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
      case reviewQueue:
        return MaterialPageRoute(
            builder: (_) => const ReviewQueueScreen(), settings: settings);
      case plansBilling:
        return MaterialPageRoute(
            builder: (_) => const PlansBillingScreen(), settings: settings);
      case auditLog:
        return MaterialPageRoute(
            builder: (_) => const AuditLogScreen(), settings: settings);
      default:
        debugPrint('[AdminRoutes] unknown route: ${settings.name} — redirecting to dashboard');
        return MaterialPageRoute(
            builder: (_) => const DashboardScreen(), settings: settings);
    }
  }
}