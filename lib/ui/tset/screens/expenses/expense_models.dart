import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  EXPENSE MODULE — DATA MODELS
//  Replace every static value here with your API response later.
//  All screens import from this single file — one update propagates everywhere.
// ═══════════════════════════════════════════════════════════════════════════

// ── Status enum ──────────────────────────────────────────────────────────────
enum ExpenseStatus { verified, needsReview, missingInfo, rejected }

extension ExpenseStatusX on ExpenseStatus {
  String get label {
    switch (this) {
      case ExpenseStatus.verified:    return 'Verified';
      case ExpenseStatus.needsReview: return 'Needs Review';
      case ExpenseStatus.missingInfo: return 'Missing Info';
      case ExpenseStatus.rejected:    return 'Rejected';
    }
  }

  Color get color {
    switch (this) {
      case ExpenseStatus.verified:    return const Color(0xFF1D9E75);
      case ExpenseStatus.needsReview: return const Color(0xFFBA7517);
      case ExpenseStatus.missingInfo: return const Color(0xFFD85A30);
      case ExpenseStatus.rejected:    return const Color(0xFFD85A30);
    }
  }

  Color get surface {
    switch (this) {
      case ExpenseStatus.verified:    return const Color(0xFFE1F5EE);
      case ExpenseStatus.needsReview: return const Color(0xFFFAEEDA);
      case ExpenseStatus.missingInfo: return const Color(0xFFFAECE7);
      case ExpenseStatus.rejected:    return const Color(0xFFFAECE7);
    }
  }
}

// ── Type enum ─────────────────────────────────────────────────────────────────
enum ExpenseType { business, personal, partial }

extension ExpenseTypeX on ExpenseType {
  String get label {
    switch (this) {
      case ExpenseType.business: return 'Business';
      case ExpenseType.personal: return 'Personal';
      case ExpenseType.partial:  return 'Partial';
    }
  }

  Color get color {
    switch (this) {
      case ExpenseType.business: return const Color(0xFF0F2A2E);
      case ExpenseType.personal: return const Color(0xFF888780);
      case ExpenseType.partial:  return const Color(0xFFBA7517);
    }
  }
}

// ── Expense item model ────────────────────────────────────────────────────────
class ExpenseItem {
  final String id;
  final String title;
  final String vendor;
  final String categoryId; // links to ExpenseCategory.id
  final String date;
  final String month;      // e.g. 'May 2024' — used for grouping
  final double amount;
  final double gstAmount;
  final double deductiblePercent; // 0–100
  final ExpenseType type;
  final ExpenseStatus status;
  final IconData icon;
  final int iconColorHex;
  final String? invoiceRef;
  final String? notes;
  final List<String> attachmentNames; // receipt filenames

  const ExpenseItem({
    required this.id,
    required this.title,
    required this.vendor,
    required this.categoryId,
    required this.date,
    required this.month,
    required this.amount,
    required this.gstAmount,
    required this.deductiblePercent,
    required this.type,
    required this.status,
    required this.icon,
    required this.iconColorHex,
    this.invoiceRef,
    this.notes,
    this.attachmentNames = const [],
  });

  String get formattedAmount => '\$${amount.toStringAsFixed(2)}';
  String get formattedGst    => '\$${gstAmount.toStringAsFixed(2)}';
  double get deductibleAmount => amount * deductiblePercent / 100;
  Color  get iconColor        => Color(iconColorHex);
}

// ── Expense category model ────────────────────────────────────────────────────
class ExpenseCategory {
  final String id;
  final String name;
  final IconData icon;
  final int iconColorHex;
  final double totalAmount;
  final double gstAmount;
  final double deductibleAmount;
  final int itemCount;
  final int verifiedCount;
  final int needsReviewCount;
  final int missingInfoCount;

  const ExpenseCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.iconColorHex,
    required this.totalAmount,
    required this.gstAmount,
    required this.deductibleAmount,
    required this.itemCount,
    required this.verifiedCount,
    required this.needsReviewCount,
    required this.missingInfoCount,
  });

  Color get iconColor => Color(iconColorHex);
  String get formattedTotal       => '\$${totalAmount.toStringAsFixed(2)}';
  String get formattedGst         => '\$${gstAmount.toStringAsFixed(2)}';
  String get formattedDeductible  => '\$${deductibleAmount.toStringAsFixed(2)}';
}

