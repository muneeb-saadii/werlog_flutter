import 'package:flutter/material.dart';
import 'package:wellness/ui/screens/profile_segment/edit_profile_screen.dart';
import 'package:wellness/ui/screens/profile_segment/subscription_usage_screen.dart';

import '../../ui/screens/profile_segment/bank_statement_screen.dart';
import '../../ui/screens/profile_segment/currency_screen.dart';
import '../../ui/screens/profile_segment/info_screens.dart';
import '../../ui/screens/profile_segment/notifications_screen.dart';
import '../../ui/screens/profile_segment/ocr_engines_screen.dart';
import '../../ui/screens/profile_segment/reset_password_screen.dart';

class ProfileNavigation {
  ProfileNavigation._();

  static void openProfile(BuildContext context) =>
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const EditProfileScreen()));

  static void openResetPassword(BuildContext context) =>
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const ResetPasswordScreen()));

  static void openCurrencySelection(BuildContext context) =>
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const CurrencyScreen()));

  static void openNotifications(BuildContext context) =>
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const NotificationsScreen()));

  static void openPlanUsage(BuildContext context) =>
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const SubscriptionUsageScreen()));

  static void openFaq(BuildContext context) =>
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const FaqScreen()));

  static void openContactSupport(BuildContext context) =>
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const ContactSupportScreen()));

  static void openTerms(BuildContext context) =>
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const TermsScreen()));

  static void openPrivacyPolicy(BuildContext context) =>
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()));

  static void openOcrEngines(BuildContext context) =>
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const OcrEnginesScreen()));

  // ── NEW ──────────────────────────────────────────────────────────────
  static void openBankStatementMatch(BuildContext context) =>
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const BankStatementScreen()));
}