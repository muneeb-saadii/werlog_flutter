import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

// ─────────────────────────────────────────
//  DATA MODELS — replace with API response
// ─────────────────────────────────────────
class ExpensesTaxData {
  // Summary stats
  static const String totalExpenses = '\$12,400';
  static const String gstHstPaid = '\$640';
  static const String eligibleDeductions = '\$1,790';
  static const int totalDocuments = 86;
  static const String estimatedRefund = '\$2,430';
  static const String businessExpenses = '\$8,432';
  static const String personalExpenses = '\$3,968';

  // Recent expenses
  static const List<Map<String, dynamic>> recentExpenses = [
    {
      'id': 'e001',
      'title': 'Adobe Creative Cloud',
      'category': 'Software',
      'date': '01 May 2024',
      'amount': '\$54.99',
      'gst': '\$5.00',
      'type': 'business',
      'status': 'verified',
      'icon': Icons.brush_outlined,
      'color': 0xFF7B5EA7,
    },
    {
      'id': 'e002',
      'title': 'Office Supplies — Staples',
      'category': 'Office',
      'date': '28 Apr 2024',
      'amount': '\$143.50',
      'gst': '\$13.05',
      'type': 'business',
      'status': 'needs_review',
      'icon': Icons.inventory_2_outlined,
      'color': 0xFF1D9E75,
    },
    {
      'id': 'e003',
      'title': 'Internet Bill — Rogers',
      'category': 'Home Office',
      'date': '25 Apr 2024',
      'amount': '\$89.99',
      'gst': '\$4.50',
      'type': 'partial',
      'status': 'verified',
      'icon': Icons.wifi_outlined,
      'color': 0xFF0F2A2E,
    },
    {
      'id': 'e004',
      'title': 'Fuel — Shell Station',
      'category': 'Vehicle',
      'date': '22 Apr 2024',
      'amount': '\$78.20',
      'gst': '\$3.91',
      'type': 'partial',
      'status': 'missing_info',
      'icon': Icons.local_gas_station_outlined,
      'color': 0xFFBA7517,
    },
    {
      'id': 'e005',
      'title': 'Lunch — Client Meeting',
      'category': 'Meals',
      'date': '20 Apr 2024',
      'amount': '\$124.00',
      'gst': '\$6.20',
      'type': 'business',
      'status': 'verified',
      'icon': Icons.restaurant_outlined,
      'color': 0xFFD85A30,
    },
    {
      'id': 'e006',
      'title': 'Flight — Toronto to Vancouver',
      'category': 'Travel',
      'date': '18 Apr 2024',
      'amount': '\$430.00',
      'gst': '\$21.50',
      'type': 'business',
      'status': 'verified',
      'icon': Icons.flight_outlined,
      'color': 0xFF5DCAA5,
    },
  ];

  // Spending by category
  static const List<Map<String, dynamic>> categoryBreakdown = [
    {'name': 'Office', 'amount': '\$4,250', 'percent': 34, 'color': 0xFF1D9E75},
    {'name': 'Auto', 'amount': '\$2,950', 'percent': 24, 'color': 0xFF0F2A2E},
    {'name': 'Travel', 'amount': '\$2,100', 'percent': 17, 'color': 0xFFBA7517},
    {'name': 'Meals', 'amount': '\$1,800', 'percent': 15, 'color': 0xFFD85A30},
    {'name': 'Other', 'amount': '\$1,300', 'percent': 10, 'color': 0xFF888780},
  ];

  // Tax summary rows
  static const List<Map<String, String>> taxSummary = [
    {'label': 'Total GST/HST Paid', 'value': '\$640', 'color': 'teal'},
    {'label': 'Claimable GST/HST', 'value': '\$598', 'color': 'teal'},
    {'label': 'Non-Claimable GST', 'value': '\$42', 'color': 'coral'},
    {'label': 'Total Deductions', 'value': '\$1,790', 'color': 'teal'},
    {'label': 'Estimated Tax Savings', 'value': '\$2,430', 'color': 'teal'},
  ];
}

class ExpensesTaxScreen extends StatefulWidget {
  const ExpensesTaxScreen({super.key});

  @override
  State<ExpensesTaxScreen> createState() => _ExpensesTaxScreenState();
}

