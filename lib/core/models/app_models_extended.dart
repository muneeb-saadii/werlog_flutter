// ─────────────────────────────────────────────────────────────
//  app_models_extended.dart
//  Data models for screens 07–14.
//  To update the UI: just change the field values.
// ─────────────────────────────────────────────────────────────

// ignore_for_file: non_constant_identifier_names

// ══════════════════════════════════════════════════════════════
//  OCR / SCAN FLOW  (screens 07, 08, 09)
// ══════════════════════════════════════════════════════════════

enum ScanType { expense, warranty }

/// Screen 07 — bottom sheet type selector
class ScanTypeSheetData {
  ScanType selectedType;

  ScanTypeSheetData({this.selectedType = ScanType.warranty});
}

/// Screen 08 — camera viewfinder
class CameraViewData {
  ScanType scanType;
  bool flashOn;
  /// Hint text shown below the frame guide
  String hintText;

  CameraViewData({
    this.scanType = ScanType.warranty,
    this.flashOn  = false,
    this.hintText = "Align receipt · auto-capturing in 2s",
  });
}

/// A single processing step shown on screen 09
class ProcessingStep {
  final String label;
  ProcessingStepStatus status;
  /// e.g. "0.4s" for done steps
  String? duration;

  ProcessingStep({
    required this.label,
    this.status = ProcessingStepStatus.pending,
    this.duration,
  });
}

enum ProcessingStepStatus { done, active, pending }

/// Screen 09 — processing / extracting state
class OcrProcessingData {
  ScanType scanType;
  String headlineText;
  String subText;
  List<ProcessingStep> steps;

  OcrProcessingData({
    required this.scanType,
    this.headlineText = 'Extracting warranty data',
    this.subText      = 'Reading vendor, model & serial number...',
    List<ProcessingStep>? steps,
  }) : steps = steps ?? [
    ProcessingStep(label: 'Uploaded securely',      status: ProcessingStepStatus.done,   duration: '0.4s'),
    ProcessingStep(label: 'Image enhanced',          status: ProcessingStepStatus.done,   duration: '0.9s'),
    ProcessingStep(label: 'GPT-4 extracting fields', status: ProcessingStepStatus.active, duration: '3s'),
    ProcessingStep(label: 'Parsing warranty dates',  status: ProcessingStepStatus.pending),
    ProcessingStep(label: 'Saving to library',       status: ProcessingStepStatus.pending),
  ];
}

// ══════════════════════════════════════════════════════════════
//  INVOICE / DETAIL  (screens 10, 11)
// ══════════════════════════════════════════════════════════════

enum InvoiceType { expense, warranty }

/// A single line item inside an invoice
class InvoiceLineItem {
  String name;
  String meta;       // e.g. "Produce · $0.69/lb"
  String amount;     // e.g. "$4.29"
  String unit;       // e.g. "6.22 lb"
  bool isHighlighted; // e.g. FREE bundled item

  InvoiceLineItem({
    required this.name,
    required this.meta,
    required this.amount,
    required this.unit,
    this.isHighlighted = false,
  });
}

/// Subtotal rows in the summary card
class InvoiceSummaryRow {
  String label;
  String value;
  bool isDiscount;

  InvoiceSummaryRow({
    required this.label,
    required this.value,
    this.isDiscount = false,
  });
}

/// Warranty badge shown for WARRANTY type invoices
class WarrantyBadgeData {
  int daysRemaining;
  String status;       // e.g. "Warranty active"
  String expiryText;   // e.g. "Expires March 24, 2027 · 1-year AppleCare included"
  String serialNumber; // e.g. "C02XY9ABZDK3"

  WarrantyBadgeData({
    this.daysRemaining = 358,
    this.status        = 'Warranty active',
    this.expiryText    = 'Expires March 24, 2027 · 1-year AppleCare included',
    this.serialNumber  = 'C02XY9ABZDK3',
  });
}

