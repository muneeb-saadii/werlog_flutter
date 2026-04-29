// ─────────────────────────────────────────────
//  WerlogAppState  — replace with your state
//  management (Provider / Riverpod / BLoC).
//  Every field here drives the UI; just update
//  a value and the widget rebuilds automatically.
// ─────────────────────────────────────────────

// ignore_for_file: non_constant_identifier_names

/// ── AUTH / USER ──────────────────────────────
class UserData {
  /// Displayed on the dashboard greeting
  String name;

  /// Email used on OTP/verify screen
  String email;

  /// Plan badge shown on balance card
  String plan; // e.g. "PRO", "FREE", "BASIC"

  UserData({
    this.name  = 'Alice',
    this.email = 'muneeb@gmail.com',
    this.plan  = 'PRO',
  });
}

/// ── DASHBOARD STATS ──────────────────────────
class DashboardStats {
  /// Hero card: total tracked amount
  String totalTracked;      // e.g. "\$847.20"

  /// Hero card: period label
  String periodLabel;       // e.g. "TOTAL TRACKED · APRIL"

  /// Hero card: sub-line
  String totalSubtext;      // e.g. "Across 12 invoices · 2 warranties saved"

  /// Quota bar
  int scansUsed;
  int scansTotal;

  /// Quick-access cards
  String expenseAmount;     // e.g. "\$612"
  int    expenseCount;
  String warrantyAmount;    // e.g. "\$1,299"
  int    warrantyCount;

  DashboardStats({
    this.totalTracked  = '\$847.20',
    this.periodLabel   = 'TOTAL TRACKED · APRIL',
    this.totalSubtext  = 'Across 12 invoices · 2 warranties saved',
    this.scansUsed     = 42,
    this.scansTotal    = 1000,
    this.expenseAmount = '\$612',
    this.expenseCount  = 9,
    this.warrantyAmount = '\$1,299',
    this.warrantyCount  = 3,
  });

  /// 0.0 – 1.0
  double get scanProgress =>
      scansTotal == 0 ? 0 : scansUsed / scansTotal;
}

/// ── WARRANTY ALERT ───────────────────────────
class WarrantyAlert {
  String title;       // e.g. "Warranty expiring in 7 days"
  String subtitle;    // e.g. "Apple MacBook Pro · May 24, 2026"
  bool   isVisible;

  WarrantyAlert({
    this.title    = 'Warranty expiring in 7 days',
    this.subtitle = 'Apple MacBook Pro · May 24, 2026',
    this.isVisible = true,
  });
}

/// ── RECENT TRANSACTIONS ──────────────────────
enum TxType { expense, warranty }

class TransactionItem {
  String   label;
  String   category;
  String   amount;
  String   dateLabel;
  TxType   type;
  String   iconEmoji; // used in icon box

  TransactionItem({
    required this.label,
    required this.category,
    required this.amount,
    required this.dateLabel,
    required this.type,
    required this.iconEmoji,
  });
}

List<TransactionItem> defaultTransactions = [
  TransactionItem(
    label:     'Whole Foods Market',
    category:  'Groceries',
    amount:    '−\$84.30',
    dateLabel: 'Today · 10:42 AM',
    type:      TxType.expense,
    iconEmoji: '🛒',
  ),
  TransactionItem(
    label:     'Apple Store',
    category:  'Electronics',
    amount:    '\$1,299',
    dateLabel: 'Yesterday',
    type:      TxType.warranty,
    iconEmoji: '🍎',
  ),
  TransactionItem(
    label:     'Shell Gas Station',
    category:  'Fuel',
    amount:    '−\$52.10',
    dateLabel: 'Yesterday',
    type:      TxType.expense,
    iconEmoji: '⛽',
  ),
  TransactionItem(
    label:     'Starbucks',
    category:  'Coffee',
    amount:    '−\$6.75',
    dateLabel: 'Mar 28',
    type:      TxType.expense,
    iconEmoji: '☕',
  ),
];

/// ── SUBSCRIPTION PLANS ───────────────────────
class SubscriptionPlan {
  String id;
  String name;
  String tagline;
  String monthlyPrice;
  String yearlyPrice;
  String? originalMonthlyPrice;
  String? originalYearlyPrice;
  String pricePeriod;         // "/mo" or "/forever"
  List<String> features;
  bool isFeatured;
  String? featuredBadge;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.tagline,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.pricePeriod,
    required this.features,
    this.originalMonthlyPrice,
    this.originalYearlyPrice,
    this.isFeatured = false,
    this.featuredBadge,
  });
}

List<SubscriptionPlan> defaultPlans = [
  SubscriptionPlan(
    id: 'free',
    name: 'Free',
    tagline: 'Try before you commit',
    monthlyPrice: '\$0',
    yearlyPrice: '\$0',
    pricePeriod: '/forever',
    features: ['10 scans/mo', 'Basic OCR', '1 device', 'With ads'],
  ),
  SubscriptionPlan(
    id: 'pro',
    name: 'Pro',
    tagline: 'Power users & freelancers',
    monthlyPrice: '\$29',
    yearlyPrice: '\$23',
    originalMonthlyPrice: null,
    originalYearlyPrice: '\$29',
    pricePeriod: '/mo',
    features: [
      '1,000 scans/mo', 'GPT-4 AI OCR', 'Line items',
      'No ads', 'Priority queue', 'All exports',
    ],
    isFeatured: true,
    featuredBadge: 'MOST POPULAR',
  ),
  SubscriptionPlan(
    id: 'basic',
    name: 'Basic',
    tagline: 'For personal use',
    monthlyPrice: '\$9',
    yearlyPrice: '\$7',
    originalMonthlyPrice: null,
    originalYearlyPrice: '\$9',
    pricePeriod: '/mo',
    features: ['100 scans/mo', 'Google Vision', '3 devices', 'No ads'],
  ),
];

/// ── CHECKOUT ─────────────────────────────────
class CheckoutData {
  String planDisplayName;   // "Pro · Yearly"
  String priceLabel;        // "\$276"
  String pricePeriod;       // "/year"
  String billingNote;       // "\$23/mo · billed annually · 7-day free trial"

  // Payment card
  String cardBrand;         // "VISA"
  String cardLast4;         // "4242"

  // Address
  String billingAddress;

  // Summary
  String lineTotal;         // "\$276.00"
  String tax;               // "\$0.00"
  String? discountLabel;    // "Annual discount"
  String? discountAmount;   // "−\$72.00"
  String dueAfterTrial;     // "\$276.00"

  CheckoutData({
    this.planDisplayName = 'Pro · Yearly',
    this.priceLabel      = '\$276',
    this.pricePeriod     = '/year',
    this.billingNote     = '\$23/mo · billed annually · 7-day free trial',
    this.cardBrand       = 'VISA',
    this.cardLast4       = '4242',
    this.billingAddress  = '123 Market St, SF, CA 94103',
    this.lineTotal       = '\$276.00',
    this.tax             = '\$0.00',
    this.discountLabel   = 'Annual discount',
    this.discountAmount  = '−\$72.00',
    this.dueAfterTrial   = '\$276.00',
  });
}