class _ExpensesTaxScreenState extends State<ExpensesTaxScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _activeFilter = 'All';

  final List<String> _filters = ['All', 'Business', 'Personal', 'Partial'];

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
            _buildAppBar(context),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildExpensesTab(),
                  _buildTaxTab(),
                  _buildDocumentsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: WerlogColors.teal,
        icon: const Icon(Icons.add_photo_alternate_outlined, color: Colors.white),
        label: Text('Add Expense',
            style: WerlogTextStyles.button.copyWith(fontSize: 13)),
      ),
    );
  }

  // ── App bar ───────────────────────────────
  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                size: 18, color: WerlogColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Expenses & Tax',
                    style: WerlogTextStyles.pageTitle.copyWith(fontSize: 18)),
                Text('Track and maximize your deductions',
                    style: WerlogTextStyles.caption),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search,
                size: 22, color: WerlogColors.textPrimary),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.tune,
                size: 20, color: WerlogColors.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  // ── Tab bar ───────────────────────────────
  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        color: WerlogColors.surface,
        border: Border(bottom: BorderSide(color: WerlogColors.border, width: 0.8)),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: WerlogColors.teal,
        unselectedLabelColor: WerlogColors.textTertiary,
        indicatorColor: WerlogColors.teal,
        indicatorWeight: 2,
        labelStyle: WerlogTextStyles.txTitle.copyWith(fontSize: 13),
        unselectedLabelStyle: WerlogTextStyles.body.copyWith(fontSize: 13),
        tabs: const [
          Tab(text: 'Expenses'),
          Tab(text: 'Tax Summary'),
          Tab(text: 'Documents'),
        ],
      ),
    );
  }

  // ── Expenses tab ──────────────────────────
  Widget _buildExpensesTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 14),
          _buildSummaryCard(),
          const SizedBox(height: 14),
          _buildCategoryBreakdown(),
          const SizedBox(height: 14),
          _buildRecentExpenses(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: WerlogGradients.darkHero(),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: WerlogColors.darkTeal.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total Expenses (This Year)',
              style: WerlogTextStyles.balanceSub.copyWith(fontSize: 11)),
          const SizedBox(height: 4),
          Text(ExpensesTaxData.totalExpenses,
              style: WerlogTextStyles.balanceAmount),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _summaryChip('GST/HST Paid', ExpensesTaxData.gstHstPaid),
                const SizedBox(width: 10),
                _summaryChip('Deductions', ExpensesTaxData.eligibleDeductions),
                const SizedBox(width: 10),
                _summaryChip('Est. Refund', ExpensesTaxData.estimatedRefund,
                    highlighted: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryChip(String label, String value,
      {bool highlighted = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: highlighted
            ? WerlogColors.teal.withOpacity(0.25)
            : Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlighted
              ? WerlogColors.tealLight.withOpacity(0.4)
              : Colors.white.withOpacity(0.12),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: WerlogTextStyles.balanceSub.copyWith(fontSize: 9)),
          const SizedBox(height: 2),
          Text(value,
              style: WerlogTextStyles.balanceSub.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: highlighted
                      ? WerlogColors.tealLight
                      : Colors.white)),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown() {
    return Container(
      decoration: BoxDecoration(
        color: WerlogColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WerlogColors.border, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('By Category', style: WerlogTextStyles.sectionTitle),
          const SizedBox(height: 12),
          // Stacked progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 8,
              child: Row(
                children: ExpensesTaxData.categoryBreakdown.map((c) {
                  return Expanded(
                    flex: c['percent'] as int,
                    child: Container(color: Color(c['color'] as int)),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...ExpensesTaxData.categoryBreakdown.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: Color(c['color'] as int),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(c['name'],
                            style: WerlogTextStyles.body
                                .copyWith(fontSize: 12))),
                    Text(c['amount'],
                        style:
                            WerlogTextStyles.txTitle.copyWith(fontSize: 12)),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 30,
                      child: Text('${c['percent']}%',
                          style: WerlogTextStyles.caption
                              .copyWith(color: WerlogColors.textTertiary),
                          textAlign: TextAlign.right),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildRecentExpenses() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Expenses',
                style: WerlogTextStyles.sectionTitle),
            GestureDetector(
              onTap: () {},
              child: Text('View All',
                  style: WerlogTextStyles.link.copyWith(fontSize: 11)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: _filters.map((f) {
              final selected = _activeFilter == f;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _activeFilter = f),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: selected
                          ? WerlogColors.teal
                          : WerlogColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? WerlogColors.teal
                            : WerlogColors.border,
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      f,
                      style: WerlogTextStyles.txTitle.copyWith(
                        fontSize: 11,
                        color: selected
                            ? Colors.white
                            : WerlogColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        ...ExpensesTaxData.recentExpenses.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _expenseItem(e),
            )),
      ],
    );
  }

  Widget _expenseItem(Map<String, dynamic> expense) {
    final statusConfig = {
      'verified': {'label': 'Verified', 'color': WerlogColors.teal, 'bg': WerlogColors.tealSurface},
      'needs_review': {'label': 'Needs Review', 'color': WerlogColors.amber, 'bg': WerlogColors.amberSurface},
      'missing_info': {'label': 'Missing Info', 'color': WerlogColors.coral, 'bg': WerlogColors.coralSurface},
    };
    final sc = statusConfig[expense['status']] ?? statusConfig['verified']!;

    return Container(
      decoration: BoxDecoration(
        color: WerlogColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: WerlogColors.border, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Color(expense['color'] as int).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(expense['icon'] as IconData,
                color: Color(expense['color'] as int), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(expense['title']!,
                    style: WerlogTextStyles.txTitle.copyWith(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(expense['category']!,
                        style: WerlogTextStyles.caption.copyWith(fontSize: 10)),
                    const SizedBox(width: 6),
                    Container(width: 3, height: 3,
                        decoration: const BoxDecoration(
                            color: WerlogColors.textTertiary,
                            shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(expense['date']!,
                        style: WerlogTextStyles.caption.copyWith(fontSize: 10)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: sc['bg'] as Color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(sc['label'] as String,
                          style: WerlogTextStyles.badgeText
                              .copyWith(color: sc['color'] as Color)),
                    ),
                    const SizedBox(width: 6),
                    _typePill(expense['type']),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(expense['amount']!,
                  style: WerlogTextStyles.txAmount),
              const SizedBox(height: 2),
              Text('GST: ${expense['gst']}',
                  style: WerlogTextStyles.caption
                      .copyWith(color: WerlogColors.teal, fontSize: 9)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _typePill(String type) {
    final configs = {
      'business': {'label': 'Business', 'color': WerlogColors.darkTeal},
      'personal': {'label': 'Personal', 'color': WerlogColors.textTertiary},
      'partial': {'label': 'Partial', 'color': WerlogColors.amber},
    };
    final c = configs[type] ?? configs['business']!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: (c['color'] as Color).withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(c['label'] as String,
          style: WerlogTextStyles.badgeText
              .copyWith(color: c['color'] as Color)),
    );
  }

  // ── Tax summary tab ───────────────────────
  Widget _buildTaxTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          _buildTaxHeroCard(),
          const SizedBox(height: 14),
          _buildTaxSummaryTable(),
          const SizedBox(height: 14),
          _buildTaxTips(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildTaxHeroCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: WerlogGradients.darkHero(),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: WerlogColors.darkTeal.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Estimated Tax Savings',
              style: WerlogTextStyles.balanceSub.copyWith(fontSize: 11)),
          Text(ExpensesTaxData.estimatedRefund,
              style: WerlogTextStyles.balanceAmount),
          const SizedBox(height: 16),
          Row(
            children: [
              _taxChip('Business', ExpensesTaxData.businessExpenses,
                  WerlogColors.teal),
              const SizedBox(width: 10),
              _taxChip('Personal', ExpensesTaxData.personalExpenses,
                  WerlogColors.textTertiary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _taxChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                  width: 7,
                  height: 7,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(label,
                  style: WerlogTextStyles.balanceSub.copyWith(fontSize: 10)),
            ],
          ),
          const SizedBox(height: 3),
          Text(value,
              style: WerlogTextStyles.balanceSub
                  .copyWith(fontSize: 14, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildTaxSummaryTable() {
    return Container(
      decoration: BoxDecoration(
        color: WerlogColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WerlogColors.border, width: 0.8),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Text('Tax Summary', style: WerlogTextStyles.sectionTitle),
          ),
          const Divider(height: 0.5, color: WerlogColors.borderLight),
          ...ExpensesTaxData.taxSummary.asMap().entries.map((e) {
            final row = e.value;
            final isLast = e.key == ExpensesTaxData.taxSummary.length - 1;
            final color = row['color'] == 'teal'
                ? WerlogColors.teal
                : WerlogColors.coral;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Text(row['label']!,
                          style:
                              WerlogTextStyles.body.copyWith(fontSize: 12)),
                      const Spacer(),
                      Text(row['value']!,
                          style: WerlogTextStyles.txTitle
                              .copyWith(fontSize: 13, color: color)),
                    ],
                  ),
                ),
                if (!isLast)
                  const Divider(height: 0.5, color: WerlogColors.borderLight),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTaxTips() {
    const List<String> tips = [
      'Keep all receipts — even under \$30 for CRA compliance',
      'Track mileage for vehicle business use claims',
      'Home office expenses may be partially deductible',
      'Professional development courses are fully deductible',
    ];

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
          Row(
            children: [
              const Icon(Icons.lightbulb_outline,
                  color: WerlogColors.teal, size: 18),
              const SizedBox(width: 8),
              Text('Tax Tips', style: WerlogTextStyles.sectionTitle),
            ],
          ),
          const SizedBox(height: 12),
          ...tips.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(top: 4),
                      decoration: const BoxDecoration(
                          color: WerlogColors.teal, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(t,
                          style:
                              WerlogTextStyles.body.copyWith(fontSize: 11)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ── Documents tab ─────────────────────────
  Widget _buildDocumentsTab() {
    // Document data variables — replace with API
    const int totalDocs = 86;
    const int verifiedDocs = 72;
    const int pendingDocs = 10;
    const int rejectedDocs = 4;

    const List<Map<String, dynamic>> docList = [
      {'name': 'Adobe_Invoice_Apr2024.pdf', 'size': '124 KB', 'date': '01 May 2024', 'type': 'Invoice'},
      {'name': 'Staples_Receipt_Apr2024.pdf', 'size': '89 KB', 'date': '28 Apr 2024', 'type': 'Receipt'},
      {'name': 'Rogers_Bill_Apr2024.pdf', 'size': '210 KB', 'date': '25 Apr 2024', 'type': 'Bill'},
      {'name': 'Shell_Fuel_Receipt.jpg', 'size': '1.2 MB', 'date': '22 Apr 2024', 'type': 'Receipt'},
      {'name': 'Meal_Receipt_ClientMeet.jpg', 'size': '876 KB', 'date': '20 Apr 2024', 'type': 'Receipt'},
    ];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          // Doc stats
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _docStat('Total', '$totalDocs', WerlogColors.textPrimary,
                    WerlogColors.surfaceAlt),
                const SizedBox(width: 10),
                _docStat('Verified', '$verifiedDocs', WerlogColors.teal,
                    WerlogColors.tealSurface),
                const SizedBox(width: 10),
                _docStat('Pending', '$pendingDocs', WerlogColors.amber,
                    WerlogColors.amberSurface),
                const SizedBox(width: 10),
                _docStat('Rejected', '$rejectedDocs', WerlogColors.coral,
                    WerlogColors.coralSurface),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text('All Documents', style: WerlogTextStyles.sectionTitle),
          const SizedBox(height: 10),
          ...docList.map((d) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _docItem(d),
              )),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _docStat(
      String label, String value, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2), width: 0.8),
      ),
      child: Column(
        children: [
          Text(label,
              style: WerlogTextStyles.caption.copyWith(color: color, fontSize: 10)),
          Text(value,
              style: WerlogTextStyles.sectionTitle
                  .copyWith(color: color, fontSize: 18)),
        ],
      ),
    );
  }

  Widget _docItem(Map<String, dynamic> doc) {
    final isImage = (doc['name'] as String).endsWith('.jpg') ||
        (doc['name'] as String).endsWith('.png');
    return Container(
      decoration: BoxDecoration(
        color: WerlogColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: WerlogColors.border, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isImage
                  ? WerlogColors.tealSurface
                  : WerlogColors.coralSurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isImage ? Icons.image_outlined : Icons.picture_as_pdf_outlined,
              color:
                  isImage ? WerlogColors.teal : WerlogColors.coral,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doc['name'],
                    style: WerlogTextStyles.txTitle.copyWith(fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(doc['type'],
                        style: WerlogTextStyles.caption
                            .copyWith(fontSize: 9)),
                    const SizedBox(width: 6),
                    Container(
                        width: 3,
                        height: 3,
                        decoration: const BoxDecoration(
                            color: WerlogColors.textTertiary,
                            shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(doc['size'],
                        style: WerlogTextStyles.caption
                            .copyWith(fontSize: 9)),
                    const SizedBox(width: 6),
                    Container(
                        width: 3,
                        height: 3,
                        decoration: const BoxDecoration(
                            color: WerlogColors.textTertiary,
                            shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(doc['date'],
                        style: WerlogTextStyles.caption
                            .copyWith(fontSize: 9)),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert,
                color: WerlogColors.textTertiary, size: 18),
            onPressed: () {},
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
