import 'package:flutter/material.dart';
import '../../../client/core/utils/shared_pref_helper.dart';
import '../../core/api/admin_api_service.dart';
import '../../core/api/admin_endpoints.dart';
import '../../core/models/dashboard_stats.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/admin_bottom_nav.dart';
import '../widgets/stat_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {

  bool            _loading  = true;
  DashboardStats? _stats;
  List<_SignupEntry> _signups = [];
  String          _adminName = 'Admin';

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
      _adminName = me?['fullName']?.toString() ?? 'Admin';
    } catch (_) {}
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final overview = await AdminApiService.get(
          context, AdminEndpoints.analyticsOverview, showLoader: false);
      debugPrint('[Dashboard] overview => $overview');

      final signupsResp = await AdminApiService.get(
        context, AdminEndpoints.analyticsSignups,
        queryParams: {'days': '30'}, showLoader: false,
      );
      debugPrint('[Dashboard] signups => $signupsResp');

      if (!mounted) return;

      if (overview != null) {
        // Handle both root-level and nested data key
        final d = (overview['data'] is Map<String, dynamic>)
            ? overview['data'] as Map<String, dynamic>
            : overview;
        _stats = DashboardStats(
          pendingJobs:         _int(d['pendingJobs'])         ?? _int(d['pending_jobs'])        ?? 0,
          failedJobs:          _int(d['failedJobs'])          ?? _int(d['failed_jobs'])         ?? 0,
          mrrUsd:              _int(d['mrrUsd'])              ?? _int(d['mrr'])                 ?? 0,
          totalUsers:          _int(d['totalUsers'])          ?? _int(d['total_users'])         ?? 0,
          newUsersThisMonth:   _int(d['newUsersThisMonth'])   ?? _int(d['new_users_this_month'])?? 0,
          activeUsers:         _int(d['activeUsers'])         ?? _int(d['active_users'])        ?? 0,
          activeUsersPercent:  _dbl(d['activeUsersPercent'])  ?? _dbl(d['active_users_pct'])    ?? 0,
          totalInvoices:       _int(d['totalInvoices'])       ?? _int(d['total_invoices'])      ?? 0,
          invoicesLast30Days:  _int(d['invoicesLast30Days'])  ?? _int(d['invoices_last_30'])    ?? 0,
          activeSubscriptions: _int(d['activeSubscriptions']) ?? _int(d['active_subs'])         ?? 0,
          signupsLast30Days:   [],
          unreadNotifications: _int(d['unreadNotifications']) ?? 0,
        );
      }

      if (signupsResp != null) {
        // API may return list of {date, count} maps or plain ints
        final raw = signupsResp['data'] as List<dynamic>?
            ?? signupsResp['signups'] as List<dynamic>?
            ?? [];
        _signups = raw.map((e) {
          if (e is Map) {
            final count = _int(e['count']) ?? _int(e['signups']) ?? 0;
            final date  = e['date']?.toString() ?? e['day']?.toString() ?? '';
            return _SignupEntry(count: count, date: date);
          }
          return _SignupEntry(count: (e as num?)?.toInt() ?? 0, date: '');
        }).toList();
      }

    } catch (e) {
      debugPrint('[Dashboard] fetch error => $e');
      if (mounted) AdminApiService.showError(context, 'Failed to load dashboard');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  static int? _int(dynamic v) => v == null ? null : (v as num?)?.toInt();
  static double? _dbl(dynamic v) => v == null ? null : (v as num?)?.toDouble();

  static String _fmt(int n) => n >= 1000 ? '${(n/1000).toStringAsFixed(1)}K' : '$n';

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final s = _stats;
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        bottomNavigationBar: const AdminBottomNav(currentIndex: 0),
        body: SafeArea(
          bottom: false,
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.accentGreen))
              : RefreshIndicator(
            onRefresh: _fetch,
            color: AppColors.accentGreen,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                _Header(greeting: _greeting, adminName: _adminName),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppMetrics.pagePadding, 0,
                      AppMetrics.pagePadding, 0),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

                    // System pulse card — lifted out of header
                    Transform.translate(
                      offset: const Offset(0, -20),
                      child: _SystemPulseCard(
                        pending: s?.pendingJobs ?? 0,
                        failed:  s?.failedJobs  ?? 0,
                        mrr:     s?.mrrUsd      ?? 0,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Stat cards row 1
                    Row(children: [
                      Expanded(child: StatCard(
                        value: _fmt(s?.totalUsers ?? 0),
                        label: 'Total users',
                        delta: '↑ ${s?.newUsersThisMonth ?? 0} this month',
                      )),
                      const SizedBox(width: AppMetrics.gapMd),
                      Expanded(child: StatCard(
                        value: _fmt(s?.activeUsers ?? 0),
                        label: 'Active users',
                        delta: '${s?.activeUsersPercent.toStringAsFixed(1) ?? '0'}% active',
                      )),
                    ]),

                    const SizedBox(height: AppMetrics.gapMd),

                    // Stat cards row 2
                    Row(children: [
                      Expanded(child: StatCard(
                        value: _fmt(s?.totalInvoices ?? 0),
                        label: 'Total invoices',
                        delta: '↑ ${s?.invoicesLast30Days ?? 0} / 30d',
                      )),
                      const SizedBox(width: AppMetrics.gapMd),
                      Expanded(child: StatCard(
                        value: '${s?.activeSubscriptions ?? 0}',
                        label: 'Active subscriptions',
                        delta: 'paid plans',
                        deltaColor: AppColors.textPrimary,
                      )),
                    ]),

                    // Signups chart
                    if (_signups.isNotEmpty) ...[
                      const SizedBox(height: AppMetrics.gapMd),
                      _SignupsCard(entries: _signups),
                    ],

                    const SizedBox(height: AppMetrics.gapMd),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Data model for a signup entry ─────────────────────────────────────────────

class _SignupEntry {
  final int    count;
  final String date; // e.g. "2026-09-01"
  const _SignupEntry({required this.count, required this.date});

  String get shortLabel {
    if (date.isEmpty) return '';
    try {
      final d = DateTime.parse(date);
      return '${d.day}/${d.month}';
    } catch (_) { return date; }
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String greeting, adminName;
  const _Header({required this.greeting, required this.adminName});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(
        AppMetrics.pagePadding, 16, AppMetrics.pagePadding, 48),
    decoration: const BoxDecoration(
      color: AppColors.darkGreen,
      borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppMetrics.headerRadius)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Admin', style: TextStyle(
          color: AppColors.textOnDarkMuted, fontSize: 13,
          fontFamily: 'DMSans')),
      const SizedBox(height: 10),
      Text('$greeting, $adminName', style: AppTextStyles.headerTitle),
      const SizedBox(height: 4),
      const Text('Operations overview · last 30 days',
          style: AppTextStyles.headerSubtitle),
    ]),
  );
}

