import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/api/admin_api_service.dart';
import '../../core/api/admin_endpoints.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  MODELS
// ─────────────────────────────────────────────────────────────────────────────

class ReceiptSubscription {
  final String subscriptionId;
  final String planCode;
  final String planName;
  final int    planPriceCents;
  final String planCurrency;
  final String billingInterval;
  final String status;
  final bool   cancelAtPeriodEnd;
  final String? currentPeriodStart;
  final String? currentPeriodEnd;
  final String? canceledAt;
  final String? createdAt;
  final String? stripeCustomerId;
  final String? stripeSubscriptionId;

  const ReceiptSubscription({
    required this.subscriptionId,
    required this.planCode,
    required this.planName,
    required this.planPriceCents,
    required this.planCurrency,
    required this.billingInterval,
    required this.status,
    required this.cancelAtPeriodEnd,
    this.currentPeriodStart,
    this.currentPeriodEnd,
    this.canceledAt,
    this.createdAt,
    this.stripeCustomerId,
    this.stripeSubscriptionId,
  });

  factory ReceiptSubscription.fromJson(Map<String, dynamic> j) => ReceiptSubscription(
    subscriptionId:       j['subscriptionId']?.toString()       ?? '',
    planCode:             j['planCode']?.toString()             ?? '',
    planName:             j['planName']?.toString()             ?? '',
    planPriceCents:       (j['planPriceCents'] as num?)?.toInt() ?? 0,
    planCurrency:         j['planCurrency']?.toString()         ?? 'USD',
    billingInterval:      j['billingInterval']?.toString()      ?? 'MONTH',
    status:               j['status']?.toString()               ?? '',
    cancelAtPeriodEnd:    j['cancelAtPeriodEnd'] == true,
    currentPeriodStart:   j['currentPeriodStart']?.toString(),
    currentPeriodEnd:     j['currentPeriodEnd']?.toString(),
    canceledAt:           j['canceledAt']?.toString(),
    createdAt:            j['createdAt']?.toString(),
    stripeCustomerId:     j['stripeCustomerId']?.toString(),
    stripeSubscriptionId: j['stripeSubscriptionId']?.toString(),
  );

  double get priceInUnits => planPriceCents / 100;

  String get priceLabel => planPriceCents == 0
      ? 'Free'
      : '${planCurrency.toUpperCase()} ${priceInUnits.toStringAsFixed(2)} / ${billingInterval.toLowerCase()}';
}

class StripeInvoice {
  final String invoiceId;
  final String? number;
  final String status;
  final int    amountPaidCents;
  final String currency;
  final String? periodStart;
  final String? periodEnd;
  final String? paidAt;
  final String? hostedUrl;
  final String? pdfUrl;

  const StripeInvoice({
    required this.invoiceId,
    this.number,
    required this.status,
    required this.amountPaidCents,
    required this.currency,
    this.periodStart,
    this.periodEnd,
    this.paidAt,
    this.hostedUrl,
    this.pdfUrl,
  });

  factory StripeInvoice.fromJson(Map<String, dynamic> j) => StripeInvoice(
    invoiceId:       j['invoiceId']?.toString()          ?? j['id']?.toString() ?? '',
    number:          j['number']?.toString(),
    status:          j['status']?.toString()             ?? '',
    amountPaidCents: (j['amountPaidCents'] as num?)?.toInt() ?? 0,
    currency:        j['currency']?.toString()           ?? 'USD',
    periodStart:     j['periodStart']?.toString(),
    periodEnd:       j['periodEnd']?.toString(),
    paidAt:          j['paidAt']?.toString(),
    hostedUrl:       j['hostedUrl']?.toString(),
    pdfUrl:          j['pdfUrl']?.toString(),
  );

  double get amountInUnits => amountPaidCents / 100;

  String get amountLabel =>
      '${currency.toUpperCase()} ${amountInUnits.toStringAsFixed(2)}';

  bool get isPaid => status.toUpperCase() == 'PAID';
}

