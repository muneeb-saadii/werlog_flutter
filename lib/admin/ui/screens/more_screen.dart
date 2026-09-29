import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/admin_bottom_nav.dart';
import 'audit_log_screen.dart';
import 'plans_billing_screen.dart';
import 'review_queue_screen.dart';

// ── Screen ────────────────────────────────────────────────────────────────────

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  // Hard-coded admin profile — replace with real session data
  static const String _adminName  = 'Admin Panel';
  static const String _adminEmail = 'admin@werlog.com';
  static const String _adminRole  = 'Super Admin';
  static const String _version    = 'v2.4.1 · build 3021';

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: const AdminBottomNav(currentIndex: 4),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(children: [

            // ── Dark header ─────────────────────────────────────────────
            _MoreHeader(),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppMetrics.pagePadding),
              child: Column(children: [

                // ── Operations section ─────────────────────────────────
                _SectionLabel('OPERATIONS'),
                const SizedBox(height: 8),
                _MenuCard(items: [
                  _MenuItem(
                    icon: Icons.rate_review_rounded,
                    iconBg: AppColors.suspendedBg,
                    iconFg: AppColors.suspendedText,
                    label: 'Review Queue',
                    subtitle: '14 low-confidence items',
                    badge: '14',
                    badgeBg: AppColors.suspendedBg,
                    badgeFg: AppColors.suspendedText,
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => const ReviewQueueScreen())),
                  ),
                  _MenuItem(
                    icon: Icons.account_balance_wallet_rounded,
                    iconBg: AppColors.proBg,
                    iconFg: AppColors.proText,
                    label: 'Plans & Billing',
                    subtitle: '3 plans · 15 paid subscribers',
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => const PlansBillingScreen())),
                  ),
                  _MenuItem(
                    icon: Icons.history_rounded,
                    iconBg: AppColors.activeBg,
                    iconFg: AppColors.activeText,
                    label: 'Audit Log',
                    subtitle: 'Every admin action, tracked',
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => const AuditLogScreen())),
                    hasDivider: false,
                  ),
                ]),

                const SizedBox(height: 20),

                // ── System section ─────────────────────────────────────
                // _SectionLabel('SYSTEM'),
                // const SizedBox(height: 8),
                // _MenuCard(items: [
                //   _MenuItem(
                //     icon: Icons.notifications_outlined,
                //     iconBg: AppColors.deletedBg,
                //     iconFg: AppColors.textSecondary,
                //     label: 'Notifications',
                //     subtitle: 'Alert settings & push config',
                //     onTap: () => _notImplemented(context, 'Notifications'),
                //   ),
                //   _MenuItem(
                //     icon: Icons.tune_rounded,
                //     iconBg: AppColors.deletedBg,
                //     iconFg: AppColors.textSecondary,
                //     label: 'System Settings',
                //     subtitle: 'Engine config, rate limits',
                //     onTap: () => _notImplemented(context, 'System Settings'),
                //     hasDivider: false,
                //   ),
                // ]),

                const SizedBox(height: 20),

                // ── Account section ────────────────────────────────────
                _SectionLabel('ACCOUNT'),
                const SizedBox(height: 8),
                _MenuCard(items: [
                  _MenuItem(
                    icon: Icons.lock_outline_rounded,
                    iconBg: AppColors.deletedBg,
                    iconFg: AppColors.textSecondary,
                    label: 'Change Password',
                    onTap: () => _notImplemented(context, 'Change Password'),
                  ),
                  _MenuItem(
                    icon: Icons.logout_rounded,
                    iconBg: const Color(0xFFFBDEDA),
                    iconFg: const Color(0xFFB94040),
                    label: 'Logout',
                    onTap: () => _confirmLogout(context),
                    hasDivider: false,
                    danger: true,
                  ),
                ]),

                const SizedBox(height: 28),

                // ── Version ────────────────────────────────────────────
                Text(_version,
                    style: AppTextStyles.footerNote.copyWith(
                        color: AppColors.textSecondary, fontSize: 12),
                    textAlign: TextAlign.center),
              ]),
            ),
          ]),
        ),
      ),
    ),
    );

  }

  void _notImplemented(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$label — coming soon'),
      duration: const Duration(seconds: 1),
      backgroundColor: AppColors.darkGreen,
    ));
  }

  void _confirmLogout(BuildContext context) {
    final outerContext = context;  // ← capture before showDialog
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(   // ← use dialogContext for pops
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout', style: AppTextStyles.cardTitle),
        content: Text('Are you sure you want to sign out?',
            style: AppTextStyles.rowLabel),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),  // ← dialogContext
            child: Text('Cancel',
                style: AppTextStyles.actionButton.copyWith(
                    color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();  // ← close dialog first
              // TODO: clear session then navigate to login
              // Navigator.of(outerContext).pushNamedAndRemoveUntil(
              //   AdminRoutes.login, (route) => false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dangerRed,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Logout',
                style: TextStyle(
                    fontFamily: 'DMSans',
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _MoreHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    decoration: const BoxDecoration(
      color: AppColors.darkGreen,
      borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppMetrics.headerRadius)),
    ),
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
    child: Column(children: [

      // Avatar
      Container(
        width: 72, height: 72,
        decoration: const BoxDecoration(
          color: AppColors.accentGreen,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const Text('A',
            style: TextStyle(
                fontFamily: 'DMSans', fontSize: 30,
                fontWeight: FontWeight.w800,
                color: Colors.white)),
      ),

      const SizedBox(height: 12),

      Text(MoreScreen._adminName,
          style: AppTextStyles.headerTitle.copyWith(fontSize: 20)),
      const SizedBox(height: 4),
      Text(MoreScreen._adminEmail,
          style: AppTextStyles.headerSubtitle),
      const SizedBox(height: 10),

      // Admin role badge
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.accentGreen.withOpacity(0.25),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: AppColors.accentGreen.withOpacity(0.4), width: 1),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.shield_rounded,
              size: 13, color: AppColors.accentGreen),
          const SizedBox(width: 5),
          Text(MoreScreen._adminRole,
              style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 12, fontWeight: FontWeight.w700,
                  color: AppColors.accentGreen)),
        ]),
      ),
    ]),
  );
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Text(label, style: AppTextStyles.sectionLabel),
  );
}

