import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:wellness/ui/tset/screens/expense_new/tax_ready_summary_screen.dart';
import '../../../../core/api/api_service.dart';
import '../../../../core/api/endpoints.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/general_functions.dart';
import '../../../../core/utils/shared_pref_helper.dart';
import 'fresh/expense_data.dart';
import 'fresh/expense_category_detail_screen.dart';
import 'tax_years_screen.dart';

// ═══════════════════════════════════════════════════════════════════════
//  SCREEN 1 — Expense Dashboard
//  Entry: call ExpenseDashboardScreen() from your main nav / bottom tab.
// ═══════════════════════════════════════════════════════════════════════
class ExpenseDashboardScreen extends StatefulWidget {
  const ExpenseDashboardScreen({super.key});

  @override
  State<ExpenseDashboardScreen> createState() => _ExpenseDashboardScreenState();
}

class _ExpenseDashboardScreenState extends State<ExpenseDashboardScreen> {

  String selectedYear = DateTime.now().year.toString();
  List<String> years = List.generate(
    6, (index) => (DateTime.now().year - index).toString(),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SharedPrefHelper.getSelectedCurrencySymbol();
      getExpenseDashboardData();
      ExpenseData.currentYear = selectedYear;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WerlogColors.background,
      body: SafeArea(
        child: Column(children: [
          _TopBar(
            selectedYear: selectedYear,
            years: years,
            onYearChanged: (year) {
              setState(() {
                selectedYear = year;
                ExpenseData.currentYear = year;
              });
              print("Selected Year => $selectedYear");
              // call api here if needed
              getExpenseDashboardData();
            },
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeroKpiCard(),
                  const SizedBox(height: 18),
                  _ExpenseSummaryCard(),
                  const SizedBox(height: 18),
                  _buildYearSummarySection(),
                  const SizedBox(height: 18),
                  _CategoriesSection(selectedYear: selectedYear),
                  const SizedBox(height: 18),
                  /*_AiInsightsSection(),
                  const SizedBox(height: 24),*/
                ],
              ),
            ),
          ),
          // _AddExpenseBar(),
        ]),
      ),
    );
  }

  String _fmt(double v) =>
      '${GeneralFunctions.currencySymbol}${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')}';

  // ── Year summary (6 KPI boxes) ───────────────────────────────────────
  Widget _buildYearSummarySection() {
    if (ExpenseData.taxYears.isEmpty) {
      return const SizedBox();
    }
    final yr = ExpenseData.taxYears.first;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        decoration: _cardDecoration(),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('${ExpenseData.currentYear} Summary', style: WerlogTextStyles.sectionTitle),
            /*GestureDetector(
              onTap: () => *//*Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const TaxReadySummaryScreen()))*//*{},
              child: const Text('Year Report', style: WerlogTextStyles.sectionTitle*//*link*//*),
            ),*/
          ]),
          const SizedBox(height: 14),
          // Row 1
          Row(children: [
            _SummaryKpiCell(label: 'Total Expenses', value: _fmt(yr.totalExpenses)),
            _SummaryDivider(),
            _SummaryKpiCell(label: 'Est. Deduction', value: _fmt(yr.estDeduction)),
            _SummaryDivider(),
            _SummaryKpiCell(label: 'GST/HST Paid', value: _fmt(yr.gstPaid)),
          ]),
          const SizedBox(height: 14),
          Divider(height: 1, color: WerlogColors.borderLight),
          const SizedBox(height: 14),
          // Row 2
          Row(children: [
            _SummaryKpiCell(label: 'Documents', value: '${yr.documents}', small: true),
            _SummaryDivider(),
            _SummaryKpiCell(label: 'Missing Receipts', value: '${yr.missingReceipts}',
                small: true, valueColor: yr.missingReceipts > 0 ? WerlogColors.coral : null),
            _SummaryDivider(),
            _SummaryKpiCell(
              label: 'Audit Readiness',
              value: '',
              small: true,
              customWidget: Row(children: [
                const Icon(Icons.verified_outlined, color: WerlogColors.teal, size: 15),
                const SizedBox(width: 4),
                Text('${yr.auditReadinessPct}%',
                    style: WerlogTextStyles.txTitle.copyWith(
                        color: WerlogColors.teal, fontSize: 14)),
              ]),
            ),
          ]),
        ]),
      ),
    );
  }



  Future<void> getExpenseDashboardData() async {

    try {

      final response = await ApiService.get(
        context,
        "${Endpoints.EXPENSE_DASHBOARD_DETAILS}$selectedYear",
      );

      print('\nSUCCESS => $response');

      final result = response['result'] == "1";

      if (result) {

        final data = response['data'] ?? {};

        final totalExpenseAndTax = data['totalExpesneAndTax'] ?? {};
        final summaryExpense = data['summaryExpense'] ?? {};
        final expenseCategories = data['expenseCategories'] ?? [];

        setState(() {

          // =========================================================
          // TOP KPI SECTION
          // =========================================================

          ExpenseData.totalExpenses =
              (totalExpenseAndTax['totalexpense'] ?? 0).toDouble();

          ExpenseData.estDeduction =
              (totalExpenseAndTax['totalIncomeTax'] ?? 0).toDouble();

          ExpenseData.gstHstClaimable =
              (totalExpenseAndTax['totalHstTax'] ?? 0).toDouble();

          ExpenseData.taxRefundForecast =
              (totalExpenseAndTax['forcastReturn'] ?? 0).toDouble();

          // =========================================================
          // DONUT SUMMARY SECTION
          // =========================================================

          ExpenseData.deductibleAmt = double.tryParse(
            summaryExpense['totalIncomeTax']
                ?.toString()
                .replaceAll('%', '') ?? '0',
          ) ?? 0;

          ExpenseData.gstPaidAmt = double.tryParse(
            summaryExpense['totalHstTax']
                ?.toString()
                .replaceAll('%', '') ?? '0',
          ) ?? 0;

          ExpenseData.nonDeductibleAmt = double.tryParse(
            summaryExpense['nonDeductable']
                ?.toString()
                .replaceAll('%', '') ?? '0',
          ) ?? 0;

          ExpenseData.personalAmt = double.tryParse(
            summaryExpense['personal']
                ?.toString()
                .replaceAll('%', '') ?? '0',
          ) ?? 0;

          // =========================================================
          // EXPENSE CATEGORIES
          // =========================================================

          ExpenseData.categories.clear();

          for (int i = 0; i < expenseCategories.length; i++) {

            final item = expenseCategories[i];

            final colors = [
              {
                'bg': const Color(0xFFE8F5E9),
                'color': const Color(0xFF2E7D32),
                'icon': Icons.directions_car_rounded,
              },
              {
                'bg': const Color(0xFFE3F2FD),
                'color': const Color(0xFF1565C0),
                'icon': Icons.home_work_rounded,
              },
              {
                'bg': const Color(0xFFF3E5F5),
                'color': const Color(0xFF6A1B9A),
                'icon': Icons.inventory_2_rounded,
              },
              {
                'bg': const Color(0xFFFFF3E0),
                'color': const Color(0xFFE65100),
                'icon': Icons.campaign_rounded,
              },
            ];

            final style = colors[i % colors.length];

            ExpenseData.categories.add(
              ExpenseCategory(
                id: item['id']
                    .toString()
                    .toLowerCase()
                    .replaceAll(' ', '_'),

                name: item['expenseName'] ?? '',

                description:
                '${item['expenseName'] ?? ''} related expenses.',

                icon: style['icon'] as IconData,

                iconBg: style['bg'] as Color,

                iconColor: style['color'] as Color,

                totalSpent:
                (item['expenseTotal'] ?? 0).toDouble(),

                deductiblePct: 0,

                gstPaid: 0,

                missingCount: item['counter'] ?? 0,

                items: [],
              ),
            );
          }
        });

      } else {
        GeneralFunctions.showError(
          context,
          response['message'].toString(),
        );
      }
    } catch (e) {
      print('ERROR => $e');
      GeneralFunctions.showError(
        context,
        "Process interrupted. Please try again!",
      );
    }

    getExpenseTaxYearData();
  }

  Future<void> getExpenseTaxYearData() async {
    try {
      final response = await ApiService.get(
        context,
        Endpoints.EXPENSE_TAX_YEARS,
      );

      print('\nSUCCESS => $response');

      final result = response['result'] == "1";

      if (result) {
        final data = response['data'] ?? {};

        final years = List<Map<String, dynamic>>.from(
          data['years'] ?? [],
        );

        final summary = data['summary'] ?? {};

        final monthly = List<Map<String, dynamic>>.from(
          data['monthly'] ?? [],
        );

        setState(() {

          // =========================================================
          // MONTHLY DATA
          // =========================================================

          final monthlyData = monthly.map((e) {
            return MonthlyExpense(
              month: e['label']?.toString() ?? '',
              expenses: (e['expenses'] ?? 0).toDouble(),

              // API greenDot → deduction
              deduction: (e['greenDot'] ?? 0).toDouble(),

              // API purpleDot → gst
              gst: (e['purpleDot'] ?? 0).toDouble(),
            );
          }).toList();

          // =========================================================
          // TAX YEARS
          // =========================================================

          ExpenseData.taxYears = years.map((e) {
            return TaxYear(
              year: e['year'] ?? 0,

              // Example: "So far"
              status: e['statusLabel']?.toString() ?? '',

              totalExpenses:
              (summary['totalExpenses'] ?? 0).toDouble(),

              estDeduction:
              (summary['estimatedDeduction'] ?? 0).toDouble(),

              gstPaid:
              (summary['gstHstPaid'] ?? 0).toDouble(),

              documents:
              summary['documents'] ?? 0,

              missingReceipts:
              summary['missingReceipts'] ?? 0,

              auditReadinessPct:
              summary['auditReadinessPercent'] ?? 0,

              monthly: monthlyData,
            );
          }).toList();

        });
      } else {
        GeneralFunctions.showError(
          context,
          response['message'].toString(),
        );
      }
    } catch (e) {
      print('ERROR => $e');
      GeneralFunctions.showError(
        context,
        "Process interrupted. Please try again!",
      );
    }
  }

}