class UserReceiptData {
  final String userId;
  final String email;
  final String fullName;
  final ReceiptSubscription? subscription;
  final int invoiceCount;
  final List<StripeInvoice> invoices;
  final String? note;

  const UserReceiptData({
    required this.userId,
    required this.email,
    required this.fullName,
    this.subscription,
    required this.invoiceCount,
    required this.invoices,
    this.note,
  });

  factory UserReceiptData.fromJson(Map<String, dynamic> j) {
    final subJson = j['subscription'] as Map<String, dynamic>?;
    final invList = j['invoices'] as List<dynamic>? ?? [];
    return UserReceiptData(
      userId:        j['userId']?.toString()    ?? '',
      email:         j['email']?.toString()     ?? '',
      fullName:      j['fullName']?.toString()  ?? '',
      subscription:  subJson != null ? ReceiptSubscription.fromJson(subJson) : null,
      invoiceCount:  (j['invoiceCount'] as num?)?.toInt() ?? invList.length,
      invoices:      invList
          .whereType<Map<String, dynamic>>()
          .map(StripeInvoice.fromJson)
          .toList(),
      note:          j['note']?.toString(),
    );
  }

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, parts.first.length.clamp(0, 2)).toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  LIST SCREEN  — fetches a page of users then loads invoices for paid ones
// ─────────────────────────────────────────────────────────────────────────────

class SubscriptionReceiptsScreen extends StatefulWidget {
  const SubscriptionReceiptsScreen({super.key});

  @override
  State<SubscriptionReceiptsScreen> createState() =>
      _SubscriptionReceiptsScreenState();
}

class _SubscriptionReceiptsScreenState
    extends State<SubscriptionReceiptsScreen> {

  bool   _loading = true;
  String _error   = '';
  List<UserReceiptData> _records = [];
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text.trim().toLowerCase()));
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // Fetch users with PRO/BUSINESS plans, then load their invoice data
  Future<void> _fetch() async {
    setState(() { _loading = true; _error = ''; });
    try {
      // Get all users — filter paid plans locally
      final resp = await AdminApiService.get(
        context,
        AdminEndpoints.adminUsers,
        queryParams: {'page': '0', 'size': '100'},
        showLoader: false,
      );
      debugPrint('[Receipts] users => ${resp?.keys}');
      if (!mounted) return;

      final raw  = resp?['data'];
      List<dynamic> users = raw is List ? raw : (raw is Map ? raw['content'] ?? [] : []);

      // Only paid users
      final paidUsers = users
          .whereType<Map<String, dynamic>>()
          .where((u) {
        final plan = (u['planCode'] ?? '').toString().toUpperCase();
        return plan == 'PRO' || plan == 'BUSINESS';
      })
          .toList();

      debugPrint('[Receipts] paid users => ${paidUsers.length}');

      // Load subscription invoices for each paid user in parallel (max 10)
      final slice = paidUsers.take(10).toList();
      final futures = slice.map((u) => AdminApiService.get(
        context,
        AdminEndpoints.adminUserSubscriptionInvoices(u['id'].toString()),
        showLoader: false,
      ));

      final results = await Future.wait(futures);
      if (!mounted) return;

      _records = results
          .where((r) => r != null && r['result']?.toString() == '1')
          .map((r) => UserReceiptData.fromJson(r!['data'] as Map<String, dynamic>))
          .toList();

      // Sort by invoice count desc
      _records.sort((a, b) => b.invoiceCount.compareTo(a.invoiceCount));

    } catch (e) {
      debugPrint('[Receipts] error => $e');
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<UserReceiptData> get _filtered {
    if (_query.isEmpty) return _records;
    return _records.where((r) =>
    r.fullName.toLowerCase().contains(_query) ||
        r.email.toLowerCase().contains(_query)).toList();
  }

  int get _totalInvoices => _records.fold(0, (s, r) => s + r.invoiceCount);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          _Header(totalInvoices: _totalInvoices, userCount: _records.length),
          if (!_loading) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppMetrics.pagePadding),
              child: _SearchBar(controller: _searchCtrl,
                  onClear: () => _searchCtrl.clear()),
            ),
          ],
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(
                color: AppColors.accentGreen))
                : _error.isNotEmpty
                ? _ErrorState(message: _error, onRetry: _fetch)
                : _filtered.isEmpty
                ? const _EmptyState()
                : RefreshIndicator(
              onRefresh: _fetch,
              color: AppColors.accentGreen,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                    AppMetrics.pagePadding, 0,
                    AppMetrics.pagePadding, 100),
                itemCount: _filtered.length,
                itemBuilder: (_, i) => _UserReceiptCard(
                  record: _filtered[i],
                  colorIndex: i,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SubscriptionReceiptDetailScreen(
                          record: _filtered[i]),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  LIST WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final int totalInvoices, userCount;
  const _Header({required this.totalInvoices, required this.userCount});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    decoration: const BoxDecoration(
      color: AppColors.darkGreen,
      borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppMetrics.headerRadius)),
    ),
    padding: const EdgeInsets.fromLTRB(8, 12, 16, 24),
    child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.chevron_left_rounded,
            color: Colors.white, size: 26),
        padding: EdgeInsets.zero,
      ),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Payment Receipts', style: AppTextStyles.headerTitle),
        const SizedBox(height: 4),
        Text(
          '$userCount paid subscribers · $totalInvoices invoices',
          style: AppTextStyles.headerSubtitle,
        ),
      ])),
      // Receipt icon circle
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            shape: BoxShape.circle),
        child: const Icon(Icons.receipt_long_rounded,
            color: Colors.white, size: 20),
      ),
    ]),
  );
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onClear;
  const _SearchBar({required this.controller, required this.onClear});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6, offset: const Offset(0, 2))]),
    child: TextField(
      controller: controller,
      style: AppTextStyles.rowValue.copyWith(fontWeight: FontWeight.w400),
      decoration: InputDecoration(
        hintText: 'Search by name or email…',
        hintStyle: AppTextStyles.emailSubtle,
        prefixIcon: const Icon(Icons.search_rounded,
            color: AppColors.textSecondary, size: 20),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (_, v, __) => v.text.isEmpty
              ? const SizedBox.shrink()
              : IconButton(
              icon: const Icon(Icons.clear_rounded,
                  color: AppColors.textSecondary, size: 18),
              onPressed: onClear),
        ),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
    ),
  );
}

