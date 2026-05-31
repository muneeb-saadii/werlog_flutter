import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/api/api_service.dart';
import '../../../core/api/endpoints.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/general_functions.dart';
import '../screen_03_subscription.dart';

// ════════════════════════════════════════════════════════════════════
//  Subscription data model
// ════════════════════════════════════════════════════════════════════
class SubscriptionPlan {
  final String id;
  final String planCode;
  final String planName;
  final String status;
  final String? currentPeriodEnd;
  final bool cancelAtPeriodEnd;
  final int scansUsed;
  final int scanLimit;
  final bool unlimited;

  const SubscriptionPlan({
    required this.id,
    required this.planCode,
    required this.planName,
    required this.status,
    this.currentPeriodEnd,
    required this.cancelAtPeriodEnd,
    required this.scansUsed,
    required this.scanLimit,
    required this.unlimited,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id:                json['id']?.toString()             ?? '',
      planCode:          json['planCode']?.toString()       ?? '',
      planName:          json['planName']?.toString()       ?? '',
      status:            json['status']?.toString()         ?? '',
      currentPeriodEnd:  json['currentPeriodEnd']?.toString(),
      cancelAtPeriodEnd: json['cancelAtPeriodEnd'] == true,
      scansUsed:         (json['scansUsed']  as num?)?.toInt() ?? 0,
      scanLimit:         (json['scanLimit']  as num?)?.toInt() ?? 0,
      unlimited:         json['unlimited'] == true,
    );
  }

  bool get isActive    => status.toUpperCase() == 'ACTIVE';
  bool get isFree      => planCode.toUpperCase() == 'FREE';
  double get usageRatio =>
      unlimited || scanLimit == 0 ? 1.0 : (scansUsed / scanLimit).clamp(0.0, 1.0);
  int get scansRemaining => unlimited ? 999999 : math.max(0, scanLimit - scansUsed);

