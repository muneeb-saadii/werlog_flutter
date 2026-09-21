import 'package:flutter/material.dart';
import '../../core/models/admin_user.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/status_badge.dart';
import '../widgets/user_avatar.dart';

/// User details screen: profile summary, account details, and
/// admin actions (Grant plan / Impersonate / Suspend / Delete).
class UserDetailScreen extends StatelessWidget {
  final AdminUser user;

  const UserDetailScreen({super.key, required this.user});

  void _confirmDestructive(BuildContext context, {required String action, required Color color}) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$action ${user.name}?'),
        content: Text('This will $action this user account. This action can be reviewed in the audit log.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$action requested for ${user.name}')),
              );
            },
            child: Text(action, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(),
              const SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppMetrics.pagePadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Transform.translate(
                      offset: const Offset(0, -5),
                      child: _ProfileCard(user: user),
                    ),
                    const SizedBox(height: AppMetrics.gapMd),
                    _DetailsCard(user: user),
                    const SizedBox(height: AppMetrics.gapLg),
                    const Text('ACTIONS', style: AppTextStyles.sectionLabel),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            label: 'Grant plan',
                            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Grant plan flow opened')),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionButton(
                            label: 'Impersonate',
                            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Impersonating ${user.name}')),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            label: 'Suspend',
                            danger: true,
                            onTap: () => _confirmDestructive(
                              context,
                              action: 'Suspend',
                              color: AppColors.dangerRed,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionButton(
                            label: 'Delete',
                            danger: true,
                            onTap: () => _confirmDestructive(
                              context,
                              action: 'Delete',
                              color: AppColors.dangerRed,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 8, AppMetrics.pagePadding, 48),
      decoration: const BoxDecoration(
        color: AppColors.darkGreen,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppMetrics.headerRadius),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.chevron_left_rounded, color: Colors.white),
          ),
          const Expanded(
            child: Text('User details', style: AppTextStyles.headerTitle),
          ),
          Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: AppColors.darkGreenLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.more_horiz_rounded, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final AdminUser user;

  const _ProfileCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(AppMetrics.cardRadius),
      ),
      child: Column(
        children: [
          UserAvatar(initials: user.initials, color: user.avatarColor, size: 76),
          const SizedBox(height: 16),
          Text(user.name, style: AppTextStyles.nameLarge),
          const SizedBox(height: 4),
          Text(user.email, style: AppTextStyles.emailSubtle),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              StatusBadge.status(user.status),
              if (user.plan == UserPlan.pro) StatusBadge.plan(user.plan),
              if (user.verified) StatusBadge.verified(),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  final AdminUser user;

  const _DetailsCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      ('Role', user.role),
      ('Subscription', user.subscriptionSummary),
      ('Last login', user.lastLoginLabel),
      ('Joined', user.joinedLabel),
      ('User ID', user.shortId),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(AppMetrics.cardRadius),
      ),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++)
            Column(
              children: [
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
                if (i != rows.length - 1) const Divider(height: 1, color: AppColors.divider),
              ],
            ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool danger;

  const _ActionButton({required this.label, required this.onTap, this.danger = false});

  @override
  Widget build(BuildContext context) {
    return Material(
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
          child: Text(
            label,
            style: danger ? AppTextStyles.actionButtonDanger : AppTextStyles.actionButton,
          ),
        ),
      ),
    );
  }
}