// ── Monthly trend model ───────────────────────────────────────────────────────
class MonthlyTrend {
  final String month;       // short label e.g. 'Jan'
  final double amount;
  final double gstAmount;

  const MonthlyTrend({
    required this.month,
    required this.amount,
    required this.gstAmount,
  });
}

// ══════════════════════════════════════════════════════════════════════════════
//  EXPENSE DASHBOARD DATA  — replace statics with API calls
// ══════════════════════════════════════════════════════════════════════════════
class ExpenseDashboardData {
  ExpenseDashboardData._();

  // ── Header KPIs ─────────────────────────────────────────────────────────────
  static const String periodLabel          = 'This Year (2024)';
  static const double totalExpenses        = 12400.00;
  static const double totalGstPaid         = 640.00;
  static const double eligibleDeductions   = 1790.00;
  static const double estimatedTaxSavings  = 2430.00;
  static const double businessExpenses     = 8432.00;
  static const double personalExpenses     = 3968.00;
  static const double yoyChange            = -8.0;  // negative = lower = good
  static const bool   yoyPositive          = false; // false = spent less = green
  static const int    totalDocuments       = 86;
  static const int    needsReviewCount     = 12;
  static const int    missingInfoCount     = 3;

  // ── Quick stats for dashboard cards ─────────────────────────────────────────
  static const double claimableGst         = 598.00;
  static const double nonClaimableGst      = 42.00;
  static const double totalDeductions      = 1790.00;

  // ── Categories ───────────────────────────────────────────────────────────────
  static const List<ExpenseCategory> categories = [
    ExpenseCategory(
      id: 'cat_office',
      name: 'Office & Supplies',
      icon: Icons.inventory_2_outlined,
      iconColorHex: 0xFF1D9E75,
      totalAmount: 4250.00,
      gstAmount: 212.50,
      deductibleAmount: 4250.00,
      itemCount: 18,
      verifiedCount: 14,
      needsReviewCount: 3,
      missingInfoCount: 1,
    ),
    ExpenseCategory(
      id: 'cat_auto',
      name: 'Auto & Vehicle',
      icon: Icons.directions_car_outlined,
      iconColorHex: 0xFF0F2A2E,
      totalAmount: 2950.00,
      gstAmount: 147.50,
      deductibleAmount: 2065.00,
      itemCount: 22,
      verifiedCount: 16,
      needsReviewCount: 4,
      missingInfoCount: 2,
    ),
    ExpenseCategory(
      id: 'cat_travel',
      name: 'Travel',
      icon: Icons.flight_outlined,
      iconColorHex: 0xFFBA7517,
      totalAmount: 2100.00,
      gstAmount: 105.00,
      deductibleAmount: 2100.00,
      itemCount: 9,
      verifiedCount: 8,
      needsReviewCount: 1,
      missingInfoCount: 0,
    ),
    ExpenseCategory(
      id: 'cat_meals',
      name: 'Meals & Entertainment',
      icon: Icons.restaurant_outlined,
      iconColorHex: 0xFFD85A30,
      totalAmount: 1800.00,
      gstAmount: 90.00,
      deductibleAmount: 900.00,
      itemCount: 14,
      verifiedCount: 10,
      needsReviewCount: 3,
      missingInfoCount: 1,
    ),
    ExpenseCategory(
      id: 'cat_software',
      name: 'Software & SaaS',
      icon: Icons.devices_outlined,
      iconColorHex: 0xFF7B5EA7,
      totalAmount: 659.00,
      gstAmount: 32.95,
      deductibleAmount: 659.00,
      itemCount: 7,
      verifiedCount: 7,
      needsReviewCount: 0,
      missingInfoCount: 0,
    ),
    ExpenseCategory(
      id: 'cat_homeoffice',
      name: 'Home Office',
      icon: Icons.home_work_outlined,
      iconColorHex: 0xFF5DCAA5,
      totalAmount: 540.00,
      gstAmount: 27.00,
      deductibleAmount: 270.00,
      itemCount: 6,
      verifiedCount: 4,
      needsReviewCount: 1,
      missingInfoCount: 1,
    ),
    ExpenseCategory(
      id: 'cat_professional',
      name: 'Professional Dev',
      icon: Icons.school_outlined,
      iconColorHex: 0xFF1D9E75,
      totalAmount: 380.00,
      gstAmount: 19.00,
      deductibleAmount: 380.00,
      itemCount: 4,
      verifiedCount: 3,
      needsReviewCount: 1,
      missingInfoCount: 0,
    ),
    ExpenseCategory(
      id: 'cat_insurance',
      name: 'Insurance',
      icon: Icons.shield_outlined,
      iconColorHex: 0xFF0F2A2E,
      totalAmount: 320.00,
      gstAmount: 0.00,
      deductibleAmount: 320.00,
      itemCount: 4,
      verifiedCount: 4,
      needsReviewCount: 0,
      missingInfoCount: 0,
    ),
    ExpenseCategory(
      id: 'cat_other',
      name: 'Other',
      icon: Icons.more_horiz,
      iconColorHex: 0xFF888780,
      totalAmount: 401.00,
      gstAmount: 6.05,
      deductibleAmount: 0.00,
      itemCount: 8,
      verifiedCount: 4,
      needsReviewCount: 3,
      missingInfoCount: 1,
    ),
  ];