// ─── Reusable widgets ──────────────────────────────────────────────────
class _SummaryKpiCell extends StatelessWidget {
  final String label, value;
  final bool small;
  final Color? valueColor;
  final Widget? customWidget;
  const _SummaryKpiCell({
    required this.label, required this.value,
    this.small = false, this.valueColor, this.customWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: WerlogTextStyles.captionSmall),
        const SizedBox(height: 4),
        if (customWidget != null)
          customWidget!
        else
          Text(value, style: TextStyle(
            fontFamily: 'DMSans',
            fontSize: small ? 16 : 18,
            fontWeight: FontWeight.w700,
            color: valueColor ?? WerlogColors.textPrimary,
          )),
      ]),
    );
  }
}

class _SummaryDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 0.8, height: 40, margin: const EdgeInsets.symmetric(horizontal: 10),
      color: WerlogColors.borderLight,
    );
  }
}

// ── Top bar ───────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {

  final String selectedYear;
  final List<String> years;
  final Function(String year) onYearChanged;

  const _TopBar({
    required this.selectedYear,
    required this.years,
    required this.onYearChanged,
  });


  @override
  Widget build(BuildContext context) {
    return Container(
      color: WerlogColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [

          GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
            },
            child: Icon(
              Icons.arrow_back,
              size: 22,
              color: WerlogColors.textPrimary,
            ),
          ),

          const Expanded(
            child: Text(
              'Expenses & Tax',
              textAlign: TextAlign.center,
              style: WerlogTextStyles.pageTitle,
            ),
          ),

          Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: WerlogColors.tealSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: WerlogColors.border,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedYear,
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: WerlogColors.textPrimary,
                  size: 18,
                ),
                dropdownColor: WerlogColors.surface,
                style: WerlogTextStyles.body.copyWith(
                  color: WerlogColors.textPrimary,
                  fontSize: 13,
                ),
                items: years.map((year) {
                  return DropdownMenuItem<String>(
                    value: year,
                    child: Text(year),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    onYearChanged(value);
                  }
                },
              ),
            ),
          ),

        ],
      ),
    );
  }
}

