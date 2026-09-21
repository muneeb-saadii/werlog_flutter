import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class AdminPlan {
  final String id;
  final String name;
  final String code;
  final String engine;
  final String scansLabel;
  final double priceUsd;
  final bool adsEnabled;
  final int subscribers;
  final bool isActive;
  final bool isPopular;

  const AdminPlan({
    required this.id,
    required this.name,
    required this.code,
    required this.engine,
    required this.scansLabel,
    required this.priceUsd,
    required this.adsEnabled,
    required this.subscribers,
    required this.isActive,
    this.isPopular = false,
  });
}

// ── Mock data ─────────────────────────────────────────────────────────────────

final _mockPlans = [
  const AdminPlan(
    id: '1', name: 'Free', code: 'FREE', engine: 'Tesseract',
    scansLabel: '20 scans/mo', priceUsd: 0,
    adsEnabled: true, subscribers: 1190, isActive: true,
  ),
  const AdminPlan(
    id: '2', name: 'Pro', code: 'PRO', engine: 'GPT4',
    scansLabel: 'unlimited', priceUsd: 9.99,
    adsEnabled: false, subscribers: 12, isActive: true, isPopular: true,
  ),
  const AdminPlan(
    id: '3', name: 'Business', code: 'BUSINESS', engine: 'GPT4',
    scansLabel: 'unlimited', priceUsd: 29,
    adsEnabled: false, subscribers: 3, isActive: true,
  ),
];

// ── Screen ────────────────────────────────────────────────────────────────────

class PlansBillingScreen extends StatefulWidget {
  const PlansBillingScreen({super.key});

  @override
  State<PlansBillingScreen> createState() => _PlansBillingScreenState();
}

class _PlansBillingScreenState extends State<PlansBillingScreen> {
  late final List<bool> _active;

  @override
  void initState() {
    super.initState();
    _active = _mockPlans.map((p) => p.isActive).toList();
  }

  @override
  Widget build(BuildContext context) {
    final totalSubscribers = _mockPlans.fold(
        0, (sum, p) => sum + p.subscribers);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          _PlansHeader(
              planCount: _mockPlans.length,
              paidSubscribers: totalSubscribers),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                  AppMetrics.pagePadding, 16,
                  AppMetrics.pagePadding, 100),
              itemCount: _mockPlans.length + 1,
              itemBuilder: (_, i) {
                if (i == _mockPlans.length) {
                  return _CreatePlanButton(
                      onTap: () => _showCreateSheet());
                }
                return _PlanCard(
                  plan: _mockPlans[i],
                  active: _active[i],
                  onToggle: (v) => setState(() => _active[i] = v),
                  onTap: () => _showEditSheet(_mockPlans[i]),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }

  void _showCreateSheet() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create plan — coming soon')),
    );
  }

  void _showEditSheet(AdminPlan plan) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardWhite,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _PlanEditSheet(plan: plan),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _PlansHeader extends StatelessWidget {
  final int planCount, paidSubscribers;
  const _PlansHeader(
      {required this.planCount, required this.paidSubscribers});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    decoration: const BoxDecoration(
      color: AppColors.darkGreen,
      borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppMetrics.headerRadius)),
    ),
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      GestureDetector(
        onTap: () => Navigator.pop(context),
        child: const Icon(Icons.chevron_left,
            color: AppColors.textOnDark, size: 26),
      ),
      const SizedBox(width: 8),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Plans & billing', style: AppTextStyles.headerTitle),
          const SizedBox(height: 4),
          Text('$planCount plans · $paidSubscribers paid subscribers',
              style: AppTextStyles.headerSubtitle),
        ],
      )),
      _CircleAction(icon: Icons.add_rounded, onTap: () {}),
    ]),
  );
}

