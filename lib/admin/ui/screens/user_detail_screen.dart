import 'package:flutter/material.dart';
import '../../core/api/admin_api_service.dart';
import '../../core/api/admin_endpoints.dart';
import '../../core/models/admin_user.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/status_badge.dart';
import '../widgets/user_avatar.dart';
import 'subscription_receipts_screen.dart';

class UserDetailScreen extends StatefulWidget {
  final AdminUser user;
  const UserDetailScreen({super.key, required this.user});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {

  bool    _actionLoading = false;
  String? _loadingAction;

  // Local mutable copy so we can reflect refreshed state
  late AdminUser _user;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
  }

  // ── Refresh user detail from API after any action ─────────────────────────

  Future<void> _refreshUser() async {
    try {
      final resp = await AdminApiService.get(
        context,
        AdminEndpoints.adminUserDetail(_user.id),
        showLoader: false,
      );
      debugPrint('[UserDetail] refresh => $resp');
      if (!mounted || resp == null) return;

      final raw = (resp['data'] as Map<String, dynamic>?) ?? resp;
      UserStatus status;
      switch ((raw['status'] ?? '').toString().toUpperCase()) {
        case 'SUSPENDED': status = UserStatus.suspended; break;
        case 'DELETED':   status = UserStatus.deleted;   break;
        default:          status = UserStatus.active;
      }
      UserPlan plan;
      switch ((raw['planCode'] ?? '').toString().toUpperCase()) {
        case 'PRO':      plan = UserPlan.pro;      break;
        case 'BUSINESS': plan = UserPlan.business; break;
        default:         plan = UserPlan.free;
      }
      setState(() {
        _user = AdminUser(
          id:                  raw['id']?.toString()       ?? _user.id,
          name:                raw['fullName']?.toString() ?? _user.name,
          email:               raw['email']?.toString()    ?? _user.email,
          status:              status,
          plan:                plan,
          role:                raw['role']?.toString()     ?? _user.role,
          verified:            raw['emailVerified'] == true,
          joined:              _parseDate(raw['createdAt']) ?? _user.joined,
          lastLogin:           _parseDate(raw['lastLoginAt']) ?? _user.lastLogin,
          subscriptionSummary: raw['subscriptionSummary']?.toString() ?? plan.label,
          avatarColor:         _user.avatarColor,
        );
      });
    } catch (e) {
      debugPrint('[UserDetail] refresh error => $e');
      // Non-fatal: we still have the pre-action state visible
    }
  }

  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    try { return DateTime.parse(v.toString()); } catch (_) { return null; }
  }

  // ── Generic action helper ─────────────────────────────────────────────────

  Future<void> _callAction(
      String label,
      Future<Map<String, dynamic>?> Function() call,
      ) async {
    setState(() { _actionLoading = true; _loadingAction = label; });
    try {
      final resp = await call();
      debugPrint('[UserDetail] $label response => $resp');
      if (!mounted) return;

      final ok = resp != null &&
          (resp['result']?.toString() == '1' ||
              resp['status']?.toString().toLowerCase() == 'success');

      if (ok) {
        AdminApiService.showSuccess(context, '$label successful');
        await _refreshUser(); // ← re-fetch and re-render
      } else {
        AdminApiService.showError(context,
            resp?['message']?.toString() ?? '$label failed');
      }
    } catch (e) {
      debugPrint('[UserDetail] $label error => $e');
      if (mounted) AdminApiService.showError(context, '$label failed');
    } finally {
      if (mounted) setState(() { _actionLoading = false; _loadingAction = null; });
    }
  }

  // ── Grant plan dialog ─────────────────────────────────────────────────────

  void _grantPlan() {
    String selectedPlan = 'PRO';
    final ctx = context;
    showDialog(
      context: context,
      builder: (dlg) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Grant plan to ${_user.name}', style: AppTextStyles.cardTitle),
        content: StatefulBuilder(
          builder: (_, setSt) => Column(
            mainAxisSize: MainAxisSize.min,
            children: ['FREE', 'PRO', 'BUSINESS'].map((p) =>
                RadioListTile<String>(
                  title: Text(p, style: AppTextStyles.rowValue),
                  value: p, groupValue: selectedPlan,
                  activeColor: AppColors.accentGreen,
                  onChanged: (v) { if (v != null) setSt(() => selectedPlan = v); },
                ),
            ).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dlg).pop(),
            child: Text('Cancel', style: AppTextStyles.actionButton
                .copyWith(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dlg).pop();
              _callAction('Grant $selectedPlan', () =>
                  AdminApiService.post(ctx,
                      AdminEndpoints.adminUserGrantPlan(_user.id),
                      body: {'planCode': selectedPlan}, showLoader: false));
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkGreen, elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20))),
            child: const Text('Grant', style: TextStyle(
                fontFamily: 'DMSans', fontWeight: FontWeight.w700,
                color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Impersonate dialog ────────────────────────────────────────────────────

  void _impersonate() {
    final ctx = context;
    showDialog(
      context: context,
      builder: (dlg) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Impersonate ${_user.name}?', style: AppTextStyles.cardTitle),
        content: Text(
            'You will act as this user in the system. '
                'All actions will be logged in the audit trail.',
            style: AppTextStyles.rowLabel),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dlg).pop(),
            child: Text('Cancel', style: AppTextStyles.actionButton
                .copyWith(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dlg).pop();
              _callAction('Impersonate', () =>
                  AdminApiService.post(ctx,
                      AdminEndpoints.adminUserImpersonate(_user.id),
                      showLoader: false));
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkGreen, elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20))),
            child: const Text('Impersonate', style: TextStyle(
                fontFamily: 'DMSans', fontWeight: FontWeight.w700,
                color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Suspend / Reactivate dialog ───────────────────────────────────────────

  void _toggleSuspend() {
    final isSuspended = _user.status == UserStatus.suspended;
    final action      = isSuspended ? 'Reactivate' : 'Suspend';
    final ctx = context;
    showDialog(
      context: context,
      builder: (dlg) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('$action ${_user.name}?', style: AppTextStyles.cardTitle),
        content: Text(
            isSuspended
                ? 'This will restore the user\'s access to the platform.'
                : 'This will block the user\'s access. '
                'This action is logged in the audit trail.',
            style: AppTextStyles.rowLabel),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dlg).pop(),
            child: Text('Cancel', style: AppTextStyles.actionButton
                .copyWith(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dlg).pop();
              _callAction(action, () => AdminApiService.post(ctx,
                  isSuspended
                      ? AdminEndpoints.adminUserReactivate(_user.id)
                      : AdminEndpoints.adminUserSuspend(_user.id),
                  showLoader: false));
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: isSuspended
                    ? AppColors.accentGreen : AppColors.dangerRed,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20))),
            child: Text(action, style: const TextStyle(
                fontFamily: 'DMSans', fontWeight: FontWeight.w700,
                color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isSuspended = _user.status == UserStatus.suspended;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 40),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

            // ── Header ────────────────────────────────────────────────────
            _DetailHeader(user: _user),

            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppMetrics.pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  // Profile card floats out of header
                  Transform.translate(
                    offset: const Offset(0, -5),
                    child: _ProfileCard(user: _user),
                  ),

                  const SizedBox(height: AppMetrics.gapMd),

                  _DetailsCard(user: _user),

                  const SizedBox(height: AppMetrics.gapLg),

                  // ── Actions label ──────────────────────────────────────
                  const Text('ACTIONS', style: AppTextStyles.sectionLabel),
                  const SizedBox(height: 12),

                  // Row 1: Grant plan + Suspend/Reactivate
                  Row(children: [
                    Expanded(child: _ActionButton(
                      label:   'Grant plan',
                      icon:    Icons.card_membership_rounded,
                      loading: _loadingAction == 'Grant PRO' ||
                          _loadingAction == 'Grant FREE' ||
                          _loadingAction == 'Grant BUSINESS',
                      onTap:   _actionLoading ? null : _grantPlan,
                    )),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionButton(
                        label:   isSuspended ? 'Reactivate user' : 'Suspend user',
                        icon:    isSuspended
                            ? Icons.check_circle_outline_rounded
                            : Icons.pause_circle_outline_rounded,
                        danger:  !isSuspended,
                        loading: _loadingAction == 'Suspend' ||
                            _loadingAction == 'Reactivate',
                        onTap:   _actionLoading ? null : _toggleSuspend,
                      ),
                    ),
                  ]),

                  const SizedBox(height: 20),

                  // ── Payment Receipts ───────────────────────────────────
                  const Text('BILLING', style: AppTextStyles.sectionLabel),
                  const SizedBox(height: 12),

                  _InvoicesEntryCard(user: _user),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _DetailHeader extends StatelessWidget {
  final AdminUser user;
  const _DetailHeader({required this.user});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(4, 8, AppMetrics.pagePadding, 48),
    decoration: const BoxDecoration(
      color: AppColors.darkGreen,
      borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppMetrics.headerRadius)),
    ),
    child: Row(children: [
      IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.chevron_left_rounded,
            color: Colors.white, size: 26),
      ),
      Expanded(child: Text('User details',
          style: AppTextStyles.headerTitle)),
    ]),
  );
}

