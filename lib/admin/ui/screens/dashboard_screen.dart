import 'package:flutter/material.dart';
import '../../../client/core/utils/shared_pref_helper.dart';
import '../../core/api/admin_api_service.dart';
import '../../core/api/admin_endpoints.dart';
import '../../core/models/dashboard_stats.dart';
import '../../core/routes/admin_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/admin_bottom_nav.dart';
import '../widgets/stat_card.dart';
import '../widgets/simple_bar_chart.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {

  bool           _loading = true;
  DashboardStats? _stats;
  List<int>      _signups = [];
  String         _adminName = 'Admin';

  @override
  void initState() {
    super.initState();
    _loadAdminName();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  void _loadAdminName() {
    try {
      final data = SharedPrefHelper.getObject(SharedPrefHelper.loginData);
      final me   = data?['meResponse'] as Map<String, dynamic>?;
      if (me != null) {
        _adminName = me['fullName']?.toString() ?? 'Admin';
      }
    } catch (_) {}
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      // ── Overview ─────────────────────────────────────────────────
      final overview = await AdminApiService.get(
          context, AdminEndpoints.analyticsOverview, showLoader: false);
      debugPrint('[Dashboard] overview => $overview');

      // ── Signups time-series ───────────────────────────────────────
      final signupsResp = await AdminApiService.get(
        context, AdminEndpoints.analyticsSignups,
        queryParams: {'days': '30'}, showLoader: false,
      );
      debugPrint('[Dashboard] signups => $signupsResp');

      if (!mounted) return;

      if (overview != null) {
        final d = overview['data'] as Map<String, dynamic>? ?? overview;
        _stats = DashboardStats(
          pendingJobs:          (d['pendingJobs']           as num?)?.toInt() ?? 0,
          failedJobs:           (d['failedJobs']            as num?)?.toInt() ?? 0,
          mrrUsd:               (d['mrrUsd']                as num?)?.toInt() ?? 0,
          totalUsers:           (d['totalUsers']            as num?)?.toInt() ?? 0,
          newUsersThisMonth:    (d['newUsersThisMonth']     as num?)?.toInt() ?? 0,
          activeUsers:          (d['activeUsers']           as num?)?.toInt() ?? 0,
          activeUsersPercent:   (d['activeUsersPercent']    as num?)?.toDouble() ?? 0,
          totalInvoices:        (d['totalInvoices']         as num?)?.toInt() ?? 0,
          invoicesLast30Days:   (d['invoicesLast30Days']    as num?)?.toInt() ?? 0,
          activeSubscriptions:  (d['activeSubscriptions']   as num?)?.toInt() ?? 0,
          signupsLast30Days:    [],
          unreadNotifications:  (d['unreadNotifications']   as num?)?.toInt() ?? 0,
        );
      }

      if (signupsResp != null) {
        final list = signupsResp['data'] as List<dynamic>?
            ?? signupsResp['signups'] as List<dynamic>?
            ?? [];
        _signups = list.map((e) {
          if (e is Map) return (e['count'] as num?)?.toInt() ?? 0;
          return (e as num?)?.toInt() ?? 0;
        }).toList();
      }

    } catch (e) {
      debugPrint('[Dashboard] fetch error => $e');
      if (mounted) AdminApiService.showError(context, 'Failed to load dashboard');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  static String _fmt(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final stats = _stats;
    return PopScope(
      canPop: false,
      child: Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: const AdminBottomNav(currentIndex: 0),
      body: SafeArea(
        bottom: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator(
                color: AppColors.accentGreen))
            : RefreshIndicator(
                onRefresh: _fetch,
                color: AppColors.accentGreen,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Header(
                          greeting: _greeting,
                          adminName: _adminName,
                          unread: stats?.unreadNotifications ?? 0),
                      const SizedBox(height: 25),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppMetrics.pagePadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Transform.translate(
                              offset: const Offset(0, -20),
                              child: _SystemPulseCard(
                                pending: stats?.pendingJobs ?? 0,
                                failed:  stats?.failedJobs  ?? 0,
                                mrr:     stats?.mrrUsd      ?? 0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(children: [
                              Expanded(child: StatCard(
                                value: _fmt(stats?.totalUsers ?? 0),
                                label: 'Total users',
                                delta: '↑ ${stats?.newUsersThisMonth ?? 0} this month',
                              )),
                              const SizedBox(width: AppMetrics.gapMd),
                              Expanded(child: StatCard(
                                value: _fmt(stats?.activeUsers ?? 0),
                                label: 'Active users',
                                delta: '${stats?.activeUsersPercent.toStringAsFixed(1) ?? 0}% active',
                              )),
                            ]),
                            const SizedBox(height: AppMetrics.gapMd),
                            Row(children: [
                              Expanded(child: StatCard(
                                value: _fmt(stats?.totalInvoices ?? 0),
                                label: 'Total invoices',
                                delta: '↑ ${stats?.invoicesLast30Days ?? 0} / 30d',
                              )),
                              const SizedBox(width: AppMetrics.gapMd),
                              Expanded(child: StatCard(
                                value: '${stats?.activeSubscriptions ?? 0}',
                                label: 'Active subscriptions',
                                delta: 'paid plans',
                                deltaColor: AppColors.textPrimary,
                              )),
                            ]),
                            if (_signups.isNotEmpty) ...[
                              const SizedBox(height: AppMetrics.gapMd),
                              _SignupsCard(values: _signups),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    ),
    );

  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String greeting, adminName;
  final int unread;
  const _Header({required this.greeting, required this.adminName,
      required this.unread});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(
        AppMetrics.pagePadding, 16, AppMetrics.pagePadding, 38),
    decoration: const BoxDecoration(
      color: AppColors.darkGreen,
      borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppMetrics.headerRadius)),
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Text('Admin', style: TextStyle(
              color: AppColors.textOnDarkMuted, fontSize: 13)),
          /*Icon(Icons.expand_more_rounded,
              color: AppColors.textOnDarkMuted, size: 18),*/
        ]),
        const SizedBox(height: 10),
        Text('$greeting, $adminName', style: AppTextStyles.headerTitle),
        const SizedBox(height: 4),
        const Text('Operations overview · last 30 days',
            style: AppTextStyles.headerSubtitle),
      ])),
      // _Bell(count: unread),
    ]),
  );
}

