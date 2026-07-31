import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
// import 'package:wellness/ui/tset/screens/expenses/expense_dashboard_screen.dart';
import '../../../core/api/api_service.dart';
import '../../../core/api/endpoints.dart';
import '../../../core/models/app_models.dart';
import '../../../core/models/app_models_extended.dart' hide CameraViewData, InvoiceLineItem;
import '../../../core/routing/AppRoutes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/general_functions.dart';
import '../../../core/utils/shared_pref_helper.dart';
import '../../screens/disclaimer/disclaimer_widget.dart';
import '../../screens/profile_segment/checkout_webview_screen.dart';
import '../../screens/profile_segment/currency_screen.dart';
import '../../screens/profile_segment/subscription_usage_screen.dart' hide SubscriptionPlan;
import '../../screens/screen_03_subscription.dart';
import 'camera_screen_new.dart';
import '../../screens/profile_segment/notifications_screen.dart';
import '../../screens/ocr_processing_screen.dart' hide WerlogTextStyles, WerlogColors, WerlogGradients;
import '../../screens/screen_04_ocr_flow.dart';
import '../../screens/screen_06_list_reports_profile.dart';
import '../../../core/widgets/plan_restriction_dialog.dart';
import 'expense_new/expense_dashboard_screen.dart';
import 'expense_new/fresh/expense_data.dart';
import 'expense_new/tax_ready_summary_screen.dart';
import 'warranty_dashboard_screen.dart';
import 'package:wellness/ui/tset/screens/expense_new/fresh/expense_detail_screen.dart';

// ─────────────────────────────────────────
//  DATA MODELS — replace with API response
// ─────────────────────────────────────────
/*class MainDashboardData {
  // Header
  static String salutation = 'Good Morning';
  static String subtitle = "Here's your ownership & tax overview";
  static String userName = 'Alex';
  static int notificationCount = 3;

  // Tax savings card
  static String taxSavingsAmount = '\$2,430';
  static String taxSavingsYear = '2024';
  static String taxSavingsChange = '18% higher than last year';
  static bool taxSavingsPositive = true;
  static String gstHstToClaim = '\$640';
  static String taxDeductions = '\$1,790';

  // Warranty summary
  static int totalWarranties = 24;
  static int activeWarranties = 14;
  static int expiringSoonWarranties = 5;
  static int expiredWarranties = 3;
  static int claimedWarranties = 2;

  // Expenses & Tax
  static String totalExpenses = '\$12,400';
  static String gstHstPaid = '\$640';
  static String eligibleDeductions = '\$1,790';
  static int documents = 86;

  // AI Insights
  static List<Map<String, String>> aiInsights = [
    {
      'title': 'You have \$380 in potential missed claims',
      'subtitle': '4 receipts are missing GST/HST details',
      'icon': 'sparkle',
    },
    {
      'title': 'Your internet bill may qualify as Home Office Expense',
      'subtitle': 'You could save up to \$120',
      'icon': 'building',
    },
    {
      'title': 'Vehicle fuel expenses may be partially claimable',
      'subtitle': 'Add your business usage percentage',
      'icon': 'car',
    },
  ];

  // Alerts
  static List<Map<String, String>> alerts = [
    {
      'title': '2 warranties\nexpiring soon',
      'subtitle': 'Next: 15 May 2024',
      'icon': 'warning',
      'color': 'coral',
    },
    {
      'title': 'Tax filing due in\n30 days',
      'subtitle': '15 Jun 2024',
      'icon': 'document',
      'color': 'amber',
    },
    {
      'title': '12 expenses\nneed review',
      'subtitle': 'Review Now',
      'icon': 'upload',
      'color': 'teal',
    },
    {
      'title': '3 receipts\nmissing info',
      'subtitle': 'Update Now',
      'icon': 'receipt',
      'color': 'purple',
    },
  ];

  // Spending Snapshot
  static String totalSpending = '\$12,400';
  static String spendingChange = '8% vs last year';
  static bool spendingPositive = false;
  static List<Map<String, dynamic>> topCategories = [
    {'name': 'Office', 'amount': '\$4,250', 'color': 'teal'},
    {'name': 'Auto', 'amount': '\$2,950', 'color': 'darkTeal'},
    {'name': 'Travel', 'amount': '\$2,100', 'color': 'amber'},
    {'name': 'Other', 'amount': '\$3,100', 'color': 'grey'},
  ];
  static double businessPercent = 68;
  static double personalPercent = 32;
  static String businessExpenses = '\$8,432';
}*/
class MainDashboardData {
  // Header
  static String salutation = '';
  static String subtitle = '';
  static String userName = '';
  static int notificationCount = 0;

  // Tax savings card
  static String taxSavingsAmount = '';
  static String taxSavingsYear = '';
  static String taxSavingsChange = '';
  static bool taxSavingsPositive = false;
  static String gstHstToClaim = '';
  static String taxDeductions = '';

  // Warranty summary
  static int totalWarranties = 0;
  static int activeWarranties = 0;
  static int expiringSoonWarranties = 0;
  static int expiredWarranties = 0;
  static int claimedWarranties = 0;

  // Expenses & Tax
  static String totalExpenses = '';
  static String gstHstPaid = '';
  static String eligibleDeductions = '';
  static int documents = 0;

  // AI Insights
  static List<Map<String, String>> aiInsights = [];

  // Alerts
  static List<Map<String, String>> alerts = [];

  // Spending Snapshot
  static String totalSpending = '';
  static String spendingChange = '';
  static bool spendingPositive = false;

  static List<Map<String, dynamic>> topCategories = [];

  static double businessPercent = 0.0;
  static double personalPercent = 0.0;
  static String businessExpenses = '';

  // Recent Invoices
  static List<Map<String, dynamic>> recentInvoices = [];
}

