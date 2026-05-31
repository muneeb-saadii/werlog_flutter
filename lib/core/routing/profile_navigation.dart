// profile_segment/profile_navigation.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// HOW TO CALL ALL PROFILE SCREENS
// ─────────────────────────────────────────────────────────────────────────────
//
// Add to pubspec.yaml:
//   shared_preferences: ^2.2.2
//   image_picker: ^1.0.7
//   url_launcher: ^6.2.5
//
// Import this single file from anywhere in the app:
//   import 'profile_segment/profile_navigation.dart';
//
// Then call any route below.

import 'package:flutter/material.dart';
import 'package:wellness/ui/screens/profile_segment/edit_profile_screen.dart';
import 'package:wellness/ui/screens/profile_segment/subscription_usage_screen.dart';

import '../../ui/screens/profile_segment/currency_screen.dart';
import '../../ui/screens/profile_segment/info_screens.dart';
import '../../ui/screens/profile_segment/notifications_screen.dart';
import '../../ui/screens/profile_segment/ocr_engines_screen.dart';
import '../../ui/screens/profile_segment/reset_password_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NAVIGATION HELPERS  (call these from anywhere)
// ─────────────────────────────────────────────────────────────────────────────

class ProfileNavigation {
  ProfileNavigation._();

  /// Full profile — edit name, avatar, view account info.
  static void openProfile(BuildContext context) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const EditProfileScreen()));
  }

  /// Change password.
  static void openResetPassword(BuildContext context) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const ResetPasswordScreen()));
  }

  /// Change password.
  static void openCurrencySelection(BuildContext context) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const CurrencyScreen()));
  }

  /// Notifications.
  static void openNotifications(BuildContext context) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const NotificationsScreen()));
  }


  static void openPlanUsage(BuildContext context) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const SubscriptionUsageScreen()));
  }

  /// FAQs.
  static void openFaq(BuildContext context) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const FaqScreen()));
  }

  /// Contact Support.
  static void openContactSupport(BuildContext context) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const ContactSupportScreen()));
  }

  /// Terms & Conditions.
  static void openTerms(BuildContext context) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const TermsScreen()));
  }

  /// Privacy Policy.
  static void openPrivacyPolicy(BuildContext context) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()));
  }

  /// OCR Engines.
  static void openOcrEngines(BuildContext context) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const OcrEnginesScreen()));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NAMED ROUTES  (alternative — register in MaterialApp.routes)
// ─────────────────────────────────────────────────────────────────────────────
//
// In MaterialApp:
//   routes: ProfileRoutes.all,
//
// Then navigate with:
//   Navigator.pushNamed(context, ProfileRoutes.profile);

class ProfileRoutes {
  ProfileRoutes._();

  static const profile       = '/profile';
  static const resetPassword = '/profile/reset-password';
  static const faq           = '/profile/faq';
  static const contact       = '/profile/contact';
  static const terms         = '/profile/terms';
  static const privacy       = '/profile/privacy';
  static const ocrEngines    = '/profile/ocr-engines';

  static Map<String, WidgetBuilder> get all => {
        profile:       (_) => const EditProfileScreen(),
        resetPassword: (_) => const ResetPasswordScreen(),
        faq:           (_) => const FaqScreen(),
        contact:       (_) => const ContactSupportScreen(),
        terms:         (_) => const TermsScreen(),
        privacy:       (_) => const PrivacyPolicyScreen(),
        ocrEngines:    (_) => const OcrEnginesScreen(),
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// EXAMPLE PROFILE MENU TILE  (drop anywhere in your settings / profile tab)
// ─────────────────────────────────────────────────────────────────────────────

class ProfileMenuSection extends StatelessWidget {
  const ProfileMenuSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Account ──────────────────────────────────────────────────────
        _MenuGroup(
          label: 'Account',
          items: [
            _MenuItem(
              icon: Icons.person_outline_rounded,
              label: 'My Profile',
              onTap: () => ProfileNavigation.openProfile(context),
            ),
            _MenuItem(
              icon: Icons.lock_outline_rounded,
              label: 'Reset Password',
              onTap: () => ProfileNavigation.openResetPassword(context),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── App ───────────────────────────────────────────────────────────
        _MenuGroup(
          label: 'App',
          items: [
            _MenuItem(
              icon: Icons.psychology_outlined,
              label: 'OCR Engines',
              onTap: () => ProfileNavigation.openOcrEngines(context),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Support ───────────────────────────────────────────────────────
        _MenuGroup(
          label: 'Support',
          items: [
            _MenuItem(
              icon: Icons.help_outline_rounded,
              label: 'FAQs',
              onTap: () => ProfileNavigation.openFaq(context),
            ),
            _MenuItem(
              icon: Icons.support_agent_outlined,
              label: 'Contact Support',
              onTap: () => ProfileNavigation.openContactSupport(context),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Legal ─────────────────────────────────────────────────────────
        _MenuGroup(
          label: 'Legal',
          items: [
            _MenuItem(
              icon: Icons.gavel_rounded,
              label: 'Terms & Conditions',
              onTap: () => ProfileNavigation.openTerms(context),
            ),
            _MenuItem(
              icon: Icons.shield_outlined,
              label: 'Privacy Policy',
              onTap: () => ProfileNavigation.openPrivacyPolicy(context),
            ),
          ],
        ),
      ],
    );
  }
}

class _MenuGroup extends StatelessWidget {
  final String label;
  final List<_MenuItem> items;
  const _MenuGroup({required this.label, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(label.toUpperCase(),
              style: const TextStyle(
                fontFamily: 'DMSans', fontSize: 10,
                fontWeight: FontWeight.w500,
                color: _C.textTertiary, letterSpacing: 0.8,
              )),
        ),
        Container(
          decoration: BoxDecoration(
            color: _C.surface,
            border: Border.all(color: _C.border),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: items.asMap().entries.map((e) {
              final isLast = e.key == items.length - 1;
              return Column(children: [
                e.value,
                if (!isLast)
                  Padding(
                    padding: const EdgeInsets.only(left: 46),
                    child: Container(height: 0.5, color: _C.borderLight),
                  ),
              ]);
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(children: [
          Icon(icon, size: 18, color: iconColor ?? _C.textTertiary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                  fontFamily: 'DMSans', fontSize: 14,
                  color: _C.textPrimary,
                )),
          ),
          const Icon(Icons.chevron_right_rounded,
              size: 18, color: _C.textDisabled),
        ]),
      ),
    );
  }
}

// Colour shorthand so this file compiles standalone
class _C {
  static const surface      = Color(0xFFFFFFFF);
  static const border       = Color(0xFFE5E3DB);
  static const borderLight  = Color(0xFFEEECE4);
  static const textPrimary  = Color(0xFF0F2A2E);
  static const textTertiary = Color(0xFF888780);
  static const textDisabled = Color(0xFFB4B2A9);
}
