import 'package:flutter/material.dart';
import 'package:wellness/core/utils/general_functions.dart';
import '../../../../core/theme/app_theme.dart';
import 'fresh/expense_data.dart';
import 'tax_ready_summary_screen.dart';

// ═══════════════════════════════════════════════════════════════════════
//  SCREEN 3 — Tax Years Archive + Monthly View
// ═══════════════════════════════════════════════════════════════════════
class TaxYearsScreen extends StatefulWidget {
  const TaxYearsScreen({super.key});

  @override
  State<TaxYearsScreen> createState() => _TaxYearsScreenState();
}

class _TaxYearsScreenState extends State<TaxYearsScreen> {
  // Currently selected year index into ExpenseData.taxYears
  // Default to index 1 (year 2025 = "Current Year")
  int _selectedIdx = 0;

  TaxYear get _selected {
    if (ExpenseData.taxYears.isEmpty) {
      return TaxYear(
        year: DateTime.now().year,
        status: '',
        totalExpenses: 0,
        estDeduction: 0,
        gstPaid: 0,
        documents: 0,
        missingReceipts: 0,
        auditReadinessPct: 0,
        monthly: [],
      );
    }
    // Prevent RangeError
    if (_selectedIdx >= ExpenseData.taxYears.length) {
      _selectedIdx = 0;
    }
    return ExpenseData.taxYears[_selectedIdx];
  }