class _UserReceiptCard extends StatelessWidget {
  final UserReceiptData record;
  final int colorIndex;
  final VoidCallback onTap;

  const _UserReceiptCard({
    required this.record,
    required this.colorIndex,
    required this.onTap,
  });

  Color get _avatarColor =>
      AppColors.avatarPalette[colorIndex % AppColors.avatarPalette.length];

  @override
  Widget build(BuildContext context) {
    final sub   = record.subscription;
    final isPro = sub?.planCode != 'FREE' && sub != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(AppMetrics.cardRadius),
          border: Border.all(
            color: isPro
                ? AppColors.accentGreen.withOpacity(0.25)
                : AppColors.divider,
            width: isPro ? 1.2 : 0.8,
          ),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(children: [

          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [

              // Avatar
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                    color: _avatarColor, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(record.initials, style: const TextStyle(
                    fontFamily: 'DMSans', fontSize: 16,
                    fontWeight: FontWeight.w700, color: Colors.white)),
              ),

              const SizedBox(width: 12),

              // Info
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(record.fullName,
                      style: AppTextStyles.nameBold.copyWith(fontSize: 15),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(record.email,
                      style: AppTextStyles.emailSubtle,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              )),

              const SizedBox(width: 8),

              // Right column
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                // Plan badge
                if (sub != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: isPro ? AppColors.proBg : AppColors.deletedBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(sub.planCode,
                        style: AppTextStyles.badgeText.copyWith(
                          fontSize: 11,
                          color: isPro
                              ? AppColors.proText
                              : AppColors.textSecondary,
                        )),
                  ),
                const SizedBox(height: 5),
                // Invoice count
                Text(
                  record.invoiceCount == 0
                      ? 'No invoices'
                      : '${record.invoiceCount} invoice${record.invoiceCount == 1 ? '' : 's'}',
                  style: AppTextStyles.footerNote.copyWith(
                      fontSize: 11,
                      color: record.invoiceCount > 0
                          ? AppColors.accentGreen
                          : AppColors.textSecondary),
                ),
              ]),
            ]),
          ),

          // Subscription price row
          if (sub != null) ...[
            Divider(color: AppColors.divider, height: 1,
                indent: 14, endIndent: 14),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Row(children: [
                const Icon(Icons.payments_outlined,
                    size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(sub.priceLabel,
                    style: AppTextStyles.footerNote.copyWith(
                        fontSize: 11.5,
                        color: AppColors.textSecondary)),
                const Spacer(),
                // Status pill
                _StatusPill(status: sub.status),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right_rounded,
                    size: 16, color: AppColors.textSecondary),
              ]),
            ),
          ],

          // "No Stripe" note
          if (record.note != null && record.invoiceCount == 0) ...[
            Divider(color: AppColors.divider, height: 1,
                indent: 14, endIndent: 14),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
              child: Row(children: [
                const Icon(Icons.info_outline,
                    size: 12, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(child: Text(record.note!,
                    style: AppTextStyles.footerNote.copyWith(
                        fontSize: 11, color: AppColors.textSecondary))),
              ]),
            ),
          ],
        ]),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg, fg;
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        bg = AppColors.activeBg; fg = AppColors.activeText; break;
      case 'CANCELED': case 'CANCELLED':
      bg = const Color(0xFFFBDEDA); fg = const Color(0xFFB94040); break;
      default:
        bg = AppColors.deletedBg; fg = AppColors.textSecondary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg,
          borderRadius: BorderRadius.circular(20)),
      child: Text(
        status[0] + status.substring(1).toLowerCase(),
        style: AppTextStyles.badgeText.copyWith(fontSize: 10, color: fg),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
              color: const Color(0xFFFBDEDA), shape: BoxShape.circle),
          child: const Icon(Icons.error_outline_rounded,
              color: Color(0xFFB94040), size: 26),
        ),
        const SizedBox(height: 16),
        const Text('Failed to load receipts',
            style: AppTextStyles.cardTitle),
        const SizedBox(height: 8),
        Text(message,
            style: AppTextStyles.emailSubtle,
            textAlign: TextAlign.center),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: onRetry,
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.darkGreen, elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20))),
          child: const Text('Try again',
              style: TextStyle(fontFamily: 'DMSans',
                  fontWeight: FontWeight.w700, color: Colors.white)),
        ),
      ]),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 56, height: 56,
        decoration: BoxDecoration(
            color: AppColors.activeBg, shape: BoxShape.circle),
        child: const Icon(Icons.receipt_long_rounded,
            color: AppColors.activeText, size: 26),
      ),
      const SizedBox(height: 14),
      const Text('No payment receipts',
          style: AppTextStyles.cardTitle),
      const SizedBox(height: 6),
      Text('Paid subscribers and their invoices appear here.',
          style: AppTextStyles.emailSubtle.copyWith(fontSize: 13),
          textAlign: TextAlign.center),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  DETAIL SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class SubscriptionReceiptDetailScreen extends StatelessWidget {
  final UserReceiptData record;

  const SubscriptionReceiptDetailScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final sub = record.subscription;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(children: [

          // Header
          _DetailHeader(record: record),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                  AppMetrics.pagePadding, 16,
                  AppMetrics.pagePadding, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  // ── Subscriber card ───────────────────────────────────
                  _SectionTitle('SUBSCRIBER'),
                  const SizedBox(height: 8),
                  _InfoCard(rows: [
                    _Row('Name',  record.fullName),
                    _Row('Email', record.email),
                    _Row('User ID', _short(record.userId), copyable: true),
                  ]),

                  const SizedBox(height: 20),

                  // ── Subscription card ─────────────────────────────────
                  if (sub != null) ...[
                    _SectionTitle('SUBSCRIPTION'),
                    const SizedBox(height: 8),
                    _SubscriptionCard(sub: sub),
                    const SizedBox(height: 20),
                  ],

                  // ── Invoices ──────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const _SectionTitle('INVOICES'),
                      if (record.invoiceCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                              color: AppColors.activeBg,
                              borderRadius: BorderRadius.circular(20)),
                          child: Text(
                            '${record.invoiceCount} total',
                            style: AppTextStyles.badgeText.copyWith(
                                fontSize: 11, color: AppColors.activeText),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (record.invoices.isEmpty)
                    _NoInvoicesCard(note: record.note)
                  else
                    ...record.invoices.asMap().entries.map((e) =>
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _InvoiceCard(
                            invoice:    e.value,
                            index:      e.key + 1,
                            currency:   sub?.planCurrency ?? 'USD',
                          ),
                        ),
                    ),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }

  static String _short(String id) {
    if (id.length <= 9) return id;
    return '${id.substring(0, 4)}…${id.substring(id.length - 4)}';
  }
}

// ── Detail header ─────────────────────────────────────────────────────────────

class _DetailHeader extends StatelessWidget {
  final UserReceiptData record;
  const _DetailHeader({required this.record});

  Color get _avatarColor => AppColors.avatarPalette[0];

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color: AppColors.darkGreen,
      borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppMetrics.headerRadius)),
    ),
    padding: const EdgeInsets.fromLTRB(8, 12, 16, 28),
    child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.chevron_left_rounded,
            color: Colors.white, size: 26),
        padding: EdgeInsets.zero,
      ),
      // Avatar
      Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
            color: _avatarColor, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Text(record.initials, style: const TextStyle(
            fontFamily: 'DMSans', fontSize: 15,
            fontWeight: FontWeight.w700, color: Colors.white)),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(record.fullName,
              style: AppTextStyles.headerTitle.copyWith(fontSize: 18),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(record.email,
              style: AppTextStyles.headerSubtitle,
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      )),
      // Plan badge
      if (record.subscription != null)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20)),
          child: Text(record.subscription!.planCode,
              style: const TextStyle(
                  fontFamily: 'DMSans', fontSize: 11.5,
                  fontWeight: FontWeight.w700, color: Colors.white)),
        ),
    ]),
  );
}