/// OCR confidence chip data
class OcrConfidenceData {
  int confidencePct;   // 0–100
  String engineLabel;  // e.g. "GPT-4"
  int lineItemCount;
  String statusNote;   // e.g. "Tap any field to edit"

  OcrConfidenceData({
    this.confidencePct = 96,
    this.engineLabel   = 'GPT-4',
    this.lineItemCount = 5,
    this.statusNote    = 'Tap any field to edit',
  });
}

/// Full data for one invoice/warranty detail screen
class InvoiceDetailData {
  InvoiceType type;
  String categoryLabel;    // e.g. "EXPENSE · GROCERIES"
  String vendor;
  String dateLabel;        // e.g. "Mar 28, 2026 · 10:42 AM · Inv #WF-4421"
  String amount;
  String currency;

  OcrConfidenceData confidence;

  // Expense fields
  List<InvoiceLineItem> lineItems;
  List<InvoiceSummaryRow> summaryRows;
  String totalPaid;

  // Meta fields
  String categoryTag;   // e.g. "Groceries"
  String paymentInfo;   // e.g. "Visa •• 4242"

  // Warranty-specific
  WarrantyBadgeData? warrantyBadge;
  String? warrantyTypeLabel; // e.g. "AppleCare+ · 1 year"

  // Footer button labels
  String primaryButtonLabel;   // e.g. "Mark reviewed ✓"
  String secondaryButtonLabel; // e.g. "Download PDF"

  InvoiceDetailData({
    this.type          = InvoiceType.expense,
    this.categoryLabel = 'EXPENSE · GROCERIES',
    this.vendor        = 'Whole Foods Market',
    this.dateLabel     = 'Mar 28, 2026 · 10:42 AM · Inv #WF-4421',
    this.amount        = '\$84.30',
    this.currency      = 'USD',
    OcrConfidenceData? confidence,
    List<InvoiceLineItem>? lineItems,
    List<InvoiceSummaryRow>? summaryRows,
    this.totalPaid           = '\$84.30',
    this.categoryTag         = 'Groceries',
    this.paymentInfo         = 'Visa •• 4242',
    this.warrantyBadge,
    this.warrantyTypeLabel,
    this.primaryButtonLabel   = 'Mark reviewed ✓',
    this.secondaryButtonLabel = 'Download PDF',
  })  : confidence = confidence ?? OcrConfidenceData(),
        lineItems  = lineItems ?? _defaultExpenseItems,
        summaryRows = summaryRows ?? _defaultExpenseSummary;
}

final List<InvoiceLineItem> _defaultExpenseItems = [
  InvoiceLineItem(name: 'Organic Bananas',        meta: 'Produce · \$0.69/lb',   amount: '\$4.29',   unit: '6.22 lb'),
  InvoiceLineItem(name: 'Greek Yogurt · Plain',    meta: 'Dairy · 32oz tub',      amount: '\$6.99',   unit: '1 × \$6.99'),
  InvoiceLineItem(name: 'Sourdough Bread',         meta: 'Bakery · fresh baked',  amount: '\$5.50',   unit: '1 × \$5.50'),
  InvoiceLineItem(name: 'Hass Avocados',           meta: 'Produce · large',       amount: '\$8.99',   unit: '3 × \$3.00'),
  InvoiceLineItem(name: 'Chicken Breast · Organic',meta: 'Meat · 2.1 lb',        amount: '\$14.50',  unit: '\$6.90/lb'),
];

final List<InvoiceSummaryRow> _defaultExpenseSummary = [
  InvoiceSummaryRow(label: 'Subtotal (5 items)', value: '\$40.27'),
  InvoiceSummaryRow(label: 'Sales tax (8%)',     value: '\$3.22'),
  InvoiceSummaryRow(label: 'Bag fee',            value: '\$0.10'),
  InvoiceSummaryRow(label: 'Discount',           value: '−\$0.00', isDiscount: true),
];

