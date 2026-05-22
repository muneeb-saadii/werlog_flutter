// ═══════════════════════════════════════════════════════════════════════
//  expense_data.dart  —  single source of truth for all 4 expense screens
// ═══════════════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';

// ─── Category model ────────────────────────────────────────────────────
class ExpenseCategory {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final double totalSpent;
  final double deductiblePct;
  final double gstPaid;
  final int missingCount;
  final List<ExpenseItem> items;

  const ExpenseCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.totalSpent,
    required this.deductiblePct,
    required this.gstPaid,
    required this.missingCount,
    required this.items,
  });

  double get deductibleAmount => totalSpent * deductiblePct / 100;
}

// ─── Expense item model ─────────────────────────────────────────────────
class ExpenseItem {
  final String id;
  final String title;
  final String date;
  final String subType;
  final double amount;
  final double gst;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;

  const ExpenseItem({
    required this.id,
    required this.title,
    required this.date,
    required this.subType,
    required this.amount,
    required this.gst,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });

  String get formattedAmount => '\$${amount.toStringAsFixed(2)}';
  String get formattedGst    => 'GST \$${gst.toStringAsFixed(2)}';
}

// ─── Invoice line item ──────────────────────────────────────────────────
class InvoiceLineItem {
  final String description;
  final int quantity;
  final double unitPrice;
  final double amount;