class MainDashboardScreen extends StatefulWidget {
  const MainDashboardScreen({super.key});

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> {

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      GeneralFunctions.getCurrencySymbol();
      refreshData();

      // ── Show disclaimer first, THEN load data ─────────────────────
      await DisclaimerWidget.show(
        context,
        type: DisclaimerType.onboarding,
        onAcknowledged: () {},
      );

      // Only starts after disclaimer is dismissed (or skipped if already seen)
      if (mounted) loadDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WerlogColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    _buildTaxSavingsCard(context),
                    const SizedBox(height: 14),
                    _buildQuickAccessRow(context),
                    const SizedBox(height: 14),
                    Visibility(
                      visible: false,
                      maintainState: false,
                      maintainAnimation: false,
                      maintainSize: false,          // ← no blank gap when hidden
                      child: _buildAiInsightsSection(context),
                    ),
                    if (MainDashboardData.topCategories.isNotEmpty) ...[
                      _buildAlertsSection(context),
                      const SizedBox(height: 14),
                    ],
                    _buildSpendingSnapshot(context),
                    const SizedBox(height: 14),
                    _buildRecentInvoices(context),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  // ── Top bar ──────────────────────────────
  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          // Icon(Icons.menu, color: WerlogColors.textPrimary, size: 20),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${MainDashboardData.salutation}, ${MainDashboardData.userName} 👋',
                style: WerlogTextStyles.dashboardName,
              ),
              Text(
                "${MainDashboardData.subtitle}",
                style: WerlogTextStyles.dashboardGreeting,
              ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationsScreen(),
                ),
              );
            },
            child: Stack(
              children: [
                Icon(Icons.notifications_outlined,
                    color: WerlogColors.textPrimary, size: 24),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(
                      color: WerlogColors.coral,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${MainDashboardData.notificationCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'DMSans',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tax savings hero card ─────────────────
  Widget _buildTaxSavingsCard(BuildContext context) {
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
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            // Left: amount
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Estimated Tax Savings (${MainDashboardData.taxSavingsYear})',
                    style: WerlogTextStyles.balanceSub.copyWith(fontSize: 11),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    MainDashboardData.taxSavingsAmount,
                    style: WerlogTextStyles.balanceAmount,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        MainDashboardData.taxSavingsPositive
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        color: WerlogColors.tealLight,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          MainDashboardData.taxSavingsChange,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: WerlogTextStyles.balanceSub.copyWith(
                            color: WerlogColors.tealLight,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Divider
            Container(
              width: 0.5,
              height: 80,
              color: Colors.white.withOpacity(0.15),
              margin: const EdgeInsets.symmetric(horizontal: 14),
            ),
            // Right: breakdown
            /*Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Breakdown  ⓘ',
                    style: WerlogTextStyles.balanceSub.copyWith(fontSize: 10)),
                const SizedBox(height: 10),
                _breakdownRow('GST/HST to Claim', MainDashboardData.gstHstToClaim),
                const SizedBox(height: 6),
                _breakdownRow('Tax Deductions', MainDashboardData.taxDeductions),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: WerlogColors.teal,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('View Expense Reports',
                            style: WerlogTextStyles.link.copyWith(
                                fontSize: 12, color: WerlogColors.tealSurface)),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right,
                            color: WerlogColors.tealSurface, size: 14),
                      ],
                    ),
                  ),
                ),
              ],
            ),*/

            // Right: breakdown
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => DisclaimerWidget.show(context, type: DisclaimerType.taxEstimate),
                    child: Text('Breakdown  ⓘ',
                        style: WerlogTextStyles.balanceSub.copyWith(fontSize: 10)),
                  ),
                  const SizedBox(height: 10),
                  _breakdownRow('GST/HST to Claim', MainDashboardData.gstHstToClaim),
                  const SizedBox(height: 6),
                  _breakdownRow('Tax Deductions', MainDashboardData.taxDeductions),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const TaxReadySummaryScreen())),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 5),
                      decoration: BoxDecoration(
                        color: WerlogColors.teal,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text('View Expense Reports',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: WerlogTextStyles.link.copyWith(
                                    fontSize: 11, color: WerlogColors.tealSurface)),
                          ),
                          const SizedBox(width: 2),
                          const Icon(Icons.chevron_right,
                              color: WerlogColors.tealSurface, size: 13),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _breakdownRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: WerlogTextStyles.balanceSub.copyWith(fontSize: 10)),
        const SizedBox(width: 12),
        Text(value,
            style: WerlogTextStyles.balanceSub
                .copyWith(color: WerlogColors.tealLight, fontWeight: FontWeight.w600)),
      ],
    );
  }

  // ── Quick access row (Warranty + Expenses) ─
  Widget _buildQuickAccessRow(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _buildWarrantyCard(context)),
          const SizedBox(width: 12),
          Expanded(child: _buildExpensesCard(context)),
        ],
      ),
    );
  }

  Widget _buildWarrantyCard(BuildContext context) {
    return GestureDetector(
      onTap: () => callWarrantyDashboardScreen(),
      child: Container(
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
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: WerlogGradients.darkHero(),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.verified_user_outlined,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Warranty', style: WerlogTextStyles.sectionTitle),
                ),
                /*const Icon(Icons.chevron_right,
                    color: WerlogColors.textTertiary, size: 18),*/
              ],
            ),
            const SizedBox(height: 5),
            Text('All your product warranties in one place',
                style: WerlogTextStyles.caption),
            const SizedBox(height: 12),
            // Donut summary
            Row(
              children: [
                SizedBox(
                  width: 66,
                  height: 66,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(66, 66),
                        painter: _DonutPainter(
                          active: MainDashboardData.activeWarranties,
                          expiringSoon: MainDashboardData.expiringSoonWarranties,
                          expired: MainDashboardData.expiredWarranties,
                          claimed: MainDashboardData.claimedWarranties,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${MainDashboardData.totalWarranties}',
                            style: WerlogTextStyles.sectionTitle
                                .copyWith(fontSize: 16),
                          ),
                          Text('Total',
                              style:
                              WerlogTextStyles.caption.copyWith(fontSize: 9)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _warrantyLegendRow(
                          WerlogColors.teal, 'Active', MainDashboardData.activeWarranties),
                      _warrantyLegendRow(
                          WerlogColors.amber, 'Expiring Soon', MainDashboardData.expiringSoonWarranties),
                      _warrantyLegendRow(
                          WerlogColors.coral, 'Expired', MainDashboardData.expiredWarranties),
                      /*_warrantyLegendRow(
                          WerlogColors.textTertiary, 'Claimed', MainDashboardData.claimedWarranties),*/
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Spacer(),
            Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: WerlogColors.tealSurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        'Manage Warranties',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: WerlogTextStyles.link.copyWith(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right,
                      color: WerlogColors.teal,
                      size: 14,
                    ),
                  ],
                )
            ),
          ],
        ),
      ),
    );
  }

  Widget _warrantyLegendRow(Color color, String label, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(label,
                style: WerlogTextStyles.caption.copyWith(fontSize: 11)),
          ),
          Text('$count',
              style: WerlogTextStyles.sectionTitle.copyWith(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildExpensesCard(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            // builder: (_) => const ExpenseDashboardScreen())),
            // builder: (_) => const ExpensesTaxScreen())),
              builder: (_) => const ExpenseDashboardScreen())),
      child: Container(
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
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: WerlogColors.tealSurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.attach_money,
                      color: WerlogColors.teal, size: 20),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    'Expense',
                    style: WerlogTextStyles.link.copyWith(fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                /*const Icon(
                  Icons.chevron_right,
                  color: WerlogColors.teal,
                  size: 14,
                ),*/
              ],
            ),
            const SizedBox(height: 6),
            Text('All your expense receipts in one place.',
                style: WerlogTextStyles.caption),
            const SizedBox(height: 12),
            _expensesRow(
                Icons.receipt_long_outlined, 'Total Expenses', MainDashboardData.totalExpenses),
            const SizedBox(height: 8),
            _expensesRow(
                Icons.receipt_outlined, 'Business Expenses', MainDashboardData.gstHstPaid),
            const SizedBox(height: 8),
            _expensesRow(
                Icons.person/*percent*/, 'Personal Expenses', MainDashboardData.eligibleDeductions),
            /*const SizedBox(height: 8),
            _expensesRow(
                Icons.description_outlined, 'Documents', '${MainDashboardData.documents}'),*/
            const SizedBox(height: 12),
            const Spacer(),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                color: WerlogColors.tealSurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('View Expenses',
                      style: WerlogTextStyles.link.copyWith(fontSize: 12)),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right,
                      color: WerlogColors.teal, size: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _expensesRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: WerlogColors.textTertiary, size: 13),
        const SizedBox(width: 6),
        Expanded(
            child: Text(label,
                style: WerlogTextStyles.caption.copyWith(
                    fontSize: (WerlogTextStyles.caption.fontSize ?? 11) - 1))),
        Text(value,
            style: WerlogTextStyles.txTitle.copyWith(fontSize: 11)),
      ],
    );
  }

  // ── AI Insights ──────────────────────────
  Widget _buildAiInsightsSection(BuildContext context) {
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
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: WerlogColors.tealSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.smart_toy_outlined,
                    color: WerlogColors.teal, size: 16),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text('AI Insights',
                            style: WerlogTextStyles.sectionTitle),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: WerlogColors.teal,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'New',
                            style: WerlogTextStyles.badgeText
                                .copyWith(color: Colors.white),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 2),

                    Text(
                      'Smart suggestions to maximize your savings',
                      style: WerlogTextStyles.caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              /*GestureDetector(
                onTap: () {},
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('View All',
                        style: WerlogTextStyles.link.copyWith(fontSize: 11)),
                    const Icon(Icons.chevron_right,
                        color: WerlogColors.teal, size: 14),
                  ],
                ),
              ),*/
            ],
          ),
          const SizedBox(height: 12),
          ...MainDashboardData.aiInsights.map((insight) => _insightRow(insight)),
        ],
      ),
    );
  }

  Widget _insightRow(Map<String, String> insight) {
    final iconData = insight['icon'] == 'sparkle'
        ? Icons.auto_awesome
        : insight['icon'] == 'building'
        ? Icons.home_work_outlined
        : Icons.directions_car_outlined;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: WerlogGradients.pageHeader(),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(iconData, color: WerlogColors.teal, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(insight['title']!,
                    style: WerlogTextStyles.txTitle.copyWith(fontSize: 11)),
                Text(insight['subtitle']!,
                    style: WerlogTextStyles.caption
                        .copyWith(color: WerlogColors.teal)),
              ],
            ),
          ),
          /*const Icon(Icons.chevron_right,
              color: WerlogColors.textTertiary, size: 16),*/
        ],
      ),
    );
  }

  // ── Alerts & Reminders ───────────────────
  Widget _buildAlertsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Alerts & Reminders',
                style: WerlogTextStyles.sectionTitle),
            /*GestureDetector(
              onTap: () {},
              child: Text('View All (4)',
                  style: WerlogTextStyles.link.copyWith(fontSize: 11)),
            ),*/
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: MainDashboardData.alerts.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) => _alertCard(MainDashboardData.alerts[i]),
          ),
        ),
      ],
    );
  }

  Widget _alertCard(Map<String, String> alert) {
    final colorMap = {
      'coral': WerlogColors.coral,
      'amber': WerlogColors.amber,
      'teal': WerlogColors.teal,
      'purple': const Color(0xFF7B5EA7),
    };
    final surfaceMap = {
      'coral': WerlogColors.coralSurface,
      'amber': WerlogColors.amberSurface,
      'teal': WerlogColors.tealSurface,
      'purple': const Color(0xFFF3EEF8),
    };
    final color = colorMap[alert['color']] ?? WerlogColors.teal;
    final surface = surfaceMap[alert['color']] ?? WerlogColors.tealSurface;

    final iconData = alert['icon'] == 'warning'
        ? Icons.warning_amber_rounded
        : alert['icon'] == 'document'
        ? Icons.description_outlined
        : alert['icon'] == 'upload'
        ? Icons.cloud_upload_outlined
        : Icons.receipt_outlined;

    return Container(
      width: 148,
      padding: const EdgeInsets.all(12),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(iconData, color: color, size: 14),
          ),

          const SizedBox(height: 4),

          Text(
            alert['title']!,
            style: WerlogTextStyles.txTitle.copyWith(fontSize: 10),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 2),

          Text(
            alert['subtitle']!,
            style: WerlogTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 9,
              height: 1.1, // 🔥 critical fix
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ── Spending Snapshot ────────────────────
  Widget _buildSpendingSnapshot(BuildContext context) {
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
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Spending Snapshot',
                      style: WerlogTextStyles.sectionTitle,
                    ),
                    TextSpan(
                      text: '  (This Year)',
                      style: WerlogTextStyles.caption,
                    ),
                  ],
                ),
              ),
              /*GestureDetector(
                onTap: () {},
                child: Text('View Report',
                    style: WerlogTextStyles.link.copyWith(fontSize: 11)),
              ),*/
            ],
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Total spending
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Spending',
                        style: WerlogTextStyles.caption),
                    Text(MainDashboardData.totalSpending,
                        style: WerlogTextStyles.pageTitle),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          MainDashboardData.spendingPositive
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          color: MainDashboardData.spendingPositive
                              ? WerlogColors.coral
                              : WerlogColors.teal,
                          size: 12,
                        ),
                        Text(
                          MainDashboardData.spendingChange,
                          style: WerlogTextStyles.caption.copyWith(
                            color: MainDashboardData.spendingPositive
                                ? WerlogColors.coral
                                : WerlogColors.teal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 24),
                // Top categories
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Top Categories',
                        style: WerlogTextStyles.caption),
                    const SizedBox(height: 8),
                    ...MainDashboardData.topCategories
                        .map((c) => _categoryRow(c))
                        .toList(),
                  ],
                ),
                /*const SizedBox(width: 24),
                // Business vs Personal
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Business vs Personal',
                        style: WerlogTextStyles.caption),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        SizedBox(
                          width: 70,
                          height: 70,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CustomPaint(
                                size: const Size(70, 70),
                                painter: _BizPersonalDonut(
                                  business: MainDashboardData.businessPercent,
                                  personal: MainDashboardData.personalPercent,
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${MainDashboardData.businessPercent.toInt()}%',
                                    style: WerlogTextStyles.sectionTitle
                                        .copyWith(fontSize: 13),
                                  ),
                                  Text('Business',
                                      style: WerlogTextStyles.caption
                                          .copyWith(fontSize: 8)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                '${MainDashboardData.personalPercent.toInt()}%',
                                style: WerlogTextStyles.txTitle
                                    .copyWith(fontSize: 11)),
                            Text('Personal',
                                style: WerlogTextStyles.caption
                                    .copyWith(fontSize: 9)),
                            const SizedBox(height: 8),
                            Text('Business\nExpenses',
                                style: WerlogTextStyles.caption
                                    .copyWith(fontSize: 9)),
                            Text(MainDashboardData.businessExpenses,
                                style: WerlogTextStyles.txTitle
                                    .copyWith(fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),*/
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryRow(Map<String, dynamic> cat) {
    final colorMap = {
      'teal': WerlogColors.teal,
      'darkTeal': WerlogColors.darkTeal,
      'amber': WerlogColors.amber,
      'grey': WerlogColors.textTertiary,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: colorMap[cat['color']] ?? WerlogColors.teal,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(cat['name'],
              style: WerlogTextStyles.caption.copyWith(fontSize: 10)),
          const SizedBox(width: 12),
          Text(cat['amount'],
              style: WerlogTextStyles.txTitle.copyWith(fontSize: 10)),
        ],
      ),
    );
  }

  // ── Bottom nav ───────────────────────────
  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: WerlogColors.surface,
        border: Border(
          top: BorderSide(color: WerlogColors.border, width: 0.8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.home_rounded, 'Home', true, () {}),
              _navItem(Icons.verified_user_outlined, 'Warranty', false,
                      () => callWarrantyDashboardScreen()),
              _navScanButton(context),
              _navItem(Icons.attach_money, 'Expenses', false,
                      () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const ExpenseDashboardScreen(),
                  ))),
              /*_navItem(Icons.attach_money, 'Expenses', false,
                  () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ExpensesTaxScreen()))),*/
              _navItem(Icons.person_outline, 'Profile', false,
                      () {
                    final userData = SharedPrefHelper.getObject(SharedPrefHelper.loginData);
                    final user = userData?['meResponse'];
                    final email = user?['email'] ?? '';
                    final name = user?['fullName'] ?? '';
                    final plan = user?['planCode'] ?? '';
                    final profAbb = name.length >= 2
                        ? name.substring(0, 2).toUpperCase()
                        : name.toUpperCase();
                    print("profile user data: $user");
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => ProfileScreen(data: ProfileData(
                            fullName: name, email: email, planLabel: plan, initials: profAbb
                        ),)));
                  }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(
      IconData icon, String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              color:
              active ? WerlogColors.teal : WerlogColors.textTertiary,
              size: 22),
          const SizedBox(height: 3),
          Text(
            label,
            style: WerlogTextStyles.tabLabel.copyWith(
              color:
              active ? WerlogColors.teal : WerlogColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _navScanButton(BuildContext context) {
    return GestureDetector(
      onTap: () {_openBottomSheet(context);},
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: WerlogGradients.darkHero(),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: WerlogColors.teal.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.crop_free, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 3),
          /*Text('Scan',
              style: WerlogTextStyles.tabLabel
                  .copyWith(color: WerlogColors.teal)),*/
        ],
      ),
    );
  }

  void _openBottomSheet(BuildContext context) {
    var scanType = ScanType.warranty;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,     // ✅ must be true
      enableDrag: true,
      builder: (_) {
        return ScanTypeSheet(
          // data: data,
          onTypeSelected: (type) {
            print("Selected type: $type");
            scanType = type;
          },
          onContinue: () {
            Navigator.pop(context); // close sheet
            // onContinue?.call();     // trigger external logic

            AppRoutes.openNewCameraScreen(
              context,
              data: CameraViewData(scanType: scanType),
              onClose: () {
                print("Camera closed");
                Navigator.pop(context);
              },
              onProceed: (result) async {

                // 🔥 Upload scanned images
                final service = CameraUploadService(
                  baseUrl: ApiService.baseUrl,
                  authToken: await SharedPrefHelper.getString(SharedPrefHelper.accessToken),
                );

                // 📦 BUILD PARAMS MAP
                /*final params = {
                  "type": (scanType==ScanType.expense) ? "EXPENSE" : "WARRANTY",
                  "engine": "GPT4",
                  "subcategoryId": "",
                  "isBusiness": false,
                };*/

                // Declare both at the top so they're in scope for uploadImages call below
                final List<File> filesToUpload;
                final Map<String, dynamic> params;
                final String fieldName;

                if (result.isPdf) {
                  // ── PDF path: single file, empty params, fieldName 'files' ────────
                  filesToUpload = [result.pdf!];
                  params = {
                    "documentType": (scanType == ScanType.expense) ? "EXPENSE" : "WARRANTY",
                    "engine": "GPT4",
                  };
                  fieldName     = 'files';
                } else {
                  // ── Images path ────────────────────────────────────────────────────
                  filesToUpload = result.images;   // already List<File>
                  fieldName     = 'files';

                  if (result.images.length > 1) {
                    params = {
                      "documentType": (scanType == ScanType.expense) ? "EXPENSE" : "WARRANTY",
                      "engine": "GPT4",
                      "mode": "MULTI_SEGMENT",
                    };
                  } else {
                    params = {
                      "documentType": (scanType == ScanType.expense) ? "EXPENSE" : "WARRANTY",
                      "engine": "GPT4",
                    };
                  }
                }

                /*if(images.length > 1) {
                  params = {
                    "documentType": (scanType == ScanType.expense)
                        ? "EXPENSE"
                        : "WARRANTY",
                    "engine": "GPT4",
                    "mode":"MULTI_SEGMENT"
                  };
                }else  {
                  params = {
                    "documentType": (scanType == ScanType.expense)
                        ? "EXPENSE"
                        : "WARRANTY",
                    "engine": "GPT4"
                  };
                }*/

                // 🔥 IMPORTANT: SEND AS STRING JSON
                // request.fields['params'] = jsonEncode(params);

                final results = await service.uploadImages(
                  context: context,
                  images:      filesToUpload,
                  endpoint:    Endpoints.UPLOAD_SCANNED_IMAGE,
                  fieldName:   fieldName,
                  extraFields: params.isNotEmpty
                      ? {"params": jsonEncode(params)}
                      : {},            // empty params → send no extra fields for PDF
                );

                if (results.success) {
                  print("Upload success");
                  print(results.body);
                } else {
                  print("Upload failed: ${results.error ?? results.body}");
                  print("## ## Upload failed: ${results.body}");

                  if (!context.mounted) return;

                  // ── Parse error body ────────────────────────────────────────────
                  Map<String, dynamic>? errorBody;
                  try {
                    errorBody = jsonDecode(results.body) as Map<String, dynamic>?;
                  } catch (_) {}

                  final errorCode    = errorBody?['error']?.toString() ?? '';
                  final errorMessage = errorBody?['message']?.toString() ?? 'Something went wrong.';

                  if (errorCode == 'PLAN_RESTRICTION') {
                    // ── Show upgrade dialog ───────────────────────────────────────
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => PlanRestrictionDialog(
                        message: errorMessage,
                        onViewPlans: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SubscriptionScreen(
                                onContinue: (plan) {
                                  _proceedCheckout(plan);
                                },
                              ),
                            ),
                          );
                        },
                        onViewUsage: () {
                          Navigator.pop(context);
                          Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const SubscriptionUsageScreen())); // or your usage screen route
                        },
                        onCancel: () {
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                      ),
                    );
                  } else {
                    // ── Generic toast error ───────────────────────────────────────
                    GeneralFunctions.showError(context, errorMessage);
                  }

                  return; // stop — don't proceed to OCR screen
                }

                /*final uploadedData = await uploadScannedImages(images);
                if (!context.mounted) return;
                // Optional fail check
                if (uploadedData == null) return;*/

                if (!context.mounted) return;
                print("#######\n" + results.body);
                final Map<String, dynamic> data =
                (jsonDecode(results.body)['data']['jobs'] as List).first
                as Map<String, dynamic>;

                // 🔥 Open OCR processing screen
                AppRoutes.openNewOcrProcessingScreen(
                  context,
                  data: OcrProcessingDataNew(
                    scanType:    scanType,
                    processData: data,
                  ),
                  onBack: () {
                    Navigator.pop(context);
                    print("Back from OCR screen");
                  },
                  /* onProceed: () {}*/
                );
              },
              /*onProceed: (result) async {

                // 🔥 Upload scanned images

                final service = CameraUploadService(
                  baseUrl: ApiService.baseUrl,
                  authToken: await SharedPrefHelper.getString(SharedPrefHelper.accessToken),
                );

                // 📦 BUILD PARAMS MAP
                *//*final params = {
                  "type": (scanType==ScanType.expense) ? "EXPENSE" : "WARRANTY",
                  "engine": "GPT4",
                  "subcategoryId": "",
                  "isBusiness": false,
                };*//*
                var params;
                if (result.isPdf) {
                  // ── PDF path ──────────────────────────────────────────
                  final pdfFile = result.pdf!;
                  params = {};
                  // upload pdfFile as a single file
                } else {
                  // ── Images path ───────────────────────────────────────
                  final images = result.images;
                  if (images.length > 1) {
                    params = {
                      "documentType": scanType == ScanType.expense ? "EXPENSE" : "WARRANTY",
                      "engine": "GPT4",
                      "mode": "MULTI_SEGMENT",
                    };
                  } else {
                    params = {
                      "documentType": scanType == ScanType.expense ? "EXPENSE" : "WARRANTY",
                      "engine": "GPT4",
                    };
                  }
                  // upload images list
                }
                *//*if(images.length > 1) {
                  params = {
                    "documentType": (scanType == ScanType.expense)
                        ? "EXPENSE"
                        : "WARRANTY",
                    "engine": "GPT4",
                    "mode":"MULTI_SEGMENT"
                  };
                }else  {
                  params = {
                    "documentType": (scanType == ScanType.expense)
                        ? "EXPENSE"
                        : "WARRANTY",
                    "engine": "GPT4"
                  };
                }*//*

                // 🔥 IMPORTANT: SEND AS STRING JSON
                // request.fields['params'] = jsonEncode(params);

                final results = await service.uploadImages(
                  images: images, // List<File>
                  endpoint: Endpoints.UPLOAD_SCANNED_IMAGE,
                  extraFields: {
                    "params": jsonEncode(params)
                  },
                );

                if (results.success) {
                  print("Upload success");
                  print(results.body);
                } else {
                  print("Upload failed: ${results.error ?? results.body}");
                }

                *//*final uploadedData = await uploadScannedImages(images);

                if (!context.mounted) return;

                // Optional fail check
                if (uploadedData == null) return;*//*
                if (!context.mounted) return;
                print("#######\n"+results.body);
                final Map<String, dynamic> data =
                  (jsonDecode(results.body)['data']['jobs'] as List).first as Map<String, dynamic>;

                // 🔥 Open OCR processing screen
                AppRoutes.openNewOcrProcessingScreen(
                  context,
                  data: OcrProcessingDataNew(
                    scanType: scanType,
                    processData: data,
                  ),
                  onBack: () {
                    Navigator.pop(context);
                    print("Back from OCR screen");
                  },
                  *//* onProceed: () {}*//*
                );
              },*/
            );
            /*AppRoutes.openCameraScreen(
              context,
              onClose: () {
                print("Camera closed");
                Navigator.pop(context);
              },
              onCapture: () {
                AppRoutes.openOcrProcessingScreen(
                  context,
                  data: OcrProcessingData(
                    scanType: scanType,
                    // add your captured image/file here if needed
                  ),
                  onBack: () {
                    Navigator.pop(context);
                    print("Back from OCR screen");
                  },
                );
              },
              onToggleFlash: () {
                print("Flash toggled");
              },
              onSwitchCamera: () {
                print("Camera switched");
              },
              onGallery: () {
                print("Gallery opened");
              },
            );*/
          },
        );
      },
    );
  }

  Future<void> refreshData() async {

    try {

      final response = await ApiService.callRefreshTokenApi();
      final responseData = response['data'];

      print("_doRefresh::REFRESH-RESPONSE: "+responseData.toString());
      // Persist the new session data locally
      await SharedPrefHelper.saveObject(
        SharedPrefHelper.loginData,
        responseData,
      );
      await SharedPrefHelper.saveString(
        SharedPrefHelper.accessToken,
        responseData['accessToken'],
      );

      final String? serverCurrency = responseData['currency']?.toString();
      print("::handleAuthResponse currency from server => $serverCurrency");

      if (serverCurrency != null && serverCurrency.isNotEmpty) {
        // Server provided a currency — find it in the fixed list and save
        final match = GeneralFunctions.kCurrencies.firstWhere(
              (c) => c.code.toUpperCase() == serverCurrency.toUpperCase(),
          orElse: () => const CurrencyItem(
              id: 'usd', code: 'USD', symbol: '\$',
              name: 'US Dollar', country: 'United States', region: 'Americas'),
        );
        await SharedPrefHelper.saveString(SharedPrefHelper.selectedCurrencyId,     match.id);
        await SharedPrefHelper.saveString(SharedPrefHelper.selectedCurrencySymbol, match.symbol);
        await SharedPrefHelper.saveString(SharedPrefHelper.selectedCurrencyCode,   match.code);
        await SharedPrefHelper.saveString(SharedPrefHelper.selectedCurrencyName,   match.name);
        GeneralFunctions.currencySymbol = '${match.symbol} ';
        print("::handleAuthResponse currency set => ${match.code} ${match.symbol}");
      } else {
        // Server returned null — keep existing saved currency or default $
        print("::handleAuthResponse currency is null — keeping existing or \$ default");
      }

    } catch (e) {

      print('ERROR => $e');

      GeneralFunctions.showError(
        context,
        "Process interrupted. Please try again!",
      );
    }
  }

  Future<void> loadDashboardData() async {

    try {

      final response = await ApiService.get(
        context,
        Endpoints.USER_MAIN_DASHBOARD,
      );

      print('\nSUCCESS => $response');

      final result = response['result'] == "1";

      if (result) {

        final data = response['data'] ?? {};
        final greeting = data['greeting'] ?? {};
        final taxSavings = data['taxSavings'] ?? {};
        final warranty = data['warranty'] ?? {};
        final expenses = data['expenses'] ?? {};
        final spendingSnapshot = data['spendingSnapshot'] ?? {};
        final split = spendingSnapshot['split'] ?? {};

        setState(() {

          // =========================================================
          // HEADER
          // =========================================================

          MainDashboardData.salutation = greeting['salutation']?.toString() ?? '';
          MainDashboardData.subtitle = greeting['subtitle']?.toString() ?? '';
          MainDashboardData.userName = greeting['name']?.toString() ?? '';

          MainDashboardData.notificationCount = data['unreadNotifications'] ?? 0;

          // =========================================================
          // TAX SAVINGS
          // =========================================================

          MainDashboardData.taxSavingsYear =
              taxSavings['year']?.toString() ?? '';

          MainDashboardData.taxSavingsAmount =
          '${GeneralFunctions.currencySymbol}${(taxSavings['estimatedSavings'] ?? 0).toString()}';

          MainDashboardData.taxSavingsChange =
          '${(taxSavings['vsLastYearPercent'] ?? 0).toString()}% higher than last year';

          MainDashboardData.taxSavingsPositive =
              (taxSavings['vsLastYearPercent'] ?? 0) >= 0;

          MainDashboardData.gstHstToClaim =
          '${GeneralFunctions.currencySymbol}${(taxSavings['gstHstClaimable'] ?? 0).toString()}';

          MainDashboardData.taxDeductions =
          '${GeneralFunctions.currencySymbol}${(taxSavings['taxDeductions'] ?? 0).toString()}';

          // =========================================================
          // WARRANTY SUMMARY
          // =========================================================

          MainDashboardData.totalWarranties =
              warranty['total'] ?? 0;

          MainDashboardData.activeWarranties =
              warranty['active'] ?? 0;

          MainDashboardData.expiringSoonWarranties =
              warranty['expiringSoon'] ?? 0;

          MainDashboardData.expiredWarranties =
              warranty['expired'] ?? 0;

          MainDashboardData.claimedWarranties =
              warranty['claimed'] ?? 0;

          // =========================================================
          // EXPENSES
          // =========================================================

          MainDashboardData.totalExpenses =
          '${GeneralFunctions.currencySymbol}${(expenses['totalExpenses'] ?? 0).toString()}';

          MainDashboardData.gstHstPaid =
          '${GeneralFunctions.currencySymbol}${(expenses['gstHstPaid'] ?? 0).toString()}';

          MainDashboardData.eligibleDeductions =
          '${GeneralFunctions.currencySymbol}${(expenses['eligibleDeductions'] ?? 0).toString()}';

          MainDashboardData.documents =
              expenses['documentsCount'] ?? 0;

          // =========================================================
          // AI INSIGHTS
          // =========================================================

          print("AI_INSIGHTS:: ${data['aiInsights']}");
          /*MainDashboardData.aiInsights =
              (data['aiInsights'] as List<dynamic>? ?? [])
                  .map<Map<String, String>>((item) => {
                'title': item['title']?.toString() ?? '',
                'subtitle': item['subtitle']?.toString() ?? '',
                'icon': item['icon']?.toString() ?? 'sparkle',
              })
                  .toList();*/
          MainDashboardData.aiInsights =
              (data['aiInsights'] as List<dynamic>? ?? [])
                  .map<Map<String, String>>((item) => {
                'title':    GeneralFunctions.replaceCurrencySymbol(
                    item['title']?.toString() ?? ''),
                'subtitle': GeneralFunctions.replaceCurrencySymbol(
                    item['subtitle']?.toString() ?? ''),
                'icon':     item['icon']?.toString() ?? 'sparkle',
              })
                  .toList();

          // =========================================================
          // ALERTS
          // =========================================================

          MainDashboardData.alerts =
              (data['alerts'] as List<dynamic>? ?? [])
                  .map<Map<String, String>>((item) {

                String color = 'teal';

                switch ((item['severity'] ?? '').toString().toUpperCase()) {
                  case 'HIGH':
                    color = 'coral';
                    break;

                  case 'MEDIUM':
                    color = 'amber';
                    break;

                  case 'LOW':
                    color = 'teal';
                    break;
                }

                return {
                  'title': item['title']?.toString() ?? '',
                  'subtitle': item['dueLabel']?.toString() ?? '',
                  'icon': item['type']?.toString() ?? 'warning',
                  'color': color,
                };
              })
                  .toList();

          // =========================================================
          // SPENDING SNAPSHOT
          // =========================================================

          MainDashboardData.totalSpending =
          '${GeneralFunctions.currencySymbol}${(spendingSnapshot['totalSpending'] ?? 0).toString()}';

          MainDashboardData.spendingChange =
          '${(spendingSnapshot['vsLastYearPercent'] ?? 0).toString()}% vs last year';

          MainDashboardData.spendingPositive =
              (spendingSnapshot['vsLastYearPercent'] ?? 0) >= 0;

          MainDashboardData.topCategories =
              (spendingSnapshot['topCategories'] as List<dynamic>? ?? [])
                  .map<Map<String, dynamic>>((item) => {
                'name': item['name']?.toString() ?? '',
                'amount': '${GeneralFunctions.currencySymbol}${(item['amount'] ?? 0).toString()}',
                'color': item['color']?.toString() ?? 'teal',
              })
                  .toList();

          MainDashboardData.businessPercent =
              ((split['businessPercent'] ?? 0) as num).toDouble();

          MainDashboardData.personalPercent =
              ((split['personalPercent'] ?? 0) as num).toDouble();

          MainDashboardData.businessExpenses =
          '${GeneralFunctions.currencySymbol}${(split['businessAmount'] ?? 0).toString()}';

          // =========================================================
          // RECENT INVOICES
          // =========================================================

          MainDashboardData.recentInvoices =
              (data['recentInvoices'] as List<dynamic>? ?? [])
                  .map<Map<String, dynamic>>((item) => {
                'invoiceId':       item['invoiceId']?.toString() ?? '',
                'vendorName':      item['vendorName']?.toString() ?? '',
                'invoiceDate':     item['invoiceDate']?.toString() ?? '',
                'totalAmount':     (item['totalAmount'] as num?)?.toDouble() ?? 0.0,
                'currency':        item['currency']?.toString() ?? '',
                'subcategoryName': item['subcategoryName']?.toString() ?? '',
                'thumbnailUrl':    item['thumbnailUrl']?.toString() ?? '',
                'needsReview':     item['needsReview'] == true,
                'autoCategorized': item['autoCategorized'] == true,
                'imageUrls':       (item['imageUrls'] as List<dynamic>? ?? [])
                    .map((e) => e.toString()).toList(),
                'items':           (item['items'] as List<dynamic>? ?? [])
                    .map<Map<String, dynamic>>((i) => {
                  'description': i['description']?.toString() ?? '',
                  'quantity':    (i['quantity'] as num?)?.toInt() ?? 1,
                  'unitPrice':   (i['unitPrice'] as num?)?.toDouble() ?? 0.0,
                  'amount':      (i['amount'] as num?)?.toDouble() ?? 0.0,
                }).toList(),
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

  Future<dynamic> uploadScannedImages(List<File> images) async {
    try {


      final response = await ApiService.get(
        context,
        Endpoints.UPLOAD_SCANNED_IMAGE,
      );

      print('\nSUCCESS => $response');

      final result = response['result'] == "1";

      if (result) {

        final data = response['data'] ?? {};

        setState(() {

          // =========================================================
          // HEADER
          // =========================================================



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

  // ── Recent Expense Invoices ───────────────────────────────────────────────
  Widget _buildRecentInvoices(BuildContext context) {
    final invoices = MainDashboardData.recentInvoices;
    if (invoices.isEmpty) return const SizedBox.shrink();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      // ── Section heading ─────────────────────────────────────────────────
      Row(children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: WerlogColors.tealSurface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.receipt_long_rounded,
              size: 14, color: WerlogColors.teal),
        ),
        const SizedBox(width: 8),
        const Text('Recent Expense Invoices',
            style: WerlogTextStyles.sectionTitle),
        // const Spacer(),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: () {
            // Navigate to full expense list
          },
          child: Text('(${invoices.length})',
              style: WerlogTextStyles.link.copyWith(fontSize: 12)),
        ),
      ]),

      const SizedBox(height: 10),

      // ── Invoice list ────────────────────────────────────────────────────
      ...invoices.map((inv) => _RecentInvoiceCard(
        invoice: inv,
        onTap: () => _openInvoiceDetail(context, inv),
      )).toList(),
    ]);
  }

  void _openInvoiceDetail(BuildContext context, Map<String, dynamic> inv) {
    // InvoiceItem.fromJson handles all field parsing including imageUrls and items
    final item = InvoiceItem.fromJson(inv);

    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ExpenseDetailScreen(
        item:      item,
        imageUrls: item.imageUrls,   // already parsed inside fromJson
      ),
    ));
  }

  void callWarrantyDashboardScreen() {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const  WarrantyDashboardScreen()));
  }



  Future<void> _proceedCheckout(SubscriptionPlan plan) async {
    try {
      final response = await ApiService.post(
        context,
        Endpoints.SUBSCRIBE_PLAN,
        body: {
          'planCode':    plan.code,
        },
      );

      debugPrint('\nSUBSCRIPTION PLANS => $response');

      final success = response['result'] == '1';

      if (success) {
        final responseData = response['data'];
        final checkoutUrl = responseData['checkoutUrl']?.toString();

        if (checkoutUrl == null || checkoutUrl.isEmpty) {
          if (mounted) {
            GeneralFunctions.showError(context, 'Invalid checkout URL.');
          }
          return;
        }

        if (!mounted) return;

        // Open WebView and wait for result
        final result = await Navigator.push<CheckoutResult>(
          context,
          MaterialPageRoute(
            builder: (_) => CheckoutWebViewScreen(
              checkoutUrl: checkoutUrl,
              successUrl: 'https://werlog.com/billing/success', // match your Stripe success_url
              cancelUrl: 'https://werlog.com/billing/cancel',   // match your Stripe cancel_url
            ),
          ),
        );

        if (!mounted) return;

        // Show result dialog
        _showCheckoutResultDialog(result ?? CheckoutResult.cancelled);

      } else {
        if (mounted) {
          GeneralFunctions.showError(
            context,
            response['message']?.toString() ?? 'Something went wrong.',
          );
        }
      }
    } catch (e) {
      debugPrint('SUBSCRIPTION ERROR => $e');
      if (mounted) {
        GeneralFunctions.showError(
          context,
          'Process interrupted. Please try again!',
        );
      }
    }
  }

  void _showCheckoutResultDialog(CheckoutResult result) {
    final isSuccess = result == CheckoutResult.success;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: isSuccess
                    ? Colors.green.shade50
                    : Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSuccess ? Icons.check_circle_outline : Icons.cancel_outlined,
                color: isSuccess ? Colors.green : Colors.orange,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isSuccess ? 'Payment Successful!' : 'Payment Cancelled',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSuccess
                  ? 'Your subscription has been activated. Enjoy your plan!'
                  : 'Your payment was cancelled. You can try again anytime.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSuccess ? Colors.green : Colors.black87,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Navigator.of(ctx).pop(); // close dialog
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const SubscriptionUsageScreen()));
                },
                child: Text(isSuccess ? 'View My Plan' : 'Okay'),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Future<void> _showDisclaimerIfNeeded() async {
    final acknowledged = await SharedPrefHelper.getBool(
        SharedPrefHelper.disclaimerAcknowledged, defaultValue: false) ?? false;
    if (acknowledged || !mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: WerlogColors.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [

              // Icon
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: WerlogColors.tealSurface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.info_outline_rounded,
                    color: WerlogColors.teal, size: 26),
              ),

              const SizedBox(height: 16),

              // Title
              const Text(
                'Before You Begin',
                style: TextStyle(
                  fontFamily: 'DMSans', fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: WerlogColors.textPrimary,
                ),
              ),

              const SizedBox(height: 12),

              // Body
              const Text(
                'Werlog helps you organise receipts, invoices, and warranties in one place.\n\n'
                    'All tax estimates, deduction figures, and financial summaries shown in the app '
                    'are for informational purposes only. Werlog does not provide tax, legal, or '
                    'accounting advice.\n\n'
                    'For personalised guidance please consult a qualified professional.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'DMSans', fontSize: 13,
                  color: WerlogColors.textSecondary,
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 20),
              const Divider(color: WerlogColors.borderLight),
              const SizedBox(height: 12),

              // Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await SharedPrefHelper.saveBool(
                        SharedPrefHelper.disclaimerAcknowledged, true);
                    if (mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WerlogColors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('I Understand',
                      style: TextStyle(
                        fontFamily: 'DMSans', fontSize: 14,
                        fontWeight: FontWeight.w500, color: Colors.white,
                      )),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Recent Invoice Card
// ─────────────────────────────────────────────────────────────────────────────

class _RecentInvoiceCard extends StatelessWidget {
  final Map<String, dynamic> invoice;
  final VoidCallback onTap;

  const _RecentInvoiceCard({
    required this.invoice,
    required this.onTap,
  });

  String get _formattedDate {
    final raw = invoice['invoiceDate']?.toString() ?? '';
    try {
      final dt = DateTime.parse(raw);
      const m = ['Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${m[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) { return raw; }
  }

  String get _formattedAmount {
    final currency = invoice['currency']?.toString() ?? '';
    final amount   = (invoice['totalAmount'] as num?)?.toDouble() ?? 0.0;
    return '$currency ${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final thumbnailUrl   = invoice['thumbnailUrl']?.toString() ?? '';
    final vendorName     = invoice['vendorName']?.toString() ?? '';
    final subcategory    = invoice['subcategoryName']?.toString() ?? '';
    final needsReview    = invoice['needsReview'] == true;
    final autoCategorized= invoice['autoCategorized'] == true;
    final items          = invoice['items'] as List<dynamic>? ?? [];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: WerlogColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: WerlogColors.border, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6, offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ── Thumbnail ──────────────────────────────────────────────────
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: WerlogColors.tealLightSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: WerlogColors.border, width: 0.8),
              ),
              clipBehavior: Clip.antiAlias,
              child: thumbnailUrl.isNotEmpty
                  ? Image.network(
                ApiService.baseImgUrl + thumbnailUrl,
                fit: BoxFit.cover,
                loadingBuilder: (_, child, progress) =>
                progress == null
                    ? child
                    : const Center(
                  child: SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: WerlogColors.teal),
                  ),
                ),
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.receipt_rounded,
                      color: WerlogColors.teal, size: 22),
                ),
              )
                  : const Center(
                child: Icon(Icons.receipt_rounded,
                    color: WerlogColors.teal, size: 22),
              ),
            ),

            const SizedBox(width: 12),

            // ── Main content ───────────────────────────────────────────────
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Vendor + amount
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(vendorName,
                          style: WerlogTextStyles.txTitle.copyWith(fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 8),
                    Text(_formattedAmount,
                        style: WerlogTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: WerlogColors.teal,
                            fontSize: 12)),
                  ],
                ),

                const SizedBox(height: 4),

                // Date + subcategory
                Row(children: [
                  const Icon(Icons.calendar_today_rounded,
                      size: 10, color: WerlogColors.textTertiary),
                  const SizedBox(width: 4),
                  Text(_formattedDate, style: WerlogTextStyles.captionSmall),
                  const SizedBox(width: 8),
                  Container(
                      width: 3, height: 3,
                      decoration: const BoxDecoration(
                          color: WerlogColors.textTertiary, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(subcategory,
                        style: WerlogTextStyles.captionSmall,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ]),

                const SizedBox(height: 6),

                // Line items preview (up to 2)
                ...items.take(2).map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(children: [
                    Container(
                      width: 4, height: 4,
                      margin: const EdgeInsets.only(right: 6, top: 1),
                      decoration: BoxDecoration(
                        color: WerlogColors.teal.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item['description']?.toString() ?? '',
                        style: WerlogTextStyles.captionSmall.copyWith(
                            color: WerlogColors.textSecondary),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${invoice['currency'] ?? ''} ${(item['amount'] as num?)?.toStringAsFixed(0) ?? '0'}',
                      style: WerlogTextStyles.captionSmall.copyWith(
                          color: WerlogColors.textSecondary),
                    ),
                  ]),
                )),

                if (items.length > 2) ...[
                  const SizedBox(height: 2),
                  Text('+${items.length - 2} more items',
                      style: WerlogTextStyles.captionSmall
                          .copyWith(color: WerlogColors.teal)),
                ],

                const SizedBox(height: 6),

                // Badges
                Row(children: [
                  if (autoCategorized)
                    _Badge(
                      label: 'Auto-categorized',
                      bg: WerlogColors.tealSurface,
                      color: WerlogColors.teal,
                      icon: Icons.auto_awesome_rounded,
                    ),
                  if (autoCategorized && needsReview)
                    const SizedBox(width: 6),
                  if (needsReview)
                    _Badge(
                      label: 'Needs review',
                      bg: WerlogColors.amberSurface,
                      color: WerlogColors.amber,
                      icon: Icons.warning_amber_rounded,
                    ),
                ]),
              ],
            )),

            // ── Chevron ────────────────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(Icons.chevron_right_rounded,
                  color: WerlogColors.textTertiary, size: 18),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Small badge widget ────────────────────────────────────────────────────────
