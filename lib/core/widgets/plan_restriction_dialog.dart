import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class PlanRestrictionDialog extends StatelessWidget {
  final String message;
  final VoidCallback onViewPlans;
  final VoidCallback onViewUsage;
  final VoidCallback onCancel;

  const PlanRestrictionDialog({
    required this.message,
    required this.onViewPlans,
    required this.onViewUsage,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: WerlogColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [

          // ── Icon ───────────────────────────────────────────────────
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: WerlogColors.amberSurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: WerlogColors.amber,
              size: 26,
            ),
          ),

          const SizedBox(height: 16),

          // ── Title ──────────────────────────────────────────────────
          const Text(
            'Plan Limit Reached',
            style: TextStyle(
              fontFamily: 'DMSans',
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: WerlogColors.textPrimary,
            ),
          ),

          const SizedBox(height: 8),

          // ── Message ────────────────────────────────────────────────
          Text(
            message,
            textAlign: TextAlign.center,
            style: WerlogTextStyles.captionSmall.copyWith(
              fontSize: 12,
              height: 1.55,
              color: WerlogColors.textSecondary,
            ),
          ),

          const SizedBox(height: 20),

          // ── Divider ────────────────────────────────────────────────
          const Divider(color: WerlogColors.borderLight),

          const SizedBox(height: 16),

          // ── Buttons ────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onViewPlans,
              style: ElevatedButton.styleFrom(
                backgroundColor: WerlogColors.teal,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.rocket_launch_rounded,
                      size: 15, color: Colors.white),
                  SizedBox(width: 7),
                  Text('Upgrade Plan',
                      style: TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      )),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onViewUsage,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 13),
                side: const BorderSide(color: WerlogColors.border),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bar_chart_rounded,
                      size: 15, color: WerlogColors.textSecondary),
                  SizedBox(width: 7),
                  Text('View Usage',
                      style: TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: WerlogColors.textSecondary,
                      )),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ── Dismiss ────────────────────────────────────────────────
          GestureDetector(
            onTap: onCancel,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Text('Maybe later',
                  style: TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 12,
                    color: WerlogColors.textTertiary,
                  )),
            ),
          ),
        ]),
      ),
    );
  }
}