class _NotifIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      const Icon(Icons.notifications_outlined, size: 22, color: WerlogColors.textPrimary),
      Positioned(
        top: 0, right: 0,
        child: Container(
          width: 8, height: 8,
          decoration: const BoxDecoration(color: WerlogColors.coral, shape: BoxShape.circle),
        ),
      ),
    ]);
  }
}

// ── Hero KPI card (teal gradient) ────────────────────────────────────
class _HeroKpiCard extends StatelessWidget {
  String _fmt(double v) =>
      '${GeneralFunctions.currencySymbol}${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')}';

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      decoration: BoxDecoration(
        gradient: WerlogGradients.heroTeal,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: WerlogColors.teal.withOpacity(0.28),
              blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(children: [
        // Title row
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Row(children: [
            Text('Tax Savings Overview (${ExpenseData.currentYear})',
                style: WerlogTextStyles.kpiLabel.copyWith(fontSize: 11)),
            const SizedBox(width: 4),
            const Icon(Icons.info_outline_rounded, size: 13, color: Color(0xAAFFFFFF)),
          ]),
        ),
        const SizedBox(height: 10),
        // KPI row (scrollable)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: IntrinsicHeight(
            child: Row(children: [
              _KpiItem(label: 'Total Expenses', value: _fmt(ExpenseData.totalExpenses)),
              _KpiDivider(),
              _KpiItem(label: 'Est. Deduction', value: _fmt(ExpenseData.estDeduction)),
              _KpiDivider(),
              _KpiItem(label: 'GST/HST Claimable', value: _fmt(ExpenseData.gstHstClaimable)),
              /*_KpiDivider(),
              _KpiItem(
                label: 'Tax Refund Forecast',
                value: _fmt(ExpenseData.taxRefundForecast),
                isHighlight: true,
              ),*/
            ]),
          ),
        ),
        const SizedBox(height: 16),
      ]),
    );
  }
}

