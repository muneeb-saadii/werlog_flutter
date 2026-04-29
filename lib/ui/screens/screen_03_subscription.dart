import 'package:flutter/material.dart';
import '../../core/models/app_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';

// ──────────────────────────────────────────────────────────────
//  SubscriptionScreen  (screen 04 · Pick a plan)
//  Pixel-faithful to mobile_02_subscription_plans_onboarding.html
// ──────────────────────────────────────────────────────────────

class SubscriptionScreen extends StatefulWidget {
  final List<SubscriptionPlan>? plans;

  /// Index of the initially selected plan (matches [plans] list)
  final int initialSelectedIndex;

  /// 0 = Monthly, 1 = Yearly
  final int initialCycle;

  final VoidCallback? onSkip;
  final void Function(SubscriptionPlan plan)? onContinue;
  final VoidCallback? onFree;

  const SubscriptionScreen({
    super.key,
    this.plans,
    this.initialSelectedIndex = 1,
    this.initialCycle         = 1,
    this.onSkip,
    this.onContinue,
    this.onFree,
  });

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  late int _cycle;     // 0 = Monthly, 1 = Yearly
  late int _selected;
  late List<SubscriptionPlan> _plans;

  @override
  void initState() {
    super.initState();
    _cycle    = widget.initialCycle;
    _selected = widget.initialSelectedIndex;
    _plans    = widget.plans ?? defaultPlans;
  }

  String _price(SubscriptionPlan p) =>
      _cycle == 0 ? p.monthlyPrice : p.yearlyPrice;

  String? _original(SubscriptionPlan p) =>
      _cycle == 0 ? p.originalMonthlyPrice : p.originalYearlyPrice;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WerlogColors.background,
      body: Column(
        children: [
          const FakeStatusBar(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Header ─────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: StepDots(total: 4, current: 2)),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: widget.onSkip,
                              child: Text('Skip →',
                                  style: WerlogTextStyles.bodySmall
                                      .copyWith(fontWeight: FontWeight.w500)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text('Choose your plan',
                            style: WerlogTextStyles.pageTitle),
                        const SizedBox(height: 6),
                        Text('Start free, upgrade anytime. No hidden fees.',
                            style: WerlogTextStyles.bodySmall),
                      ],
                    ),
                  ),
                  // ── Cycle toggle ────────────────────────────
                  _CycleToggle(
                    selected: _cycle,
                    onChanged: (v) => setState(() => _cycle = v),
                  ),
                  // ── Plan cards ──────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: List.generate(_plans.length, (i) {
                        final p = _plans[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _PlanCard(
                            plan:       p,
                            price:      _price(p),
                            original:   _original(p),
                            isSelected: i == _selected,
                            onTap: () => setState(() => _selected = i),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ── CTA footer ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(22, 10, 22, 20),
            decoration: const BoxDecoration(
              color: WerlogColors.background,
              border: Border(
                  top: BorderSide(color: WerlogColors.border, width: 0.5)),
            ),
            child: Column(
              children: [
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: WerlogTextStyles.caption,
                    children: [
                      TextSpan(
                        text: '7 days free',
                        style: WerlogTextStyles.caption.copyWith(
                            color: WerlogColors.textPrimary,
                            fontWeight: FontWeight.w500),
                      ),
                      const TextSpan(
                          text:
                              ' · cancel anytime · no card required for Free'),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                PrimaryButton(
                  text: _selected < _plans.length
                      ? 'Continue with ${_plans[_selected].name} →'
                      : 'Continue →',
                  onTap: () =>
                      widget.onContinue?.call(_plans[_selected]),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: widget.onFree,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      foregroundColor: WerlogColors.textSecondary,
                    ),
                    child: Text('Start with Free plan',
                        style: WerlogTextStyles.bodySmall
                            .copyWith(fontWeight: FontWeight.w500)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Cycle toggle (Monthly / Yearly) ───────────────────────────
class _CycleToggle extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;
  const _CycleToggle({required this.selected, required this.onChanged});

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
        children: [
          _CycleOption(
              label: 'Monthly',
              active: selected == 0,
              onTap: () => onChanged(0)),
          _CycleOption(
            label: 'Yearly',
            active: selected == 1,
            onTap: () => onChanged(1),
            trailing: selected == 1
                ? null
                : _SavePill(),
          ),
        ],
      ),
    );
  }
}

class _CycleOption extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final Widget? trailing;

  const _CycleOption({
    required this.label,
    required this.active,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(vertical: 8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? WerlogColors.surface : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: WerlogColors.textPrimary.withOpacity(0.06),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        )
                      ]
                    : null,
              ),
              child: Text(
                label,
                style: WerlogTextStyles.bodySmall.copyWith(
                  color: active
                      ? WerlogColors.textPrimary
                      : WerlogColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (trailing != null)
              Positioned(
                top: -8, right: 6,
                child: trailing!,
              ),
          ],
        ),
      ),
    );
  }
}