  String get formattedPeriodEnd {
    if (currentPeriodEnd == null) return 'No expiry';
    try {
      final dt = DateTime.parse(currentPeriodEnd!);
      const months = ['Jan','Feb','Mar','Apr','May','Jun',
                      'Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) { return currentPeriodEnd!; }
  }
}

// ════════════════════════════════════════════════════════════════════
//  SubscriptionScreen
//
//  How to call:
//    Navigator.push(context,
//      MaterialPageRoute(builder: (_) => const SubscriptionScreen()));
//
//  Or from AppRoutes:
//    static void openSubscriptionScreen(BuildContext context) =>
//        Navigator.push(context,
//          MaterialPageRoute(builder: (_) => const SubscriptionScreen()));
// ════════════════════════════════════════════════════════════════════
class SubscriptionUsageScreen extends StatefulWidget {
  const SubscriptionUsageScreen({super.key});

  @override
  State<SubscriptionUsageScreen> createState() => _SubscriptionUsageScreenState();
}

class _SubscriptionUsageScreenState extends State<SubscriptionUsageScreen>
    with SingleTickerProviderStateMixin {
  SubscriptionPlan? _plan;
  bool _loading = true;

  // Animation controller for the scan progress arc
  late final AnimationController _arcCtrl;
  late final Animation<double> _arcAnim;

  @override
  void initState() {
    super.initState();
    _arcCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100));
    _arcAnim = CurvedAnimation(parent: _arcCtrl, curve: Curves.easeOutCubic);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPlan();
    });
  }

  @override
  void dispose() {
    _arcCtrl.dispose();
    super.dispose();
  }

  // ── API ──────────────────────────────────────────────────────────
  Future<void> _loadPlan() async {
    setState(() => _loading = true);
    try {
      final response = await ApiService.get(
        context,
        Endpoints.SUBSCRIPTION_USAGE,
        showLoader: true,
      );
      if (response != null && response['result'] == '1') {
        final plan = SubscriptionPlan.fromJson(
            response['data'] as Map<String, dynamic>);
        setState(() {
          _plan    = plan;
          _loading = false;
        });
        // Animate progress arc after data arrives
        _arcCtrl.forward(from: 0);
      } else {
        setState(() => _loading = false);
        if (mounted) {
          GeneralFunctions.showError(context,
              response?['message']?.toString() ?? 'Failed to load plan.');
        }
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        GeneralFunctions.showError(context, 'Something went wrong.');
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WerlogColors.background,
      body: SafeArea(
        child: Column(children: [
          _buildAppBar(),
          Expanded(
            child: _loading
                ? _buildSkeleton()
                : _plan == null
                    ? _buildError()
                    : _buildContent(),
          ),
        ]),
      ),
    );
  }

  // ── App bar ───────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return Container(
      color: WerlogColors.surface,
      padding: const EdgeInsets.fromLTRB(8, 10, 16, 10),
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: WerlogColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        const Expanded(
          child: Text('My Plan',
              textAlign: TextAlign.center,
              style: WerlogTextStyles.pageTitle),
        ),
        // Refresh button
        IconButton(
          icon: const Icon(Icons.refresh_rounded,
              size: 20, color: WerlogColors.teal),
          onPressed: _loadPlan,
        ),
      ]),
    );
  }

  // ── Main scrollable content ───────────────────────────────────────
  Widget _buildContent() {
    final plan = _plan!;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(children: [
        const SizedBox(height: 16),
        _buildHeroCard(plan),
        const SizedBox(height: 14),
        _buildScanUsageCard(plan),
        const SizedBox(height: 14),
        _buildDetailsGrid(plan),
        const SizedBox(height: 14),
        if (!plan.isFree) _buildRenewalCard(plan),
        if (!plan.isFree) const SizedBox(height: 14),
        if (plan.isFree) _buildUpgradeCard(),
        if (plan.isFree) const SizedBox(height: 14),
        const SizedBox(height: 40),
      ]),
    );
  }

  // ── Hero card (plan name + status badge + ID) ─────────────────────
  Widget _buildHeroCard(SubscriptionPlan plan) {
    return Container(
      decoration: BoxDecoration(
        gradient: WerlogGradients.darkHero(),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Top row: plan icon + status badge
        Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: Colors.white.withOpacity(0.12), width: 0.8),
            ),
            child: Icon(
              plan.isFree
                  ? Icons.layers_outlined
                  : Icons.workspace_premium_rounded,
              color: plan.isFree ? WerlogColors.tealLight : WerlogColors.amber,
              size: 22,
            ),
          ),
          const Spacer(),
          _StatusBadge(status: plan.status, isActive: plan.isActive),
        ]),

        const SizedBox(height: 16),

        // Plan name
        Text(
          plan.planName,
          style: const TextStyle(
            fontFamily: 'DMSans',
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Plan Code: ${plan.planCode}',
          style: TextStyle(
            fontFamily: 'DMSans',
            fontSize: 11,
            color: Colors.white.withOpacity(0.4),
            letterSpacing: 0.5,
          ),
        ),

        const SizedBox(height: 20),
        Divider(color: Colors.white.withOpacity(0.08), height: 1),
        const SizedBox(height: 16),

        // Subscription ID
        Row(children: [
          Icon(Icons.fingerprint_rounded,
              size: 14, color: Colors.white.withOpacity(0.35)),
          const SizedBox(width: 6),
          Text(
            'ID: ${plan.id}',
            style: TextStyle(
              fontFamily: 'DMSans',
              fontSize: 9,
              color: Colors.white.withOpacity(0.3),
              letterSpacing: 0.3,
            ),
          ),
        ]),
      ]),
    );
  }

  // ── Scan usage card with animated arc ────────────────────────────
  Widget _buildScanUsageCard(SubscriptionPlan plan) {
    return Container(
      decoration: _cardDeco(),
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Header
        Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: WerlogColors.tealSurface,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.document_scanner_outlined,
                color: WerlogColors.teal, size: 16),
          ),
          const SizedBox(width: 10),
          const Text('Scan Usage', style: WerlogTextStyles.cardTitle),
          const Spacer(),
          if (plan.unlimited)
            _Badge(label: 'Unlimited',
                bg: WerlogColors.tealSurface,
                textColor: WerlogColors.teal),
        ]),

        const SizedBox(height: 20),

        // Animated arc + numbers
        Row(children: [
          // Arc
          SizedBox(
            width: 110, height: 110,
            child: AnimatedBuilder(
              animation: _arcAnim,
              builder: (_, __) => CustomPaint(
                painter: _ArcPainter(
                  progress: plan.unlimited ? 1.0 : plan.usageRatio * _arcAnim.value,
                  usedColor: plan.usageRatio > 0.85
                      ? WerlogColors.coral
                      : WerlogColors.teal,
                  trackColor: WerlogColors.borderLight,
                  label: plan.unlimited ? '∞' : '${plan.scansUsed}',
                  sublabel: plan.unlimited ? 'scans' : 'used',
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),

          // Stats column
          Expanded(child: Column(children: [
            _UsageStat(
              label: 'Scans Used',
              value: plan.unlimited ? '∞' : '${plan.scansUsed}',
              color: WerlogColors.teal,
            ),
            const SizedBox(height: 10),
            _UsageStat(
              label: 'Scan Limit',
              value: plan.unlimited ? 'Unlimited' : '${plan.scanLimit}',
              color: WerlogColors.textPrimary,
            ),
            const SizedBox(height: 10),
            _UsageStat(
              label: 'Remaining',
              value: plan.unlimited
                  ? '∞'
                  : '${plan.scansRemaining}',
              color: plan.scansRemaining < 3
                  ? WerlogColors.coral
                  : WerlogColors.textPrimary,
            ),
          ])),
        ]),

        // Progress bar (only for limited plans)
        if (!plan.unlimited) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(plan.usageRatio * 100).toStringAsFixed(0)}% used',
                style: WerlogTextStyles.captionSmall,
              ),
              Text(
                '${plan.scansRemaining} left',
                style: WerlogTextStyles.captionSmall.copyWith(
                  color: plan.scansRemaining < 3
                      ? WerlogColors.coral
                      : WerlogColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          AnimatedBuilder(
            animation: _arcAnim,
            builder: (_, __) => ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: plan.usageRatio * _arcAnim.value,
                minHeight: 7,
                backgroundColor: WerlogColors.borderLight,
                valueColor: AlwaysStoppedAnimation<Color>(
                  plan.usageRatio > 0.85
                      ? WerlogColors.coral
                      : WerlogColors.teal,
                ),
              ),
            ),
          ),
        ],
      ]),
    );
  }

  // ── Details grid (status, renewal, cancelAtPeriodEnd) ────────────
  Widget _buildDetailsGrid(SubscriptionPlan plan) {
    return Row(children: [
      Expanded(child: _DetailTile(
        icon: Icons.check_circle_outline_rounded,
        iconColor: plan.isActive ? WerlogColors.teal : WerlogColors.coral,
        iconBg: plan.isActive
            ? WerlogColors.tealSurface
            : WerlogColors.coralSurface,
        label: 'Status',
        value: plan.status,
      )),
      const SizedBox(width: 10),
      Expanded(child: _DetailTile(
        icon: Icons.event_outlined,
        iconColor: WerlogColors.amber,
        iconBg: WerlogColors.amberSurface,
        label: 'Period End',
        value: plan.formattedPeriodEnd,
      )),
      const SizedBox(width: 10),
      Expanded(child: _DetailTile(
        icon: plan.cancelAtPeriodEnd
            ? Icons.cancel_outlined
            : Icons.autorenew_rounded,
        iconColor: plan.cancelAtPeriodEnd
            ? WerlogColors.coral
            : WerlogColors.teal,
        iconBg: plan.cancelAtPeriodEnd
            ? WerlogColors.coralSurface
            : WerlogColors.tealSurface,
        label: 'Auto-Renew',
        value: plan.cancelAtPeriodEnd ? 'No' : 'Yes',
      )),
    ]);
  }

  // ── Renewal card (paid plans) ─────────────────────────────────────
  Widget _buildRenewalCard(SubscriptionPlan plan) {
    return Container(
      decoration: _cardDeco(),
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: plan.cancelAtPeriodEnd
                ? WerlogColors.coralSurface
                : WerlogColors.tealSurface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            plan.cancelAtPeriodEnd
                ? Icons.warning_amber_rounded
                : Icons.autorenew_rounded,
            color: plan.cancelAtPeriodEnd
                ? WerlogColors.coral
                : WerlogColors.teal,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              plan.cancelAtPeriodEnd
                  ? 'Cancellation Scheduled'
                  : 'Subscription Active',
              style: WerlogTextStyles.cardTitle,
            ),
            const SizedBox(height: 3),
            Text(
              plan.cancelAtPeriodEnd
                  ? 'Your plan will end on ${plan.formattedPeriodEnd}. Renew to keep access.'
                  : 'Renews automatically on ${plan.formattedPeriodEnd}.',
              style: WerlogTextStyles.captionSmall,
            ),
          ],
        )),
      ]),
    );
  }

  // ── Upgrade card (free plan) ──────────────────────────────────────
  Widget _buildUpgradeCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: WerlogGradients.heroTeal,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(18),
      child: Row(children: [
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Upgrade to Pro',
                style: TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                )),
            const SizedBox(height: 5),
            Text('Unlock unlimited scans and\npremium features.',
                style: TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.7),
                  height: 1.5,
                )),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: (){
                Navigator.of(context).pop;
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => SubscriptionScreen()));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('View Plans',
                    style: TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: WerlogColors.teal,
                    )),
              ),
            ),
          ],
        )),
        const SizedBox(width: 12),
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.workspace_premium_rounded,
              color: Colors.white, size: 28),
        ),
      ]),
    );
  }

  // ── Loading skeleton ──────────────────────────────────────────────
  Widget _buildSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        _Skeleton(height: 160, radius: 20),
        const SizedBox(height: 14),
        _Skeleton(height: 180, radius: 16),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _Skeleton(height: 80, radius: 14)),
          const SizedBox(width: 10),
          Expanded(child: _Skeleton(height: 80, radius: 14)),
          const SizedBox(width: 10),
          Expanded(child: _Skeleton(height: 80, radius: 14)),
        ]),
      ]),
    );
  }

  // ── Error state ───────────────────────────────────────────────────
  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              color: WerlogColors.coralSurface,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.error_outline_rounded,
                color: WerlogColors.coral, size: 28),
          ),
          const SizedBox(height: 16),
          const Text('Failed to load plan',
              style: WerlogTextStyles.cardTitle),
          const SizedBox(height: 6),
          Text('Check your connection and retry.',
              style: WerlogTextStyles.captionSmall),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _loadPlan,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 11),
              decoration: BoxDecoration(
                color: WerlogColors.teal,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('Retry',
                  style: TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  )),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDeco() => BoxDecoration(
    color: WerlogColors.surface,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: WerlogColors.border, width: 0.8),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 8, offset: const Offset(0, 2),
      ),
    ],
  );
}

