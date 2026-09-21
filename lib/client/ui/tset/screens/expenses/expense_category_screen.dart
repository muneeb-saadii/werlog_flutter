import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'expense_models.dart';
import 'expense_item_detail_screen.dart';

// ══════════════════════════════════════════════════════════════════════════════
//  EXPENSE CATEGORY SCREEN — Screen 2
//  Shows all expense items for a given category with stats, filters, search.
//  Navigation: ExpenseDashboard → ExpenseCategoryScreen → ExpenseItemDetailScreen
// ══════════════════════════════════════════════════════════════════════════════
class ExpenseCategoryScreen extends StatefulWidget {
  final ExpenseCategory category;

  const ExpenseCategoryScreen({super.key, required this.category});

  @override
  State<ExpenseCategoryScreen> createState() => _ExpenseCategoryScreenState();
}

class _ExpenseCategoryScreenState extends State<ExpenseCategoryScreen> {
  String _searchQuery = '';
  String _sortBy = 'Date';           // 'Date' | 'Amount' | 'Status'
  ExpenseStatus? _statusFilter;      // null = show all
  ExpenseType?   _typeFilter;        // null = show all
  bool _listView = true;

  // ── Derived data  (swap for API call) ──────────────────────────────────────
  List<ExpenseItem> get _allItems =>
      ExpenseItemsData.forCategory(widget.category.id);