// Convenience factory for warranty detail
InvoiceDetailData warrantyDetailData() => InvoiceDetailData(
  type:          InvoiceType.warranty,
  categoryLabel: 'WARRANTY · ELECTRONICS',
  vendor:        'Apple Store',
  dateLabel:     'Mar 24, 2025 · Invoice #A-8812',
  amount:        '\$1,299.00',
  currency:      'USD',
  confidence:    OcrConfidenceData(
    confidencePct: 99,
    lineItemCount: 3,
    statusNote:    'Serial verified · Warranty auto-tracked',
  ),
  lineItems: [
    InvoiceLineItem(name: 'MacBook Pro 14″',        meta: 'M3 · 16GB · 512GB · Space Black', amount: '\$1,199', unit: '1 unit'),
    InvoiceLineItem(name: 'USB-C to MagSafe cable', meta: '2m · braided',                    amount: '\$49.00',  unit: '1 unit'),
    InvoiceLineItem(name: 'AppleCare+ (included)',  meta: 'Extended coverage to 2027',        amount: 'FREE',    unit: 'Bundle', isHighlighted: true),
  ],
  summaryRows: [
    InvoiceSummaryRow(label: 'Product subtotal',    value: '\$1,248.00'),
    InvoiceSummaryRow(label: 'Education discount',  value: '−\$49.00', isDiscount: true),
    InvoiceSummaryRow(label: 'Sales tax (8.5%)',    value: '\$100.00'),
  ],
  totalPaid:           '\$1,299.00',
  categoryTag:         'Electronics',
  warrantyBadge:       WarrantyBadgeData(),
  warrantyTypeLabel:   'AppleCare+ · 1 year',
  primaryButtonLabel:  'Mark reviewed ✓',
  secondaryButtonLabel: 'Set reminder',
);

// ══════════════════════════════════════════════════════════════
//  INVOICE LIST  (screen 12)
// ══════════════════════════════════════════════════════════════

enum InvoiceFilterType { all, expenses, warranties }

class InvoiceListItem {
  String vendor;
  String category;
  String typeMeta;   // e.g. "5 items · Groceries"
  String amount;
  String timeLabel;
  InvoiceType type;
  String iconEmoji;
  String iconColorKey; // 'food' | 'elec' | 'fuel' | 'util'

  InvoiceListItem({
    required this.vendor,
    required this.category,
    required this.typeMeta,
    required this.amount,
    required this.timeLabel,
    required this.type,
    required this.iconEmoji,
    required this.iconColorKey,
  });
}

class InvoiceListGroup {
  String dateLabel; // e.g. "TODAY · MONDAY"
  List<InvoiceListItem> items;

  InvoiceListGroup({required this.dateLabel, required this.items});
}

class InvoiceListData {
  InvoiceFilterType filter;
  int totalCount;
  int expenseCount;
  int warrantyCount;
  String thisMonthTotal;
  String thisMonthDelta;
  String avgWeeklyTotal;
  String avgWeeklyDelta;
  List<InvoiceListGroup> groups;

  InvoiceListData({
    this.filter          = InvoiceFilterType.all,
    this.totalCount      = 87,
    this.expenseCount    = 76,
    this.warrantyCount   = 11,
    this.thisMonthTotal  = '\$612.50',
    this.thisMonthDelta  = '↑ \$84 vs Mar',
    this.avgWeeklyTotal  = '\$156.40',
    this.avgWeeklyDelta  = '↓ 8% saved',
    List<InvoiceListGroup>? groups,
  }) : groups = groups ?? _defaultGroups;
}

