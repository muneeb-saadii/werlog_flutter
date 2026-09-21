import 'package:flutter/material.dart';
import '../../core/data/mock_data.dart';
import '../../core/models/dashboard_stats.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/admin_bottom_nav.dart';
import '../widgets/stat_card.dart';
import '../widgets/simple_bar_chart.dart';

/// Operations overview / dashboard screen — the app's home tab.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final DashboardStats stats = MockData.dashboardStats;

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: const AdminBottomNav(currentIndex: 0),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(unreadNotifications: stats.unreadNotifications),
              const SizedBox(height: 25),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppMetrics.pagePadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Transform.translate(
                      offset: const Offset(0, -20),
                      child: _SystemPulseCard(stats: stats),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            value: _formatCount(stats.totalUsers),
                            label: 'Total users',
                            delta: '↑ ${stats.newUsersThisMonth} this month',
                          ),
                        ),
                        const SizedBox(width: AppMetrics.gapMd),
                        Expanded(
                          child: StatCard(
                            value: _formatCount(stats.activeUsers),
                            label: 'Active users',
                            delta: '${stats.activeUsersPercent.toStringAsFixed(1)}% active',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppMetrics.gapMd),
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            value: _formatCount(stats.totalInvoices),
                            label: 'Total invoices',
                            delta: '↑ ${stats.invoicesLast30Days} / 30d',
                          ),
                        ),
                        const SizedBox(width: AppMetrics.gapMd),
                        Expanded(
                          child: StatCard(
                            value: '${stats.activeSubscriptions}',
                            label: 'Active subscriptions',
                            delta: 'paid plans',
                            deltaColor: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppMetrics.gapMd),
                    _SignupsCard(values: stats.signupsLast30Days),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatCount(int n) {
    final s = n.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final posFromEnd = s.length - i;
      buffer.write(s[i]);
      if (posFromEnd > 1 && posFromEnd % 3 == 1) buffer.write(',');
    }
    return buffer.toString();
  }
}

class _Header extends StatelessWidget {
  final int unreadNotifications;

  const _Header({required this.unreadNotifications});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppMetrics.pagePadding, 16, AppMetrics.pagePadding, 38,
      ),
      decoration: const BoxDecoration(
        color: AppColors.darkGreen,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppMetrics.headerRadius),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Text('Admin', style: TextStyle(color: AppColors.textOnDarkMuted, fontSize: 13)),
                    Icon(Icons.expand_more_rounded, color: AppColors.textOnDarkMuted, size: 18),
                  ],
                ),
                const SizedBox(height: 10),
                const Text('Good morning, Admin', style: AppTextStyles.headerTitle),
                const SizedBox(height: 4),
                const Text('Operations overview · last 30 days', style: AppTextStyles.headerSubtitle),
              ],
            ),
          ),
          _NotificationBell(count: unreadNotifications),
        ],
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  final int count;

  const _NotificationBell({required this.count});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.darkGreenLight,
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.notifications_rounded, color: Colors.amber, size: 20),
        ),
        if (count > 0)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              alignment: Alignment.center,
              child: Text(
                '$count',
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
          ),
      ],
    );
  }
}

class _SystemPulseCard extends StatelessWidget {
  final DashboardStats stats;

  const _SystemPulseCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkGreen,
        borderRadius: BorderRadius.circular(AppMetrics.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('SYSTEM PULSE', style: AppTextStyles.sectionLabel),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.darkGreenLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.circle, size: 8, color: AppColors.liveDotGreen),
                    SizedBox(width: 5),
                    Text('Live', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _PulseMetric(value: '${stats.pendingJobs}', label: 'Pending jobs'),
              const SizedBox(width: 28),
              _PulseMetric(value: '${stats.failedJobs}', label: 'Failed jobs', valueColor: AppColors.failedHighlight),
              const SizedBox(width: 28),
              _PulseMetric(value: '\$${stats.mrrUsd}', label: 'MRR'),
            ],
          ),
        ],
      ),
    );
  }
}

class _PulseMetric extends StatelessWidget {
  final String value;
  final String label;
  final Color? valueColor;

  const _PulseMetric({required this.value, required this.label, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: AppTextStyles.statValueOnDark.copyWith(color: valueColor ?? Colors.white)),
        const SizedBox(height: 2),
        Text(label, style: AppTextStyles.statLabelOnDark),
      ],
    );
  }
}

class _SignupsCard extends StatelessWidget {
  final List<int> values;

  const _SignupsCard({required this.values});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(AppMetrics.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Signups', style: AppTextStyles.cardTitle),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('30 days', style: AppTextStyles.footerNote),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SimpleBarChart(values: values),
        ],
      ),
    );
  }
}