  List<ExpenseItem> get _filtered {
    var list = _allItems;
    if (_searchQuery.isNotEmpty) {
      list = list.where((e) =>
          e.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.vendor.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }
    if (_statusFilter != null) list = list.where((e) => e.status == _statusFilter).toList();
    if (_typeFilter   != null) list = list.where((e) => e.type   == _typeFilter).toList();

    switch (_sortBy) {
      case 'Amount': list = [...list]..sort((a, b) => b.amount.compareTo(a.amount));
      case 'Status': list = [...list]..sort((a, b) => a.status.index.compareTo(b.status.index));
      default:       list = [...list]..sort((a, b) => b.date.compareTo(a.date));
    }
    return list;
  }

  Map<String, List<ExpenseItem>> get _groupedItems =>
      ExpenseItemsData.groupedByMonth(_filtered);

  Map<String, dynamic> get _stats =>
      ExpenseItemsData.statsForCategory(widget.category.id);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WerlogColors.background,
      body: SafeArea(
        child: Column(children: [
          _buildAppBar(context),
          _StatsHeader(category: widget.category, stats: _stats),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  _buildSummaryCards(),
                  const SizedBox(height: 12),
                  _buildSearchAndFilters(),
                  const SizedBox(height: 10),
                  _buildSortRow(),
                  const SizedBox(height: 12),
                  _buildItemList(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ]),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: WerlogColors.teal,
        icon: const Icon(Icons.add, color: Colors.white, size: 20),
        label: Text('Add Expense', style: WerlogTextStyles.button.copyWith(fontSize: 13)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  // ── App bar ─────────────────────────────────────────────────────────────────
  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: WerlogColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: widget.category.iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(widget.category.icon, color: widget.category.iconColor, size: 17),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(widget.category.name,
              style: WerlogTextStyles.pageTitle.copyWith(fontSize: 17)),
        ),
        IconButton(
          icon: const Icon(Icons.more_vert, color: WerlogColors.textPrimary, size: 22),
          onPressed: () {},
        ),
      ]),
    );
  }

  // ── Summary mini-cards (horizontal scroll) ──────────────────────────────────
  Widget _buildSummaryCards() {
    final stats = _stats;
    final deductPct = stats['totalAmount'] > 0
        ? (stats['totalDeductible'] / stats['totalAmount'] * 100).toStringAsFixed(0)
        : '0';

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(children: [
        _SummaryMiniCard(
            icon: Icons.receipt_long_outlined,
            iconColor: WerlogColors.teal,
            label: 'Total Spent',
            value: '\$${(stats['totalAmount'] as double).toStringAsFixed(2)}'),
        const SizedBox(width: 10),
        _SummaryMiniCard(
            icon: Icons.percent,
            iconColor: WerlogColors.amber,
            label: 'GST Paid',
            value: '\$${(stats['totalGst'] as double).toStringAsFixed(2)}'),
        const SizedBox(width: 10),
        _SummaryMiniCard(
            icon: Icons.savings_outlined,
            iconColor: WerlogColors.teal,
            label: 'Deductible',
            value: '\$${(stats['totalDeductible'] as double).toStringAsFixed(2)}',
            sub: '$deductPct% of total'),
        const SizedBox(width: 10),
        _SummaryMiniCard(
            icon: Icons.folder_outlined,
            iconColor: WerlogColors.textSecondary,
            label: 'Transactions',
            value: '${stats['total']}'),
      ]),
    );
  }

  // ── Search + filter chips ───────────────────────────────────────────────────
  Widget _buildSearchAndFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search
        Row(children: [
          Expanded(
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: WerlogColors.surface,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: WerlogColors.border, width: 0.8),
              ),
              child: Row(children: [
                const SizedBox(width: 12),
                const Icon(Icons.search, color: WerlogColors.textTertiary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Search in ${widget.category.name}...',
                      hintStyle: WerlogTextStyles.caption,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                    style: WerlogTextStyles.body,
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => setState(() { _statusFilter = null; _typeFilter = null; }),
            child: Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: (_statusFilter != null || _typeFilter != null)
                    ? WerlogColors.tealSurface
                    : WerlogColors.surface,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: WerlogColors.border, width: 0.8),
              ),
              child: Icon(Icons.filter_list,
                  color: (_statusFilter != null || _typeFilter != null)
                      ? WerlogColors.teal
                      : WerlogColors.textTertiary,
                  size: 20),
            ),
          ),
        ]),
        const SizedBox(height: 10),
        // Status filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(children: [
            _FilterChip(label: 'All', selected: _statusFilter == null && _typeFilter == null,
                onTap: () => setState(() { _statusFilter = null; _typeFilter = null; })),
            const SizedBox(width: 6),
            _FilterChip(label: 'Business', selected: _typeFilter == ExpenseType.business,
                color: WerlogColors.darkTeal,
                onTap: () => setState(() { _typeFilter = _typeFilter == ExpenseType.business ? null : ExpenseType.business; })),
            const SizedBox(width: 6),
            _FilterChip(label: 'Partial', selected: _typeFilter == ExpenseType.partial,
                color: WerlogColors.amber,
                onTap: () => setState(() { _typeFilter = _typeFilter == ExpenseType.partial ? null : ExpenseType.partial; })),
            const SizedBox(width: 6),
            _FilterChip(label: 'Needs Review', selected: _statusFilter == ExpenseStatus.needsReview,
                color: WerlogColors.amber,
                onTap: () => setState(() { _statusFilter = _statusFilter == ExpenseStatus.needsReview ? null : ExpenseStatus.needsReview; })),
            const SizedBox(width: 6),
            _FilterChip(label: 'Missing Info', selected: _statusFilter == ExpenseStatus.missingInfo,
                color: WerlogColors.coral,
                onTap: () => setState(() { _statusFilter = _statusFilter == ExpenseStatus.missingInfo ? null : ExpenseStatus.missingInfo; })),
          ]),
        ),
      ],
    );
  }

  // ── Sort row ────────────────────────────────────────────────────────────────
  Widget _buildSortRow() {
    return Row(children: [
      const Text('Sort by: ', style: TextStyle(fontFamily: 'DMSans', fontSize: 11, color: WerlogColors.textTertiary)),
      ...['Date', 'Amount', 'Status'].map((s) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: GestureDetector(
          onTap: () => setState(() => _sortBy = s),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _sortBy == s ? WerlogColors.teal : WerlogColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: _sortBy == s ? WerlogColors.teal : WerlogColors.border,
                  width: 0.8),
            ),
            child: Text(s,
                style: WerlogTextStyles.caption.copyWith(
                    fontSize: 10,
                    color: _sortBy == s ? Colors.white : WerlogColors.textSecondary,
                    fontWeight: FontWeight.w500)),
          ),
        ),
      )),
      const Spacer(),
      GestureDetector(
        onTap: () => setState(() => _listView = !_listView),
        child: Icon(_listView ? Icons.view_list : Icons.grid_view,
            color: WerlogColors.teal, size: 20),
      ),
    ]);
  }

  // ── Items list ──────────────────────────────────────────────────────────────
  Widget _buildItemList() {
    if (_filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(children: [
            Icon(Icons.search_off, color: WerlogColors.textTertiary, size: 40),
            const SizedBox(height: 10),
            Text('No expenses found', style: WerlogTextStyles.body.copyWith(color: WerlogColors.textTertiary)),
          ]),
        ),
      );
    }

    if (_listView) {
      // Grouped by month
      final groups = _groupedItems;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: groups.entries.map((e) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MonthHeader(month: e.key, items: e.value),
            const SizedBox(height: 8),
            ...e.value.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ExpenseListItem(item: item, category: widget.category),
            )),
            const SizedBox(height: 6),
          ],
        )).toList(),
      );
    } else {
      // Grid view
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.85),
        itemCount: _filtered.length,
        itemBuilder: (_, i) => _ExpenseGridItem(item: _filtered[i], category: widget.category),
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  STATS HEADER (gradient strip)
// ─────────────────────────────────────────────────────────────────────────────
class _StatsHeader extends StatelessWidget {
  final ExpenseCategory category;
  final Map<String, dynamic> stats;
  const _StatsHeader({required this.category, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: WerlogGradients.pageHeader(),
        border: const Border(bottom: BorderSide(color: WerlogColors.border, width: 0.8)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(children: [
          _StatBox('Total', '${stats['total']}', WerlogColors.textPrimary, WerlogColors.surfaceAlt),
          const SizedBox(width: 10),
          _StatBox('Verified', '${stats['verified']}', WerlogColors.teal, WerlogColors.tealSurface),
          const SizedBox(width: 10),
          _StatBox('Needs Review', '${stats['needsReview']}', WerlogColors.amber, WerlogColors.amberSurface),
          const SizedBox(width: 10),
          _StatBox('Missing Info', '${stats['missingInfo']}', WerlogColors.coral, WerlogColors.coralSurface),
        ]),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label, value;
  final Color color, bg;
  const _StatBox(this.label, this.value, this.color, this.bg);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2), width: 0.8),
      ),
      child: Column(children: [
        Text(label, style: WerlogTextStyles.caption.copyWith(color: color, fontSize: 9)),
        Text(value,  style: WerlogTextStyles.sectionTitle.copyWith(color: color, fontSize: 20, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  REUSABLE WIDGETS
// ─────────────────────────────────────────────────────────────────────────────
class _SummaryMiniCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label, value;
  final String? sub;
  const _SummaryMiniCard({required this.icon, required this.iconColor,
      required this.label, required this.value, this.sub});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: WerlogColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: WerlogColors.border, width: 0.8),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 30, height: 30,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 15),
        ),
        const SizedBox(height: 8),
        Text(label, style: WerlogTextStyles.caption.copyWith(fontSize: 9)),
        Text(value, style: WerlogTextStyles.txTitle.copyWith(fontSize: 13)),
        if (sub != null) Text(sub!, style: WerlogTextStyles.caption.copyWith(color: iconColor, fontSize: 9)),
      ]),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected,
      this.color = WerlogColors.teal, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : WerlogColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : WerlogColors.border, width: 0.8),
        ),
        child: Text(label,
            style: WerlogTextStyles.txTitle.copyWith(
                fontSize: 11,
                color: selected ? Colors.white : WerlogColors.textSecondary)),
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  final String month;
  final List<ExpenseItem> items;
  const _MonthHeader({required this.month, required this.items});

  @override
  Widget build(BuildContext context) {
    final monthTotal = items.fold(0.0, (s, e) => s + e.amount);
    return Row(children: [
      Text(month, style: WerlogTextStyles.sectionTitle.copyWith(fontSize: 12)),
      const SizedBox(width: 8),
      Container(width: 1, height: 12, color: WerlogColors.border),
      const SizedBox(width: 8),
      Text('\$${monthTotal.toStringAsFixed(2)}',
          style: WerlogTextStyles.caption.copyWith(color: WerlogColors.teal, fontWeight: FontWeight.w600)),
      const SizedBox(width: 6),
      Text('${items.length} items', style: WerlogTextStyles.caption.copyWith(fontSize: 9)),
    ]);
  }
}

