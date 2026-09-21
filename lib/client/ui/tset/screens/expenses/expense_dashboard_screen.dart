import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'expense_models.dart';
import 'expense_category_screen.dart';

// ══════════════════════════════════════════════════════════════════════════════
//  EXPENSE DASHBOARD — Screen 1
//  Entry point from Main Dashboard "Expenses & Tax" card.
//  Navigation: MainDashboard → ExpenseDashboard → ExpenseCategoryScreen
//                                               → ExpenseTaxSummaryScreen (tab)
// ══════════════════════════════════════════════════════════════════════════════
class ExpenseDashboardScreen extends StatefulWidget {
  const ExpenseDashboardScreen({super.key});

  @override
  State<ExpenseDashboardScreen> createState() => _ExpenseDashboardScreenState();
}

class _ExpenseDashboardScreenState extends State<ExpenseDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WerlogColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _AppBar(),
            _HeroBanner(),
            _TabBar(controller: _tabController),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const BouncingScrollPhysics(),
                children: [
                  _OverviewTab(),
                  _TaxTab(),
                  _DocumentsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: WerlogColors.teal,
        elevation: 4,
        icon: const Icon(Icons.add_photo_alternate_outlined, color: Colors.white, size: 20),
        label: Text('Scan Receipt', style: WerlogTextStyles.button.copyWith(fontSize: 13)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  APP BAR
// ─────────────────────────────────────────────────────────────────────────────
class _AppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: WerlogColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Expenses & Tax', style: WerlogTextStyles.pageTitle.copyWith(fontSize: 18)),
                Text(ExpenseDashboardData.periodLabel, style: WerlogTextStyles.caption),
              ],
            ),
          ),
          _NotifBadge(),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.search, size: 22, color: WerlogColors.textPrimary),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.tune, size: 20, color: WerlogColors.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class _NotifBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final total = ExpenseDashboardData.needsReviewCount + ExpenseDashboardData.missingInfoCount;
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, size: 22, color: WerlogColors.textPrimary),
          onPressed: () {},
        ),
        if (total > 0)
          Positioned(
            top: 8, right: 8,
            child: Container(
              width: 14, height: 14,
              decoration: const BoxDecoration(color: WerlogColors.coral, shape: BoxShape.circle),
              child: Center(
                child: Text('$total',
                    style: const TextStyle(color: Colors.white, fontSize: 8,
                        fontWeight: FontWeight.bold, fontFamily: 'DMSans')),
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  HERO BANNER  — dark gradient card with KPI chips
// ─────────────────────────────────────────────────────────────────────────────
class _HeroBanner extends StatelessWidget {
  String _fmt(double v) => '\$${v.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          gradient: WerlogGradients.darkHero(),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: WerlogColors.darkTeal.withOpacity(0.35),
                blurRadius: 24, offset: const Offset(0, 10)),
          ],
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1 — total + trend
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Expenses', style: WerlogTextStyles.balanceSub.copyWith(fontSize: 11)),
                    const SizedBox(height: 4),
                    Text(_fmt(ExpenseDashboardData.totalExpenses),
                        style: WerlogTextStyles.balanceAmount),
                    const SizedBox(height: 6),
                    Row(children: [
                      Icon(
                        ExpenseDashboardData.yoyPositive ? Icons.arrow_upward : Icons.arrow_downward,
                        color: ExpenseDashboardData.yoyPositive ? WerlogColors.coral : WerlogColors.tealLight,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${ExpenseDashboardData.yoyChange.abs().toStringAsFixed(0)}% vs last year',
                        style: WerlogTextStyles.balanceSub.copyWith(
                          color: ExpenseDashboardData.yoyPositive ? WerlogColors.coral : WerlogColors.tealLight,
                          fontSize: 11,
                        ),
                      ),
                    ]),
                  ],
                ),
                const Spacer(),
                // Est. savings highlight pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: WerlogColors.teal.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: WerlogColors.tealLight.withOpacity(0.4), width: 0.8),
                  ),
                  child: Column(
                    children: [
                      Text('Est. Tax Savings', style: WerlogTextStyles.balanceSub.copyWith(fontSize: 9)),
                      const SizedBox(height: 2),
                      Text(_fmt(ExpenseDashboardData.estimatedTaxSavings),
                          style: WerlogTextStyles.balanceSub.copyWith(
                              fontSize: 16, fontWeight: FontWeight.w700,
                              color: WerlogColors.tealLight)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Row 2 — KPI chips (scrollable)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(children: [
                _KpiChip(label: 'GST/HST Paid',   value: _fmt(ExpenseDashboardData.totalGstPaid),     icon: Icons.receipt_outlined),
                const SizedBox(width: 8),
                _KpiChip(label: 'Deductions',     value: _fmt(ExpenseDashboardData.eligibleDeductions), icon: Icons.percent),
                const SizedBox(width: 8),
                _KpiChip(label: 'Business',       value: _fmt(ExpenseDashboardData.businessExpenses),  icon: Icons.business_center_outlined),
                const SizedBox(width: 8),
                _KpiChip(label: 'Personal',       value: _fmt(ExpenseDashboardData.personalExpenses),  icon: Icons.person_outline),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiChip extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _KpiChip({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.12), width: 0.8),
      ),
      child: Row(children: [
        Icon(icon, color: Colors.white.withOpacity(0.5), size: 13),
        const SizedBox(width: 6),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: WerlogTextStyles.balanceSub.copyWith(fontSize: 9)),
          Text(value,  style: WerlogTextStyles.balanceSub.copyWith(
              fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
        ]),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  TAB BAR
// ─────────────────────────────────────────────────────────────────────────────
class _TabBar extends StatelessWidget {
  final TabController controller;
  const _TabBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: WerlogColors.surface,
        border: Border(bottom: BorderSide(color: WerlogColors.border, width: 0.8)),
      ),
      child: TabBar(
        controller: controller,
        labelColor: WerlogColors.teal,
        unselectedLabelColor: WerlogColors.textTertiary,
        indicatorColor: WerlogColors.teal,
        indicatorWeight: 2,
        labelStyle: WerlogTextStyles.txTitle.copyWith(fontSize: 13),
        unselectedLabelStyle: WerlogTextStyles.body.copyWith(fontSize: 13),
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Tax Summary'),
          Tab(text: 'Documents'),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  TAB 1 — OVERVIEW
// ═════════════════════════════════════════════════════════════════════════════
class _OverviewTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 14),
          _AlertsRow(),
          const SizedBox(height: 14),
          _SpendingBarChart(),
          const SizedBox(height: 14),
          _CategoriesSection(),
          const SizedBox(height: 14),
          _AiInsightsCard(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// ── Alerts row ────────────────────────────────────────────────────────────────
class _AlertsRow extends StatelessWidget {
  static const _colorMap = {
    'amber':  Color(0xFFBA7517),
    'teal':   Color(0xFF1D9E75),
    'coral':  Color(0xFFD85A30),
    'purple': Color(0xFF7B5EA7),
  };
  static const _surfaceMap = {
    'amber':  Color(0xFFFAEEDA),
    'teal':   Color(0xFFE1F5EE),
    'coral':  Color(0xFFFAECE7),
    'purple': Color(0xFFF3EEF8),
  };
  static const _iconMap = {
    'deadline':    Icons.event_outlined,
    'review':      Icons.rate_review_outlined,
    'missing':     Icons.receipt_long_outlined,
    'opportunity': Icons.lightbulb_outline,
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Alerts & Reminders', style: WerlogTextStyles.sectionTitle),
            GestureDetector(
              onTap: () {},
              child: Text('View All (${ExpenseDashboardData.alerts.length})',
                  style: WerlogTextStyles.link.copyWith(fontSize: 11)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: ExpenseDashboardData.alerts.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final a = ExpenseDashboardData.alerts[i];
              final color   = _colorMap[a['color']] ?? WerlogColors.teal;
              final surface = _surfaceMap[a['color']] ?? WerlogColors.tealSurface;
              final icon    = _iconMap[a['type']] ?? Icons.info_outline;
              return _AlertCard(
                title: a['title']!, subtitle: a['subtitle']!,
                icon: icon, color: color, surface: surface,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AlertCard extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final Color color, surface;
  const _AlertCard({required this.title, required this.subtitle,
      required this.icon, required this.color, required this.surface});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 158,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: WerlogColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: WerlogColors.border, width: 0.8),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 15),
          ),
          const SizedBox(height: 6),
          Text(title, style: WerlogTextStyles.txTitle.copyWith(fontSize: 10), maxLines: 2, overflow: TextOverflow.ellipsis),
          const Spacer(),
          Text(subtitle, style: WerlogTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w600, fontSize: 9)),
        ],
      ),
    );
  }
}

// ── Spending bar chart (custom painter) ──────────────────────────────────────
class _SpendingBarChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final data = ExpenseDashboardData.monthlyTrend;
    final maxVal = data.fold(0.0, (m, e) => e.amount > m ? e.amount : m);

    return Container(
      decoration: BoxDecoration(
        color: WerlogColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WerlogColors.border, width: 0.8),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Monthly Spending', style: WerlogTextStyles.sectionTitle),
                  Text('Last 12 months', style: WerlogTextStyles.caption),
                ],
              ),
              GestureDetector(
                onTap: () {},
                child: Text('Full Report', style: WerlogTextStyles.link.copyWith(fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: data.map((m) {
                  final barH = maxVal > 0 ? (m.amount / maxVal) * 80 : 0.0;
                  final isEmpty = m.amount == 0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (!isEmpty)
                          Text('\$${(m.amount / 1000).toStringAsFixed(1)}k',
                              style: WerlogTextStyles.caption.copyWith(fontSize: 8)),
                        const SizedBox(height: 3),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          width: 22,
                          height: isEmpty ? 4 : barH,
                          decoration: BoxDecoration(
                            gradient: isEmpty ? null : WerlogGradients.darkHero(),
                            color: isEmpty ? WerlogColors.surfaceAlt : null,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(m.month, style: WerlogTextStyles.caption.copyWith(fontSize: 9)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Categories section ────────────────────────────────────────────────────────
class _CategoriesSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cats = ExpenseDashboardData.categories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Categories (${cats.length})', style: WerlogTextStyles.sectionTitle),
            GestureDetector(
              onTap: () {},
              child: Text('View All', style: WerlogTextStyles.link.copyWith(fontSize: 11)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Horizontal scrollable category chips — tap opens detail
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: cats.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) => _CategoryChip(cat: cats[i]),
          ),
        ),
        const SizedBox(height: 12),
        // Full list rows
        ...cats.map((c) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _CategoryListRow(cat: c),
        )),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final ExpenseCategory cat;
  const _CategoryChip({required this.cat});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => ExpenseCategoryScreen(category: cat))),
      child: Container(
        width: 110,
        decoration: BoxDecoration(
          color: WerlogColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: WerlogColors.border, width: 0.8),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5, offset: const Offset(0, 2))],
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                color: cat.iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(cat.icon, color: cat.iconColor, size: 16),
            ),
            const Spacer(),
            Text(cat.name,
                style: WerlogTextStyles.txTitle.copyWith(fontSize: 10),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            Text(cat.formattedTotal,
                style: WerlogTextStyles.sectionTitle.copyWith(fontSize: 11, color: WerlogColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}

class _CategoryListRow extends StatelessWidget {
  final ExpenseCategory cat;
  const _CategoryListRow({required this.cat});

  static double get _totalAll => ExpenseDashboardData.categories
      .fold(0.0, (s, c) => s + c.totalAmount);

  @override
  Widget build(BuildContext context) {
    final pct = _totalAll > 0 ? cat.totalAmount / _totalAll : 0.0;

    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => ExpenseCategoryScreen(category: cat))),
      child: Container(
        decoration: BoxDecoration(
          color: WerlogColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: WerlogColors.border, width: 0.8),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5, offset: const Offset(0, 2))],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          children: [
            Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: cat.iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(cat.icon, color: cat.iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cat.name, style: WerlogTextStyles.txTitle.copyWith(fontSize: 12)),
                    const SizedBox(height: 2),
                    Row(children: [
                      _StatusDot(color: WerlogColors.teal, label: '${cat.verifiedCount} verified'),
                      const SizedBox(width: 8),
                      if (cat.needsReviewCount > 0)
                        _StatusDot(color: WerlogColors.amber, label: '${cat.needsReviewCount} review'),
                      if (cat.missingInfoCount > 0) ...[
                        const SizedBox(width: 8),
                        _StatusDot(color: WerlogColors.coral, label: '${cat.missingInfoCount} missing'),
                      ],
                    ]),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(cat.formattedTotal, style: WerlogTextStyles.txAmount),
                Text('GST: ${cat.formattedGst}',
                    style: WerlogTextStyles.caption.copyWith(color: WerlogColors.teal, fontSize: 9)),
                Text('${(pct * 100).toStringAsFixed(0)}%',
                    style: WerlogTextStyles.caption.copyWith(fontSize: 9)),
              ]),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: WerlogColors.textTertiary, size: 16),
            ]),
            const SizedBox(height: 8),
            // Mini progress bar: deductible vs total
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: cat.totalAmount > 0 ? cat.deductibleAmount / cat.totalAmount : 0,
                backgroundColor: WerlogColors.surfaceAlt,
                valueColor: AlwaysStoppedAnimation<Color>(cat.iconColor.withOpacity(0.7)),
                minHeight: 3,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Deductible: ${cat.formattedDeductible}',
                    style: WerlogTextStyles.caption.copyWith(fontSize: 9, color: WerlogColors.teal)),
                Text('${cat.itemCount} expenses',
                    style: WerlogTextStyles.caption.copyWith(fontSize: 9)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final Color color;
  final String label;
  const _StatusDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 6, height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 3),
      Text(label, style: WerlogTextStyles.caption.copyWith(fontSize: 9)),
    ]);
  }
}