class _KpiItem extends StatelessWidget {
  final String label, value;
  final bool isHighlight;
  const _KpiItem({required this.label, required this.value, this.isHighlight = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: WerlogTextStyles.kpiLabel),
        const SizedBox(height: 4),
        Row(children: [
          Text(value,
              style: isHighlight ? WerlogTextStyles.kpiValueGreen : WerlogTextStyles.kpiValue),
          if (isHighlight) ...[
            const SizedBox(width: 4),
            const Icon(Icons.trending_up_rounded, color: Color(0xFF5DCAA5), size: 16),
          ],
        ]),
      ]),
    );
  }
}

class _KpiDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 0.8, margin: const EdgeInsets.only(right: 20),
      color: Colors.white.withOpacity(0.25),
    );
  }
}

// ── Expense Summary card (donut + legend) ────────────────────────────
class _ExpenseSummaryCard extends StatelessWidget {
  String _fmt(double v) =>
      '${GeneralFunctions.currencySymbol}${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')}';

  String _pct(double part) =>
      '(${(part / ExpenseData.totalExpenses * 100).toStringAsFixed(0)}%)';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        decoration: _cardDecoration(),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Expense Summary (${ExpenseData.currentYear})',
                style: WerlogTextStyles.sectionTitle),
            GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const TaxYearsScreen())),
              child: const Text('View Reports', style: WerlogTextStyles.link),
            ),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            // Donut
            SizedBox(
              width: 110, height: 110,
              child: Stack(alignment: Alignment.center, children: [
                CustomPaint(
                  size: const Size(110, 110),
                  painter: _DonutPainter(segments: [
                    _Seg(ExpenseData.deductibleAmt,    WerlogColors.teal),
                    _Seg(ExpenseData.gstPaidAmt,       WerlogColors.blue),
                    _Seg(ExpenseData.nonDeductibleAmt, WerlogColors.orange),
                    _Seg(ExpenseData.personalAmt,      WerlogColors.coral),
                  ]),
                ),
                Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(_fmt(ExpenseData.totalExpenses),
                      style: WerlogTextStyles.txTitle.copyWith(fontSize: 13)),
                  const Text('Total Spent',
                      style: WerlogTextStyles.captionSmall),
                ]),
              ]),
            ),
            const SizedBox(width: 20),
            // Legend
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _LegendRow(color: WerlogColors.teal,   label: 'Deductible',
                  amount: _fmt(ExpenseData.deductibleAmt),   pct: _pct(ExpenseData.deductibleAmt)),
              const SizedBox(height: 10),
              _LegendRow(color: WerlogColors.blue,   label: 'GST/HST Paid',
                  amount: _fmt(ExpenseData.gstPaidAmt),      pct: _pct(ExpenseData.gstPaidAmt)),
              const SizedBox(height: 10),
              _LegendRow(color: WerlogColors.orange, label: 'Non-deductible',
                  amount: _fmt(ExpenseData.nonDeductibleAmt),pct: _pct(ExpenseData.nonDeductibleAmt)),
              const SizedBox(height: 10),
              _LegendRow(color: WerlogColors.coral,  label: 'Personal',
                  amount: _fmt(ExpenseData.personalAmt),     pct: _pct(ExpenseData.personalAmt)),
            ])),
          ]),
        ]),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label, amount, pct;
  const _LegendRow({required this.color, required this.label, required this.amount, required this.pct});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 9, height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 8),
      Expanded(child: Text(label, style: WerlogTextStyles.captionSmall)),
      Text(amount, style: const TextStyle(
          fontFamily: 'DMSans', fontSize: 11, fontWeight: FontWeight.w600,
          color: WerlogColors.textPrimary)),
      const SizedBox(width: 4),
      Text(pct, style: WerlogTextStyles.captionSmall),
    ]);
  }
}

// ── Categories section ────────────────────────────────────────────────
class _CategoriesSection extends StatelessWidget {
  final String selectedYear;
  const _CategoriesSection({
    required this.selectedYear,
  });

