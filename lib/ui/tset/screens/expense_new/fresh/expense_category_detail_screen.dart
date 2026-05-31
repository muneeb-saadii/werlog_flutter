import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:wellness/ui/tset/screens/expense_new/fresh/expense_detail_screen.dart';
import '../../../../../core/api/api_service.dart';
import '../../../../../core/api/endpoints.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/general_functions.dart';
import '../tax_years_screen.dart';
import 'expense_data.dart';



// ═══════════════════════════════════════════════════════════════════════
//  SCREEN — Category Detail Page  (e.g. Medical & Healthcare)
// ═══════════════════════════════════════════════════════════════════════
class ExpenseCategoryDetailScreen extends StatefulWidget {
  final ExpenseCategory category;
  final String catId;        // UUID passed from calling screen
  final String selectedYear;    // e.g. 2026

  const ExpenseCategoryDetailScreen({
    super.key,
    required this.category,
    required this.catId,
    required this.selectedYear,
  });

  @override
  State<ExpenseCategoryDetailScreen> createState() =>
      _ExpenseCategoryDetailScreenState();
}

class _ExpenseCategoryDetailScreenState
    extends State<ExpenseCategoryDetailScreen> {

  // ── State ──────────────────────────────────────────────────────────
  late double _businessUsePct;
  int? _hoveredBarIndex;
  bool _invoicesExpanded = true;   // invoice list open by default

  // API-driven data (null = not yet loaded)
  CategoryDetail? _detail;

  // ── Init ───────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _businessUsePct = widget.category.deductiblePct;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadExpenseCategoryData();
    });
  }

  // ── Convenience getters ────────────────────────────────────────────
  ExpenseCategory get cat => widget.category;

  double get _totalSpent      => _detail?.totalSpent      ?? cat.totalSpent;
  double get _deductibleAmt   => _detail?.deductibleAmount ?? cat.deductibleAmount;
  double get _gstPaid         => _detail?.gstHstPaid       ?? cat.gstPaid;
  String get _currency        => GeneralFunctions.currencySymbol ?? /*_detail?.currency.isNotEmpty == true
      ? _detail!.currency :*/ '\$';
  List<MonthlyExpense> get _monthly =>
      _detail?.monthly ?? ExpenseData.vehicleMonthly;
  List<InvoiceItem> get _invoices => _detail?.recentInvoices ?? [];

  String _fmt(double v) {
    final prefix = _currency.isNotEmpty ? '$_currency ' : '\$';
    return '$prefix${v.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')}';
  }

  // ── Build ──────────────────────────────────────────────────────────
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
                _buildInvoiceSection(),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  // ── App bar ────────────────────────────────────────────────────────
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
        Expanded(
          child: Text(
            _detail?.name ?? cat.name,
            textAlign: TextAlign.center,
            style: WerlogTextStyles.pageTitle,
          ),
        ),
        // Spacer to keep title centred
        const SizedBox(width: 48),
      ]),
    );
  }

  // ── Category header card ───────────────────────────────────────────
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
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_detail?.name ?? cat.name,
                  style: WerlogTextStyles.cardTitle.copyWith(fontSize: 16)),
              const SizedBox(height: 3),
              Text(cat.description,
                  style: WerlogTextStyles.captionSmall, maxLines: 2),
              if (_detail != null && _detail!.invoiceCount > 0) ...[
                const SizedBox(height: 6),
                _Badge(
                  label: '${_detail!.invoiceCount} invoice${_detail!.invoiceCount == 1 ? '' : 's'}',
                  bg: WerlogColors.tealSurface,
                  textColor: WerlogColors.teal,
                ),
              ],
            ],
          )),
        ]),
      ),
    );
  }

  // ── KPI row ────────────────────────────────────────────────────────
  Widget _buildKpiRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(children: [
        _KpiBox(label: 'Total Spent',       value: _fmt(_totalSpent)),
        const SizedBox(width: 10),
        _KpiBox(
          label: 'Deductible (${_businessUsePct.toInt()}%)',
          value: _fmt(_deductibleAmt),
          highlight: true,
        ),
        const SizedBox(width: 10),
        _KpiBox(label: 'GST/HST Paid',      value: _fmt(_gstPaid)),
      ]),
    );
  }

  // ── Business use slider ────────────────────────────────────────────
  Widget _buildBusinessUseCard() {
    final helpText = _detail?.helpText ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        decoration: _cardDecoration(),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Business Use', style: WerlogTextStyles.cardTitle),
            /*GestureDetector(
              onTap: () {},
              child: const Text('Edit', style: WerlogTextStyles.link),
            ),*/
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Text('${_businessUsePct.toInt()}%',
                style: WerlogTextStyles.amountLarge.copyWith(
                    color: WerlogColors.teal, fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: IgnorePointer(
                ignoring: true,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 6,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 9,
                    ),
                    overlayShape: SliderComponentShape.noOverlay,
                    activeTrackColor: WerlogColors.teal,
                    inactiveTrackColor: WerlogColors.border,
                    thumbColor: WerlogColors.teal,
                    disabledActiveTrackColor: WerlogColors.teal,
                    disabledInactiveTrackColor: WerlogColors.border,
                    disabledThumbColor: WerlogColors.teal,
                  ),
                  child: Slider(
                    value: _businessUsePct,
                    min: 0,
                    max: 100,
                    divisions: 20,
                    onChanged: null, // makes slider static / non-editable
                  ),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 4),
          Text(
            helpText.isNotEmpty
                ? helpText
                : 'Set your business use percentage to calculate deductions',
            style: WerlogTextStyles.captionSmall,
          ),
        ]),
      ),
    );
  }

  // ── Monthly bar chart ──────────────────────────────────────────────
  Widget _buildMonthlyChart() {
    final maxVal = _monthly.fold(0.0, (m, e) => e.expenses > m ? e.expenses : m);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        decoration: _cardDecoration(),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Monthly Breakdown (${widget.selectedYear})',
                style: WerlogTextStyles.cardTitle),
            GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const TaxYearsScreen())),
              child: const Text('View Year', style: WerlogTextStyles.link),
            ),
          ]),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              // Y-axis labels
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final label in [_fmt(maxVal), _fmt(maxVal * 0.75),
                    _fmt(maxVal * 0.5), _fmt(maxVal * 0.25), '0'])
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
                        final barH = maxVal > 0
                            ? (m.expenses / maxVal) * 120
                            : 0.0;
                        final isHovered = _hoveredBarIndex == idx;

                        return Expanded(
                          child: GestureDetector(
                            onTapDown: (_) =>
                                setState(() => _hoveredBarIndex = idx),
                            onTapUp: (_) =>
                                setState(() => _hoveredBarIndex = null),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (isHovered)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: WerlogColors.darkTeal,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${m.month}\n${_fmt(m.expenses)}',
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 8,
                                          fontFamily: 'DMSans', height: 1.3),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                const SizedBox(height: 3),
                                Container(
                                  height: barH.clamp(m.expenses > 0 ? 4.0 : 0.0, 130.0),
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  decoration: BoxDecoration(
                                    color: isHovered
                                        ? WerlogColors.darkTeal
                                        : (m.expenses > 0
                                        ? WerlogColors.teal
                                        : WerlogColors.border),
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(4)),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(m.month,
                                    style: WerlogTextStyles.captionSmall
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

  // ── Invoice section ────────────────────────────────────────────────
  Widget _buildInvoiceSection() {
    if (_detail == null) return const SizedBox.shrink();
    if (_invoices.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Container(
          decoration: _cardDecoration(),
          padding: const EdgeInsets.all(20),
          child: Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: WerlogColors.tealSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.receipt_long_rounded,
                  color: WerlogColors.teal, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('No Invoices Yet', style: WerlogTextStyles.cardTitle),
                SizedBox(height: 3),
                Text('Uploaded receipts for this category will appear here.',
                    style: WerlogTextStyles.captionSmall),
              ],
            )),
          ]),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Section heading card (tap to expand / collapse) ───────────
        GestureDetector(
          onTap: () => setState(() => _invoicesExpanded = !_invoicesExpanded),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [WerlogColors.darkTeal, Color(0xFF1A4A50)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(
                top: const Radius.circular(16),
                // When collapsed the card stands alone — round all corners.
                bottom: Radius.circular(_invoicesExpanded ? 0 : 16),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.receipt_long_rounded,
                    color: Colors.white, size: 17),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Recent Invoices',
                      style: TextStyle(
                        fontFamily: 'DMSans', fontSize: 14,
                        fontWeight: FontWeight.w600, color: Colors.white,
                      )),
                  Text('${_invoices.length} receipt${_invoices.length == 1 ? '' : 's'} found',
                      style: TextStyle(
                        fontFamily: 'DMSans', fontSize: 10,
                        color: Colors.white.withOpacity(0.65),
                      )),
                ],
              )),

              // Animated chevron — up when expanded, down when collapsed
              AnimatedRotation(
                turns: _invoicesExpanded ? 0.0 : 0.5,   // 0° → 180°
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: const Icon(Icons.keyboard_arrow_up_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
            ]),
          ),
        ),

        // ── Invoice list card (animated show/hide) ────────────────────
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 260),
          sizeCurve: Curves.easeInOut,
          firstCurve: Curves.easeInOut,
          secondCurve: Curves.easeInOut,
          crossFadeState: _invoicesExpanded
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          secondChild: const SizedBox.shrink(),
          firstChild: Container(
            decoration: BoxDecoration(
              color: WerlogColors.surface,
              borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(16)),
              border: Border.all(color: WerlogColors.border, width: 0.8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8, offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: _invoices.length,
              separatorBuilder: (_, __) => Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                color: const Color(0xFFD8D6CE),   // slightly darker than borderLight
              ),
              itemBuilder: (context, index) =>
                  _InvoiceCard(invoice: _invoices[index], currency: _currency, onResult: (){
                    loadExpenseCategoryData();
                  }),
            ),
          ),         // end firstChild Container
        ),         // end AnimatedCrossFade
      ]),
    );
  }

  // ── API ────────────────────────────────────────────────────────────
  Future<void> loadExpenseCategoryData() async {
    try {
      final response = await ApiService.get(
        context,
        '${Endpoints.EXPENSE_CATEGORY_DETAILS}${widget.catId}?year=${widget.selectedYear}',
      );

      debugPrint('\nSUCCESS => $response');

      final result = response['result'] == '1';

      if (result) {
        final data = response['data'] as Map<String, dynamic>? ?? {};
        setState(() {
          _detail = CategoryDetail.fromJson(data);
          // Sync business-use slider from API
          _businessUsePct = _detail!.businessUsePercent.toDouble();
        });
      } else {
        GeneralFunctions.showError(
          context,
          response['message']?.toString() ?? 'Something went wrong.',
        );
      }
    } catch (e) {
      debugPrint('ERROR => $e');
      GeneralFunctions.showError(
        context,
        'Process interrupted. Please try again!',
      );
    }
  }
}

