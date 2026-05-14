import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'expense_data.dart';
import 'tax_years_screen.dart';

// ═══════════════════════════════════════════════════════════════════════
//  SCREEN 2 — Category Detail Page  (e.g. Vehicle & Fuel)
// ═══════════════════════════════════════════════════════════════════════
class ExpenseCategoryDetailScreen extends StatefulWidget {
  final ExpenseCategory category;
  const ExpenseCategoryDetailScreen({super.key, required this.category});

  @override
  State<ExpenseCategoryDetailScreen> createState() =>
      _ExpenseCategoryDetailScreenState();
}

class _ExpenseCategoryDetailScreenState
    extends State<ExpenseCategoryDetailScreen> {
  // Business use %  — editable; replace with API patch later
  late double _businessUsePct;
  int? _hoveredBarIndex; // touched bar in chart

  @override
  void initState() {
    super.initState();
    _businessUsePct = widget.category.deductiblePct;
  }

  ExpenseCategory get cat => widget.category;

  // Computed fields
  double get _deductible => cat.totalSpent * _businessUsePct / 100;
  List<MonthlyExpense> get _monthly => ExpenseData.vehicleMonthly; // swap per category

  String _fmt(double v) =>
      '\$${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')}';

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
              child: Column(children: [
                _buildCategoryHeader(),
                const SizedBox(height: 16),
                _buildKpiRow(),
                const SizedBox(height: 16),
                _buildBusinessUseCard(),
                const SizedBox(height: 16),
                _buildMonthlyChart(),
                const SizedBox(height: 16),
                _buildRecentExpenses(context),
                const SizedBox(height: 16),
                _buildAiAdviceCard(),
                const SizedBox(height: 100),
              ]),
            ),
          ),
          _buildBottomBar(),
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
        Expanded(child: Text(cat.name,
            textAlign: TextAlign.center,
            style: WerlogTextStyles.pageTitle)),
        IconButton(
          icon: const Icon(Icons.more_vert_rounded, size: 20,
              color: WerlogColors.textPrimary),
          onPressed: () {},
        ),
      ]),
    );
  }

  // ── Category header card ─────────────────────────────────────────────
  Widget _buildCategoryHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      child: Container(
        decoration: _cardDecoration(),
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: cat.iconBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(cat.icon, color: cat.iconColor, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(cat.name, style: WerlogTextStyles.cardTitle.copyWith(fontSize: 16)),
            const SizedBox(height: 3),
            Text(cat.description,
                style: WerlogTextStyles.captionSmall, maxLines: 2),
          ])),
        ]),
      ),
    );
  }

  // ── KPI row ──────────────────────────────────────────────────────────
  Widget _buildKpiRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(children: [
        _KpiBox(label: 'Total Spent',       value: _fmt(cat.totalSpent)),
        const SizedBox(width: 10),
        _KpiBox(label: 'Deductible (${_businessUsePct.toInt()}%)',
            value: _fmt(_deductible), highlight: true),
        const SizedBox(width: 10),
        _KpiBox(label: 'GST/HST Paid',      value: _fmt(cat.gstPaid)),
      ]),
    );
  }

  // ── Business use slider ──────────────────────────────────────────────
  Widget _buildBusinessUseCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        decoration: _cardDecoration(),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Business Use', style: WerlogTextStyles.cardTitle),
            GestureDetector(
              onTap: () {},
              child: const Text('Edit', style: WerlogTextStyles.link),
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Text('${_businessUsePct.toInt()}%',
                style: WerlogTextStyles.amountLarge.copyWith(
                    color: WerlogColors.teal, fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 6,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                  activeTrackColor: WerlogColors.teal,
                  inactiveTrackColor: WerlogColors.border,
                  thumbColor: WerlogColors.teal,
                  overlayColor: WerlogColors.teal.withOpacity(0.12),
                ),
                child: Slider(
                  value: _businessUsePct,
                  min: 0, max: 100, divisions: 20,
                  onChanged: (v) => setState(() => _businessUsePct = v),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 4),
          const Text('Set your business use percentage to calculate deductions',
              style: WerlogTextStyles.captionSmall),
        ]),
      ),
    );
  }

  // ── Monthly bar chart ────────────────────────────────────────────────
  Widget _buildMonthlyChart() {
    final maxVal = _monthly.fold(0.0, (m, e) => e.expenses > m ? e.expenses : m);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        decoration: _cardDecoration(),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Monthly Breakdown (${ExpenseData.currentYear})',
                style: WerlogTextStyles.cardTitle),
            GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const TaxYearsScreen())),
              child: const Text('View Year', style: WerlogTextStyles.link),
            ),
          ]),
          const SizedBox(height: 16),
          // Y-axis labels + bars
          SizedBox(
            height: 160,
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              // Y labels
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final label in ['\$1k', '\$800', '\$400', '\$200', '\$0'])
                    Text(label, style: WerlogTextStyles.captionSmall),
                ],
              ),
              const SizedBox(width: 8),
              // Bars
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: SizedBox(
                    width: math.max(
                        MediaQuery.of(context).size.width - 80,
                        _monthly.length * 28.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: _monthly.asMap().entries.map((e) {
                        final idx = e.key;
                        final m = e.value;
                        final barH = maxVal > 0 ? (m.expenses / 1000) * 120 : 0.0;
                        final isHovered = _hoveredBarIndex == idx;

                        return Expanded(
                          child: GestureDetector(
                            onTapDown: (_) => setState(() => _hoveredBarIndex = idx),
                            onTapUp: (_) => setState(() => _hoveredBarIndex = null),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                // Tooltip
                                if (isHovered)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: WerlogColors.darkTeal,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${m.month}\n\$${m.expenses.toInt()}',
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 8,
                                          fontFamily: 'DMSans', height: 1.3),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                const SizedBox(height: 3),
                                Container(
                                  height: barH.clamp(4, 130),
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  decoration: BoxDecoration(
                                    color: isHovered ? WerlogColors.darkTeal : WerlogColors.teal,
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(4)),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(m.month, style: WerlogTextStyles.captionSmall
                                    .copyWith(fontSize: 9)),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  // ── Recent expenses list ─────────────────────────────────────────────
  Widget _buildRecentExpenses(BuildContext context) {
    final items = cat.items;
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        decoration: _cardDecoration(),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Recent Expenses', style: WerlogTextStyles.cardTitle),
            const Text('View All', style: WerlogTextStyles.link),
          ]),
          const SizedBox(height: 12),
          ...items.map((item) => _ExpenseItemRow(item: item)),
        ]),
      ),
    );
  }

  // ── AI Advice card ───────────────────────────────────────────────────
  Widget _buildAiAdviceCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        decoration: BoxDecoration(
          color: WerlogColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: WerlogColors.border, width: 0.8),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              gradient: WerlogGradients.heroTeal,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 15),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Text('AI Tax Advice', style: WerlogTextStyles.cardTitle),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: WerlogColors.teal,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('New',
                    style: TextStyle(color: Colors.white, fontSize: 9,
                        fontFamily: 'DMSans', fontWeight: FontWeight.w600)),
              ),
            ]),
            const SizedBox(height: 6),
            const Text(
              'Your business percentage is not set for some months.\nThis may affect your deduction calculation.',
              style: WerlogTextStyles.bodySmall,
            ),
          ])),
          const Icon(Icons.chevron_right_rounded, color: WerlogColors.textTertiary, size: 18),
        ]),
      ),
    );
  }

  // ── Bottom action bar ────────────────────────────────────────────────
  Widget _buildBottomBar() {
    return Container(
      color: WerlogColors.surface,
      padding: EdgeInsets.fromLTRB(16, 12, 16,
          MediaQuery.of(context).padding.bottom + 12),
      child: Row(children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add_rounded, size: 18, color: WerlogColors.textPrimary),
            label: const Text('Add Expense',
                style: TextStyle(fontFamily: 'DMSans', fontSize: 13,
                    fontWeight: FontWeight.w600, color: WerlogColors.textPrimary)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 13),
              side: const BorderSide(color: WerlogColors.border, width: 1.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.camera_alt_rounded, size: 18, color: Colors.white),
            label: const Text('Upload Receipt', style: WerlogTextStyles.button),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── KPI box ───────────────────────────────────────────────────────────
class _KpiBox extends StatelessWidget {
  final String label, value;
  final bool highlight;
  const _KpiBox({required this.label, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: highlight ? WerlogColors.tealSurface : WerlogColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: highlight ? WerlogColors.teal.withOpacity(0.3) : WerlogColors.border,
            width: 0.8,
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: WerlogTextStyles.captionSmall),
          const SizedBox(height: 4),
          Text(value,
              style: WerlogTextStyles.amountLarge.copyWith(
                  fontSize: 16,
                  color: highlight ? WerlogColors.teal : WerlogColors.textPrimary)),
        ]),
      ),
    );
  }
}

// ── Expense item row ──────────────────────────────────────────────────
class _ExpenseItemRow extends StatelessWidget {
  final ExpenseItem item;
  const _ExpenseItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: item.iconBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(item.icon, color: item.iconColor, size: 19),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.title, style: WerlogTextStyles.txTitle.copyWith(fontSize: 13)),
          const SizedBox(height: 2),
          Row(children: [
            Text(item.date, style: WerlogTextStyles.captionSmall),
            const Text(' • ', style: WerlogTextStyles.captionSmall),
            Text(item.subType, style: WerlogTextStyles.captionSmall),
          ]),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(item.formattedAmount, style: WerlogTextStyles.txAmount),
          const SizedBox(height: 2),
          Text(item.formattedGst,
              style: WerlogTextStyles.captionSmall.copyWith(color: WerlogColors.teal)),
        ]),
      ]),
    );
  }
}

BoxDecoration _cardDecoration() => BoxDecoration(
  color: WerlogColors.surface,
  borderRadius: BorderRadius.circular(16),
  border: Border.all(color: WerlogColors.border, width: 0.8),
  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
      blurRadius: 8, offset: const Offset(0, 2))],
);
