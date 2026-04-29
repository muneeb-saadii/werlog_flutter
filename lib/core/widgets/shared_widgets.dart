import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────
//  Fake status bar (phone chrome)
// ─────────────────────────────────────────────
class FakeStatusBar extends StatelessWidget {
  final Color textColor;
  const FakeStatusBar({super.key, this.textColor = WerlogColors.textPrimary});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 0)
          .copyWith(top: 12, bottom: 8),
      child: Visibility(
        visible: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('9:41',
                style: WerlogTextStyles.statusBar.copyWith(color: textColor)),
            Text('●●●',
                style: WerlogTextStyles.statusBar.copyWith(color: textColor)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Primary button
// ─────────────────────────────────────────────
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onTap,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: WerlogColors.teal,
          foregroundColor: Colors.white,
          padding: padding ??
              const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(11)),
          elevation: 0,
        ),
        child: Text(text, style: WerlogTextStyles.button),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Ghost / text button
// ─────────────────────────────────────────────
class GhostButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const GhostButton({super.key, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 10),
        foregroundColor: WerlogColors.textSecondary,
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────
//  Icon box (colored square with emoji/icon)
// ─────────────────────────────────────────────
class IconBox extends StatelessWidget {
  final Color background;
  final Widget child;
  final double size;
  final double radius;

  const IconBox({
    super.key,
    required this.background,
    required this.child,
    this.size = 38,
    this.radius = 11,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(radius),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}

// ─────────────────────────────────────────────
//  Badge pill (EXPENSE / WARRANTY / PRO)
// ─────────────────────────────────────────────
class BadgePill extends StatelessWidget {
  final String label;
  final Color background;
  final Color textColor;

  const BadgePill({
    super.key,
    required this.label,
    required this.background,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: WerlogTextStyles.badgeText.copyWith(color: textColor),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Segmented control (Monthly / Yearly)
// ─────────────────────────────────────────────
class SegmentedToggle extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;
  final Widget? Function(int index)? trailingBuilder;

  const SegmentedToggle({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
    this.trailingBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: WerlogColors.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final active = i == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: active ? WerlogColors.surface : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: active
                          ? [
                              BoxShadow(
                                color: WerlogColors.textPrimary
                                    .withOpacity(0.06),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              )
                            ]
                          : null,
                    ),
                    child: Text(
                      labels[i],
                      style: WerlogTextStyles.bodySmall.copyWith(
                        color: active
                            ? WerlogColors.textPrimary
                            : WerlogColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (trailingBuilder != null)
                    trailingBuilder!(i) ?? const SizedBox.shrink(),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Progress bar (quota / scan usage)
// ─────────────────────────────────────────────
class ThinProgressBar extends StatelessWidget {
  final double value;   // 0.0 – 1.0
  final Color trackColor;
  final Color fillColor;
  final double height;

  const ThinProgressBar({
    super.key,
    required this.value,
    this.trackColor = const Color(0x1FFFFFFF),
    this.fillColor  = WerlogColors.tealLight,
    this.height = 4,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: trackColor,
          borderRadius: BorderRadius.circular(height / 2),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: value.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: fillColor,
                borderRadius: BorderRadius.circular(height / 2),
              ),
            ),
          ),
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────
//  Divider with "or continue with" label
// ─────────────────────────────────────────────
class OrDivider extends StatelessWidget {
  final String label;
  const OrDivider({super.key, this.label = 'or continue with'});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        children: [
          const Expanded(
            child: Divider(
                color: WerlogColors.border, thickness: 0.5, endIndent: 10),
          ),
          Text(label, style: WerlogTextStyles.caption),
          const Expanded(
            child: Divider(
                color: WerlogColors.border, thickness: 0.5, indent: 10),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Social login button (Google / Apple)
// ─────────────────────────────────────────────
class SocialButton extends StatelessWidget {
  final Widget logo;
  final String label;
  final VoidCallback? onTap;

  const SocialButton({
    super.key,
    required this.logo,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: WerlogColors.surface,
            border: Border.all(color: WerlogColors.border),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              logo,
              const SizedBox(width: 7),
              Text(label, style: WerlogTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Onboarding step dots
// ─────────────────────────────────────────────
class StepDots extends StatelessWidget {
  final int total;
  final int current; // 0-indexed, -1 means all off

  const StepDots({super.key, required this.total, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        return Expanded(
          child: Container(
            margin: i < total - 1
                ? const EdgeInsets.only(right: 5)
                : EdgeInsets.zero,
            height: 3,
            decoration: BoxDecoration(
              color: i <= current
                  ? WerlogColors.teal
                  : WerlogColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────
//  Checkmark circle (plan feature)
// ─────────────────────────────────────────────
class CheckCircle extends StatelessWidget {
  const CheckCircle({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: const BoxDecoration(
        color: WerlogColors.teal,
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Text('✓',
            style: TextStyle(
                fontSize: 7, color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Section header row (title + "See all")
// ─────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(title, style: WerlogTextStyles.sectionTitle),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Text(action!, style: WerlogTextStyles.link),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Checkout summary row
// ─────────────────────────────────────────────
class SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  const SummaryRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = bold
        ? WerlogTextStyles.body.copyWith(
            fontWeight: FontWeight.w500,
            color: valueColor ?? WerlogColors.textPrimary,
            fontSize: 13,
          )
        : WerlogTextStyles.caption.copyWith(
            color: valueColor ?? WerlogColors.textSecondary,
          );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(bold ? label : label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}
