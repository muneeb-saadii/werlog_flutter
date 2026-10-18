import 'package:flutter/material.dart';
import '../../../client/core/utils/general_functions.dart';
import '../../../client/core/utils/shared_pref_helper.dart';
import '../../core/api/admin_api_service.dart';
import '../../core/api/admin_endpoints.dart';
import '../../core/routes/admin_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/admin_bottom_nav.dart';
import 'audit_log_screen.dart';
import 'invoices_screen.dart';          // ← NEW
import 'plans_billing_screen.dart';
import 'review_queue_screen.dart';
import 'subscription_receipts_screen.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {

  static const String _version = 'v2.4.1 · build 3021';

  String _name    = 'Admin';
  String _email   = '';
  String _initial = 'A';

  int? _reviewCount;
  int? _planCount;
  int? _paidSubs;
  int? _invoiceCount;    // ← NEW

  @override
  void initState() {
    super.initState();
    _loadProfile();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchStats());
  }

  void _loadProfile() {
    try {
      final data = SharedPrefHelper.getObject(SharedPrefHelper.loginData);
      final me   = data?['meResponse'] as Map<String, dynamic>?;
      if (me != null) {
        _name    = me['fullName']?.toString() ?? 'Admin';
        _email   = me['email']?.toString()    ?? '';
        _initial = _name.isNotEmpty ? _name[0].toUpperCase() : 'A';
      }
    } catch (e) {
      debugPrint('[More] profile error => $e');
    }
  }

  Future<void> _fetchStats() async {
    try {
      final results = await Future.wait([
        AdminApiService.get(context, AdminEndpoints.adminAuditQueue,
            queryParams: {'limit': '1', 'includeReviewed': 'false'},
            showLoader: false),
        AdminApiService.get(context, AdminEndpoints.adminPlans,
            showLoader: false),
        AdminApiService.get(context, AdminEndpoints.adminInvoices,
            queryParams: {'page': '0', 'size': '1'}, showLoader: false),
      ]);

      if (!mounted) return;

      // Review queue
      final qR = results[0];
      if (qR != null) {
        final raw = qR['data'];
        if (raw is List)
          _reviewCount = (qR['total'] as num?)?.toInt() ?? raw.length;
        else if (raw is Map)
          _reviewCount = (raw['totalElements'] as num?)?.toInt()
              ?? (raw['total'] as num?)?.toInt()
              ?? (raw['content'] as List?)?.length ?? 0;
      }

      // Plans
      final pR = results[1];
      if (pR != null) {
        final raw = pR['data'];
        if (raw is List) {
          _planCount = raw.length;
          _paidSubs = raw
              .whereType<Map<String, dynamic>>()
              .fold<int>(0, (s, p) {
            final count = p['subscriberCount']
                ?? p['totalSubscribers']
                ?? p['activeSubscriptions'];
            return s + ((count as num?)?.toInt() ?? 0);
          });
        }
      }

      // Invoices count
      final iR = results[2];
      if (iR != null) {
        final raw = iR['data'];
        if (raw is List) {
          _invoiceCount = (iR['total'] as num?)?.toInt() ?? raw.length;
        } else if (raw is Map) {
          _invoiceCount = (raw['totalElements'] as num?)?.toInt()
              ?? (raw['total'] as num?)?.toInt()
              ?? (raw['content'] as List?)?.length ?? 0;
        }
      }

      setState(() {});
    } catch (e) {
      debugPrint('[More] stats error => $e');
    }
  }

  String get _reviewSubtitle =>
      _reviewCount == null ? 'Loading…'
          : _reviewCount == 0  ? 'All caught up'
          : '$_reviewCount low-confidence items';

  String? get _reviewBadge =>
      (_reviewCount != null && _reviewCount! > 0) ? '$_reviewCount' : null;

  String get _plansSubtitle =>
      _planCount == null ? 'Loading…'
          : '$_planCount plans · ${_paidSubs ?? 0} paid subscribers';

  String get _invoicesSubtitle =>
      _invoiceCount == null ? 'Loading…' : '$_invoiceCount total invoices';

  Future<void> _logout(BuildContext outerCtx) async {
    SharedPrefHelper.clearAll();
    GeneralFunctions.restartApp();
  }

  void _confirmLogout() {
    final outerCtx = context;
    showDialog(
      context: context,
      builder: (dlg) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign out?', style: AppTextStyles.cardTitle),
        content: Text('You will be signed out and returned to the login screen.',
            style: AppTextStyles.rowLabel),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dlg).pop(),
            child: Text('Cancel', style: AppTextStyles.actionButton
                .copyWith(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () { Navigator.of(dlg).pop(); _logout(outerCtx); },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dangerRed, elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Logout', style: TextStyle(
                fontFamily: 'DMSans', fontWeight: FontWeight.w700,
                color: Colors.white)),
          ),
        ],
      ),
    );
  }

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

              _ProfileHeader(name: _name, email: _email, initial: _initial),
              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppMetrics.pagePadding),
                child: Column(children: [

                  // ── Operations ────────────────────────────────────────
                  const _SectionLabel('OPERATIONS'),
                  const SizedBox(height: 8),
                  _MenuCard(items: [
                    _MenuItem(
                      icon:    Icons.rate_review_rounded,
                      iconBg:  AppColors.suspendedBg,
                      iconFg:  AppColors.suspendedText,
                      label:   'Review Queue',
                      subtitle: _reviewSubtitle,
                      badge:   _reviewBadge,
                      badgeBg: AppColors.suspendedBg,
                      badgeFg: AppColors.suspendedText,
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => const ReviewQueueScreen())),
                    ),
                    _MenuItem(
                      icon:    Icons.history_rounded,
                      iconBg:  AppColors.activeBg,
                      iconFg:  AppColors.activeText,
                      label:   'Audit Log',
                      subtitle: 'Every admin action, tracked',
                      hasDivider: false,
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => const AuditLogScreen())),
                    ),
                  ]),

                  const SizedBox(height: 20),

                  // ── Billing ───────────────────────────────────────────
                  const _SectionLabel('BILLING'),
                  const SizedBox(height: 8),
                  _MenuCard(items: [
                    // Invoices now lives here
                    _MenuItem(
                      icon:    Icons.receipt_long_rounded,
                      iconBg:  AppColors.deletedBg,
                      iconFg:  AppColors.textSecondary,
                      label:   'Invoices',
                      subtitle: _invoicesSubtitle,
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => const InvoicesScreen())),
                    ),
                    _MenuItem(
                      icon:    Icons.receipt_outlined,
                      iconBg:  AppColors.proBg,
                      iconFg:  AppColors.proText,
                      label:   'Payment Receipts',
                      subtitle: 'Subscription invoices per subscriber',
                      hasDivider: false,
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => const SubscriptionReceiptsScreen())),
                    ),
                  ]),

                  const SizedBox(height: 20),

                  // ── Account ───────────────────────────────────────────
                  const _SectionLabel('ACCOUNT'),
                  const SizedBox(height: 8),
                  _MenuCard(items: [
                    _MenuItem(
                      icon:      Icons.logout_rounded,
                      iconBg:    const Color(0xFFFBDEDA),
                      iconFg:    const Color(0xFFB94040),
                      label:     'Logout',
                      hasDivider: false,
                      danger:    true,
                      onTap:     _confirmLogout,
                    ),
                  ]),

                  const SizedBox(height: 28),
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
}

