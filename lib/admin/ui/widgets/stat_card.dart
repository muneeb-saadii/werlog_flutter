import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';

/// A single white metric card used in the dashboard's 2x2 stats grid,
/// e.g. "1,284 / Total users / ↑ 42 this month".
class StatCard extends StatelessWidget {
  final String value;
  final String label;
  final String? delta;
  final Color? deltaColor;

  const StatCard({
    super.key,
    required this.value,
    required this.label,
    this.delta,
    this.deltaColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(AppMetrics.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: AppTextStyles.statValue),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.statLabel),
          if (delta != null) ...[
            const SizedBox(height: 6),
            Text(
              delta!,
              style: AppTextStyles.statDelta.copyWith(
                color: deltaColor ?? AppColors.activeText,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