// ════════════════════════════════════════════════════════════════════
//  Sub-widgets
// ════════════════════════════════════════════════════════════════════

class _StatusBadge extends StatelessWidget {
  final String status;
  final bool isActive;
  const _StatusBadge({required this.status, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isActive
            ? WerlogColors.teal.withOpacity(0.15)
            : WerlogColors.coral.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? WerlogColors.teal.withOpacity(0.4)
              : WerlogColors.coral.withOpacity(0.4),
          width: 0.8,
        ),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 6, height: 6,
          decoration: BoxDecoration(
            color: isActive ? WerlogColors.tealLight : WerlogColors.coral,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          status,
          style: TextStyle(
            fontFamily: 'DMSans',
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isActive ? WerlogColors.tealLight : WerlogColors.coral,
            letterSpacing: 0.3,
          ),
        ),
      ]),
    );
  }
}

class _UsageStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _UsageStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: WerlogTextStyles.captionSmall),
        Text(value,
            style: TextStyle(
              fontFamily: 'DMSans',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            )),
      ],
    );
  }
}

class _DetailTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String value;
  const _DetailTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: WerlogColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: WerlogColors.border, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6, offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 30, height: 30,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 15),
        ),
        const SizedBox(height: 10),
        Text(label, style: WerlogTextStyles.captionSmall),
        const SizedBox(height: 3),
        Text(value,
            style: const TextStyle(
              fontFamily: 'DMSans',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: WerlogColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      ]),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color textColor;
  const _Badge({required this.label, required this.bg, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
            fontFamily: 'DMSans',
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: textColor,
          )),
    );
  }
}

