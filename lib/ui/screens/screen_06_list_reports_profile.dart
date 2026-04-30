import 'package:flutter/material.dart';
import '../../core/models/app_models_extended.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';


// ══════════════════════════════════════════════════════════════
//  InvoiceListScreen  (screen 12)
// ══════════════════════════════════════════════════════════════
class InvoiceListScreen extends StatefulWidget {
  final InvoiceListData? data;
  final void Function(InvoiceListItem item)? onItemTap;
  final void Function(int tab)? onTabChanged;
  final int currentTab;

  const InvoiceListScreen({
    super.key,
    this.data,
    this.onItemTap,
    this.onTabChanged,
    this.currentTab = 1,
  });

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  late InvoiceFilterType _filter;

  @override
  void initState() {
    super.initState();
    _filter = widget.data?.filter ?? InvoiceFilterType.all;
  }

  InvoiceListData get _d => widget.data ?? InvoiceListData();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WerlogColors.background,
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
              gradient: WerlogGradients.pageHeader()),
          child: Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Gradient header area
                          Container(
                            /*decoration: BoxDecoration(
                              gradient: WerlogGradients.pageHeader()),*/
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const FakeStatusBar(),
                                _ListPageHeader(d: _d),
                                _SearchBar(),
                                _FilterChips(
                                  filter: _filter,
                                  d: _d,
                                  onChanged: (f) =>
                                      setState(() => _filter = f),
                                ),
                                _StatsRow(d: _d),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, gi) {
                            final group = _d.groups[gi];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (gi > 0) const SizedBox(height: 10),
                                Text(group.dateLabel,
                                    style: WerlogTextStyles.caption.copyWith(
                                      fontSize: 9,
                                      color: WerlogColors.textTertiary,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.8,
                                    )),
                                const SizedBox(height: 6),
                                ...group.items.asMap().entries.map((e) {
                                  final last =
                                      e.key == group.items.length - 1;
                                  return Column(
                                    children: [
                                      _InvoiceListRow(
                                        item: e.value,
                                        onTap: () => widget.onItemTap?.call(e.value),
                                      ),
                                      if (!last)
                                        const Divider(
                                          height: 0, thickness: 0.5,
                                          color: WerlogColors.borderLight),
                                    ],
                                  );
                                }),
                              ],
                            );
                          },
                          childCount: _d.groups.length,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              /*_SharedBottomNav(
                  selected: widget.currentTab,
                  onTap: widget.onTabChanged),*/
            ],
          ),
        ),
      ),
    );
  }
}