// ── AI Insights card ──────────────────────────────────────────────────────────
class _AiInsightsCard extends StatelessWidget {
  static const _iconMap = {
    'home':    Icons.home_work_outlined,
    'car':     Icons.directions_car_outlined,
    'receipt': Icons.receipt_long_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: WerlogColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WerlogColors.border, width: 0.8),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(color: WerlogColors.tealSurface, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.auto_awesome, color: WerlogColors.teal, size: 15),
            ),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text('AI Insights', style: WerlogTextStyles.sectionTitle),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: WerlogColors.teal, borderRadius: BorderRadius.circular(4)),
                  child: Text('New', style: WerlogTextStyles.badgeText.copyWith(color: Colors.white)),
                ),
              ]),
              Text('Smart suggestions to maximize your savings', style: WerlogTextStyles.caption),
            ]),
            const Spacer(),
            GestureDetector(
              onTap: () {},
              child: Row(children: [
                Text('View All', style: WerlogTextStyles.link.copyWith(fontSize: 11)),
                const Icon(Icons.chevron_right, color: WerlogColors.teal, size: 14),
              ]),
            ),
          ]),
          const SizedBox(height: 12),
          ...ExpenseDashboardData.aiInsights.map((ins) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(gradient: WerlogGradients.pageHeader(), borderRadius: BorderRadius.circular(9)),
                child: Icon(_iconMap[ins['icon']] ?? Icons.lightbulb_outline,
                    color: WerlogColors.teal, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(ins['title']!, style: WerlogTextStyles.txTitle.copyWith(fontSize: 11)),
                Text(ins['subtitle']!, style: WerlogTextStyles.caption.copyWith(color: WerlogColors.teal)),
              ])),
              const Icon(Icons.chevron_right, color: WerlogColors.textTertiary, size: 16),
            ]),
          )),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  TAB 2 — TAX SUMMARY
