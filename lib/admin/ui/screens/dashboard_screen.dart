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

// ── Shared chart entry model ──────────────────────────────────────────────────

class _BarEntry {
  final String label;
  final int    value;
  const _BarEntry({required this.label, required this.value});
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {

  bool            _loading = true;
  DashboardStats? _stats;
  String          _adminName = 'Admin';

  List<_BarEntry> _signups     = [];
  List<_BarEntry> _tokens      = [];   // monthly token total
  List<_BarEntry> _revenue     = [];   // monthly revenue (cents → display)
  List<_BarEntry> _invoiceCounts = []; // from overview invoicesLast30Days fallback

  int  _totalTokens  = 0;
  int  _totalRevCents = 0;

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
      final results = await Future.wait([
        AdminApiService.get(context, AdminEndpoints.analyticsOverview,  showLoader: false),
        AdminApiService.get(context, AdminEndpoints.analyticsSignups,
            queryParams: {'days': '30'}, showLoader: false),
        AdminApiService.get(context, AdminEndpoints.analyticsTokenUsage,
            queryParams: {'months': '12'}, showLoader: false),
        AdminApiService.get(context, AdminEndpoints.analyticsRevenue,
            queryParams: {'months': '12'}, showLoader: false),
      ]);

      if (!mounted) return;

      // ── Overview ─────────────────────────────────────────────────────
      final overview = results[0];
      if (overview != null) {
        final d = (overview['data'] is Map<String, dynamic>)
            ? overview['data'] as Map<String, dynamic>
            : overview;
        _stats = DashboardStats(
          pendingJobs:         _int(d['pendingJobs'])         ?? 0,
          failedJobs:          _int(d['failedJobs'])          ?? 0,
          mrrUsd:              _int(d['mrrUsd'])              ?? 0,
          totalUsers:          _int(d['totalUsers'])          ?? 0,
          newUsersThisMonth:   _int(d['newUsersThisMonth'])   ?? 0,
          activeUsers:         _int(d['activeUsers'])         ?? 0,
          activeUsersPercent:  _dbl(d['activeUsersPercent'])  ?? 0,
          totalInvoices:       _int(d['totalInvoices'])       ?? 0,
          invoicesLast30Days:  _int(d['invoicesLast30Days'])  ?? 0,
          activeSubscriptions: _int(d['activeSubscriptions']) ?? 0,
          signupsLast30Days:   [],
          unreadNotifications: _int(d['unreadNotifications']) ?? 0,
        );
      }

      // ── Signups ──────────────────────────────────────────────────────
      final signupsR = results[1];
      if (signupsR != null) {
        final raw = (signupsR['data'] as List<dynamic>?)
            ?? (signupsR['signups'] as List<dynamic>?) ?? [];
        _signups = raw.map((e) {
          if (e is Map) {
            return _BarEntry(
              label: _shortDate(e['date']?.toString() ?? e['day']?.toString() ?? ''),
              value: _int(e['count']) ?? _int(e['signups']) ?? 0,
            );
          }
          return _BarEntry(label: '', value: (e as num?)?.toInt() ?? 0);
        }).toList();
      }

      // ── Token usage ───────────────────────────────────────────────────
      // Response: { data: { totalTokens, monthly: [{month, totalTokens, ...}] } }
      final tokenR = results[2];
      if (tokenR != null) {
        final d = tokenR['data'] as Map<String, dynamic>?;
        if (d != null) {
          _totalTokens = _int(d['totalTokens']) ?? 0;
          final monthly = d['monthly'] as List<dynamic>? ?? [];
          _tokens = monthly.map((e) => _BarEntry(
            label: _shortMonth(e['month']?.toString() ?? ''),
            value: _int(e['totalTokens']) ?? 0,
          )).toList();
        }
      }

      // ── Revenue ───────────────────────────────────────────────────────
      // Response: { data: { totalRevenueCents, monthly: [{month, revenueCents}] } }
      final revR = results[3];
      if (revR != null) {
        final d = revR['data'] as Map<String, dynamic>?;
        if (d != null) {
          _totalRevCents = _int(d['totalRevenueCents']) ?? 0;
          final monthly = d['monthly'] as List<dynamic>? ?? [];
          _revenue = monthly.map((e) => _BarEntry(
            label: _shortMonth(e['month']?.toString() ?? ''),
            value: _int(e['revenueCents']) ?? _int(e['revenue']) ?? 0,
          )).toList();
        }
      }

    } catch (e) {
      debugPrint('[Dashboard] fetch error => $e');
      if (mounted) AdminApiService.showError(context, 'Failed to load dashboard');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── helpers ───────────────────────────────────────────────────────────────

  static int? _int(dynamic v) => v == null ? null : (v as num?)?.toInt();
  static double? _dbl(dynamic v) => v == null ? null : (v as num?)?.toDouble();
  static String _fmt(int n) => n >= 1000 ? '${(n/1000).toStringAsFixed(1)}K' : '$n';

  static String _shortDate(String s) {
    try {
      final d = DateTime.parse(s);
      return '${d.day}/${d.month}';
    } catch (_) { return s; }
  }

  static String _shortMonth(String s) {
    // s = "2026-10"
    try {
      final parts = s.split('-');
      if (parts.length < 2) return s;
      const months = ['','Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'];
      final m = int.tryParse(parts[1]) ?? 0;
      return m > 0 && m <= 12 ? months[m] : s;
    } catch (_) { return s; }
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String get _revenueLabel {
    final dollars = _totalRevCents / 100;
    return dollars >= 1000
        ? '\$${(dollars/1000).toStringAsFixed(1)}K'
        : '\$${dollars.toStringAsFixed(0)}';
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
              ? const Center(child: CircularProgressIndicator(
              color: AppColors.accentGreen))
              : RefreshIndicator(
            onRefresh: _fetch,
            color: AppColors.accentGreen,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  _Header(greeting: _greeting, adminName: _adminName),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppMetrics.pagePadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [

                        // System pulse
                        Transform.translate(
                          offset: const Offset(0, -20),
                          child: _SystemPulseCard(
                            pending: s?.pendingJobs ?? 0,
                            failed:  s?.failedJobs  ?? 0,
                            mrr:     s?.mrrUsd      ?? 0,
                          ),
                        ),

                        const SizedBox(height: 4),

                        // Row 1 — users
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

                        // Row 2 — invoices + subscriptions
                        Row(children: [
                          Expanded(child: StatCard(
                            value: _fmt(s?.totalInvoices ?? 0),
                            label: 'Total invoices',
                            delta: '↑ ${s?.invoicesLast30Days ?? 0} / 30d',
                          )),
                          const SizedBox(width: AppMetrics.gapMd),
                          Expanded(child: StatCard(
                            value: '${s?.activeSubscriptions ?? 0}',
                            label: 'Active subs',
                            delta: 'paid plans',
                            deltaColor: AppColors.textPrimary,
                          )),
                        ]),

                        const SizedBox(height: AppMetrics.gapMd),

                        // Row 3 — tokens + revenue
                        Row(children: [
                          Expanded(child: StatCard(
                            value: _fmt(_totalTokens),
                            label: 'Total tokens',
                            delta: 'all time',
                            deltaColor: AppColors.textSecondary,
                          )),
                          const SizedBox(width: AppMetrics.gapMd),
                          Expanded(child: StatCard(
                            value: _revenueLabel,
                            label: 'Total revenue',
                            delta: 'all time',
                            deltaColor: AppColors.textSecondary,
                          )),
                        ]),

                        // ── Signups chart ──────────────────────────
                        if (_signups.isNotEmpty) ...[
                          const SizedBox(height: AppMetrics.gapMd),
                          _ChartCard(
                            title: 'Signups',
                            subtitle: '${_signups.length} days',
                            entries: _signups,
                            color: AppColors.accentGreen,
                          ),
                        ],

                        // ── Token consumption chart ────────────────
                        if (_tokens.isNotEmpty) ...[
                          const SizedBox(height: AppMetrics.gapMd),
                          _ChartCard(
                            title: 'Token consumption',
                            subtitle: 'monthly · last 12 mo',
                            entries: _tokens,
                            color: const Color(0xFF6C8EF5),
                          ),
                        ],

                        // ── Revenue chart ──────────────────────────
                        if (_revenue.isNotEmpty) ...[
                          const SizedBox(height: AppMetrics.gapMd),
                          _ChartCard(
                            title: 'Revenue',
                            subtitle: 'monthly · last 12 mo · USD',
                            entries: _revenue,
                            color: const Color(0xFFE89A3C),
                            valueFormatter: (v) =>
                            '\$${(v / 100).toStringAsFixed(0)}',
                          ),
                        ],

                        const SizedBox(height: AppMetrics.gapMd),
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

// ─────────────────────────────────────────────────────────────────────────────
//  WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

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
        _Metric(value: '$failed',  label: 'Failed jobs',
            color: AppColors.failedHighlight),
        const SizedBox(width: 28),
        _Metric(value: '\$$mrr',   label: 'MRR'),
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

// ── Reusable chart card ───────────────────────────────────────────────────────

class _ChartCard extends StatelessWidget {
  final String   title;
  final String   subtitle;
  final List<_BarEntry> entries;
  final Color    color;
  final String Function(int)? valueFormatter;

  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.entries,
    required this.color,
    this.valueFormatter,
  });

  @override
  Widget build(BuildContext context) {
    final total = entries.fold(0, (s, e) => s + e.value);
    final peak  = entries.isEmpty ? 0
        : entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final fmt   = valueFormatter ?? (v) => v >= 1000
        ? '${(v/1000).toStringAsFixed(1)}K' : '$v';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(AppMetrics.cardRadius),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: AppTextStyles.cardTitle),
              const SizedBox(height: 2),
              Text(
                'Total: ${fmt(total)} · Peak: ${fmt(peak)}',
                style: AppTextStyles.footerNote.copyWith(
                    color: AppColors.textSecondary, fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
            ]),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(20)),
            child: Text(subtitle, style: AppTextStyles.footerNote),
          ),
        ]),