class _ListPageHeader extends StatelessWidget {
  final InvoiceListData d;
  const _ListPageHeader({required this.d});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Invoices', style: WerlogTextStyles.pageTitle),
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: WerlogColors.surface,
              border: Border.all(color: WerlogColors.border),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text('⚙',
                style: WerlogTextStyles.body
                    .copyWith(color: WerlogColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: WerlogColors.surface,
        border: Border.all(color: WerlogColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Text('⌕',
              style: TextStyle(
                  fontSize: 14, color: WerlogColors.textTertiary)),
          const SizedBox(width: 8),
          Text('Search vendor, amount, date...',
              style: WerlogTextStyles.bodySmall
                  .copyWith(color: WerlogColors.textTertiary)),
        ],
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  final InvoiceFilterType filter;
  final InvoiceListData d;
  final ValueChanged<InvoiceFilterType> onChanged;

  const _FilterChips(
      {required this.filter, required this.d, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _Chip(
              label: 'All · ${d.totalCount}',
              active: filter == InvoiceFilterType.all,
              activeColor: WerlogColors.darkTeal,
              onTap: () => onChanged(InvoiceFilterType.all),
            ),
            const SizedBox(width: 6),
            _Chip(
              label: 'Expenses · ${d.expenseCount}',
              active: filter == InvoiceFilterType.expenses,
              activeColor: WerlogColors.darkTeal,
              onTap: () => onChanged(InvoiceFilterType.expenses),
            ),
            const SizedBox(width: 6),
            _Chip(
              label: 'Warranties · ${d.warrantyCount}',
              active: filter == InvoiceFilterType.warranties,
              activeColor: WerlogColors.amber,
              onTap: () => onChanged(InvoiceFilterType.warranties),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? activeColor : WerlogColors.surface,
          border: Border.all(
            color: active ? activeColor : WerlogColors.border),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: WerlogTextStyles.caption.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: active ? Colors.white : WerlogColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final InvoiceListData d;
  const _StatsRow({required this.d});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              label: 'THIS MONTH',
              value: d.thisMonthTotal,
              delta: d.thisMonthDelta,
              isWarning: false,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatCard(
              label: 'AVG/WEEK',
              value: d.avgWeeklyTotal,
              delta: d.avgWeeklyDelta,
              isWarning: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String delta;
  final bool isWarning;

  const _StatCard({
    required this.label,
    required this.value,
    required this.delta,
    required this.isWarning,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: WerlogColors.surface,
        border: Border.all(color: WerlogColors.border),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: WerlogTextStyles.labelUppercase
                  .copyWith(fontSize: 9)),
          const SizedBox(height: 2),
          Text(value,
              style: WerlogTextStyles.balanceAmount.copyWith(
                color: WerlogColors.textPrimary, fontSize: 17,
                letterSpacing: -0.3)),
          const SizedBox(height: 1),
          Text(delta,
              style: WerlogTextStyles.caption.copyWith(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: isWarning ? WerlogColors.amber : WerlogColors.teal,
              )),
        ],
      ),
    );
  }
}

// ── Invoice row ────────────────────────────────────────────────
class _InvoiceListRow extends StatelessWidget {
  final InvoiceListItem item;
  final VoidCallback? onTap;

  const _InvoiceListRow({required this.item, this.onTap});

  static const Map<String, Color> _iconBg = {
    'food': WerlogColors.coralSurface,
    'elec': WerlogColors.tealSurface,
    'fuel': WerlogColors.amberSurface,
    'util': Color(0xFFEEEDFE),
  };

  static const Map<String, Color> _iconColor = {
    'food': WerlogColors.coralDark,
    'elec': Color(0xFF0F6E56),
    'fuel': WerlogColors.amberDark,
    'util': Color(0xFF3C3489),
  };

  @override
  Widget build(BuildContext context) {
    final bg    = _iconBg[item.iconColorKey] ?? WerlogColors.surfaceAlt;
    final color = _iconColor[item.iconColorKey] ?? WerlogColors.textSecondary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: bg, borderRadius: BorderRadius.circular(11)),
              alignment: Alignment.center,
              child: Text(item.iconEmoji,
                  style: TextStyle(fontSize: 15, color: color)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.vendor,
                      style: WerlogTextStyles.txTitle,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: item.type == InvoiceType.expense
                              ? WerlogColors.coral.withOpacity(0.10)
                              : WerlogColors.amber.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          item.type == InvoiceType.expense
                              ? 'EXPENSE' : 'WARRANTY',
                          style: WerlogTextStyles.badgeText.copyWith(
                            fontSize: 7,
                            color: item.type == InvoiceType.expense
                                ? const Color(0xFF712B13)
                                : WerlogColors.amberDeep,
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(item.typeMeta,
                          style: WerlogTextStyles.txMeta),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(item.amount,
                    style: WerlogTextStyles.txAmount
                        .copyWith(fontSize: 12)),
                const SizedBox(height: 1),
                Text(item.timeLabel,
                    style: WerlogTextStyles.txDate),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  ReportsScreen  (screen 13)
// ══════════════════════════════════════════════════════════════
class ReportsScreen extends StatelessWidget {
  final ReportsData? data;
  final VoidCallback? onExport;
  final void Function(int tab)? onTabChanged;
  final int currentTab;

  const ReportsScreen({
    super.key,
    this.data,
    this.onExport,
    this.onTabChanged,
    this.currentTab = 3,
  });

  @override
  Widget build(BuildContext context) {
    final d = data ?? ReportsData();

    return Scaffold(
      backgroundColor: WerlogColors.background,
      body: SafeArea(
        child: Container(
          // margin: const EdgeInsets.only(top: 14),
          decoration: BoxDecoration(
              gradient: WerlogGradients.pageHeader()),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        /*decoration: BoxDecoration(
                            gradient: WerlogGradients.pageHeader()),*/
                        child: Column(
                          children: [
                            // const FakeStatusBar(),
                            _ReportsHeader(d: d),
                          ],
                        ),
                      ),
                      _TotalCard(d: d),
                      // _MonthlyTrendSection(d: d),
                      _CategorySection(d: d),
                      _ExportBanner(onTap: onExport),
                      const SizedBox(height: 14),
                    ],
                  ),
                ),
              ),
              /*_SharedBottomNav(
                  selected: currentTab, onTap: onTabChanged),*/
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportsHeader extends StatelessWidget {
  final ReportsData d;
  const _ReportsHeader({required this.d});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Reports', style: WerlogTextStyles.pageTitle),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 11, vertical: 5),
            decoration: BoxDecoration(
              color: WerlogColors.surface,
              border: Border.all(color: WerlogColors.border),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Text(d.periodLabel,
                    style: WerlogTextStyles.body.copyWith(
                        fontSize: 10, fontWeight: FontWeight.w500)),
                const SizedBox(width: 5),
                const Text('▾',
                    style: TextStyle(
                        fontSize: 10,
                        color: WerlogColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  final ReportsData d;
  const _TotalCard({required this.d});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: WerlogGradients.reportsCard(),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TOTAL TRACKED',
                  style: WerlogTextStyles.balanceLabel),
              const SizedBox(height: 3),
              Text(d.totalTracked,
                  style: WerlogTextStyles.balanceAmount),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _SparkBar(
                      label: 'Expenses',
                      barClass: 'e',
                      value: d.expensesTotal,
                      ratio: d.expensesRatio,
                      pct: d.expensesRatioPct,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SparkBar(
                      label: 'Warranties',
                      barClass: 'w',
                      value: d.warrantiesTotal,
                      ratio: d.warrantiesRatio,
                      pct: d.warrantiesRatioPct,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          top: 14 - 40, right: 20 - 40,
          child: IgnorePointer(
            child: Container(
              width: 130, height: 130,
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

class _SparkBar extends StatelessWidget {
  final String label;
  final String barClass; // 'e' or 'w'
  final String value;
  final double ratio;
  final String pct;

  const _SparkBar({
    required this.label,
    required this.barClass,
    required this.value,
    required this.ratio,
    required this.pct,
  });

  @override
  Widget build(BuildContext context) {
    final barColor = barClass == 'e'
        ? const Color(0xFFF0997B)
        : const Color(0xFFEF9F27);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: WerlogTextStyles.balanceSub.copyWith(fontSize: 9)),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: Container(
            height: 3,
            color: Colors.white.withOpacity(0.12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: ratio,
                child: Container(color: barColor),
              ),
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text('$value · $pct',
            style: WerlogTextStyles.balanceSub.copyWith(
                fontSize: 12, fontWeight: FontWeight.w500,
                color: Colors.white)),
      ],
    );
  }
}

class _MonthlyTrendSection extends StatelessWidget {
  final ReportsData d;
  const _MonthlyTrendSection({required this.d});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('MONTHLY TREND',
                  style: WerlogTextStyles.labelUppercase
                      .copyWith(fontSize: 9)),
              Text('Expenses vs Warranties',
                  style: WerlogTextStyles.link.copyWith(fontSize: 9)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: WerlogColors.surface,
              border: Border.all(color: WerlogColors.border),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 110,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: d.monthlyBars.map((b) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    // Warranty bar (top)
                                    FractionallySizedBox(
                                      heightFactor:
                                          b.warrantyRatio.clamp(0.0, 1.0),
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFEF9F27),
                                          borderRadius: BorderRadius.vertical(
                                              top: Radius.circular(3)),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    // Expense bar
                                    FractionallySizedBox(
                                      heightFactor:
                                          b.expenseRatio.clamp(0.0, 1.0),
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFD85A30),
                                          borderRadius: BorderRadius.vertical(
                                              top: Radius.circular(3)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(b.month,
                                  style: WerlogTextStyles.caption.copyWith(
                                    fontSize: 9,
                                    fontWeight: b.isCurrent
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                    color: b.isCurrent
                                        ? WerlogColors.textPrimary
                                        : WerlogColors.textTertiary,
                                  )),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const Divider(
                    height: 14, thickness: 0.5,
                    color: WerlogColors.borderLight),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _Legend(color: const Color(0xFFD85A30), label: 'Expenses'),
                    const SizedBox(width: 14),
                    _Legend(
                        color: const Color(0xFFEF9F27),
                        label: 'Warranties'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: WerlogTextStyles.caption
                .copyWith(fontSize: 9)),
      ],
    );
  }
}

class _CategorySection extends StatelessWidget {
  final ReportsData d;
  const _CategorySection({required this.d});

  static const Map<String, Color> _barColors = {
    'util': Color(0xFF7F77DD),
    'food': Color(0xFFD85A30),
    'elec': WerlogColors.teal,
    'fuel': WerlogColors.amber,
  };

  static const Map<String, Color> _iconBg = {
    'util': Color(0xFFEEEDFE),
    'food': WerlogColors.coralSurface,
    'elec': WerlogColors.tealSurface,
    'fuel': WerlogColors.amberSurface,
  };

  static const Map<String, Color> _iconColor = {
    'util': Color(0xFF3C3489),
    'food': WerlogColors.coralDark,
    'elec': Color(0xFF0F6E56),
    'fuel': WerlogColors.amberDark,
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('BY CATEGORY',
                  style: WerlogTextStyles.labelUppercase
                      .copyWith(fontSize: 9)),
              Text('View all ›',
                  style: WerlogTextStyles.link.copyWith(fontSize: 9)),
            ],
          ),
          const SizedBox(height: 10),
          ...d.categories.asMap().entries.map((e) {
            final cat = e.value;
            final last = e.key == d.categories.length - 1;
            return Column(
              children: [
                _CategoryRow(
                  cat:       cat,
                  barColor:  _barColors[cat.colorKey] ?? WerlogColors.teal,
                  iconBg:    _iconBg[cat.colorKey] ?? WerlogColors.surfaceAlt,
                  iconColor: _iconColor[cat.colorKey] ?? WerlogColors.textSecondary,
                ),
                if (!last)
                  const Divider(
                      height: 0, thickness: 0.5,
                      color: WerlogColors.borderLight),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final CategoryReportItem cat;
  final Color barColor;
  final Color iconBg;
  final Color iconColor;

  const _CategoryRow({
    required this.cat,
    required this.barColor,
    required this.iconBg,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              color: iconBg, borderRadius: BorderRadius.circular(8)),
            alignment: Alignment.center,
            child: Text(cat.iconEmoji,
                style: TextStyle(fontSize: 12, color: iconColor)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cat.name,
                    style: WerlogTextStyles.body
                        .copyWith(fontSize: 11, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: Container(
                    height: 4,
                    color: WerlogColors.surfaceAlt,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: cat.ratio,
                        child: Container(color: barColor),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(cat.amount,
                  style: WerlogTextStyles.txAmount
                      .copyWith(fontSize: 12)),
              Text(cat.percentage,
                  style: WerlogTextStyles.caption
                      .copyWith(fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExportBanner extends StatelessWidget {
  final VoidCallback? onTap;
  const _ExportBanner({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: WerlogColors.tealSurface,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Export this report',
                    style: WerlogTextStyles.body.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF085041))),
                const SizedBox(height: 2),
                Text('CSV, PDF or Excel',
                    style: WerlogTextStyles.caption.copyWith(
                        color: const Color(0xFF0F6E56))),
              ],
            ),
            const Text('⇣',
                style: TextStyle(
                    fontSize: 16, color: WerlogColors.teal)),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  ProfileScreen  (screen 14)
// ══════════════════════════════════════════════════════════════
class ProfileScreen extends StatefulWidget {
  final ProfileData? data;
  final void Function(SettingRow row)? onSettingTap;
  final void Function(int tab)? onTabChanged;
  final int currentTab;

  const ProfileScreen({
    super.key,
    this.data,
    this.onSettingTap,
    this.onTabChanged,
    this.currentTab = 4,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late ProfileData _data;

  @override
  void initState() {
    super.initState();
    _data = widget.data ?? ProfileData();
  }

  void _toggleRow(SettingRow row) {
    setState(() => row.toggleValue = !row.toggleValue);
    widget.onSettingTap?.call(row);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WerlogColors.background,
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
              gradient: WerlogGradients.pageHeader()),
          child: Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Container(
                        /*decoration: BoxDecoration(
                            gradient: WerlogGradients.pageHeader()),*/
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const FakeStatusBar(),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Profile',
                                      style: WerlogTextStyles.pageTitle),
                                  Container(
                                    width: 34, height: 34,
                                    decoration: BoxDecoration(
                                      color: WerlogColors.surface,
                                      border: Border.all(
                                          color: WerlogColors.border),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Text('◉',
                                        style: TextStyle(
                                            color: WerlogColors.textPrimary)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                        child: _ProfileCard(data: _data),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) {
                          final sec = _data.sections[i];
                          return Padding(
                            padding:
                                const EdgeInsets.fromLTRB(20, 12, 20, 0),
                            child: _SettingSection(
                              section: sec,
                              onRowTap: (r) {
                                if (r.trailing ==
                                    SettingTrailingType.toggle) {
                                  _toggleRow(r);
                                } else {
                                  widget.onSettingTap?.call(r);
                                }
                              },
                            ),
                          );
                        },
                        childCount: _data.sections.length,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Text(
                          _data.appVersion,
                          textAlign: TextAlign.center,
                          style: WerlogTextStyles.caption
                              .copyWith(fontSize: 9),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              /*_SharedBottomNav(
                  selected: widget.currentTab,
                  onTap: widget.onTabChanged),*/
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final ProfileData data;
  const _ProfileCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: WerlogColors.surface,
        border: Border.all(color: WerlogColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              gradient: WerlogGradients.avatar(),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(data.initials,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.3)),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(data.fullName,
                  style: WerlogTextStyles.body.copyWith(
                      fontWeight: FontWeight.w500, fontSize: 14)),
              const SizedBox(height: 1),
              Text(data.email,
                  style: WerlogTextStyles.caption),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: WerlogColors.darkTeal,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(data.planLabel,
                    style: WerlogTextStyles.badgeText.copyWith(
                        color: WerlogColors.tealLight,
                        fontSize: 8,
                        letterSpacing: 0.6,
                        fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingSection extends StatelessWidget {
  final SettingSection section;
  final void Function(SettingRow) onRowTap;
  const _SettingSection(
      {required this.section, required this.onRowTap});

  static const Map<String, Color> _iconBg = {
    'g': WerlogColors.surfaceAlt,
    't': WerlogColors.tealSurface,
    'a': WerlogColors.amberSurface,
    'c': WerlogColors.coralSurface,
    'r': Color(0xFFFCEBEB),
  };

  static const Map<String, Color> _iconColor = {
    'g': WerlogColors.textSecondary,
    't': Color(0xFF0F6E56),
    'a': WerlogColors.amberDark,
    'c': WerlogColors.coralDark,
    'r': Color(0xFFA32D2D),
  };

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: WerlogColors.surface,
          border: Border.all(color: WerlogColors.border),
          borderRadius: BorderRadius.circular(14),
        ),
        /*Container(
        decoration: BoxDecoration(
          color: WerlogColors.surface,
          border: Border.all(color: WerlogColors.border),
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.none,
        ),*/
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
              child: Text(section.header,
                  style: WerlogTextStyles.labelUppercase.copyWith(
                      fontSize: 9, color: WerlogColors.textTertiary)),
            ),
            ...section.rows.asMap().entries.map((e) {
              final row  = e.value;
              final isSignOut =
                  row.iconColorKey == 'r';
              return Column(
                children: [
                  const Divider(
                      height: 0, thickness: 0.5,
                      color: WerlogColors.borderLight),
                  GestureDetector(
                    onTap: () => onRowTap(row),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 11),
                      child: Row(
                        children: [
                          Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(
                              color:
                                  _iconBg[row.iconColorKey] ??
                                      WerlogColors.surfaceAlt,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(row.iconEmoji,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _iconColor[row.iconColorKey] ??
                                      WerlogColors.textSecondary,
                                )),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(row.title,
                                    style: WerlogTextStyles.body
                                        .copyWith(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: isSignOut
                                          ? const Color(0xFFA32D2D)
                                          : WerlogColors.textPrimary,
                                    )),
                                if (row.subtitle != null)
                                  Text(row.subtitle!,
                                      style: WerlogTextStyles.caption
                                          .copyWith(fontSize: 9)),
                              ],
                            ),
                          ),
                          // Trailing
                          if (row.trailing ==
                              SettingTrailingType.chevron)
                            Text('›',
                                style: WerlogTextStyles.body.copyWith(
                                    color: WerlogColors.textTertiary,
                                    fontSize: 16))
                          else if (row.trailing ==
                              SettingTrailingType.toggle)
                            _Toggle(on: row.toggleValue),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  final bool on;
  const _Toggle({required this.on});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 32, height: 18,
      decoration: BoxDecoration(
        color: on ? WerlogColors.teal : const Color(0xFFD3D1C7),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Align(
          alignment: on ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 14, height: 14,
            decoration: const BoxDecoration(
                color: Colors.white, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  Shared bottom nav bar (used by list, reports, profile screens)
// ──────────────────────────────────────────────────────────────
class _SharedBottomNav extends StatelessWidget {
  final int selected;
  final void Function(int)? onTap;

  const _SharedBottomNav({required this.selected, this.onTap});

  static const _tabs = [
    ('⌂', 'Home'), ('≡', 'Invoices'), ('', ''),
    ('◔', 'Reports'), ('◯', 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: WerlogColors.surface,
        border: Border(
            top: BorderSide(color: WerlogColors.border, width: 1)),
      ),
      child: Row(
        children: List.generate(_tabs.length, (i) {
          final t = _tabs[i];
          final active = i == selected;

          if (i == 2) {
            return Expanded(
              child: GestureDetector(
                onTap: () => Navigator.pop(context)/*onTap?.call(i)*/,
                child: Container(
                  alignment: Alignment.center,
                  child: Transform.translate(
                    offset: const Offset(0, -14),
                    child: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: WerlogColors.teal,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: WerlogColors.teal.withOpacity(0.32),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          )
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Text('+',
                          style: TextStyle(
                              fontSize: 22,
                              color: Colors.white,
                              fontWeight: FontWeight.w300,
                              height: 1)),
                    ),
                  ),
                ),
              ),
            );
          }

          return Expanded(
            child: GestureDetector(
              onTap: () => Navigator.pop(context)/*onTap?.call(i)*/,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 7)
                    .copyWith(bottom: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(t.$1,
                        style: TextStyle(
                            fontSize: 14,
                            color: active
                                ? WerlogColors.teal
                                : WerlogColors.tabInactive)),
                    const SizedBox(height: 2),
                    Text(t.$2,
                        style: WerlogTextStyles.tabLabel.copyWith(
                          color: active
                              ? WerlogColors.teal
                              : WerlogColors.tabInactive,
                        )),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