// ═════════════════════════════════════════════════════════════════════════════
class _TaxTab extends StatelessWidget {
  String _fmt(double v) => '\$${v.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          _TaxHeroCard(),
          const SizedBox(height: 14),
          _BusinessPersonalSplit(),
          const SizedBox(height: 14),
          _TaxSummaryTable(),
          const SizedBox(height: 14),
          _TaxTipsCard(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _TaxHeroCard extends StatelessWidget {
  String _fmt(double v) => '\$${v.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: WerlogGradients.darkHero(),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: WerlogColors.darkTeal.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Estimated Tax Savings', style: WerlogTextStyles.balanceSub.copyWith(fontSize: 11)),
          const SizedBox(height: 4),
          Text(_fmt(ExpenseDashboardData.estimatedTaxSavings), style: WerlogTextStyles.balanceAmount),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(children: [
              _TaxChip('GST Claimable', _fmt(ExpenseDashboardData.claimableGst), WerlogColors.teal),
              const SizedBox(width: 8),
              _TaxChip('Non-Claimable', _fmt(ExpenseDashboardData.nonClaimableGst), WerlogColors.coral),
              const SizedBox(width: 8),
              _TaxChip('Deductions', _fmt(ExpenseDashboardData.totalDeductions), WerlogColors.tealLight),
            ]),
          ),
        ],
      ),
    );
  }
}

