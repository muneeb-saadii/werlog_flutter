import 'package:flutter/material.dart';
import '../../core/api/admin_api_service.dart';
import '../../core/api/admin_endpoints.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/admin_bottom_nav.dart';

// ── Model ─────────────────────────────────────────────────────────────────────

class _Invoice {
  final String  id;
  final String  vendorName;
  final String  userName;
  final String  date;
  final String  category;
  final double? amount;
  final String  status;   // raw string from API

  const _Invoice({
    required this.id,
    required this.vendorName,
    required this.userName,
    required this.date,
    required this.category,
    this.amount,
    required this.status,
  });

  factory _Invoice.fromJson(Map<String, dynamic> j) {
    double? amt;
    try { amt = (j['totalAmount'] ?? j['amount'] as num?)?.toDouble(); } catch (_) {}

    return _Invoice(
      id:         j['invoiceId']?.toString()  ?? j['id']?.toString() ?? '',
      vendorName: j['vendorName']?.toString() ?? 'Unknown vendor',
      userName:   j['userFullName']?.toString()
          ?? j['userName']?.toString()
          ?? j['userId']?.toString() ?? '',
      date:       _fmtDate(j['invoiceDate']?.toString() ?? j['createdAt']?.toString()),
      category:   j['categoryName']?.toString() ?? j['category']?.toString() ?? '',
      amount:     amt,
      status:     j['status']?.toString().toUpperCase() ?? 'UNKNOWN',
    );
  }

  static String _fmtDate(String? s) {
    if (s == null || s.isEmpty) return '';
    try {
      final d = DateTime.parse(s);
      const m = ['Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${d.day} ${m[d.month-1]}';
    } catch (_) { return s; }
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {

  bool            _loading = true;
  List<_Invoice>  _invoices = [];
  int             _total   = 0;
  String          _filter  = '';   // '' | COMPLETED | PROCESSING | FAILED

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final resp = await AdminApiService.get(
        context,
        AdminEndpoints.adminInvoices,
        queryParams: {
          if (_filter.isNotEmpty) 'status': _filter,
          'page': '0', 'size': '20',
        },
        showLoader: false,
      );
      debugPrint('[Invoices] response keys => ${resp?.keys}');
      if (!mounted) return;

      if (resp != null) {
        final raw = resp['data'];
        List<dynamic> list = [];
        int tot = 0;

        if (raw is List) {
          list = raw;
          tot  = raw.length;
        } else if (raw is Map<String, dynamic>) {
          list = raw['content'] as List<dynamic>? ?? [];
          tot  = (raw['totalElements'] as num?)?.toInt() ?? list.length;
        }

        _invoices = list
            .whereType<Map<String, dynamic>>()
            .map(_Invoice.fromJson)
            .toList();
        _total = tot;
      }
    } catch (e) {
      debugPrint('[Invoices] error => $e');
      if (mounted) AdminApiService.showError(context, 'Failed to load invoices');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete(String id) async {
    try {
      final resp = await AdminApiService.delete(
          context, AdminEndpoints.adminInvoiceDelete(id), showLoader: false);
      debugPrint('[Invoices] delete $id => $resp');
      if (!mounted) return;
      AdminApiService.showSuccess(context, 'Invoice deleted');
      _invoices.removeWhere((i) => i.id == id);
      setState(() {});
    } catch (e) {
      if (mounted) AdminApiService.showError(context, 'Delete failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: const AdminBottomNav(currentIndex: 3),
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          _Header(total: _total),
          _FilterChips(
            selected: _filter,
            onSelected: (s) { setState(() => _filter = s); _fetch(); },
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(
                color: AppColors.accentGreen))
                : _invoices.isEmpty
                ? const _EmptyState()
                : RefreshIndicator(
              onRefresh: _fetch,
              color: AppColors.accentGreen,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                    AppMetrics.pagePadding, 8,
                    AppMetrics.pagePadding, 100),
                itemCount: _invoices.length,
                separatorBuilder: (_, __) => const Divider(
                    height: 1, indent: 72,
                    color: AppColors.divider),
                itemBuilder: (_, i) => _InvoiceRow(
                  invoice: _invoices[i],
                  onTap: () => _showActions(_invoices[i]),
                ),
              ),
            ),
          ),
        ]),
      ),
    ),
    );

  }

  void _showActions(_Invoice inv) {
    final dialogContext = context;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardWhite,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4,
              decoration: BoxDecoration(color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text(inv.vendorName, style: AppTextStyles.cardTitle),
          const SizedBox(height: 4),
          Text('${inv.userName} · ${inv.date}',
              style: AppTextStyles.emailSubtle),
          const SizedBox(height: 20),
          ListTile(
            onTap: () => Navigator.pop(dialogContext),
            leading: const Icon(Icons.visibility_outlined,
                color: AppColors.textPrimary),
            title: Text('View invoice details',
                style: AppTextStyles.actionButton),
          ),
          const Divider(color: AppColors.divider),
          ListTile(
            onTap: () {
              Navigator.pop(dialogContext);
              _delete(inv.id);
            },
            leading: const Icon(Icons.delete_outline_rounded,
                color: AppColors.dangerRed),
            title: Text('Delete invoice',
                style: AppTextStyles.actionButtonDanger),
          ),
        ]),
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final int total;
  const _Header({required this.total});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    decoration: const BoxDecoration(
      color: AppColors.darkGreen,
      borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppMetrics.headerRadius)),
    ),
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      GestureDetector(
        onTap: () => Navigator.pop(context),
        child: const Icon(Icons.chevron_left,
            color: AppColors.textOnDark, size: 26),
      ),
      const SizedBox(width: 8),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Invoices', style: AppTextStyles.headerTitle),
          const SizedBox(height: 4),
          Text('$total total across all users',
              style: AppTextStyles.headerSubtitle),
        ],
      )),
      _CircleIcon(icon: Icons.search_rounded),
    ]),
  );
}