// ── Subscription card ─────────────────────────────────────────────────────────

class _SubscriptionCard extends StatelessWidget {
  final ReceiptSubscription sub;
  const _SubscriptionCard({required this.sub});

  static String _fmtDate(String? s) {
    if (s == null || s.isEmpty || s == 'null') return '—';
    try {
      final d = DateTime.parse(s);
      const m = ['Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${d.day} ${m[d.month-1]} ${d.year}';
    } catch (_) { return s; }
  }

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [AppColors.darkGreen, Color(0xFF1A6B42)],
      ),
      borderRadius: BorderRadius.circular(AppMetrics.cardRadius),
      boxShadow: [BoxShadow(
          color: AppColors.darkGreen.withOpacity(0.25),
          blurRadius: 12, offset: const Offset(0, 4))],
    ),
    padding: const EdgeInsets.all(18),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      // Plan name + status
      Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(11)),
          child: const Icon(Icons.workspace_premium_rounded,
              color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(sub.planName, style: const TextStyle(
                fontFamily: 'DMSans', fontSize: 16,
                fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 2),
            Text(sub.priceLabel, style: TextStyle(
                fontFamily: 'DMSans', fontSize: 12,
                color: Colors.white.withOpacity(0.7))),
          ],
        )),
        _StatusPill(status: sub.status),
      ]),

      const SizedBox(height: 16),
      Divider(color: Colors.white.withOpacity(0.15), height: 1),
      const SizedBox(height: 14),

      // Period info grid
      Row(children: [
        _SubMetric('Period start', _fmtDate(sub.currentPeriodStart)),
        const SizedBox(width: 24),
        _SubMetric('Period end',   _fmtDate(sub.currentPeriodEnd)),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        _SubMetric('Created', _fmtDate(sub.createdAt)),
        const SizedBox(width: 24),
        _SubMetric('Cancel at end',
            sub.cancelAtPeriodEnd ? 'Yes' : 'No'),
      ]),

      if (sub.stripeSubscriptionId != null) ...[
        const SizedBox(height: 14),
        Divider(color: Colors.white.withOpacity(0.15), height: 1),
        const SizedBox(height: 12),
        Row(children: [
          const Icon(Icons.link_rounded,
              size: 13, color: Colors.white60),
          const SizedBox(width: 6),
          Expanded(child: Text(
            'Stripe: ${sub.stripeSubscriptionId}',
            style: const TextStyle(
                fontFamily: 'DMSans', fontSize: 11,
                color: Colors.white60),
            maxLines: 1, overflow: TextOverflow.ellipsis,
          )),
        ]),
      ],
    ]),
  );
}