// ── System pulse card ─────────────────────────────────────────────────────────

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
                color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600,
                fontFamily: 'DMSans')),
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
      Text(value, style: AppTextStyles.statValueOnDark.copyWith(
          color: color ?? Colors.white)),
      const SizedBox(height: 2),
      Text(label, style: AppTextStyles.statLabelOnDark),
    ],
  );
}

// ── Signups card with labelled bar chart ──────────────────────────────────────

class _SignupsCard extends StatelessWidget {
  final List<_SignupEntry> entries;
  const _SignupsCard({required this.entries});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(AppMetrics.cardRadius),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8, offset: const Offset(0, 2))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

      // Header row
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Signups', style: AppTextStyles.cardTitle),
          const SizedBox(height: 2),
          Text(
            'Total: ${entries.fold(0, (s, e) => s + e.count)} '
                '· Peak: ${entries.isEmpty ? 0 : entries.map((e) => e.count).reduce((a,b)=>a>b?a:b)}',
            style: AppTextStyles.footerNote.copyWith(
                color: AppColors.textSecondary, fontSize: 11),
          ),
        ]),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(20)),
          child: Text('${entries.length} days',
              style: AppTextStyles.footerNote),
        ),
      ]),

      const SizedBox(height: 16),

      // Bar chart with labels
      _LabelledBarChart(entries: entries),
    ]),
  );
}

// ── Labelled bar chart ────────────────────────────────────────────────────────

class _LabelledBarChart extends StatelessWidget {
  final List<_SignupEntry> entries;
  final double barHeight;

  const _LabelledBarChart({required this.entries, this.barHeight = 100});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();

    final maxVal = entries.map((e) => e.count).reduce((a,b)=>a>b?a:b);
    // Show labels only every N bars to avoid crowding
    final showEvery = entries.length > 14 ? 7 : entries.length > 7 ? 3 : 1;

    return Column(children: [
      // Bars
      SizedBox(
        height: barHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: entries.asMap().entries.map((e) {
            final fraction = maxVal == 0 ? 0.0 : e.value.count / maxVal;
            final isHighest = e.value.count == maxVal;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Tooltip(
                  message: '${e.value.shortLabel}: ${e.value.count}',
                  child: FractionallySizedBox(
                    heightFactor: 0.12 + fraction * 0.88,
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(5)),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: isHighest
                              ? [AppColors.accentGreen,
                            AppColors.accentGreen.withOpacity(0.7)]
                              : [AppColors.accentGreen.withOpacity(0.85),
                            const Color(0xFF7FD3A6)],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),

      const SizedBox(height: 6),

      // X-axis labels
      Row(
        children: entries.asMap().entries.map((e) {
          final showLabel = e.key % showEvery == 0;
          return Expanded(
            child: Text(
              showLabel ? e.value.shortLabel : '',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'DMSans', fontSize: 8.5,
                color: AppColors.textSecondary,
              ),
            ),
          );
        }).toList(),
      ),

      const SizedBox(height: 8),

      // Y-axis legend row
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        _YLegend('0'),
        _YLegend('${(maxVal / 2).round()}'),
        _YLegend('$maxVal'),
      ]),
    ]);
  }
}

class _YLegend extends StatelessWidget {
  final String label;
  const _YLegend(this.label);

  @override
  Widget build(BuildContext context) => Text(label,
      style: const TextStyle(
          fontFamily: 'DMSans', fontSize: 9,
          color: AppColors.textSecondary));
}