class _FilterChips extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;
  const _FilterChips({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 52,
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        for (final item in [
          ('', 'All'), ('COMPLETED', 'Completed'),
          ('PROCESSING', 'Processing'), ('FAILED', 'Failed'),
        ])
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _Chip(label: item.$2,
                active: selected == item.$1,
                onTap: () => onSelected(item.$1)),
          ),
      ],
    ),
  );
}

class _Chip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: active ? AppColors.darkGreen : AppColors.cardWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: active ? AppColors.darkGreen : AppColors.divider),
      ),
      child: Text(label,
          style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 13, fontWeight: FontWeight.w600,
              color: active ? Colors.white : AppColors.textSecondary)),
    ),
  );
}

class _InvoiceRow extends StatelessWidget {
  final _Invoice invoice;
  final VoidCallback onTap;
  const _InvoiceRow({required this.invoice, required this.onTap});

  Color get _bg => invoice.status == 'COMPLETED'
      ? AppColors.activeBg
      : invoice.status == 'PROCESSING'
      ? AppColors.suspendedBg
      : const Color(0xFFFBDEDA);

  Color get _fg => invoice.status == 'COMPLETED'
      ? AppColors.activeText
      : invoice.status == 'PROCESSING'
      ? AppColors.suspendedText
      : const Color(0xFFB94040);

  String get _label {
    switch (invoice.status) {
      case 'COMPLETED': return 'Done';
      case 'PROCESSING': return 'Processing';
      default: return 'Failed';
    }
  }

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
              color: _bg, borderRadius: BorderRadius.circular(12)),
          child: Icon(Icons.receipt_long_rounded, color: _fg, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(invoice.vendorName, style: AppTextStyles.nameBold.copyWith(fontSize: 15),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 3),
          Text(
            [if (invoice.userName.isNotEmpty) invoice.userName,
              if (invoice.date.isNotEmpty) invoice.date,
              if (invoice.category.isNotEmpty) invoice.category]
                .join(' · '),
            style: AppTextStyles.emailSubtle,
            maxLines: 1, overflow: TextOverflow.ellipsis,
          ),
        ])),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(
            invoice.amount != null ? '\$${invoice.amount!.toStringAsFixed(2)}' : '—',
            style: AppTextStyles.nameBold.copyWith(fontSize: 15),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: _bg, borderRadius: BorderRadius.circular(20)),
            child: Text(_label,
                style: TextStyle(fontFamily: AppTextStyles.fontFamily,
                    fontSize: 11.5, fontWeight: FontWeight.w700, color: _fg)),
          ),
        ]),
      ]),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => const Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.receipt_long_rounded, size: 52, color: AppColors.textSecondary),
      SizedBox(height: 12),
      Text('No invoices found', style: AppTextStyles.statLabel),
    ]),
  );
}

class _CircleIcon extends StatelessWidget {
  final IconData icon;
  const _CircleIcon({required this.icon});

  @override
  Widget build(BuildContext context) => Container(
    width: 40, height: 40,
    decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12), shape: BoxShape.circle),
    child: Icon(icon, color: Colors.white, size: 20),
  );
}