  const InvoiceLineItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.amount,
  });

  factory InvoiceLineItem.fromJson(Map<String, dynamic> json) {
    return InvoiceLineItem(
      description: json['description']?.toString() ?? '',
      quantity:    (json['quantity'] as num?)?.toInt() ?? 1,
      unitPrice:   (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      amount:      (json['amount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

// ─── Invoice (recentInvoices) model ────────────────────────────────────
class InvoiceItem {
  final String invoiceId;
  final String vendorName;
  final String invoiceDate;      // e.g. '2026-04-30'
  final double totalAmount;
  final String currency;
  final String subcategoryName;
  final String? thumbnailUrl;
  final bool needsReview;
  final bool autoCategorized;
  final List<InvoiceLineItem> items;
  final List<String> imageUrls;
  final String? websiteUrl;

  const InvoiceItem({
    required this.invoiceId,
    required this.vendorName,
    required this.invoiceDate,
    required this.totalAmount,
    required this.currency,
    required this.subcategoryName,
    this.thumbnailUrl,
    required this.needsReview,
    required this.autoCategorized,
    required this.items,
    required this.imageUrls,
    this.websiteUrl,
  });

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      invoiceId:        json['invoiceId']?.toString() ?? '',
      vendorName:       json['vendorName']?.toString() ?? '',
      invoiceDate:      json['invoiceDate']?.toString() ?? '',
      totalAmount:      (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      currency:         json['currency']?.toString() ?? '',
      subcategoryName:  json['subcategoryName']?.toString() ?? '',
      thumbnailUrl:     json['thumbnailUrl']?.toString(),
      needsReview:      json['needsReview'] == true,
      autoCategorized:  json['autoCategorized'] == true,
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => InvoiceLineItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      imageUrls: (json['imageUrls'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      websiteUrl: json['websiteurl']?.toString(),
    );
  }

  /// Display-friendly date: '2026-04-30' → 'Apr 30, 2026'
  String get formattedDate {
    try {
      final parts = invoiceDate.split('-');
      if (parts.length != 3) return invoiceDate;
      final dt = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      const months = [
        'Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec',
      ];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return invoiceDate;
    }
  }

  String get formattedAmount =>
      '${currency.isNotEmpty ? currency : '\$'} ${totalAmount.toStringAsFixed(2)}';
}

// ─── Category detail API response model ────────────────────────────────
class CategoryDetail {
  // header
  final String categoryId;
  final String name;
  final String? slug;
  final String? iconKey;

  // stats
  final double totalSpent;
  final double deductibleAmount;
  final double deductiblePercent;
  final double gstHstPaid;
  final int invoiceCount;
  final String currency;

  // businessUse
  final int businessUsePercent;
  final bool appliesToCategory;
  final String helpText;

  // monthly
  final List<MonthlyExpense> monthly;

  // recentInvoices
  final List<InvoiceItem> recentInvoices;

  const CategoryDetail({
    required this.categoryId,
    required this.name,
    this.slug,
    this.iconKey,
    required this.totalSpent,
    required this.deductibleAmount,
    required this.deductiblePercent,
    required this.gstHstPaid,
    required this.invoiceCount,
    required this.currency,
    required this.businessUsePercent,
    required this.appliesToCategory,
    required this.helpText,
    required this.monthly,
    required this.recentInvoices,
  });

  factory CategoryDetail.fromJson(Map<String, dynamic> data) {
    final header       = data['header']      as Map<String, dynamic>? ?? {};
    final stats        = data['stats']       as Map<String, dynamic>? ?? {};
    final businessUse  = data['businessUse'] as Map<String, dynamic>? ?? {};

    final monthlyRaw = data['monthly'] as List<dynamic>? ?? [];
    final invoicesRaw = data['recentInvoices'] as List<dynamic>? ?? [];

    return CategoryDetail(
      categoryId:         header['categoryId']?.toString() ?? '',
      name:               header['name']?.toString() ?? '',
      slug:               header['slug']?.toString(),
      iconKey:            header['iconKey']?.toString(),

      totalSpent:         (stats['totalSpent'] as num?)?.toDouble() ?? 0.0,
      deductibleAmount:   (stats['deductibleAmount'] as num?)?.toDouble() ?? 0.0,
      deductiblePercent:  (stats['deductiblePercent'] as num?)?.toDouble() ?? 0.0,
      gstHstPaid:         (stats['gstHstPaid'] as num?)?.toDouble() ?? 0.0,
      invoiceCount:       (stats['invoiceCount'] as num?)?.toInt() ?? 0,
      currency:           stats['currency']?.toString() ?? '',

      businessUsePercent: (businessUse['currentPercent'] as num?)?.toInt() ?? 100,
      appliesToCategory:  businessUse['appliesToCategory'] == true,
      helpText:           businessUse['helpText']?.toString() ?? '',

      monthly: monthlyRaw.map((e) =>
          MonthlyExpense.fromJson(e as Map<String, dynamic>)).toList(),

      recentInvoices: invoicesRaw.map((e) =>
          InvoiceItem.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

// ─── Monthly data model ─────────────────────────────────────────────────
class MonthlyExpense {
  final int monthNumber;    // 1–12
  final String month;       // 'Jan'
  final double expenses;
  final double deduction;
  final double gst;
  final int invoiceCount;

  const MonthlyExpense({
    this.monthNumber = 0,
    required this.month,
    required this.expenses,
    this.deduction = 0,
    this.gst = 0,
    this.invoiceCount = 0,
  });

  factory MonthlyExpense.fromJson(Map<String, dynamic> json) {
    return MonthlyExpense(
      monthNumber:  (json['month'] as num?)?.toInt() ?? 0,
      month:        json['monthLabel']?.toString() ?? '',
      expenses:     (json['amount'] as num?)?.toDouble() ?? 0.0,
      invoiceCount: (json['invoiceCount'] as num?)?.toInt() ?? 0,
    );
  }
}

// ─── Year data model ────────────────────────────────────────────────────
class TaxYear {
  final int year;
  final String status;
  final double totalExpenses;
  final double estDeduction;
  final double gstPaid;
  final int documents;
  final int missingReceipts;
  final int auditReadinessPct;
  final List<MonthlyExpense> monthly;

  const TaxYear({
    required this.year,
    required this.status,
    required this.totalExpenses,
    required this.estDeduction,
    required this.gstPaid,
    required this.documents,
    required this.missingReceipts,
    required this.auditReadinessPct,
    required this.monthly,
  });
}

// ─── Checklist item model ────────────────────────────────────────────────
class ChecklistItem {
  final String label;
  final String status;
  final String? detail;
  final IconData icon;

  const ChecklistItem({
    required this.label,
    required this.status,
    this.detail,
    required this.icon,
  });
}

// ═══════════════════════════════════════════════════════════════════════
//  DEMO DATA — replace statics with API response
// ═══════════════════════════════════════════════════════════════════════
class ExpenseData {
  ExpenseData._();

  static String currentYear       = '2025';
  static double totalExpenses     = 28540.00;
  static double estDeduction      = 8620.00;
  static double gstHstClaimable   = 2930.00;
  static double taxRefundForecast = 3450.00;

  static double deductibleAmt    = 8620.00;
  static double gstPaidAmt       = 2930.00;
  static double nonDeductibleAmt = 12750.00;
  static double personalAmt      = 4240.00;

  static List<Map<String, String>> aiInsights = [
    {'text': 'You may be missing \$420 in vehicle expense claims.', 'type': 'warning'},
    {'text': 'Internet bill of \$90/month may be eligible for deduction.', 'type': 'info'},
    {'text': '2 receipts need GST/HST details to be claimable.', 'type': 'warning'},
  ];

  static final List<ExpenseCategory> categories = [
    ExpenseCategory(
      id: 'vehicle', name: 'Vehicle & Fuel',
      description: 'Expenses related to vehicle, fuel,\nmaintenance, insurance, parking etc.',
      icon: Icons.directions_car_rounded,
      iconBg: const Color(0xFFE8F5E9), iconColor: const Color(0xFF2E7D32),
      totalSpent: 6540, deductiblePct: 70, gstPaid: 624, missingCount: 2,
      items: [
        ExpenseItem(id:'v1', title:'Shell Fuel', date:'May 15, 2025', subType:'Fuel',
            amount:80.50, gst:3.83, icon:Icons.local_gas_station_rounded,
            iconBg:Color(0xFFE8F5E9), iconColor:Color(0xFF2E7D32)),
        ExpenseItem(id:'v2', title:'Vehicle Insurance', date:'May 01, 2025', subType:'Insurance',
            amount:150.00, gst:0.00, icon:Icons.shield_rounded,
            iconBg:Color(0xFFE8F5E9), iconColor:Color(0xFF2E7D32)),
      ],
    ),
    ExpenseCategory(
      id: 'homeoffice', name: 'Home Office',
      description: 'Internet, phone, office space and related home office expenses.',
      icon: Icons.home_work_rounded,
      iconBg: const Color(0xFFE3F2FD), iconColor: const Color(0xFF1565C0),
      totalSpent: 4230, deductiblePct: 50, gstPaid: 380, missingCount: 1, items: [],
    ),
    ExpenseCategory(
      id: 'misc', name: 'Miscellaneous',
      description: 'Other business expenses that do not fit a specific category.',
      icon: Icons.more_horiz_rounded,
      iconBg: const Color(0xFFF5F5F5), iconColor: const Color(0xFF616161),
      totalSpent: 520, deductiblePct: 50, gstPaid: 26, missingCount: 0, items: [],
    ),
  ];

  static List<MonthlyExpense> vehicleMonthly = [
    MonthlyExpense(month:'Jan', expenses:420, deduction:294, gst:40),
    MonthlyExpense(month:'Feb', expenses:380, deduction:266, gst:36),
    MonthlyExpense(month:'Mar', expenses:510, deduction:357, gst:49),
    MonthlyExpense(month:'Apr', expenses:620, deduction:434, gst:59),
    MonthlyExpense(month:'May', expenses:720, deduction:504, gst:68),
    MonthlyExpense(month:'Jun', expenses:480, deduction:336, gst:46),
    MonthlyExpense(month:'Jul', expenses:550, deduction:385, gst:52),
    MonthlyExpense(month:'Aug', expenses:490, deduction:343, gst:47),
    MonthlyExpense(month:'Sep', expenses:670, deduction:469, gst:64),
    MonthlyExpense(month:'Oct', expenses:440, deduction:308, gst:42),
    MonthlyExpense(month:'Nov', expenses:380, deduction:266, gst:36),
    MonthlyExpense(month:'Dec', expenses:880, deduction:616, gst:84),
  ];

  static List<TaxYear> taxYears = [
    TaxYear(
      year: 2026, status: 'So far',
      totalExpenses: 18240, estDeduction: 5200, gstPaid: 1640,
      documents: 62, missingReceipts: 3, auditReadinessPct: 78,
      monthly: [],
    ),
    TaxYear(
      year: 2025, status: 'Current Year',
      totalExpenses: 28540, estDeduction: 8620, gstPaid: 2930,
      documents: 186, missingReceipts: 7, auditReadinessPct: 85,
      monthly: [],
    ),
  ];

  static List<ChecklistItem> checklist = [
    ChecklistItem(label:'Expense Entries',      status:'complete', icon:Icons.receipt_long_rounded),
    ChecklistItem(label:'Receipts Uploaded',    status:'partial',  detail:'179 / 186', icon:Icons.upload_file_rounded),
    ChecklistItem(label:'GST/HST Details',      status:'complete', icon:Icons.percent_rounded),
    ChecklistItem(label:'Bank / Payment Proofs',status:'complete', icon:Icons.account_balance_rounded),
    ChecklistItem(label:'Business Use % Set',   status:'complete', icon:Icons.tune_rounded),
    ChecklistItem(label:'Review & Validate',    status:'pending',  icon:Icons.fact_check_rounded),
  ];
}



class InvoiceLineItemData {
  final String description;
  final int    quantity;
  final double unitPrice;
  final double amount;

  const InvoiceLineItemData({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.amount,
  });

  factory InvoiceLineItemData.fromJson(Map<String, dynamic> json) =>
      InvoiceLineItemData(
        description: json['description']?.toString() ?? '',
        quantity:    (json['quantity']  as num?)?.toInt()    ?? 1,
        unitPrice:   (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
        amount:      (json['amount']    as num?)?.toDouble() ?? 0.0,
      );
}

class ExpenseItemData {
  final String id;
  final String name;
  final String serial;
  final String purchaseDate;
  final String status; // 'active' | 'expiring_soon' | 'expired' | 'claimed'
  final String expiresOn;
  final String timeLeft;
  final String? imageAsset; // local asset path — null uses icon placeholder
  final String price;
  final String invoiceNo;
  final String expenseType;
  final String provider;
  final String duration;
  final String claimSupport;
  final String website;
  final List<String> imageUrls;
  final List<InvoiceLineItemData> items;

  const ExpenseItemData({
    required this.id,
    required this.name,
    required this.serial,
    required this.purchaseDate,
    required this.status,
    required this.expiresOn,
    required this.timeLeft,
    this.imageAsset,
    required this.price,
    required this.invoiceNo,
    required this.expenseType,
    required this.provider,
    required this.duration,
    required this.claimSupport,
    required this.website,
    this.imageUrls = const [],
    this.items = const [],
  });
}