  @override
  Widget build(BuildContext context) {
    final cats = ExpenseData.categories;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Expense Categories', style: WerlogTextStyles.sectionTitle),
          /*GestureDetector(
            onTap: () {},
            child: const Text('View All', style: WerlogTextStyles.link),
          ),*/
        ]),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.05,
          ),
          itemCount: cats.length,
          itemBuilder: (_, i) => _CategoryTile(cat: cats[i], selectedYear: selectedYear),
        ),
      ]),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final ExpenseCategory cat;
  final String selectedYear;

  const _CategoryTile({required this.cat, required this.selectedYear});

  String _fmt(double v) =>
      '${GeneralFunctions.currencySymbol}${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')}';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ExpenseCategoryDetailScreen(
            category: cat,
            catId: cat.id,
            selectedYear: selectedYear,
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: WerlogColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: WerlogColors.border, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔝 TOP SECTION (flexible)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: cat.iconBg,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(cat.icon, color: cat.iconColor, size: 17),
                ),
                const SizedBox(width: 8),

                // 🔥 TEXT AREA FLEXIBLE (prevents overflow)
                Expanded(
                  child: Text(
                    cat.name,
                    maxLines: 3, // allow growth safely
                    overflow: TextOverflow.ellipsis,
                    style: WerlogTextStyles.captionSmall.copyWith(
                      color: WerlogColors.textPrimary,
                      fontWeight: FontWeight.w500,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),

            // 🔥 SPACER pushes bottom content safely
            const Spacer(),

            // 🔻 BOTTOM SECTION (always visible)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // amount (flex safe)
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _fmt(cat.totalSpent),
                    style: WerlogTextStyles.cardTitle.copyWith(fontSize: 12),
                  ),
                ),

                const SizedBox(height: 2),

                // missing text (flex safe)
                Text(
                  cat.missingCount > 0
                      ? '${cat.missingCount} Missing'
                      : '0 Missing',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: WerlogTextStyles.captionSmall.copyWith(
                    color: cat.missingCount > 0
                        ? WerlogColors.coral
                        : WerlogColors.textTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── AI Tax Insights ───────────────────────────────────────────────────
class _AiInsightsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        decoration: _cardDecoration(),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  gradient: WerlogGradients.heroTeal,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 15),
              ),
              const SizedBox(width: 8),
              const Text('AI Tax Insights', style: WerlogTextStyles.cardTitle),
            ]),
            const Text('View All', style: WerlogTextStyles.link),
          ]),
          const SizedBox(height: 12),
          ...ExpenseData.aiInsights.map((ins) => _InsightRow(
              text: ins['text']!, type: ins['type']!)),
        ]),
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  final String text, type;
  const _InsightRow({required this.text, required this.type});

  @override
  Widget build(BuildContext context) {
    final isWarning = type == 'warning';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 20, height: 20, margin: const EdgeInsets.only(top: 1),
          decoration: BoxDecoration(
            color: isWarning ? WerlogColors.amberSurface : WerlogColors.tealSurface,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Icon(
            isWarning ? Icons.warning_amber_rounded : Icons.lightbulb_outline_rounded,
            color: isWarning ? WerlogColors.amber : WerlogColors.teal, size: 12,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: WerlogTextStyles.bodySmall)),
      ]),
    );
  }
}

// ── Bottom add-expense bar ────────────────────────────────────────────
class _AddExpenseBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: WerlogColors.surface,
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add_rounded, size: 20),
          label: const Text('Add Expense / Upload Receipt', style: WerlogTextStyles.buttonGhost),
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
//  PAINTERS & HELPERS
// ═══════════════════════════════════════════════════════════════════════
class _Seg {
  final double value;
  final Color color;
  const _Seg(this.value, this.color);
}

class _DonutPainter extends CustomPainter {
  final List<_Seg> segments;
  const _DonutPainter({required this.segments});

  @override
  void paint(Canvas canvas, Size size) {
    final total = segments.fold(0.0, (s, e) => s + e.value);
    if (total == 0) return;
    final rect = Rect.fromLTWH(6, 6, size.width - 12, size.height - 12);
    const stroke = 13.0;
    double start = -math.pi / 2;

    for (final seg in segments) {
      final sweep = (seg.value / total) * 2 * math.pi;
      canvas.drawArc(rect, start, sweep - 0.04, false,
          Paint()
            ..color = seg.color
            ..style = PaintingStyle.stroke
            ..strokeWidth = stroke
            ..strokeCap = StrokeCap.butt);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter o) => false;
}

BoxDecoration _cardDecoration() => BoxDecoration(
  color: WerlogColors.surface,
  borderRadius: BorderRadius.circular(16),
  border: Border.all(color: WerlogColors.border, width: 0.8),
  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
      blurRadius: 8, offset: const Offset(0, 2))],
);