// ── Plan card ─────────────────────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  final AdminPlan plan;
  final bool active;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTap;
  const _PlanCard({
    required this.plan,
    required this.active,
    required this.onToggle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(AppMetrics.cardRadius),
        border: Border.all(
          color: plan.isPopular ? AppColors.accentGreen : Colors.transparent,
          width: plan.isPopular ? 2 : 0,
        ),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(plan.name, style: AppTextStyles.cardTitle),
                  if (plan.isPopular) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.activeBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('popular',
                          style: AppTextStyles.badgeText.copyWith(
                              color: AppColors.activeText, fontSize: 11)),
                    ),
                  ],
                ]),
                const SizedBox(height: 4),
                Text(
                  'code: ${plan.code} · ${plan.engine} · ${plan.scansLabel}',
                  style: AppTextStyles.emailSubtle,
                ),
              ],
            )),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(
                plan.priceUsd == 0
                    ? '\$0'
                    : '\$${plan.priceUsd % 1 == 0 ? plan.priceUsd.toInt() : plan.priceUsd}',
                style: AppTextStyles.cardTitle,
              ),
              const SizedBox(height: 6),
              Switch.adaptive(
                value: active,
                onChanged: onToggle,
                activeColor: AppColors.accentGreen,
              ),
            ]),
          ]),
        ),
        const Divider(height: 1, indent: 16, endIndent: 16,
            color: AppColors.divider),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          child: Row(children: [
            _PillTag(
              label: plan.adsEnabled ? 'ads on' : 'no ads',
              bg: plan.adsEnabled
                  ? AppColors.suspendedBg
                  : AppColors.activeBg,
              fg: plan.adsEnabled
                  ? AppColors.suspendedText
                  : AppColors.activeText,
            ),
            const SizedBox(width: 8),
            _PillTag(
              label: '${_formatCount(plan.subscribers)} subscribers',
              bg: AppColors.proBg,
              fg: AppColors.proText,
            ),
          ]),
        ),
      ]),
    ),
  );

  String _formatCount(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

class _PillTag extends StatelessWidget {
  final String label;
  final Color bg, fg;
  const _PillTag({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(
        color: bg, borderRadius: BorderRadius.circular(20)),
    child: Text(label,
        style: AppTextStyles.badgeText.copyWith(color: fg, fontSize: 12)),
  );
}

// ── Create plan button ────────────────────────────────────────────────────────

class _CreatePlanButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CreatePlanButton({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.darkGreen,
        borderRadius: BorderRadius.circular(AppMetrics.cardRadius),
      ),
      alignment: Alignment.center,
      child: const Text('+ Create new plan',
          style: TextStyle(
              fontFamily: 'DMSans', fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white)),
    ),
  );
}

// ── Edit plan sheet ───────────────────────────────────────────────────────────

class _PlanEditSheet extends StatelessWidget {
  final AdminPlan plan;
  const _PlanEditSheet({required this.plan});

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
        20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 32),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 36, height: 4,
          decoration: BoxDecoration(color: AppColors.divider,
              borderRadius: BorderRadius.circular(2))),
      const SizedBox(height: 16),
      Text(plan.name, style: AppTextStyles.cardTitle),
      const SizedBox(height: 4),
      Text('code: ${plan.code}', style: AppTextStyles.emailSubtle),
      const SizedBox(height: 20),
      ListTile(onTap: () => Navigator.pop(context),
          leading: const Icon(Icons.edit_rounded,
              color: AppColors.textPrimary),
          title: Text('Edit plan details',
              style: AppTextStyles.actionButton)),
      const Divider(color: AppColors.divider),
      ListTile(onTap: () => Navigator.pop(context),
          leading: const Icon(Icons.people_rounded,
              color: AppColors.textPrimary),
          title: Text('View subscribers',
              style: AppTextStyles.actionButton)),
      const Divider(color: AppColors.divider),
      ListTile(onTap: () => Navigator.pop(context),
          leading: const Icon(Icons.delete_outline_rounded,
              color: AppColors.dangerRed),
          title: Text('Archive plan',
              style: AppTextStyles.actionButtonDanger)),
    ]),
  );
}

class _CircleAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          shape: BoxShape.circle),
      child: Icon(icon, color: Colors.white, size: 20),
    ),
  );
}