class _SavePill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: WerlogColors.amber,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'SAVE 20%',
        style: WerlogTextStyles.badgeText
            .copyWith(color: Colors.white, fontSize: 8),
      ),
    );
  }
}

// ── Plan card ──────────────────────────────────────────────────
class _PlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final String price;
  final String? original;
  final bool isSelected;
  final VoidCallback onTap;

  const _PlanCard({
    required this.plan,
    required this.price,
    this.original,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final featured = plan.isFeatured;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: featured
                  ? const Color(0xFFE1F5EE).withOpacity(0.6)
                  : WerlogColors.surface,
              border: Border.all(
                color: featured
                    ? WerlogColors.teal
                    : WerlogColors.border,
                width: featured ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(plan.name,
                            style: WerlogTextStyles.planName),
                        const SizedBox(height: 2),
                        Text(plan.tagline,
                            style: WerlogTextStyles.planDesc),
                      ],
                    ),
                    _RadioDot(active: isSelected, featured: featured),
                  ],
                ),
                const SizedBox(height: 10),
                // Price row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(price, style: WerlogTextStyles.planPrice),
                    const SizedBox(width: 4),
                    Text(plan.pricePeriod,
                        style: WerlogTextStyles.planPricePer),
                    if (original != null) ...[
                      const SizedBox(width: 4),
                      Text(
                        original!,
                        style: WerlogTextStyles.planPricePer.copyWith(
                          color: WerlogColors.textTertiary,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                // Features grid
                _FeaturesGrid(features: plan.features),
              ],
            ),
          ),
          // Featured badge
          if (featured && plan.featuredBadge != null)
            Positioned(
              top: -9, right: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: WerlogColors.darkTeal,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  plan.featuredBadge!,
                  style: WerlogTextStyles.badgeText.copyWith(
                    color: WerlogColors.tealLight,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  final bool active;
  final bool featured;
  const _RadioDot({required this.active, required this.featured});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 18, height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? WerlogColors.teal : Colors.transparent,
        border: Border.all(
          color: active ? WerlogColors.teal : WerlogColors.border,
          width: 1.5,
        ),
      ),
      child: active
          ? const Center(
              child: CircleAvatar(
                radius: 4, backgroundColor: Colors.white))
          : null,
    );
  }
}

class _FeaturesGrid extends StatelessWidget {
  final List<String> features;
  const _FeaturesGrid({required this.features});

  @override
  Widget build(BuildContext context) {
    // Two-column layout
    final rows = <Widget>[];
    for (var i = 0; i < features.length; i += 2) {
      rows.add(Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Expanded(child: _FeatureItem(features[i])),
            if (i + 1 < features.length)
              Expanded(child: _FeatureItem(features[i + 1]))
            else
              const Expanded(child: SizedBox()),
          ],
        ),
      ));
    }
    return Column(children: rows);
  }
}

class _FeatureItem extends StatelessWidget {
  final String text;
  const _FeatureItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CheckCircle(),
        const SizedBox(width: 5),
        Expanded(
            child: Text(text, style: WerlogTextStyles.planFeature)),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  CheckoutScreen  (screen 05 · Payment details)
//  Pixel-faithful to mobile_02 : right-side screen
// ──────────────────────────────────────────────────────────────

class CheckoutScreen extends StatelessWidget {
  final CheckoutData? data;
  final VoidCallback? onBack;
  final VoidCallback? onChangeCard;
  final VoidCallback? onChangeAddress;
  final VoidCallback? onAddPromo;
  final VoidCallback? onPay;