  // ── Monthly trend (12 months) ────────────────────────────────────────────────
  static const List<MonthlyTrend> monthlyTrend = [
    MonthlyTrend(month: 'Jul', amount: 920,  gstAmount: 46),
    MonthlyTrend(month: 'Aug', amount: 1100, gstAmount: 55),
    MonthlyTrend(month: 'Sep', amount: 870,  gstAmount: 43),
    MonthlyTrend(month: 'Oct', amount: 1340, gstAmount: 67),
    MonthlyTrend(month: 'Nov', amount: 1580, gstAmount: 79),
    MonthlyTrend(month: 'Dec', amount: 1920, gstAmount: 96),
    MonthlyTrend(month: 'Jan', amount: 780,  gstAmount: 39),
    MonthlyTrend(month: 'Feb', amount: 1050, gstAmount: 52),
    MonthlyTrend(month: 'Mar', amount: 960,  gstAmount: 48),
    MonthlyTrend(month: 'Apr', amount: 1130, gstAmount: 56),
    MonthlyTrend(month: 'May', amount: 750,  gstAmount: 37),
    MonthlyTrend(month: 'Jun', amount: 0,    gstAmount: 0),
  ];

  // ── Alerts ────────────────────────────────────────────────────────────────────
  static const List<Map<String, String>> alerts = [
    {
      'title': 'Tax filing due in 30 days',
      'subtitle': '15 Jun 2024',
      'type': 'deadline',
      'color': 'amber',
    },
    {
      'title': '12 expenses need review',
      'subtitle': 'Review Now',
      'type': 'review',
      'color': 'teal',
    },
    {
      'title': '3 receipts missing info',
      'subtitle': 'Update Now',
      'type': 'missing',
      'color': 'coral',
    },
    {
      'title': '\$380 potential missed claims',
      'subtitle': 'View Details',
      'type': 'opportunity',
      'color': 'purple',
    },
  ];

  // ── AI Insights ───────────────────────────────────────────────────────────────
  static const List<Map<String, String>> aiInsights = [
    {
      'title': 'Internet bill may qualify as Home Office Expense',
      'subtitle': 'You could save up to \$120',
      'icon': 'home',
    },
    {
      'title': 'Vehicle fuel expenses partially claimable',
      'subtitle': 'Add business usage % to unlock \$260 deduction',
      'icon': 'car',
    },
    {
      'title': '4 receipts are missing GST/HST details',
      'subtitle': '\$380 in potential missed claims',
      'icon': 'receipt',
    },
  ];