class _Skeleton extends StatelessWidget {
  final double height;
  final double radius;
  const _Skeleton({required this.height, required this.radius});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: WerlogColors.borderLight,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
//  Arc painter — animated donut-style progress arc
// ════════════════════════════════════════════════════════════════════
class _ArcPainter extends CustomPainter {
  final double progress;   // 0.0 – 1.0
  final Color usedColor;
  final Color trackColor;
  final String label;
  final String sublabel;

  const _ArcPainter({
    required this.progress,
    required this.usedColor,
    required this.trackColor,
    required this.label,
    required this.sublabel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx     = size.width  / 2;
    final cy     = size.height / 2;
    final radius = (size.width / 2) - 10;
    final rect   = Rect.fromCircle(center: Offset(cx, cy), radius: radius);
    const startAngle = -math.pi / 2;          // top
    const fullSweep  = 2 * math.pi;

    // Track
    final trackPaint = Paint()
      ..color       = trackColor
      ..style       = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap   = StrokeCap.round;
    canvas.drawArc(rect, startAngle, fullSweep, false, trackPaint);

    // Progress arc
    if (progress > 0) {
      final arcPaint = Paint()
        ..color       = usedColor
        ..style       = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap   = StrokeCap.round;
      canvas.drawArc(
          rect, startAngle, fullSweep * progress, false, arcPaint);
    }

    // Centre label
    final labelPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          fontFamily: 'DMSans',
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: WerlogColors.textPrimary,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    labelPainter.paint(
      canvas,
      Offset(cx - labelPainter.width / 2, cy - labelPainter.height / 2 - 6),
    );

    // Sublabel
    final subPainter = TextPainter(
      text: TextSpan(
        text: sublabel,
        style: const TextStyle(
          fontFamily: 'DMSans',
          fontSize: 9,
          color: WerlogColors.textTertiary,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    subPainter.paint(
      canvas,
      Offset(cx - subPainter.width / 2, cy + labelPainter.height / 2 - 4),
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.progress != progress;
}