        const SizedBox(height: 16),
        _LabelledBarChart(entries: entries, color: color,
            valueFormatter: valueFormatter),
      ]),
    );
  }
}

class _LabelledBarChart extends StatelessWidget {
  final List<_BarEntry> entries;
  final Color color;
  final String Function(int)? valueFormatter;
  const _LabelledBarChart({required this.entries, required this.color,
    this.valueFormatter});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    final maxVal = entries.map((e) => e.value).reduce((a,b)=>a>b?a:b);
    if (maxVal == 0) return _emptyLabel();
    final showEvery = entries.length > 14 ? 7 : entries.length > 7 ? 3 : 1;

    return Column(children: [
      SizedBox(
        height: 100,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: entries.asMap().entries.map((e) {
            final frac = maxVal == 0 ? 0.0 : e.value.value / maxVal;
            final isTop = e.value.value == maxVal;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Tooltip(
                  message: '${e.value.label}: ${e.value.value}',
                  child: FractionallySizedBox(
                    heightFactor: 0.12 + frac * 0.88,
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(5)),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: isTop
                              ? [color, color.withOpacity(0.7)]
                              : [color.withOpacity(0.85), color.withOpacity(0.5)],
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
      Row(
        children: entries.asMap().entries.map((e) {
          final show = e.key % showEvery == 0;
          return Expanded(child: Text(
            show ? e.value.label : '',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontFamily: 'DMSans', fontSize: 8.5,
                color: AppColors.textSecondary),
          ));
        }).toList(),
      ),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: _YL('0', align: TextAlign.start)),
        Expanded(child: _YL(
          (valueFormatter ?? (v) => '$v')((maxVal / 2).round()),
          align: TextAlign.center,
        )),
        Expanded(child: _YL(
          (valueFormatter ?? (v) => '$v')(maxVal),
          align: TextAlign.end,
        )),
      ]),
    ]);
  }

  Widget _emptyLabel() => const Center(
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Text('No data yet',
          style: TextStyle(fontFamily: 'DMSans', fontSize: 12,
              color: AppColors.textSecondary)),
    ),
  );
}

class _YL extends StatelessWidget {
  final String label;
  final TextAlign align;
  const _YL(this.label, {this.align = TextAlign.start});
  @override
  Widget build(BuildContext context) => Text(label,
      textAlign: align,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontFamily: 'DMSans', fontSize: 9,
          color: AppColors.textSecondary));
}