class _Badge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color color;
  final IconData icon;

  const _Badge({
    required this.label,
    required this.bg,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(6)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 9, color: color),
        const SizedBox(width: 3),
        Text(label,
            style: TextStyle(
              fontFamily: 'DMSans', fontSize: 9,
              fontWeight: FontWeight.w500, color: color,
            )),
      ]),
    );
  }
}

// ── Custom painters ───────────────────────
class _DonutPainter extends CustomPainter {
  final int active, expiringSoon, expired, claimed;
  _DonutPainter(
      {required this.active,
        required this.expiringSoon,
        required this.expired,
        required this.claimed});

  @override
  void paint(Canvas canvas, Size size) {
    final total = (active + expiringSoon + expired + claimed).toDouble();
    if (total == 0) return;
    final rect = Rect.fromLTWH(4, 4, size.width - 8, size.height - 8);
    final strokeWidth = 7.0;
    final colors = [
      WerlogColors.teal,
      WerlogColors.amber,
      WerlogColors.coral,
      WerlogColors.textTertiary,
    ];
    final values = [active, expiringSoon, expired, claimed];
    double startAngle = -1.5708; // -π/2
    for (int i = 0; i < values.length; i++) {
      final sweep = (values[i] / total) * 2 * 3.14159;
      canvas.drawArc(
        rect,
        startAngle,
        sweep - 0.05,
        false,
        Paint()
          ..color = colors[i]
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BizPersonalDonut extends CustomPainter {
  final double business, personal;
  _BizPersonalDonut({required this.business, required this.personal});

  @override
  void paint(Canvas canvas, Size size) {
    final total = business + personal;
    final rect = Rect.fromLTWH(5, 5, size.width - 10, size.height - 10);
    double startAngle = -1.5708;

    final parts = [
      {'value': business, 'color': WerlogColors.darkTeal},
      {'value': personal, 'color': WerlogColors.tealLight},
    ];
    for (final p in parts) {
      final sweep =
          ((p['value'] as double) / total) * 2 * 3.14159;
      canvas.drawArc(
        rect,
        startAngle,
        sweep - 0.05,
        false,
        Paint()
          ..color = p['color'] as Color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..strokeCap = StrokeCap.round,
      );
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}