// ── List item ─────────────────────────────────────────────────────────────────
class _ExpenseListItem extends StatelessWidget {
  final ExpenseItem item;
  final ExpenseCategory category;
  const _ExpenseListItem({required this.item, required this.category});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => ExpenseItemDetailScreen(item: item, category: category))),
      child: Container(
        decoration: BoxDecoration(
          color: WerlogColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: item.status == ExpenseStatus.missingInfo
                ? WerlogColors.coral.withOpacity(0.3)
                : WerlogColors.border,
            width: 0.8,
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: item.iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: item.iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.title,
                  style: WerlogTextStyles.txTitle.copyWith(fontSize: 12),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(item.vendor, style: WerlogTextStyles.caption.copyWith(fontSize: 10)),
              const SizedBox(height: 5),
              Row(children: [
                _StatusBadge(item.status),
                const SizedBox(width: 6),
                _TypeBadge(item.type),
                const SizedBox(width: 6),
                Text(item.date, style: WerlogTextStyles.txDate),
              ]),
            ]),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(item.formattedAmount, style: WerlogTextStyles.txAmount),
            const SizedBox(height: 2),
            Text('GST: ${item.formattedGst}',
                style: WerlogTextStyles.caption.copyWith(color: WerlogColors.teal, fontSize: 9)),
            if (item.deductiblePercent < 100)
              Text('${item.deductiblePercent.toInt()}% deduct.',
                  style: WerlogTextStyles.caption.copyWith(color: WerlogColors.amber, fontSize: 9)),
          ]),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: WerlogColors.textTertiary, size: 16),
        ]),
      ),
    );
  }
}