  // ── Tax summary rows ──────────────────────────────────────────────────────────
  static const List<Map<String, String>> taxSummaryRows = [
    {'label': 'Total GST/HST Paid',       'value': '\$640.00',    'type': 'neutral'},
    {'label': 'Claimable GST/HST',        'value': '\$598.00',    'type': 'positive'},
    {'label': 'Non-Claimable GST',        'value': '\$42.00',     'type': 'negative'},
    {'label': 'Total Business Expenses',  'value': '\$8,432.00',  'type': 'neutral'},
    {'label': 'Total Deductions',         'value': '\$1,790.00',  'type': 'positive'},
    {'label': 'Estimated Tax Savings',    'value': '\$2,430.00',  'type': 'highlight'},
  ];

  // ── Tax tips ──────────────────────────────────────────────────────────────────
  static const List<String> taxTips = [
    'Keep all receipts — even under \$30 for CRA compliance.',
    'Track mileage for vehicle business use claims.',
    'Home office expenses are partially deductible (workspace %).',
    'Professional development courses are 100% deductible.',
    'Meals with clients are 50% deductible — always note the business purpose.',
    'Software subscriptions used solely for business are fully deductible.',
  ];
}

// ══════════════════════════════════════════════════════════════════════════════
//  EXPENSE ITEMS — per category  (replace with API-filtered response)
// ══════════════════════════════════════════════════════════════════════════════
class ExpenseItemsData {
  ExpenseItemsData._();