  String _fmt(double v) =>
      '${GeneralFunctions.currencySymbol}${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WerlogColors.background,
      body: SafeArea(
        child: Column(children: [
          _buildAppBar(context),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildYearSelector(),
                  const SizedBox(height: 18),
                  _buildYearSummarySection(),
                  const SizedBox(height: 18),
                  _buildMonthlyViewSection(),
                  const SizedBox(height: 18),
                  /*_buildAiInsightCard(),
                  const SizedBox(height: 30),*/
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // ── App bar ──────────────────────────────────────────────────────────
  Widget _buildAppBar(BuildContext context) {
    return Container(
      color: WerlogColors.surface,
      padding: const EdgeInsets.fromLTRB(8, 10, 16, 10),
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18,
              color: WerlogColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        const Expanded(
          child: Text('Tax Years', textAlign: TextAlign.center,
              style: WerlogTextStyles.pageTitle),
        ),
        // Icon(Icons.calendar_today_outlined, size: 20, color: WerlogColors.textPrimary),
      ]),
    );
  }

  // ── Year selector horizontal scroll ─────────────────────────────────
  Widget _buildYearSelector() {
    return Container(
      color: WerlogColors.surface,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Row(
          children: ExpenseData.taxYears.asMap().entries.map((e) {
            final idx = e.key;
            final year = e.value;
            final isSelected = _selectedIdx == idx;

            return GestureDetector(
              onTap: () => setState(() => _selectedIdx = idx),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? WerlogColors.teal : WerlogColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? WerlogColors.teal : WerlogColors.border,
                    width: isSelected ? 0 : 0.8,
                  ),
                  boxShadow: isSelected
                      ? [BoxShadow(color: WerlogColors.teal.withOpacity(0.3),
                          blurRadius: 10, offset: const Offset(0, 4))]
                      : [],
                ),
                child: Column(children: [
                  Text(
                    year.status == 'So far' ? '${year.year}\n(So far)'
                        : year.status == 'Current Year' ? '${year.year}\nCurrent Year'
                        : '${year.year}\nFiled',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'DMSans', fontSize: 11,
                      fontWeight: FontWeight.w500, height: 1.4,
                      color: isSelected ? Colors.white : WerlogColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _fmt(year.totalExpenses),
                    style: TextStyle(
                      fontFamily: 'DMSans', fontSize: 13, fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : WerlogColors.textPrimary,
                    ),
                  ),
                ]),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Year summary (6 KPI boxes) ───────────────────────────────────────
  Widget _buildYearSummarySection() {
    if (ExpenseData.taxYears.isEmpty) {
      return const SizedBox();
    }
    final yr = _selected;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        decoration: _cardDecoration(),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('${yr.year} Summary', style: WerlogTextStyles.sectionTitle),
            /*GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const TaxReadySummaryScreen())),
              child: const Text('Download Year Report', style: WerlogTextStyles.link),
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

  // ── Monthly view grid ────────────────────────────────────────────────
  Widget _buildMonthlyViewSection() {
    final monthly = _selected.monthly;
    if (monthly.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Container(
          decoration: _cardDecoration(),
          padding: const EdgeInsets.all(20),
          child: const Center(
            child: Text('Monthly data not available for filed years.',
                style: WerlogTextStyles.bodySmall),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        decoration: _cardDecoration(),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('Monthly View – ${_selected.year}',
                style: WerlogTextStyles.sectionTitle),
          ]),
          const SizedBox(height: 8),
          // Legend
          Row(children: [
            _MonthLegendDot(color: WerlogColors.teal,   label: 'Expenses'),
            const SizedBox(width: 14),
            _MonthLegendDot(color: WerlogColors.blue,   label: 'Deduction'),
            const SizedBox(width: 14),
            _MonthLegendDot(color: WerlogColors.purple, label: 'GST/HST'),
          ]),
          const SizedBox(height: 14),
          // 3-column grid of months
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.15,
            ),
            itemCount: monthly.length,
            itemBuilder: (_, i) => _MonthCell(data: monthly[i]),
          ),
        ]),
      ),
    );
  }

  // ── AI Insight card ──────────────────────────────────────────────────
  Widget _buildAiInsightCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        decoration: _cardDecoration(),
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              gradient: WerlogGradients.heroTeal,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 17),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Your expenses are 12% higher than last year. You\'re on track\nto claim \$1,240 more in deductions.',
              style: WerlogTextStyles.bodySmall,
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: WerlogColors.textTertiary, size: 18),
        ]),
      ),
    );
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

class _MonthLegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _MonthLegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 8, height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: WerlogTextStyles.captionSmall),
    ]);
  }
}

class _MonthCell extends StatelessWidget {
  final MonthlyExpense data;
  const _MonthCell({required this.data});

  String _fmt(double v) => '${GeneralFunctions.currencySymbol}${v.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')}';

  @override
  Widget build(BuildContext context) {
    final isEmpty = data.expenses == 0;

    return Container(
      decoration: BoxDecoration(
        color: isEmpty ? WerlogColors.surfaceAlt : WerlogColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WerlogColors.border, width: 0.7),
      ),
      padding: const EdgeInsets.all(10),

      // 🔥 THIS IS THE KEY FIX
      child: LayoutBuilder(
        builder: (context, constraints) {
          return FittedBox(
            fit: BoxFit.scaleDown, // 👈 allows shrinking when needed
            alignment: Alignment.topLeft,

            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: constraints.maxWidth,
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Month
                  Text(
                    data.month,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: WerlogTextStyles.label.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 6),

                  if (isEmpty)
                    Text(
                      '—',
                      style: WerlogTextStyles.captionSmall.copyWith(
                        color: WerlogColors.textDisabled,
                      ),
                    )
                  else ...[
                    // Amount
                    Text(
                      _fmt(data.expenses),
                      style: WerlogTextStyles.txTitle.copyWith(fontSize: 12),
                    ),

                    const SizedBox(height: 6),

                    // Deduction
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: WerlogColors.teal,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            '${GeneralFunctions.currencySymbol}${data.deduction.toInt()}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: WerlogTextStyles.captionSmall.copyWith(fontSize: 9),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 2),

                    // GST
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: WerlogColors.purple,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            '${GeneralFunctions.currencySymbol}${data.gst.toInt()}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: WerlogTextStyles.captionSmall.copyWith(fontSize: 9),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // @override
  Widget build_(BuildContext context) {
    final isEmpty = data.expenses == 0;

    return Container(
      decoration: BoxDecoration(
        color: isEmpty ? WerlogColors.surfaceAlt : WerlogColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WerlogColors.border, width: 0.7),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(data.month,
            style: WerlogTextStyles.label.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        if (isEmpty)
          Text('—', style: WerlogTextStyles.captionSmall.copyWith(color: WerlogColors.textDisabled))
        else ...[
          Text(_fmt(data.expenses),
              style: WerlogTextStyles.txTitle.copyWith(fontSize: 12)),
          const SizedBox(height: 4),
          // Mini bar trio
          /*_MiniBar(value: data.deduction, max: data.expenses, color: WerlogColors.teal),
          const SizedBox(height: 2),
          _MiniBar(value: data.gst, max: data.expenses, color: WerlogColors.purple),*/
          const SizedBox(height: 4),
          Row(children: [
            Container(width: 6, height: 6,
                decoration: const BoxDecoration(color: WerlogColors.teal, shape: BoxShape.circle)),
            const SizedBox(width: 3),
            Text('${GeneralFunctions.currencySymbol}${data.deduction.toInt()}',
                style: WerlogTextStyles.captionSmall.copyWith(fontSize: 9)),
          ]),
          Row(children: [
            Container(width: 6, height: 6,
                decoration: const BoxDecoration(color: WerlogColors.purple, shape: BoxShape.circle)),
            const SizedBox(width: 3),
            Text('${GeneralFunctions.currencySymbol}${data.gst.toInt()}',
                style: WerlogTextStyles.captionSmall.copyWith(fontSize: 9)),
          ]),
        ],
      ]),
    );
  }
}

class _MiniBar extends StatelessWidget {
  final double value, max;
  final Color color;
  const _MiniBar({required this.value, required this.max, required this.color});

  @override
  Widget build(BuildContext context) {
    final ratio = max > 0 ? (value / max).clamp(0.0, 1.0) : 0.0;
    return LayoutBuilder(builder: (_, c) {
      return Stack(children: [
        Container(height: 3, width: c.maxWidth, color: WerlogColors.borderLight,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(2))),
        Container(height: 3, width: c.maxWidth * ratio, color: color,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(2))),
      ]);
    });
  }
}

BoxDecoration _cardDecoration() => BoxDecoration(
  color: WerlogColors.surface,
  borderRadius: BorderRadius.circular(16),
  border: Border.all(color: WerlogColors.border, width: 0.8),
  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
      blurRadius: 8, offset: const Offset(0, 2))],
);