class _Bell extends StatelessWidget {
  final int count;
  const _Bell({required this.count});

  @override
  Widget build(BuildContext context) => Stack(clipBehavior: Clip.none, children: [
    Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
          color: AppColors.darkGreenLight,
          borderRadius: BorderRadius.circular(14)),
      alignment: Alignment.center,
      child: const Icon(Icons.notifications_rounded,
          color: Colors.amber, size: 20),
    ),
    if (count > 0) Positioned(
      top: -4, right: -4,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(
            color: Colors.redAccent, shape: BoxShape.circle),
        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
        alignment: Alignment.center,
        child: Text('$count', style: const TextStyle(
            color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
      ),
    ),
  ]);
}

class _SystemPulseCard extends StatelessWidget {
  final int pending, failed, mrr;
  const _SystemPulseCard({required this.pending, required this.failed,
      required this.mrr});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
        color: AppColors.darkGreen,
        borderRadius: BorderRadius.circular(AppMetrics.cardRadius)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('SYSTEM PULSE', style: AppTextStyles.sectionLabel),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
              color: AppColors.darkGreenLight,
              borderRadius: BorderRadius.circular(20)),
          child: Row(mainAxisSize: MainAxisSize.min, children: const [
            Icon(Icons.circle, size: 8, color: AppColors.liveDotGreen),
            SizedBox(width: 5),
            Text('Live', style: TextStyle(
                color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ]),
        ),
      ]),
      const SizedBox(height: 18),
      Row(children: [
        _Metric(value: '$pending', label: 'Pending jobs'),
        const SizedBox(width: 28),
        _Metric(value: '$failed', label: 'Failed jobs',
            color: AppColors.failedHighlight),
        const SizedBox(width: 28),
        _Metric(value: '\$$mrr', label: 'MRR'),
      ]),
    ]),
  );
}

class _Metric extends StatelessWidget {
  final String value, label;
  final Color? color;
  const _Metric({required this.value, required this.label, this.color});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(value,
          style: AppTextStyles.statValueOnDark.copyWith(
              color: color ?? Colors.white)),
      const SizedBox(height: 2),
      Text(label, style: AppTextStyles.statLabelOnDark),
    ],
  );
}

class _SignupsCard extends StatelessWidget {
  final List<int> values;
  const _SignupsCard({required this.values});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(AppMetrics.cardRadius)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('Signups', style: AppTextStyles.cardTitle),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(20)),
          child: const Text('30 days', style: AppTextStyles.footerNote),
        ),
      ]),
      const SizedBox(height: 16),
      SimpleBarChart(values: values),
    ]),
  );
}