  static const List<ExpenseItem> all = [
    // ── Office & Supplies ──
    ExpenseItem(
      id: 'e001', title: 'Adobe Creative Cloud', vendor: 'Adobe Inc.',
      categoryId: 'cat_software', date: '01 May 2024', month: 'May 2024',
      amount: 54.99, gstAmount: 2.75, deductiblePercent: 100,
      type: ExpenseType.business, status: ExpenseStatus.verified,
      icon: Icons.brush_outlined, iconColorHex: 0xFF7B5EA7,
      invoiceRef: 'ADB-2024-0501', notes: 'Annual plan renewal.',
      attachmentNames: ['Adobe_Invoice_May2024.pdf'],
    ),
    ExpenseItem(
      id: 'e002', title: 'Office Supplies — Staples', vendor: 'Staples Canada',
      categoryId: 'cat_office', date: '28 Apr 2024', month: 'Apr 2024',
      amount: 143.50, gstAmount: 13.05, deductiblePercent: 100,
      type: ExpenseType.business, status: ExpenseStatus.needsReview,
      icon: Icons.inventory_2_outlined, iconColorHex: 0xFF1D9E75,
      invoiceRef: 'STP-2024-0428', attachmentNames: ['Staples_Receipt_Apr2024.pdf'],
    ),
    ExpenseItem(
      id: 'e003', title: 'Internet Bill — Rogers', vendor: 'Rogers',
      categoryId: 'cat_homeoffice', date: '25 Apr 2024', month: 'Apr 2024',
      amount: 89.99, gstAmount: 4.50, deductiblePercent: 50,
      type: ExpenseType.partial, status: ExpenseStatus.verified,
      icon: Icons.wifi_outlined, iconColorHex: 0xFF5DCAA5,
      invoiceRef: 'ROG-2024-0425', notes: '50% home office allocation.',
      attachmentNames: ['Rogers_Bill_Apr2024.pdf'],
    ),
    ExpenseItem(
      id: 'e004', title: 'Fuel — Shell Station', vendor: 'Shell Canada',
      categoryId: 'cat_auto', date: '22 Apr 2024', month: 'Apr 2024',
      amount: 78.20, gstAmount: 3.91, deductiblePercent: 70,
      type: ExpenseType.partial, status: ExpenseStatus.missingInfo,
      icon: Icons.local_gas_station_outlined, iconColorHex: 0xFFBA7517,
      notes: 'Add business usage percentage.',
      attachmentNames: ['Shell_Receipt_Apr22.jpg'],
    ),
    ExpenseItem(
      id: 'e005', title: 'Client Lunch — Buca', vendor: 'Buca Restaurant',
      categoryId: 'cat_meals', date: '20 Apr 2024', month: 'Apr 2024',
      amount: 124.00, gstAmount: 6.20, deductiblePercent: 50,
      type: ExpenseType.business, status: ExpenseStatus.verified,
      icon: Icons.restaurant_outlined, iconColorHex: 0xFFD85A30,
      invoiceRef: 'BUCA-APR20', notes: 'Meeting with Q2 client — John Smith.',
      attachmentNames: ['Buca_Receipt_Apr2024.jpg'],
    ),
    ExpenseItem(
      id: 'e006', title: 'Flight — Toronto → Vancouver', vendor: 'Air Canada',
      categoryId: 'cat_travel', date: '18 Apr 2024', month: 'Apr 2024',
      amount: 430.00, gstAmount: 21.50, deductiblePercent: 100,
      type: ExpenseType.business, status: ExpenseStatus.verified,
      icon: Icons.flight_outlined, iconColorHex: 0xFF5DCAA5,
      invoiceRef: 'AC-2024-3941', notes: 'Conference trip.',
      attachmentNames: ['AirCanada_Booking.pdf'],
    ),
    ExpenseItem(
      id: 'e007', title: 'Parking — Conference Centre', vendor: 'Impark',
      categoryId: 'cat_auto', date: '17 Apr 2024', month: 'Apr 2024',
      amount: 22.00, gstAmount: 1.10, deductiblePercent: 100,
      type: ExpenseType.business, status: ExpenseStatus.verified,
      icon: Icons.local_parking_outlined, iconColorHex: 0xFF0F2A2E,
      attachmentNames: ['Impark_Receipt.jpg'],
    ),
    ExpenseItem(
      id: 'e008', title: 'Notion — Monthly', vendor: 'Notion Labs',
      categoryId: 'cat_software', date: '15 Apr 2024', month: 'Apr 2024',
      amount: 16.00, gstAmount: 0.80, deductiblePercent: 100,
      type: ExpenseType.business, status: ExpenseStatus.verified,
      icon: Icons.edit_note_outlined, iconColorHex: 0xFF0F2A2E,
      invoiceRef: 'NTN-2024-0415', attachmentNames: [],
    ),
    ExpenseItem(
      id: 'e009', title: 'LinkedIn Premium', vendor: 'LinkedIn',
      categoryId: 'cat_professional', date: '12 Apr 2024', month: 'Apr 2024',
      amount: 59.99, gstAmount: 3.00, deductiblePercent: 100,
      type: ExpenseType.business, status: ExpenseStatus.verified,
      icon: Icons.work_outline, iconColorHex: 0xFF0A66C2,
      invoiceRef: 'LI-2024-0412', attachmentNames: ['LinkedIn_Invoice.pdf'],
    ),
    ExpenseItem(
      id: 'e010', title: 'Hotel — Vancouver Marriott', vendor: 'Marriott',
      categoryId: 'cat_travel', date: '10 Apr 2024', month: 'Apr 2024',
      amount: 348.00, gstAmount: 17.40, deductiblePercent: 100,
      type: ExpenseType.business, status: ExpenseStatus.verified,
      icon: Icons.hotel_outlined, iconColorHex: 0xFFBA7517,
      invoiceRef: 'MARR-2024-78421', notes: '2 nights conference stay.',
      attachmentNames: ['Marriott_Folio.pdf'],
    ),
    ExpenseItem(
      id: 'e011', title: 'Car Insurance — Q2', vendor: 'Intact Insurance',
      categoryId: 'cat_insurance', date: '01 Apr 2024', month: 'Apr 2024',
      amount: 320.00, gstAmount: 0.00, deductiblePercent: 100,
      type: ExpenseType.business, status: ExpenseStatus.verified,
      icon: Icons.shield_outlined, iconColorHex: 0xFF0F2A2E,
      invoiceRef: 'INT-2024-Q2', attachmentNames: ['Intact_Policy.pdf'],
    ),
    ExpenseItem(
      id: 'e012', title: 'Printer Paper — Bulk', vendor: 'Costco Business',
      categoryId: 'cat_office', date: '05 Mar 2024', month: 'Mar 2024',
      amount: 89.00, gstAmount: 8.10, deductiblePercent: 100,
      type: ExpenseType.business, status: ExpenseStatus.verified,
      icon: Icons.print_outlined, iconColorHex: 0xFF1D9E75,
      attachmentNames: ['Costco_Receipt_Mar.jpg'],
    ),
    ExpenseItem(
      id: 'e013', title: 'Fuel — Petro-Canada', vendor: 'Petro-Canada',
      categoryId: 'cat_auto', date: '28 Mar 2024', month: 'Mar 2024',
      amount: 92.50, gstAmount: 4.63, deductiblePercent: 70,
      type: ExpenseType.partial, status: ExpenseStatus.verified,
      icon: Icons.local_gas_station_outlined, iconColorHex: 0xFFBA7517,
      attachmentNames: ['PetroCanada_Receipt.jpg'],
    ),
    ExpenseItem(
      id: 'e014', title: 'Team Dinner', vendor: 'The Keg',
      categoryId: 'cat_meals', date: '22 Mar 2024', month: 'Mar 2024',
      amount: 380.00, gstAmount: 19.00, deductiblePercent: 50,
      type: ExpenseType.business, status: ExpenseStatus.needsReview,
      icon: Icons.dinner_dining_outlined, iconColorHex: 0xFFD85A30,
      notes: 'Missing attendee list.',
      attachmentNames: ['Keg_Receipt_Mar.jpg'],
    ),
    ExpenseItem(
      id: 'e015', title: 'Udemy Course — Flutter', vendor: 'Udemy',
      categoryId: 'cat_professional', date: '10 Mar 2024', month: 'Mar 2024',
      amount: 29.99, gstAmount: 1.50, deductiblePercent: 100,
      type: ExpenseType.business, status: ExpenseStatus.verified,
      icon: Icons.school_outlined, iconColorHex: 0xFF1D9E75,
      invoiceRef: 'UDM-2024-0310', attachmentNames: ['Udemy_Invoice.pdf'],
    ),
  ];