// ══════════════════════════════════════════════════════════════════════
//  Invoice card — full-width item inside the list
// ══════════════════════════════════════════════════════════════════════
class _InvoiceCard extends StatelessWidget {
  final InvoiceItem invoice;
  final String currency;
  final VoidCallback  onResult;

  const _InvoiceCard({required this.invoice, required this.currency, required this.onResult});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ExpenseDetailScreen(
              item: invoice,
              imageUrls: invoice.imageUrls,
            ),
          ),
        );

        if (result == true) {
          onResult.call(); // refresh your API / list
        }
      }, // open invoice detail
      borderRadius: BorderRadius.circular(0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Thumbnail / placeholder
          _InvoiceThumbnail(url: invoice.thumbnailUrl),
          const SizedBox(width: 12),

          // Main content
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vendor + amount row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(invoice.vendorName,
                        style: WerlogTextStyles.txTitle.copyWith(fontSize: 13),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${currency.isNotEmpty ? currency : 'PKR'} ${invoice.totalAmount.toStringAsFixed(2)}',
                    style: WerlogTextStyles.txAmount.copyWith(
                        fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 5),

              // Date + subcategory
              Row(children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 10, color: WerlogColors.textTertiary),
                const SizedBox(width: 4),
                Text(invoice.formattedDate, style: WerlogTextStyles.captionSmall),
                const SizedBox(width: 8),
                Container(
                  width: 3, height: 3,
                  decoration: const BoxDecoration(
                    color: WerlogColors.textTertiary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(invoice.subcategoryName,
                      style: WerlogTextStyles.captionSmall,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ]),
              const SizedBox(height: 8),

              // Line items preview (up to 2)
              if (invoice.items.isNotEmpty)
                ...invoice.items.take(2).map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(children: [
                    Container(
                      width: 4, height: 4,
                      margin: const EdgeInsets.only(right: 6, top: 1),
                      decoration: BoxDecoration(
                        color: WerlogColors.teal.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(item.description,
                          style: WerlogTextStyles.captionSmall
                              .copyWith(color: WerlogColors.textSecondary),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    Text(
                      '${currency.isNotEmpty ? currency : 'PKR'} ${item.amount.toStringAsFixed(0)}',
                      style: WerlogTextStyles.captionSmall
                          .copyWith(color: WerlogColors.textSecondary),
                    ),
                  ]),
                )),

              if (invoice.items.length > 2) ...[
                const SizedBox(height: 2),
                Text('+${invoice.items.length - 2} more item${invoice.items.length - 2 == 1 ? '' : 's'}',
                    style: WerlogTextStyles.captionSmall
                        .copyWith(color: WerlogColors.teal)),
              ],

              const SizedBox(height: 8),

              // Badge row
              Row(children: [
                if (invoice.autoCategorized)
                  _Badge(
                    label: 'Auto-categorized',
                    bg: WerlogColors.tealSurface,
                    textColor: WerlogColors.teal,
                    icon: Icons.auto_awesome_rounded,
                  ),
                if (invoice.autoCategorized && invoice.needsReview)
                  const SizedBox(width: 6),
                if (invoice.needsReview)
                  _Badge(
                    label: 'Needs review',
                    bg: WerlogColors.amberSurface,
                    textColor: WerlogColors.amber,
                    icon: Icons.warning_amber_rounded,
                  ),
              ]),
            ],
          )),

          // Chevron
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.chevron_right_rounded,
                color: WerlogColors.textTertiary, size: 18),
          ),
        ]),
      ),
    );
  }
}