// ── Widgets (same as before) ──────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final String name, email, initial;
  const _ProfileHeader({required this.name, required this.email, required this.initial});

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
      Container(
        width: 72, height: 72,
        decoration: const BoxDecoration(
            color: AppColors.accentGreen, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Text(initial, style: const TextStyle(
            fontFamily: 'DMSans', fontSize: 30,
            fontWeight: FontWeight.w800, color: Colors.white)),
      ),
      const SizedBox(height: 12),
      Text(name, style: AppTextStyles.headerTitle.copyWith(fontSize: 20)),
      const SizedBox(height: 4),
      Text(email, style: AppTextStyles.headerSubtitle),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.accentGreen.withOpacity(0.25),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.accentGreen.withOpacity(0.4), width: 1),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: const [
          Icon(Icons.shield_rounded, size: 13, color: AppColors.accentGreen),
          SizedBox(width: 5),
          Text('Super Admin', style: TextStyle(
              fontFamily: 'DMSans', fontSize: 12,
              fontWeight: FontWeight.w700, color: AppColors.accentGreen)),
        ]),
      ),
    ]),
  );
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Text(label, style: AppTextStyles.sectionLabel),
  );
}

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
      children: items.asMap().entries.map((e) => Column(children: [
        e.value,
        if (e.value.hasDivider)
          const Divider(height: 1, indent: 68, color: AppColors.divider),
      ])).toList(),
    ),
  );
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconBg, iconFg;
  final String label;
  final String? subtitle, badge;
  final Color? badgeBg, badgeFg;
  final VoidCallback onTap;
  final bool hasDivider, danger;

  const _MenuItem({
    required this.icon, required this.iconBg, required this.iconFg,
    required this.label, this.subtitle, this.badge, this.badgeBg, this.badgeFg,
    required this.onTap, this.hasDivider = true, this.danger = false,
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
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: AppTextStyles.rowValue.copyWith(
              color: danger ? AppColors.dangerRed : AppColors.textPrimary)),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!, style: AppTextStyles.emailSubtle.copyWith(fontSize: 12)),
          ],
        ])),
        if (badge != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
                color: badgeBg, borderRadius: BorderRadius.circular(20)),
            child: Text(badge!, style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 11.5, fontWeight: FontWeight.w700, color: badgeFg)),
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