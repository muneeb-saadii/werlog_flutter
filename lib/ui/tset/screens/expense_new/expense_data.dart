// ═══════════════════════════════════════════════════════════════════════
//  expense_data.dart  —  single source of truth for all 4 expense screens
//  Replace every static field with your API response later.
// ═══════════════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';

// ─── Category model ────────────────────────────────────────────────────
class ExpenseCategory {
  final String id;
  final String name;
  final String description;   // subtitle shown on category detail screen
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final double totalSpent;
  final double deductiblePct; // 0–100, editable (Business Use %)
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
  final String subType;      // e.g. 'Fuel', 'Insurance', 'Parking'
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

// ─── Monthly data model ─────────────────────────────────────────────────
class MonthlyExpense {
  final String month;         // e.g. 'Jan'
  final double expenses;
  final double deduction;
  final double gst;

  const MonthlyExpense({
    required this.month,
    required this.expenses,
    required this.deduction,
    required this.gst,
  });
}

// ─── Year data model ────────────────────────────────────────────────────
class TaxYear {
  final int year;
  final String status;        // 'Current Year' | 'Filed' | 'So far'
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
  final String status;   // 'complete' | 'partial' | 'pending'
  final String? detail;  // e.g. '179 / 186'
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

  // ── Screen 1 KPIs ──────────────────────────────────────────────────
  static String currentYear = '';

  static double totalExpenses     = 0;
  static double estDeduction      = 0;
  static double gstHstClaimable   = 0;
  static double taxRefundForecast = 0;

  // Donut segments
  static double deductibleAmt    = 0;
  static double gstPaidAmt       = 0;
  static double nonDeductibleAmt = 0;
  static double personalAmt      = 0;

  // AI insights
  static List<Map<String, String>> aiInsights = [
    {
      'text': '',
      'type': '',
    }
  ];

  // ── Categories ─────────────────────────────────────────────────────
  static final List<ExpenseCategory> categories = [
    ExpenseCategory(
      id: '',
      name: '',
      description: '',
      icon: Icons.receipt_long_rounded,
      iconBg: const Color(0xFFFFFFFF),
      iconColor: const Color(0xFF000000),
      totalSpent: 0,
      deductiblePct: 0,
      gstPaid: 0,
      missingCount: 0,
      items: [
        ExpenseItem(
          id: '',
          title: '',
          date: '',
          subType: '',
          amount: 0,
          gst: 0,
          icon: Icons.receipt_long_rounded,
          iconBg: const Color(0xFFFFFFFF),
          iconColor: const Color(0xFF000000),
        ),
      ],
    ),
  ];

  // ── Monthly bar chart data ────────────────────────────────────────
  static List<MonthlyExpense> vehicleMonthly = [
    MonthlyExpense(
      month: '',
      expenses: 0,
      deduction: 0,
      gst: 0,
    ),
  ];

  // ── Tax years ─────────────────────────────────────────────────────
  static List<TaxYear> taxYears = [
    TaxYear(
      year: 0,
      status: '',
      totalExpenses: 0,
      estDeduction: 0,
      gstPaid: 0,
      documents: 0,
      missingReceipts: 0,
      auditReadinessPct: 0,
      monthly: [
        MonthlyExpense(
          month: '',
          expenses: 0,
          deduction: 0,
          gst: 0,
        ),
      ],
    ),
  ];