// ── Thumbnail widget ──────────────────────────────────────────────────
class _InvoiceThumbnail extends StatelessWidget {
  final String? url;
  const _InvoiceThumbnail({this.url});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52, height: 52,
      decoration: BoxDecoration(
        color: WerlogColors.tealLightSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: WerlogColors.border, width: 0.8),
      ),
      clipBehavior: Clip.antiAlias,
      child: url != null && url!.isNotEmpty
          ? Image.network(
        'https://werlog.com$url',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const _ThumbnailPlaceholder(),
        loadingBuilder: (_, child, progress) => progress == null
            ? child
            : const Center(
          child: SizedBox(
            width: 18, height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: WerlogColors.teal,
            ),
          ),
        ),
      )
          : const _ThumbnailPlaceholder(),
    );
  }
}

class _ThumbnailPlaceholder extends StatelessWidget {
  const _ThumbnailPlaceholder();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(Icons.receipt_rounded,
          color: WerlogColors.teal, size: 22),
    );
  }
}

// ── Badge widget ──────────────────────────────────────────────────────
class _Badge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color textColor;
  final IconData? icon;

  const _Badge({
    required this.label,
    required this.bg,
    required this.textColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon, size: 9, color: textColor),
          const SizedBox(width: 3),
        ],
        Text(label,
            style: TextStyle(
              fontFamily: 'DMSans', fontSize: 9,
              fontWeight: FontWeight.w500, color: textColor,
            )),
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
            color: highlight
                ? WerlogColors.teal.withOpacity(0.3)
                : WerlogColors.border,
            width: 0.8,
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: WerlogTextStyles.captionSmall),
          const SizedBox(height: 4),
          Text(value,
              style: WerlogTextStyles.amountLarge.copyWith(
                  fontSize: 14,
                  color: highlight
                      ? WerlogColors.teal
                      : WerlogColors.textPrimary)),
        ]),
      ),
    );
  }
}

// ── Card decoration ───────────────────────────────────────────────────
BoxDecoration _cardDecoration() => BoxDecoration(
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