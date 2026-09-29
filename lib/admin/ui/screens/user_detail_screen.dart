import 'package:flutter/material.dart';
import '../../core/api/admin_api_service.dart';
import '../../core/api/admin_endpoints.dart';
import '../../core/models/admin_user.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/status_badge.dart';
import '../widgets/user_avatar.dart';


class UserDetailScreen extends StatefulWidget {
  final AdminUser user;
  const UserDetailScreen({super.key, required this.user});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {

  bool    _actionLoading = false;
  String? _loadingAction; // which button is spinning

  AdminUser get u => widget.user;

  // ── API helpers ───────────────────────────────────────────────────────────

  Future<void> _callAction(
      String actionLabel,
      Future<Map<String, dynamic>?> Function() call, {
        VoidCallback? onSuccess,
      }) async {
    setState(() { _actionLoading = true; _loadingAction = actionLabel; });
    try {
      final resp = await call();
      debugPrint('[UserDetail] $actionLabel response => $resp');
      if (!mounted) return;
      final ok = resp != null &&
          (resp['result']?.toString() == '1' ||
              resp['status']?.toString().toLowerCase() == 'success');
      if (ok) {
        AdminApiService.showSuccess(context, '$actionLabel successful');
        onSuccess?.call();
      } else {
        AdminApiService.showError(
            context,
            resp?['message']?.toString() ?? '$actionLabel failed');
      }
    } catch (e) {
      debugPrint('[UserDetail] $actionLabel error => $e');
      if (mounted) AdminApiService.showError(context, '$actionLabel failed: $e');
    } finally {
      if (mounted) setState(() { _actionLoading = false; _loadingAction = null; });
    }
  }

  // ── Grant plan ────────────────────────────────────────────────────────────

  void _grantPlan() {
    String? selectedPlan = 'PRO';
    final dialogContext = context;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text('Grant plan to ${u.name}',
            style: AppTextStyles.cardTitle),
        content: StatefulBuilder(
          builder: (_, setSt) => Column(
            mainAxisSize: MainAxisSize.min,
            children: ['FREE', 'PRO', 'BUSINESS'].map((p) =>
                RadioListTile<String>(
                  title: Text(p, style: AppTextStyles.rowValue),
                  value: p,
                  groupValue: selectedPlan,
                  activeColor: AppColors.accentGreen,
                  onChanged: (v) => setSt(() => selectedPlan = v),
                ),
            ).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel',
                style: AppTextStyles.actionButton.copyWith(
                    color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _callAction('Grant $selectedPlan', () =>
                  AdminApiService.post(
                    dialogContext,
                    AdminEndpoints.adminUserGrantPlan(u.id),
                    body: {'planCode': selectedPlan},
                    showLoader: false,
                  ),
              );
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkGreen, elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20))),
            child: const Text('Grant',
                style: TextStyle(fontFamily: 'DMSans',
                    fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Impersonate ───────────────────────────────────────────────────────────

  void _impersonate() {
    final dialogContext = context;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Impersonate ${u.name}?',
            style: AppTextStyles.cardTitle),
        content: Text(
            'You will act as this user in the system. '
                'All actions will be logged in the audit trail.',
            style: AppTextStyles.rowLabel),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel',
                style: AppTextStyles.actionButton.copyWith(
                    color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _callAction('Impersonate', () =>
                  AdminApiService.post(
                    dialogContext,
                    AdminEndpoints.adminUserImpersonate(u.id),
                    showLoader: false,
                  ),
              );
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkGreen, elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20))),
            child: const Text('Impersonate',
                style: TextStyle(fontFamily: 'DMSans',
                    fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Suspend / Reactivate ──────────────────────────────────────────────────

  void _toggleSuspend() {
    final isSuspended = u.status == UserStatus.suspended;
    final action      = isSuspended ? 'Reactivate' : 'Suspend';
    final dialogContext = context;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('$action ${u.name}?', style: AppTextStyles.cardTitle),
        content: Text(
            isSuspended
                ? 'This will restore the user\'s access to the platform.'
                : 'This will block the user\'s access to the platform. '
                'This action is logged in the audit trail.',
            style: AppTextStyles.rowLabel),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel',
                style: AppTextStyles.actionButton.copyWith(
                    color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _callAction(action, () =>
                  AdminApiService.post(
                    dialogContext,
                    isSuspended
                        ? AdminEndpoints.adminUserReactivate(u.id)
                        : AdminEndpoints.adminUserSuspend(u.id),
                    showLoader: false,
                  ),
              );
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: isSuspended
                    ? AppColors.accentGreen
                    : AppColors.dangerRed,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20))),
            child: Text(action,
                style: const TextStyle(fontFamily: 'DMSans',
                    fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  void _delete() {
    final dialogContext = context;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete ${u.name}?', style: AppTextStyles.cardTitle),
        content: Text(
            'This will soft-delete the account. The user\'s data will be '
                'retained but they will no longer be able to sign in.',
            style: AppTextStyles.rowLabel),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel',
                style: AppTextStyles.actionButton.copyWith(
                    color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _callAction('Delete', () =>
                  AdminApiService.delete(
                    dialogContext,
                    AdminEndpoints.adminUserDelete(u.id),
                    showLoader: false,
                  ),
                onSuccess: () => Navigator.of(dialogContext).pop(),
              );
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.dangerRed, elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20))),
            child: const Text('Delete',
                style: TextStyle(fontFamily: 'DMSans',
                    fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isSuspended = u.status == UserStatus.suspended;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _Header(),
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppMetrics.pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Transform.translate(
                    offset: const Offset(0, -5),
                    child: _ProfileCard(user: u),
                  ),
                  const SizedBox(height: AppMetrics.gapMd),
                  _DetailsCard(user: u),
                  const SizedBox(height: AppMetrics.gapLg),
                  const Text('ACTIONS', style: AppTextStyles.sectionLabel),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _ActionButton(
                      label: 'Grant plan',
                      icon: Icons.card_membership_rounded,
                      loading: _loadingAction == 'Grant plan',
                      onTap: _actionLoading ? null : _grantPlan,
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _ActionButton(
                      label: 'Impersonate',
                      icon: Icons.swap_horiz_rounded,
                      loading: _loadingAction == 'Impersonate',
                      onTap: _actionLoading ? null : _impersonate,
                    )),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _ActionButton(
                      label: isSuspended ? 'Reactivate' : 'Suspend',
                      icon: isSuspended
                          ? Icons.check_circle_outline_rounded
                          : Icons.pause_circle_outline_rounded,
                      danger: !isSuspended,
                      loading: _loadingAction == 'Suspend' ||
                          _loadingAction == 'Reactivate',
                      onTap: _actionLoading ? null : _toggleSuspend,
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _ActionButton(
                      label: 'Delete',
                      icon: Icons.delete_outline_rounded,
                      danger: true,
                      loading: _loadingAction == 'Delete',
                      onTap: _actionLoading ? null : _delete,
                    )),
                  ]),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Sub-widgets (unchanged structure, same as original) ───────────────────────

class _Header extends StatelessWidget {
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
        icon: const Icon(Icons.chevron_left_rounded, color: Colors.white),
      ),
      const Expanded(
          child: Text('User details', style: AppTextStyles.headerTitle)),
      // Container(
      //   width: 40, height: 40,
      //   margin: const EdgeInsets.only(right: 4),
      //   decoration: BoxDecoration(
      //       color: AppColors.darkGreenLight,
      //       borderRadius: BorderRadius.circular(12)),
      //   child: const Icon(Icons.more_horiz_rounded,
      //       color: Colors.white, size: 20),
      // ),
    ]),
  );
}

class _ProfileCard extends StatelessWidget {
  final AdminUser user;
  const _ProfileCard({required this.user});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
    decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(AppMetrics.cardRadius)),
    child: Column(children: [
      UserAvatar(initials: user.initials, color: user.avatarColor, size: 76),
      const SizedBox(height: 16),
      Text(user.name, style: AppTextStyles.nameLarge),
      const SizedBox(height: 4),
      Text(user.email, style: AppTextStyles.emailSubtle),
      const SizedBox(height: 14),
      Wrap(
        spacing: 8, runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          StatusBadge.status(user.status),
          if (user.plan == UserPlan.pro) StatusBadge.plan(user.plan),
          if (user.verified) StatusBadge.verified(),
        ],
      ),
    ]),
  );
}