  const CheckoutScreen({
    super.key,
    this.data,
    this.onBack,
    this.onChangeCard,
    this.onChangeAddress,
    this.onAddPromo,
    this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    final d = data ?? CheckoutData();

    return Scaffold(
      backgroundColor: WerlogColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const FakeStatusBar(),
            // ── Back + title ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: onBack,
                    child: const Text('‹',
                        style: TextStyle(
                            fontSize: 28,
                            color: WerlogColors.textPrimary)),
                  ),
                  const SizedBox(height: 12),
                  Text('Payment details',
                      style: WerlogTextStyles.pageTitle),
                  const SizedBox(height: 4),
                  Text('Secure checkout powered by Stripe',
                      style: WerlogTextStyles.bodySmall),
                ],
              ),
            ),
            // ── Plan summary card ────────────────────────────
            _PlanSummaryCard(data: d),
            const SizedBox(height: 18),
            // ── Payment method ───────────────────────────────
            _SectionLabel(label: 'PAYMENT METHOD'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: GestureDetector(
                onTap: onChangeCard,
                child: _RowField(
                  leading: Container(
                    width: 32, height: 22,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1F71),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    alignment: Alignment.center,
                    child: Text(d.cardBrand,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w500)),
                  ),
                  label: '•••• •••• •••• ${d.cardLast4}',
                  mono: true,
                ),
              ),
            ),
            const SizedBox(height: 14),
            _SectionLabel(label: 'BILLING ADDRESS'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: onChangeAddress,
                    child: _SimpleRow(
                        label: d.billingAddress,
                        trailing: '›'),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: onAddPromo,
                    child: _SimpleRow(
                      label: 'Promo code',
                      labelColor: WerlogColors.textSecondary,
                      trailing: 'Add',
                      trailingColor: WerlogColors.teal,
                      trailingBold: true,
                    ),
                  ),
                ],
              ),
            ),
            // ── Order summary ────────────────────────────────
            Container(
              margin: const EdgeInsets.all(22),
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: BoxDecoration(
                color: WerlogColors.surfaceAlt,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Column(
                children: [
                  SummaryRow(
                      label: _planLabel(d),
                      value: d.lineTotal),
                  SummaryRow(label: 'Tax', value: d.tax),
                  if (d.discountLabel != null)
                    SummaryRow(
                      label: d.discountLabel!,
                      value: d.discountAmount ?? '',
                      valueColor: WerlogColors.amber,
                    ),
                  const Divider(
                      height: 16,
                      color: WerlogColors.border,
                      thickness: 1),
                  SummaryRow(
                    label: 'Due after trial',
                    value: d.dueAfterTrial,
                    bold: true,
                  ),
                ],
              ),
            ),
            // ── Pay button ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onPay,
                      icon: const Text('🔒',
                          style: TextStyle(fontSize: 13)),
                      label: Text('Start 7-day free trial',
                          style: WerlogTextStyles.button),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: WerlogColors.teal,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Charged only after trial ends · cancel anytime in Settings',
                    textAlign: TextAlign.center,
                    style: WerlogTextStyles.caption
                        .copyWith(fontSize: 9, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _planLabel(CheckoutData d) {
    // e.g. "Pro yearly"
    return d.planDisplayName.replaceAll('·', '').trim();
  }
}

// ── Plan summary dark card ─────────────────────────────────────
class _PlanSummaryCard extends StatelessWidget {
  final CheckoutData data;
  const _PlanSummaryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(22, 16, 22, 0),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: WerlogColors.darkTeal,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('YOU\'RE SUBSCRIBING TO',
                  style: WerlogTextStyles.checkoutPlanLabel),
              const SizedBox(height: 3),
              Text(data.planDisplayName,
                  style: WerlogTextStyles.checkoutPlanName),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(data.priceLabel,
                      style: WerlogTextStyles.checkoutAmount),
                  const SizedBox(width: 5),
                  Text(data.pricePeriod,
                      style: WerlogTextStyles.checkoutSub),
                ],
              ),
              const SizedBox(height: 3),
              Text(data.billingNote,
                  style: WerlogTextStyles.checkoutSub),
            ],
          ),
        ),
        // Deco circle
        Positioned(
          top: 16, right: 22,
          child: IgnorePointer(
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                color: WerlogColors.teal.withOpacity(0.20),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Section label ──────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 10),
      child: Text(label,
          style: WerlogTextStyles.labelUppercase
              .copyWith(fontSize: 10, color: WerlogColors.textSecondary)),
    );
  }
}

// ── Payment row (card) ─────────────────────────────────────────
class _RowField extends StatelessWidget {
  final Widget leading;
  final String label;
  final bool mono;
  const _RowField(
      {required this.leading,
      required this.label,
      this.mono = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: WerlogColors.surface,
        border: Border.all(color: WerlogColors.border),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: mono
                  ? WerlogTextStyles.body.copyWith(
                      fontFamily: 'monospace',
                      letterSpacing: 0.5,
                    )
                  : WerlogTextStyles.body,
            ),
          ),
          Text('›',
              style: WerlogTextStyles.bodySmall
                  .copyWith(color: WerlogColors.textSecondary)),
        ],
      ),
    );
  }
}

// ── Simple address / promo row ─────────────────────────────────
class _SimpleRow extends StatelessWidget {
  final String label;
  final Color? labelColor;
  final String trailing;
  final Color? trailingColor;
  final bool trailingBold;

  const _SimpleRow({
    required this.label,
    this.labelColor,
    required this.trailing,
    this.trailingColor,
    this.trailingBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: WerlogColors.surface,
        border: Border.all(color: WerlogColors.border),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: WerlogTextStyles.bodySmall
                  .copyWith(color: labelColor ?? WerlogColors.textPrimary)),
          Text(
            trailing,
            style: WerlogTextStyles.bodySmall.copyWith(
              color: trailingColor ?? WerlogColors.textSecondary,
              fontWeight:
                  trailingBold ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