// ── Profile card ──────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final AdminUser user;
  const _ProfileCard({required this.user});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
    decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(AppMetrics.cardRadius),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10, offset: const Offset(0, 3))]),
    child: Column(children: [
      UserAvatar(initials: user.initials, color: user.avatarColor, size: 76),
      const SizedBox(height: 16),
      Text(user.name, style: AppTextStyles.nameLarge),
      const SizedBox(height: 4),
      Text(user.email, style: AppTextStyles.emailSubtle),
      const SizedBox(height: 14),
      Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
        StatusBadge.status(user.status),
        if (user.plan != UserPlan.free) StatusBadge.plan(user.plan),
        if (user.verified) StatusBadge.verified(),
      ]),
    ]),
  );
}

// ── Details card ──────────────────────────────────────────────────────────────

class _DetailsCard extends StatelessWidget {
  final AdminUser user;
  const _DetailsCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      ('Role',         user.role.isNotEmpty ? user.role : '—'),
      ('Plan',         user.subscriptionSummary),
      ('Last login',   user.lastLoginLabel),
      ('Joined',       user.joinedLabel),
      ('User ID',      user.shortId),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(AppMetrics.cardRadius),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(
        children: List.generate(rows.length, (i) => Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(rows[i].$1, style: AppTextStyles.rowLabel),
              Flexible(child: Text(rows[i].$2,
                  style: AppTextStyles.rowValue,
                  textAlign: TextAlign.right)),
            ]),
          ),
          if (i < rows.length - 1)
            const Divider(height: 1, color: AppColors.divider),
        ])),
      ),
    );
  }
}