// ── Menu card ─────────────────────────────────────────────────────────────────

class _MenuCard extends StatelessWidget {
  final List<_MenuItem> items;
  const _MenuCard({required this.items});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.cardWhite,
      borderRadius: BorderRadius.circular(AppMetrics.cardRadius),
      boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: Column(
      children: items.asMap().entries.map((e) {
        final item = e.value;
        return Column(children: [
          item,
          if (item.hasDivider)
            const Divider(height: 1, indent: 68, color: AppColors.divider),
        ]);
      }).toList(),
    ),
  );
}

// ── Menu item ─────────────────────────────────────────────────────────────────

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconBg, iconFg;
  final String label;
  final String? subtitle;
  final String? badge;
  final Color? badgeBg, badgeFg;
  final VoidCallback onTap;
  final bool hasDivider;
  final bool danger;

  const _MenuItem({
    required this.icon,
    required this.iconBg,
    required this.iconFg,
    required this.label,
    this.subtitle,
    this.badge,
    this.badgeBg,
    this.badgeFg,
    required this.onTap,
    this.hasDivider = true,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(AppMetrics.cardRadius),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
              color: iconBg, borderRadius: BorderRadius.circular(11)),
          child: Icon(icon, color: iconFg, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: AppTextStyles.rowValue.copyWith(
                    color: danger
                        ? AppColors.dangerRed
                        : AppColors.textPrimary)),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(subtitle!,
                  style: AppTextStyles.emailSubtle.copyWith(fontSize: 12)),
            ],
          ],
        )),
        if (badge != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
                color: badgeBg, borderRadius: BorderRadius.circular(20)),
            child: Text(badge!,
                style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 11.5, fontWeight: FontWeight.w700,
                    color: badgeFg)),
          ),
          const SizedBox(width: 6),
        ],
        if (!danger)
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.textSecondary, size: 20),
      ]),
    ),
  );
}