final List<InvoiceListGroup> _defaultGroups = [
  InvoiceListGroup(dateLabel: 'TODAY · MONDAY', items: [
    InvoiceListItem(vendor: 'Whole Foods Market', category: 'Groceries', typeMeta: '5 items · Groceries', amount: '−\$84.30', timeLabel: '10:42 AM', type: InvoiceType.expense, iconEmoji: '🛒', iconColorKey: 'food'),
    InvoiceListItem(vendor: 'Xfinity Internet',  category: 'Utilities',  typeMeta: 'Monthly · Utilities', amount: '−\$79.99', timeLabel: '9:15 AM',  type: InvoiceType.expense, iconEmoji: '⬡', iconColorKey: 'util'),
  ]),
  InvoiceListGroup(dateLabel: 'YESTERDAY · SUN', items: [
    InvoiceListItem(vendor: 'Apple Store',        category: 'Electronics', typeMeta: 'MacBook Pro · 358d left', amount: '\$1,299', timeLabel: 'Saved',   type: InvoiceType.warranty, iconEmoji: '💻', iconColorKey: 'elec'),
    InvoiceListItem(vendor: 'Shell Gas Station',  category: 'Fuel',        typeMeta: '12.8 gal · Fuel',         amount: '−\$52.10', timeLabel: '2:30 PM', type: InvoiceType.expense,  iconEmoji: '⛽', iconColorKey: 'fuel'),
  ]),
  InvoiceListGroup(dateLabel: 'MAR 28', items: [
    InvoiceListItem(vendor: 'Blue Bottle Coffee', category: 'Coffee', typeMeta: '2 items · Coffee', amount: '−\$12.50', timeLabel: '8:15 AM', type: InvoiceType.expense, iconEmoji: '☕', iconColorKey: 'food'),
  ]),
];

// ══════════════════════════════════════════════════════════════
//  REPORTS  (screen 13)
// ══════════════════════════════════════════════════════════════

class MonthBarData {
  final String month;
  final double expenseRatio;   // 0.0–1.0
  final double warrantyRatio;  // 0.0–1.0
  final bool isCurrent;

  const MonthBarData({
    required this.month,
    required this.expenseRatio,
    required this.warrantyRatio,
    this.isCurrent = false,
  });
}

class CategoryReportItem {
  String name;
  double ratio;        // 0.0–1.0
  String amount;
  String percentage;
  String iconEmoji;
  String colorKey;     // 'util' | 'food' | 'elec' | 'fuel'

  CategoryReportItem({
    required this.name,
    required this.ratio,
    required this.amount,
    required this.percentage,
    required this.iconEmoji,
    required this.colorKey,
  });
}

class ReportsData {
  String periodLabel;
  String totalTracked;
  String expensesTotal;
  String expensesRatioPct;
  double expensesRatio;
  String warrantiesTotal;
  String warrantiesRatioPct;
  double warrantiesRatio;
  List<MonthBarData> monthlyBars;
  List<CategoryReportItem> categories;

  ReportsData({
    this.periodLabel         = 'April 2026',
    this.totalTracked        = '\$2,147.30',
    this.expensesTotal       = '\$612',
    this.expensesRatioPct    = '72%',
    this.expensesRatio       = 0.72,
    this.warrantiesTotal     = '\$1,535',
    this.warrantiesRatioPct  = '28%',
    this.warrantiesRatio     = 0.28,
    List<MonthBarData>? monthlyBars,
    List<CategoryReportItem>? categories,
  })  : monthlyBars = monthlyBars ?? _defaultBars,
        categories  = categories  ?? _defaultCategories;
}

const List<MonthBarData> _defaultBars = [
  MonthBarData(month: 'Nov', expenseRatio: 0.42, warrantyRatio: 0.06),
  MonthBarData(month: 'Dec', expenseRatio: 0.58, warrantyRatio: 0.15),
  MonthBarData(month: 'Jan', expenseRatio: 0.48, warrantyRatio: 0.04),
  MonthBarData(month: 'Feb', expenseRatio: 0.50, warrantyRatio: 0.22),
  MonthBarData(month: 'Mar', expenseRatio: 0.60, warrantyRatio: 0.08),
  MonthBarData(month: 'Apr', expenseRatio: 0.62, warrantyRatio: 0.35, isCurrent: true),
];

