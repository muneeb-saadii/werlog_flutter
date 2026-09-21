import 'package:flutter/material.dart';
import '../../core/models/admin_user.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// A small rounded pill used for status/plan/verified indicators,
/// e.g. "● Active", "PRO", "✓ Verified".
class StatusBadge extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final String? leadingGlyph;

  const StatusBadge({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    this.leadingGlyph,
  });

  /// Badge for [UserStatus] (Active / Suspended / Deleted), with a bullet dot.
  factory StatusBadge.status(UserStatus status) {
    switch (status) {
      case UserStatus.active:
        return StatusBadge(
          label: 'Active',
          background: AppColors.activeBg,
          foreground: AppColors.activeText,
          leadingGlyph: '●',
        );
      case UserStatus.suspended:
        return StatusBadge(
          label: 'Suspended',
          background: AppColors.suspendedBg,
          foreground: AppColors.suspendedText,
        );
      case UserStatus.deleted:
        return StatusBadge(
          label: 'Deleted',
          background: AppColors.deletedBg,
          foreground: AppColors.deletedText,
        );
    }
  }

  /// Badge for [UserPlan] (PRO / FREE / BUSINESS).
  factory StatusBadge.plan(UserPlan plan) {
    if (plan == UserPlan.pro) {
      return StatusBadge(
        label: 'PRO',
        background: AppColors.proBg,
        foreground: AppColors.proText,
      );
    }
    return StatusBadge(
      label: plan.label,
      background: AppColors.deletedBg,
      foreground: AppColors.textSecondary,
    );
  }

  /// Badge for the "Verified" checkmark indicator.
  factory StatusBadge.verified() {
    return StatusBadge(
      label: 'Verified',
      background: AppColors.verifiedBg,
      foreground: AppColors.verifiedText,
      leadingGlyph: '✓',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leadingGlyph != null) ...[
            Text(
              leadingGlyph!,
              style: AppTextStyles.badgeText.copyWith(color: foreground, fontSize: 10),
            ),
            const SizedBox(width: 4),
          ],
          Text(label, style: AppTextStyles.badgeText.copyWith(color: foreground)),
        ],
      ),
    );
  }
}