class _SubMetric extends StatelessWidget {
  final String label, value;
  const _SubMetric(this.label, this.value);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(
          fontFamily: 'DMSans', fontSize: 10,
          color: Colors.white.withOpacity(0.55))),
      const SizedBox(height: 3),
      Text(value, style: const TextStyle(
          fontFamily: 'DMSans', fontSize: 13,
          fontWeight: FontWeight.w600, color: Colors.white)),
    ]),
  );
}

// ── Invoice card ──────────────────────────────────────────────────────────────

class _InvoiceCard extends StatelessWidget {
  final StripeInvoice invoice;
  final int    index;
  final String currency;

  const _InvoiceCard({
    required this.invoice,
    required this.index,
    required this.currency,
  });

  static String _fmtDate(String? s) {
    if (s == null || s.isEmpty || s == 'null') return '—';
    try {
      final d = DateTime.parse(s);
      const m = ['Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${d.day} ${m[d.month-1]} ${d.year}';
    } catch (_) { return s; }
  }

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.cardWhite,
      borderRadius: BorderRadius.circular(AppMetrics.cardRadius),
      border: Border.all(
        color: invoice.isPaid
            ? AppColors.accentGreen.withOpacity(0.2)
            : AppColors.divider,
        width: 0.8,
      ),
      boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      // Top row
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Row(children: [
          // Invoice icon
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: invoice.isPaid
                  ? AppColors.activeBg
                  : AppColors.suspendedBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              invoice.isPaid
                  ? Icons.check_circle_outline_rounded
                  : Icons.schedule_rounded,
              color: invoice.isPaid
                  ? AppColors.activeText
                  : AppColors.suspendedText,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                invoice.number ?? 'Invoice #$index',
                style: AppTextStyles.nameBold.copyWith(fontSize: 14),
              ),
              const SizedBox(height: 2),
              Text('Paid on ${_fmtDate(invoice.paidAt)}',
                  style: AppTextStyles.emailSubtle.copyWith(fontSize: 12)),
            ],
          )),
          // Amount
          Text(
            invoice.amountLabel,
            style: AppTextStyles.nameBold.copyWith(
              fontSize: 16,
              color: invoice.isPaid
                  ? AppColors.activeText
                  : AppColors.textPrimary,
            ),
          ),
        ]),
      ),

      Divider(color: AppColors.divider, height: 1, indent: 16, endIndent: 16),

      // Details grid
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(children: [
          Expanded(child: _InvoiceField(
              label: 'Period start',
              value: _fmtDate(invoice.periodStart))),
          Expanded(child: _InvoiceField(
              label: 'Period end',
              value: _fmtDate(invoice.periodEnd))),
          Expanded(child: _InvoiceField(
              label: 'Status',
              value: invoice.status.isNotEmpty
                  ? invoice.status[0].toUpperCase() +
                  invoice.status.substring(1).toLowerCase()
                  : '—',
              valueColor: invoice.isPaid
                  ? AppColors.activeText : null)),
        ]),
      ),

      // Invoice ID + copy
      if (invoice.invoiceId.isNotEmpty) ...[
        Divider(color: AppColors.divider, height: 1, indent: 16, endIndent: 16),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 12, 12),
          child: Row(children: [
            const Icon(Icons.tag_rounded, size: 12,
                color: AppColors.textSecondary),
            const SizedBox(width: 5),
            Expanded(child: Text(
              invoice.invoiceId.length > 30
                  ? '${invoice.invoiceId.substring(0, 14)}…'
                  '${invoice.invoiceId.substring(invoice.invoiceId.length - 8)}'
                  : invoice.invoiceId,
              style: AppTextStyles.footerNote.copyWith(fontSize: 11),
            )),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: invoice.invoiceId));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Invoice ID copied'),
                  duration: Duration(seconds: 1),
                  backgroundColor: AppColors.accentGreen,
                  behavior: SnackBarBehavior.floating,
                ));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.copy_rounded, size: 11,
                      color: AppColors.textSecondary),
                  SizedBox(width: 4),
                  Text('Copy', style: TextStyle(
                      fontFamily: 'DMSans', fontSize: 10,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500)),
                ]),
              ),
            ),
          ]),
        ),
      ],
    ]),
  );
}