class _TaxChip extends StatelessWidget {
  final String label, value;
  final Color color;
  const _TaxChip(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3), width: 0.8),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(label, style: WerlogTextStyles.balanceSub.copyWith(fontSize: 9)),
        ]),
        const SizedBox(height: 3),
        Text(value, style: WerlogTextStyles.balanceSub.copyWith(
            fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
      ]),
    );
  }
}

class _BusinessPersonalSplit extends StatelessWidget {
  String _fmt(double v) => '\$${v.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

  @override
  Widget build(BuildContext context) {
    final total = ExpenseDashboardData.businessExpenses + ExpenseDashboardData.personalExpenses;
    final bizPct = total > 0 ? ExpenseDashboardData.businessExpenses / total : 0.0;
    final perPct = 1 - bizPct;

    return Container(
      decoration: BoxDecoration(
        color: WerlogColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WerlogColors.border, width: 0.8),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Business vs Personal Split', style: WerlogTextStyles.sectionTitle),
          const SizedBox(height: 14),
          Row(children: [
            // Stacked horizontal bar
            Expanded(
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      height: 14,
                      child: Row(children: [
                        Expanded(flex: (bizPct * 100).toInt(), child: Container(color: WerlogColors.darkTeal)),
                        const SizedBox(width: 2),
                        Expanded(flex: (perPct * 100).toInt(), child: Container(color: WerlogColors.tealLight)),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(children: [
                    _SplitLegend(color: WerlogColors.darkTeal, label: 'Business',
                        pct: '${(bizPct * 100).toStringAsFixed(0)}%', amount: _fmt(ExpenseDashboardData.businessExpenses)),
                    const SizedBox(width: 16),
                    _SplitLegend(color: WerlogColors.tealLight, label: 'Personal',
                        pct: '${(perPct * 100).toStringAsFixed(0)}%', amount: _fmt(ExpenseDashboardData.personalExpenses)),
                  ]),
                ],
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class _SplitLegend extends StatelessWidget {
  final Color color;
  final String label, pct, amount;
  const _SplitLegend({required this.color, required this.label, required this.pct, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 6),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: WerlogTextStyles.caption.copyWith(fontSize: 10)),
        Text('$amount ($pct)', style: WerlogTextStyles.txTitle.copyWith(fontSize: 11)),
      ]),
    ]);
  }
}

class _TaxSummaryTable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: WerlogColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WerlogColors.border, width: 0.8),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(children: [
            Text('Tax Summary', style: WerlogTextStyles.sectionTitle),
            const Spacer(),
            GestureDetector(
              onTap: () {},
              child: Text('Download PDF', style: WerlogTextStyles.link.copyWith(fontSize: 11)),
            ),
          ]),
        ),
        const Divider(height: 0.5, color: WerlogColors.borderLight),
        ...ExpenseDashboardData.taxSummaryRows.asMap().entries.map((e) {
          final row = e.value;
          final isLast = e.key == ExpenseDashboardData.taxSummaryRows.length - 1;
          final isHighlight = row['type'] == 'highlight';
          final valueColor = isHighlight
              ? WerlogColors.teal
              : row['type'] == 'negative' ? WerlogColors.coral : WerlogColors.textPrimary;
          return Container(
            color: isHighlight ? WerlogColors.tealSurface : null,
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(children: [
                  Text(row['label']!,
                      style: WerlogTextStyles.body.copyWith(
                          fontSize: 12, fontWeight: isHighlight ? FontWeight.w600 : FontWeight.w400)),
                  const Spacer(),
                  Text(row['value']!,
                      style: WerlogTextStyles.txTitle.copyWith(
                          fontSize: isHighlight ? 14 : 13, color: valueColor)),
                ]),
              ),
              if (!isLast) const Divider(height: 0.5, color: WerlogColors.borderLight),
            ]),
          );
        }),
      ]),
    );
  }
}