  // ── Checklist ─────────────────────────────────────────────────────
  static List<ChecklistItem> checklist = [
    ChecklistItem(
      label: 'Expense Entries',
      status: '',
      icon: Icons.receipt_long_rounded,
    ),
  ];
}
/*class ExpenseData {
  ExpenseData._();

  // ── Screen 1 KPIs ──────────────────────────────────────────────────
  static String currentYear       = '2025';
  static double totalExpenses     = 28540.00;
  static double estDeduction      = 8620.00;
  static double gstHstClaimable   = 2930.00;
  static double taxRefundForecast = 3450.00;

  // Donut segments
  static double deductibleAmt    = 8620.00;  // teal
  static double gstPaidAmt       = 2930.00;  // blue
  static double nonDeductibleAmt = 12750.00; // orange
  static double personalAmt      = 4240.00;  // coral/red

  // AI insights for screen 1
  static List<Map<String, String>> aiInsights = [
    {
      'text': 'You may be missing \$420 in vehicle expense claims.',
      'type': 'warning',
    },
    {
      'text': 'Internet bill of \$90/month may be eligible for deduction.',
      'type': 'info',
    },
    {
      'text': '2 receipts need GST/HST details to be claimable.',
      'type': 'warning',
    },
  ];

  // ── Categories ─────────────────────────────────────────────────────
  static final List<ExpenseCategory> categories = [
    ExpenseCategory(
      id: 'vehicle',
      name: 'Vehicle & Fuel',
      description: 'Expenses related to vehicle, fuel,\nmaintenance, insurance, parking etc.',
      icon: Icons.directions_car_rounded,
      iconBg: const Color(0xFFE8F5E9),
      iconColor: const Color(0xFF2E7D32),
      totalSpent: 6540,
      deductiblePct: 70,
      gstPaid: 624,
      missingCount: 2,
      items: [
        ExpenseItem(id:'v1', title:'Shell Fuel', date:'May 15, 2025', subType:'Fuel',
            amount:80.50, gst:3.83, icon:Icons.local_gas_station_rounded,
            iconBg:Color(0xFFE8F5E9), iconColor:Color(0xFF2E7D32)),
        ExpenseItem(id:'v2', title:'Vehicle Insurance', date:'May 01, 2025', subType:'Insurance',
            amount:150.00, gst:0.00, icon:Icons.shield_rounded,
            iconBg:Color(0xFFE8F5E9), iconColor:Color(0xFF2E7D32)),
        ExpenseItem(id:'v3', title:'Parking - Client Meeting', date:'Apr 28, 2025', subType:'Parking',
            amount:18.00, gst:0.86, icon:Icons.local_parking_rounded,
            iconBg:Color(0xFFE8F5E9), iconColor:Color(0xFF2E7D32)),
        ExpenseItem(id:'v4', title:'Car Maintenance', date:'Apr 20, 2025', subType:'Maintenance',
            amount:420.00, gst:20.00, icon:Icons.build_rounded,
            iconBg:Color(0xFFE8F5E9), iconColor:Color(0xFF2E7D32)),
        ExpenseItem(id:'v5', title:'Esso Fuel', date:'Apr 18, 2025', subType:'Fuel',
            amount:65.30, gst:3.11, icon:Icons.local_gas_station_rounded,
            iconBg:Color(0xFFE8F5E9), iconColor:Color(0xFF2E7D32)),
      ],
    ),
    ExpenseCategory(
      id: 'homeoffice',
      name: 'Home Office',
      description: 'Internet, phone, office space and related home office expenses.',
      icon: Icons.home_work_rounded,
      iconBg: const Color(0xFFE3F2FD),
      iconColor: const Color(0xFF1565C0),
      totalSpent: 4230,
      deductiblePct: 50,
      gstPaid: 380,
      missingCount: 1,
      items: [],
    ),
    ExpenseCategory(
      id: 'office',
      name: 'Office Supplies',
      description: 'Stationery, printing, software subscriptions and supplies.',
      icon: Icons.inventory_2_rounded,
      iconBg: const Color(0xFFF3E5F5),
      iconColor: const Color(0xFF6A1B9A),
      totalSpent: 2180,
      deductiblePct: 100,
      gstPaid: 196,
      missingCount: 0,
      items: [],
    ),
    ExpenseCategory(
      id: 'phone',
      name: 'Internet & Phone',
      description: 'Monthly internet, cell phone and communication bills.',
      icon: Icons.wifi_rounded,
      iconBg: const Color(0xFFE3F2FD),
      iconColor: const Color(0xFF0277BD),
      totalSpent: 1560,
      deductiblePct: 60,
      gstPaid: 140,
      missingCount: 0,
      items: [],
    ),
    ExpenseCategory(
      id: 'meals',
      name: 'Meals & Travel',
      description: 'Client meals, business travel, accommodation and related.',
      icon: Icons.restaurant_rounded,
      iconBg: const Color(0xFFFBE9E7),
      iconColor: const Color(0xFFBF360C),
      totalSpent: 2980,
      deductiblePct: 50,
      gstPaid: 267,
      missingCount: 1,
      items: [],
    ),
    ExpenseCategory(
      id: 'professional',
      name: 'Professional Fees',
      description: 'Accounting, legal, consulting and other professional services.',
      icon: Icons.work_rounded,
      iconBg: const Color(0xFFE8EAF6),
      iconColor: const Color(0xFF283593),
      totalSpent: 3450,
      deductiblePct: 100,
      gstPaid: 310,
      missingCount: 0,
      items: [],
    ),
    ExpenseCategory(
      id: 'advertising',
      name: 'Advertising',
      description: 'Digital ads, print, promotions and marketing expenses.',
      icon: Icons.campaign_rounded,
      iconBg: const Color(0xFFFFF3E0),
      iconColor: const Color(0xFFE65100),
      totalSpent: 1230,
      deductiblePct: 100,
      gstPaid: 110,
      missingCount: 0,
      items: [],
    ),
    ExpenseCategory(
      id: 'equipment',
      name: 'Equipment',
      description: 'Computers, peripherals, machinery and business equipment.',
      icon: Icons.computer_rounded,
      iconBg: const Color(0xFFE0F2F1),
      iconColor: const Color(0xFF00695C),
      totalSpent: 4120,
      deductiblePct: 100,
      gstPaid: 370,
      missingCount: 1,
      items: [],
    ),
    ExpenseCategory(
      id: 'insurance',
      name: 'Insurance',
      description: 'Business liability, property and professional insurance.',
      icon: Icons.shield_rounded,
      iconBg: const Color(0xFFE8F5E9),
      iconColor: const Color(0xFF1B5E20),
      totalSpent: 1850,
      deductiblePct: 100,
      gstPaid: 0,
      missingCount: 0,
      items: [],
    ),
    ExpenseCategory(
      id: 'training',
      name: 'Training / Courses',
      description: 'Professional development, certifications and education.',
      icon: Icons.school_rounded,
      iconBg: const Color(0xFFF3E5F5),
      iconColor: const Color(0xFF7B1FA2),
      totalSpent: 920,
      deductiblePct: 100,
      gstPaid: 82,
      missingCount: 0,
      items: [],
    ),
    ExpenseCategory(
      id: 'utilities',
      name: 'Utilities',
      description: 'Electricity, gas, water and other utility bills.',
      icon: Icons.bolt_rounded,
      iconBg: const Color(0xFFFFF8E1),
      iconColor: const Color(0xFFF9A825),
      totalSpent: 950,
      deductiblePct: 40,
      gstPaid: 85,
      missingCount: 0,
      items: [],
    ),
    ExpenseCategory(
      id: 'misc',
      name: 'Miscellaneous',
      description: 'Other business expenses that do not fit a specific category.',
      icon: Icons.more_horiz_rounded,
      iconBg: const Color(0xFFF5F5F5),
      iconColor: const Color(0xFF616161),
      totalSpent: 520,
      deductiblePct: 50,
      gstPaid: 26,
      missingCount: 0,
      items: [],
    ),
  ];

  // ── Monthly bar chart data for category detail (12 months) ─────────
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

  // ── Tax years ───────────────────────────────────────────────────────
  static List<TaxYear> taxYears = [
    TaxYear(
      year: 2026, status: 'So far',
      totalExpenses: 18240, estDeduction: 5200, gstPaid: 1640,
      documents: 62, missingReceipts: 3, auditReadinessPct: 78,
      monthly: [
        MonthlyExpense(month:'Jan', expenses:2120, deduction:650, gst:210),
        MonthlyExpense(month:'Feb', expenses:1980, deduction:600, gst:190),
        MonthlyExpense(month:'Mar', expenses:2450, deduction:760, gst:260),
        MonthlyExpense(month:'Apr', expenses:2780, deduction:840, gst:280),
        MonthlyExpense(month:'May', expenses:3210, deduction:980, gst:330),
        MonthlyExpense(month:'Jun', expenses:2560, deduction:770, gst:240),
        MonthlyExpense(month:'Jul', expenses:0, deduction:0, gst:0),
        MonthlyExpense(month:'Aug', expenses:0, deduction:0, gst:0),
        MonthlyExpense(month:'Sep', expenses:0, deduction:0, gst:0),
        MonthlyExpense(month:'Oct', expenses:0, deduction:0, gst:0),
        MonthlyExpense(month:'Nov', expenses:0, deduction:0, gst:0),
        MonthlyExpense(month:'Dec', expenses:0, deduction:0, gst:0),
      ],
    ),
    TaxYear(
      year: 2025, status: 'Current Year',
      totalExpenses: 28540, estDeduction: 8620, gstPaid: 2930,
      documents: 186, missingReceipts: 7, auditReadinessPct: 85,
      monthly: [
        MonthlyExpense(month:'Jan', expenses:2120, deduction:650, gst:210),
        MonthlyExpense(month:'Feb', expenses:1980, deduction:600, gst:190),
        MonthlyExpense(month:'Mar', expenses:2450, deduction:760, gst:260),
        MonthlyExpense(month:'Apr', expenses:2780, deduction:840, gst:280),
        MonthlyExpense(month:'May', expenses:3210, deduction:980, gst:330),
        MonthlyExpense(month:'Jun', expenses:2560, deduction:770, gst:240),
        MonthlyExpense(month:'Jul', expenses:2320, deduction:700, gst:220),
        MonthlyExpense(month:'Aug', expenses:2670, deduction:810, gst:270),
        MonthlyExpense(month:'Sep', expenses:2390, deduction:720, gst:230),
        MonthlyExpense(month:'Oct', expenses:2680, deduction:810, gst:260),
        MonthlyExpense(month:'Nov', expenses:2110, deduction:640, gst:200),
        MonthlyExpense(month:'Dec', expenses:2290, deduction:670, gst:220),
      ],
    ),
    TaxYear(
      year: 2024, status: 'Filed',
      totalExpenses: 26180, estDeduction: 7900, gstPaid: 2710,
      documents: 174, missingReceipts: 0, auditReadinessPct: 100,
      monthly: [
        MonthlyExpense(month:'Jan', expenses:1980, deduction:600, gst:190),
        MonthlyExpense(month:'Feb', expenses:1740, deduction:520, gst:170),
        MonthlyExpense(month:'Mar', expenses:2200, deduction:680, gst:220),
        MonthlyExpense(month:'Apr', expenses:2410, deduction:740, gst:240),
        MonthlyExpense(month:'May', expenses:2850, deduction:870, gst:290),
        MonthlyExpense(month:'Jun', expenses:2340, deduction:710, gst:230),
        MonthlyExpense(month:'Jul', expenses:2090, deduction:630, gst:210),
        MonthlyExpense(month:'Aug', expenses:2320, deduction:700, gst:230),
        MonthlyExpense(month:'Sep', expenses:2160, deduction:660, gst:220),
        MonthlyExpense(month:'Oct', expenses:2510, deduction:770, gst:250),
        MonthlyExpense(month:'Nov', expenses:1980, deduction:600, gst:200),
        MonthlyExpense(month:'Dec', expenses:1600, deduction:420, gst:160),
      ],
    ),
    TaxYear(
      year: 2023, status: 'Filed',
      totalExpenses: 22760, estDeduction: 6800, gstPaid: 2410,
      documents: 158, missingReceipts: 0, auditReadinessPct: 100,
      monthly: [],
    ),
    TaxYear(
      year: 2022, status: 'Filed',
      totalExpenses: 19320, estDeduction: 5900, gstPaid: 2100,
      documents: 141, missingReceipts: 0, auditReadinessPct: 100,
      monthly: [],
    ),
  ];

  // ── Checklist for Tax Ready Summary (screen 4) ──────────────────────
  static List<ChecklistItem> checklist = [
    ChecklistItem(label:'Expense Entries',     status:'complete', icon:Icons.receipt_long_rounded)
  ];
}*/