class _InvoiceField extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  const _InvoiceField({required this.label, required this.value,
    this.valueColor});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: AppTextStyles.footerNote.copyWith(
          fontSize: 10, color: AppColors.textSecondary)),
      const SizedBox(height: 3),
      Text(value, style: AppTextStyles.rowValue.copyWith(
          fontSize: 12, color: valueColor ?? AppColors.textPrimary)),
    ],
  );
}

class _NoInvoicesCard extends StatelessWidget {
  final String? note;
  const _NoInvoicesCard({this.note});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.cardWhite,
      borderRadius: BorderRadius.circular(AppMetrics.cardRadius),
      border: Border.all(color: AppColors.divider, width: 0.8),
    ),
    child: Column(children: [
      Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
            color: AppColors.deletedBg, shape: BoxShape.circle),
        child: const Icon(Icons.receipt_long_outlined,
            color: AppColors.textSecondary, size: 22),
      ),
      const SizedBox(height: 12),
      const Text('No invoices yet',
          style: AppTextStyles.nameBold),
      if (note != null) ...[
        const SizedBox(height: 6),
        Text(note!, style: AppTextStyles.emailSubtle.copyWith(fontSize: 12),
            textAlign: TextAlign.center),
      ],
    ]),
  );
}

// ── Shared detail widgets ─────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String label;
  const _SectionTitle(this.label);

  @override
  Widget build(BuildContext context) => Text(label,
      style: AppTextStyles.sectionLabel);
}

class _InfoCard extends StatelessWidget {
  final List<_Row> rows;
  const _InfoCard({required this.rows});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.cardWhite,
      borderRadius: BorderRadius.circular(AppMetrics.cardRadius),
      boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: Column(
      children: rows.asMap().entries.map((e) => Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(e.value.label, style: AppTextStyles.rowLabel),
              const SizedBox(width: 12),
              Flexible(child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(child: Text(e.value.value,
                      style: AppTextStyles.rowValue.copyWith(fontSize: 14),
                      textAlign: TextAlign.right,
                      maxLines: 1, overflow: TextOverflow.ellipsis)),
                  if (e.value.copyable) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: e.value.value));
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${e.value.label} copied'),
                                duration: const Duration(seconds: 1),
                                backgroundColor: AppColors.accentGreen,
                                behavior: SnackBarBehavior.floating));
                      },
                      child: const Icon(Icons.copy_rounded,
                          size: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ],
              )),
            ],
          ),
        ),
        if (e.key < rows.length - 1)
          const Divider(height: 1, color: AppColors.divider),
      ])).toList(),
    ),
  );
}

class _Row {
  final String label, value;
  final bool copyable;
  const _Row(this.label, this.value, {this.copyable = false});
}