class _TaxTipsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: WerlogGradients.pageHeader(),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WerlogColors.border, width: 0.8),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.lightbulb_outline, color: WerlogColors.teal, size: 18),
            const SizedBox(width: 8),
            Text('Tax Tips', style: WerlogTextStyles.sectionTitle),
          ]),
          const SizedBox(height: 12),
          ...ExpenseDashboardData.taxTips.map((t) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: 6, height: 6, margin: const EdgeInsets.only(top: 4),
                  decoration: const BoxDecoration(color: WerlogColors.teal, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Expanded(child: Text(t, style: WerlogTextStyles.body.copyWith(fontSize: 11))),
            ]),
          )),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  TAB 3 — DOCUMENTS
// ═════════════════════════════════════════════════════════════════════════════
class _DocumentsTab extends StatelessWidget {
  // ── Document data variables — replace with API ──────────────────────────
  static const int totalDocs    = 86;
  static const int verifiedDocs = 72;
  static const int pendingDocs  = 10;
  static const int rejectedDocs = 4;

  static const List<Map<String, dynamic>> docList = [
    {'name': 'Adobe_Invoice_May2024.pdf', 'size': '124 KB', 'date': '01 May 2024', 'type': 'Invoice',  'category': 'Software', 'isImage': false},
    {'name': 'Staples_Receipt_Apr2024.pdf','size': '89 KB', 'date': '28 Apr 2024', 'type': 'Receipt',  'category': 'Office',   'isImage': false},
    {'name': 'Rogers_Bill_Apr2024.pdf',    'size': '210 KB','date': '25 Apr 2024', 'type': 'Bill',     'category': 'Home Office','isImage': false},
    {'name': 'Shell_Receipt_Apr22.jpg',    'size': '1.2 MB','date': '22 Apr 2024', 'type': 'Receipt',  'category': 'Auto',     'isImage': true},
    {'name': 'Buca_Receipt_Apr2024.jpg',   'size': '876 KB','date': '20 Apr 2024', 'type': 'Receipt',  'category': 'Meals',    'isImage': true},
    {'name': 'AirCanada_Booking.pdf',      'size': '344 KB','date': '18 Apr 2024', 'type': 'Invoice',  'category': 'Travel',   'isImage': false},
    {'name': 'Marriott_Folio.pdf',         'size': '198 KB','date': '10 Apr 2024', 'type': 'Invoice',  'category': 'Travel',   'isImage': false},
    {'name': 'LinkedIn_Invoice.pdf',       'size': '65 KB', 'date': '12 Apr 2024', 'type': 'Invoice',  'category': 'Professional','isImage': false},
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(children: [
              _DocStatChip('Total', '$totalDocs', WerlogColors.textPrimary, WerlogColors.surfaceAlt),
              const SizedBox(width: 10),
              _DocStatChip('Verified', '$verifiedDocs', WerlogColors.teal, WerlogColors.tealSurface),
              const SizedBox(width: 10),
              _DocStatChip('Pending', '$pendingDocs', WerlogColors.amber, WerlogColors.amberSurface),
              const SizedBox(width: 10),
              _DocStatChip('Rejected', '$rejectedDocs', WerlogColors.coral, WerlogColors.coralSurface),
            ]),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('All Documents', style: WerlogTextStyles.sectionTitle),
              GestureDetector(
                onTap: () {},
                child: Text('Sort / Filter', style: WerlogTextStyles.link.copyWith(fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...docList.map((d) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _DocItem(doc: d),
          )),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _DocStatChip extends StatelessWidget {
  final String label, value;
  final Color color, bgColor;
  const _DocStatChip(this.label, this.value, this.color, this.bgColor);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2), width: 0.8),
      ),
      child: Column(children: [
        Text(label, style: WerlogTextStyles.caption.copyWith(color: color, fontSize: 10)),
        Text(value,  style: WerlogTextStyles.sectionTitle.copyWith(color: color, fontSize: 18)),
      ]),
    );
  }
}