// ── Grid item ─────────────────────────────────────────────────────────────────
class _ExpenseGridItem extends StatelessWidget {
  final ExpenseItem item;
  final ExpenseCategory category;
  const _ExpenseGridItem({required this.item, required this.category});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => ExpenseItemDetailScreen(item: item, category: category))),
      child: Container(
        decoration: BoxDecoration(
          color: WerlogColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: WerlogColors.border, width: 0.8),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5, offset: const Offset(0, 2))],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: item.iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item.icon, color: item.iconColor, size: 18),
            ),
            const Spacer(),
            _StatusDot(item.status),
          ]),
          const SizedBox(height: 8),
          Text(item.title, style: WerlogTextStyles.txTitle.copyWith(fontSize: 11),
              maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(item.vendor, style: WerlogTextStyles.caption.copyWith(fontSize: 9),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const Spacer(),
          Text(item.formattedAmount,
              style: WerlogTextStyles.txAmount.copyWith(fontSize: 13)),
          Text('GST: ${item.formattedGst}',
              style: WerlogTextStyles.caption.copyWith(color: WerlogColors.teal, fontSize: 9)),
          Text(item.date, style: WerlogTextStyles.txDate),
        ]),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final ExpenseStatus status;
  const _StatusDot(this.status);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8, height: 8,
      decoration: BoxDecoration(color: status.color, shape: BoxShape.circle),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final ExpenseStatus status;
  const _StatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: status.surface,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(status.label,
          style: WerlogTextStyles.badgeText.copyWith(color: status.color)),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final ExpenseType type;
  const _TypeBadge(this.type);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: type.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(type.label,
          style: WerlogTextStyles.badgeText.copyWith(color: type.color)),
    );
  }
}