// ── Action button ─────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool danger, loading;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.label, required this.icon,
    this.danger = false, this.loading = false, this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.cardWhite,
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: danger ? AppColors.dangerBorder : AppColors.divider,
            width: 1.2,
          ),
        ),
        alignment: Alignment.center,
        child: loading
            ? SizedBox(width: 18, height: 18,
            child: CircularProgressIndicator(strokeWidth: 2,
                color: danger ? AppColors.dangerRed : AppColors.accentGreen))
            : Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16,
              color: danger ? AppColors.dangerRed : AppColors.textPrimary),
          const SizedBox(width: 7),
          Text(label,
              style: danger
                  ? AppTextStyles.actionButtonDanger
                  : AppTextStyles.actionButton),
        ]),
      ),
    ),
  );
}

// ── Invoices entry card ───────────────────────────────────────────────────────
// Tapping this fetches subscription invoices for this specific user
// then pushes the detail screen from subscription_receipts_screen.dart.

class _InvoicesEntryCard extends StatefulWidget {
  final AdminUser user;
  const _InvoicesEntryCard({required this.user});

  @override
  State<_InvoicesEntryCard> createState() => _InvoicesEntryCardState();
}

class _InvoicesEntryCardState extends State<_InvoicesEntryCard> {

  bool _loading = false;

  Future<void> _viewInvoices() async {
    setState(() => _loading = true);
    try {
      final resp = await AdminApiService.get(
        context,
        AdminEndpoints.adminUserSubscriptionInvoices(widget.user.id),
        showLoader: false,
      );
      debugPrint('[UserDetail] invoices => $resp');
      if (!mounted) return;

      if (resp != null && resp['result']?.toString() == '1') {
        final record = UserReceiptData.fromJson(
            resp['data'] as Map<String, dynamic>);
        Navigator.push(context, MaterialPageRoute(
            builder: (_) => SubscriptionReceiptDetailScreen(record: record)));
      } else {
        AdminApiService.showError(context,
            resp?['message']?.toString() ?? 'Failed to load invoices');
      }
    } catch (e) {
      debugPrint('[UserDetail] invoices error => $e');
      if (mounted) AdminApiService.showError(context, 'Failed to load invoices');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPaid = widget.user.plan != UserPlan.free;
    return Material(
      color: AppColors.cardWhite,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: _loading ? null : _viewInvoices,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isPaid
                  ? AppColors.accentGreen.withOpacity(0.3)
                  : AppColors.divider,
              width: 1.2,
            ),
          ),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: isPaid ? AppColors.activeBg : AppColors.deletedBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.receipt_long_rounded,
                  size: 18,
                  color: isPaid
                      ? AppColors.activeText
                      : AppColors.textSecondary),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Payment Receipts',
                    style: AppTextStyles.actionButton),
                const SizedBox(height: 2),
                Text(
                  isPaid
                      ? 'View subscription invoices for ${widget.user.plan.label}'
                      : 'No paid subscription',
                  style: AppTextStyles.emailSubtle.copyWith(fontSize: 12),
                ),
              ],
            )),
            _loading
                ? const SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.accentGreen))
                : const Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondary, size: 20),
          ]),
        ),
      ),
    );
  }
}