class _DetailsCard extends StatelessWidget {
  final AdminUser user;
  const _DetailsCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      ('Role',         user.role),
      ('Subscription', user.subscriptionSummary),
      ('Last login',   user.lastLoginLabel),
      ('Joined',       user.joinedLabel),
      ('User ID',      user.shortId),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(AppMetrics.cardRadius)),
      child: Column(
        children: List.generate(rows.length, (i) => Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(rows[i].$1, style: AppTextStyles.rowLabel),
                Text(rows[i].$2, style: AppTextStyles.rowValue),
              ],
            ),
          ),
          if (i != rows.length - 1)
            const Divider(height: 1, color: AppColors.divider),
        ])),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool danger;
  final bool loading;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    this.danger   = false,
    this.loading  = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.cardWhite,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: danger ? AppColors.dangerBorder : AppColors.divider,
            width: 1.2,
          ),
        ),
        alignment: Alignment.center,
        child: loading
            ? SizedBox(
            width: 18, height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: danger ? AppColors.dangerRed : AppColors.accentGreen,
            ))
            : Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon,
              size: 16,
              color: danger
                  ? AppColors.dangerRed
                  : AppColors.textPrimary),
          const SizedBox(width: 6),
          Text(label,
              style: danger
                  ? AppTextStyles.actionButtonDanger
                  : AppTextStyles.actionButton),
        ]),
      ),
    ),
  );
}