final List<CategoryReportItem> _defaultCategories = [
  CategoryReportItem(name: 'Utilities',     ratio: 1.00, amount: '\$238', percentage: '38%', iconEmoji: '⬡',  colorKey: 'util'),
  CategoryReportItem(name: 'Food & Dining', ratio: 0.68, amount: '\$162', percentage: '25%', iconEmoji: '🛒', colorKey: 'food'),
  CategoryReportItem(name: 'Electronics',   ratio: 0.54, amount: '\$128', percentage: '20%', iconEmoji: '💻', colorKey: 'elec'),
  CategoryReportItem(name: 'Fuel',          ratio: 0.28, amount: '\$65',  percentage: '10%', iconEmoji: '⛽', colorKey: 'fuel'),
];

// ══════════════════════════════════════════════════════════════
//  PROFILE  (screen 14)
// ══════════════════════════════════════════════════════════════

class SettingRow {
  final String title;
  final String? subtitle;
  final String iconColorKey;   // 'g' | 't' | 'a' | 'c' | 'r'
  final String iconEmoji;
  final SettingTrailingType trailing;
  bool toggleValue;

  SettingRow({
    required this.title,
    this.subtitle,
    required this.iconColorKey,
    required this.iconEmoji,
    this.trailing    = SettingTrailingType.chevron,
    this.toggleValue = true,
  });
}

enum SettingTrailingType { chevron, toggle, none }

class SettingSection {
  final String header;
  final List<SettingRow> rows;
  const SettingSection({required this.header, required this.rows});
}

class ProfileData {
  String fullName;
  String initials;
  String email;
  String planLabel;       // e.g. "PRO · YEARLY"
  String appVersion;

  List<SettingSection> sections;

  ProfileData({
    this.fullName   = 'Alice Smith',
    this.initials   = 'AS',
    this.email      = 'alice@example.com',
    this.planLabel  = 'PRO · YEARLY',
    this.appVersion = 'Werlog v2.1.4 · Terms · Privacy',
    List<SettingSection>? sections,
  }) : sections = sections ?? _defaultSections;
}

final List<SettingSection> _defaultSections = [
  SettingSection(header: 'ACCOUNT', rows: [
    SettingRow(title: 'Personal info', subtitle: 'Name, phone, timezone',     iconColorKey: 'g', iconEmoji: '◯'),
    SettingRow(title: 'Security',      subtitle: 'Password, 2FA, devices',    iconColorKey: 'g', iconEmoji: '⚿'),
  ]),
  SettingSection(header: 'SUBSCRIPTION', rows: [
    SettingRow(title: 'Current plan',       subtitle: 'Pro · renews Apr 1, 2027',  iconColorKey: 't', iconEmoji: '◆'),
    SettingRow(title: 'Billing & invoices', subtitle: 'Payment methods, receipts', iconColorKey: 't', iconEmoji: '◉'),
    SettingRow(title: 'Usage',              subtitle: '42/1000 scans · 4.2%',       iconColorKey: 't', iconEmoji: '↗'),
  ]),
  SettingSection(header: 'PREFERENCES', rows: [
    SettingRow(title: 'Categories',           iconColorKey: 'a', iconEmoji: '◈'),
    SettingRow(title: 'Warranty reminders',   iconColorKey: 'a', iconEmoji: '◆', trailing: SettingTrailingType.toggle, toggleValue: true),
    SettingRow(title: 'Email notifications',  iconColorKey: 'a', iconEmoji: '✉', trailing: SettingTrailingType.toggle, toggleValue: true),
    SettingRow(title: 'Weekly digest',        iconColorKey: 'a', iconEmoji: '◔', trailing: SettingTrailingType.toggle, toggleValue: false),
  ]),
  SettingSection(header: 'SUPPORT', rows: [
    SettingRow(title: 'Help center',       iconColorKey: 'c', iconEmoji: 'ⓘ'),
    SettingRow(title: 'Contact support',   iconColorKey: 'c', iconEmoji: '✉'),
    SettingRow(title: 'Sign out',          iconColorKey: 'r', iconEmoji: '⏻', trailing: SettingTrailingType.none),
  ]),
];