  /// Filter items by categoryId — replace with API query parameter
  static List<ExpenseItem> forCategory(String categoryId) =>
      all.where((e) => e.categoryId == categoryId).toList();

  /// Filter items by status
  static List<ExpenseItem> byStatus(ExpenseStatus status) =>
      all.where((e) => e.status == status).toList();

  /// Filter items by type
  static List<ExpenseItem> byType(ExpenseType type) =>
      all.where((e) => e.type == type).toList();

  /// Group by month for section headers
  static Map<String, List<ExpenseItem>> groupedByMonth(List<ExpenseItem> items) {
    final map = <String, List<ExpenseItem>>{};
    for (final item in items) {
      map.putIfAbsent(item.month, () => []).add(item);
    }
    return map;
  }

  /// Stats for a given category
  static Map<String, dynamic> statsForCategory(String categoryId) {
    final items = forCategory(categoryId);
    final totalAmount    = items.fold(0.0, (s, e) => s + e.amount);
    final totalGst       = items.fold(0.0, (s, e) => s + e.gstAmount);
    final totalDeductible = items.fold(0.0, (s, e) => s + e.deductibleAmount);
    final verified      = items.where((e) => e.status == ExpenseStatus.verified).length;
    final needsReview   = items.where((e) => e.status == ExpenseStatus.needsReview).length;
    final missingInfo   = items.where((e) => e.status == ExpenseStatus.missingInfo).length;
    return {
      'total': items.length,
      'totalAmount': totalAmount,
      'totalGst': totalGst,
      'totalDeductible': totalDeductible,
      'verified': verified,
      'needsReview': needsReview,
      'missingInfo': missingInfo,
      'businessCount': items.where((e) => e.type == ExpenseType.business).length,
      'partialCount': items.where((e) => e.type == ExpenseType.partial).length,
      'personalCount': items.where((e) => e.type == ExpenseType.personal).length,
    };
  }
}