class _DocItem extends StatelessWidget {
  final Map<String, dynamic> doc;
  const _DocItem({required this.doc});

  @override
  Widget build(BuildContext context) {
    final isImage = doc['isImage'] as bool;
    return Container(
      decoration: BoxDecoration(
        color: WerlogColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: WerlogColors.border, width: 0.8),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: isImage ? WerlogColors.tealSurface : WerlogColors.coralSurface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isImage ? Icons.image_outlined : Icons.picture_as_pdf_outlined,
            color: isImage ? WerlogColors.teal : WerlogColors.coral,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(doc['name'], style: WerlogTextStyles.txTitle.copyWith(fontSize: 11),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 3),
          Wrap(spacing: 6, children: [
            _MetaPill(doc['type'], WerlogColors.textTertiary),
            _MetaPill(doc['category'], WerlogColors.teal),
            _MetaPill(doc['size'], WerlogColors.textTertiary),
          ]),
          Text(doc['date'], style: WerlogTextStyles.txDate),
        ])),
        IconButton(
          icon: const Icon(Icons.more_vert, color: WerlogColors.textTertiary, size: 18),
          onPressed: () {},
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ]),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final String text;
  final Color color;
  const _MetaPill(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: WerlogTextStyles.caption.copyWith(color: color, fontSize: 9));
  }
}
