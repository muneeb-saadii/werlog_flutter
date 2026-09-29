import 'package:flutter/material.dart';
import '../../core/api/admin_api_service.dart';
import '../../core/api/admin_endpoints.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/admin_bottom_nav.dart';
import 'ocr_jobs_screen.dart' show OpsInvoice, OpsInvoiceDetailScreen;

// ── Screen ────────────────────────────────────────────────────────────────────

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {

  bool              _loading  = true;
  List<OpsInvoice>  _all      = [];
  String            _filter   = '';
  final _search = TextEditingController();
  String            _query    = '';

  List<OpsInvoice> get _filtered {
    List<OpsInvoice> list = _filter.isEmpty
        ? _all
        : _all.where((i) => i.status == _filter).toList();
    if (_query.isNotEmpty) {
      list = list.where((i) =>
      (i.vendorName ?? '').toLowerCase().contains(_query) ||
          i.currency.toLowerCase().contains(_query) ||
          i.type.toLowerCase().contains(_query)).toList();
    }
    return list;
  }

  @override
  void initState() {
    super.initState();
    _search.addListener(
            () => setState(() => _query = _search.text.toLowerCase().trim()));
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final resp = await AdminApiService.get(
        context, AdminEndpoints.adminInvoices,
        queryParams: {'page': '0', 'size': '50'},
        showLoader: false,
      );
      debugPrint('[Invoices] response keys => ${resp?.keys}');
      if (!mounted) return;
      if (resp != null) {
        final raw = resp['data'];
        final list = raw is List ? raw : (raw is Map ? raw['content'] ?? [] : []);
        _all = (list as List<dynamic>)
            .whereType<Map<String, dynamic>>()
            .map(OpsInvoice.fromJson)
            .toList();
      }
    } catch (e) {
      debugPrint('[Invoices] error => $e');
      if (mounted) AdminApiService.showError(context, 'Failed to load invoices');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete(OpsInvoice inv) async {
    try {
      await AdminApiService.delete(
          context, AdminEndpoints.adminInvoiceDelete(inv.id),
          showLoader: false);
      if (!mounted) return;
      AdminApiService.showSuccess(context, 'Invoice deleted');
      _all.removeWhere((i) => i.id == inv.id);
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

            // ── Header ─────────────────────────────────────────────────
            _Header(total: _all.length, onRefresh: _fetch),

            // ── Search ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Container(
                decoration: BoxDecoration(
                    color: AppColors.cardWhite,
                    borderRadius: BorderRadius.circular(12)),
                child: TextField(
                  controller: _search,
                  style: AppTextStyles.rowValue
                      .copyWith(fontWeight: FontWeight.w400),
                  decoration: InputDecoration(
                    hintText: 'Search vendor, currency, type…',
                    hintStyle: AppTextStyles.emailSubtle,
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppColors.textSecondary, size: 19),
                    suffixIcon: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _search,
                      builder: (_, v, __) => v.text.isEmpty
                          ? const SizedBox.shrink()
                          : IconButton(
                          icon: const Icon(Icons.clear_rounded,
                              color: AppColors.textSecondary, size: 17),
                          onPressed: _search.clear),
                    ),
                    border: InputBorder.none,
                    contentPadding:
                    const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),

            // ── Filter chips ────────────────────────────────────────────
            _FilterRow(
              items: const [
                ('', 'All'), ('COMPLETED', 'Completed'),
                ('PROCESSING', 'Processing'), ('FAILED', 'Failed'),
              ],
              selected: _filter,
              onSelected: (f) => setState(() => _filter = f),
            ),

            // ── List ────────────────────────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(
                  color: AppColors.accentGreen))
                  : _filtered.isEmpty
                  ? const _EmptyState(
                  icon: Icons.receipt_long_outlined,
                  label: 'No invoices')
                  : RefreshIndicator(
                onRefresh: _fetch,
                color: AppColors.accentGreen,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                      16, 4, 16, 24),
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) => _InvoiceCard(
                    invoice:  _filtered[i],
                    onTap:    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OpsInvoiceDetailScreen(
                          invoice:  _filtered[i],
                          onDelete: () => _delete(_filtered[i]),
                        ),
                      ),
                    ),
                    onDelete: () => _delete(_filtered[i]),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final int total;
  final VoidCallback onRefresh;
  const _Header({required this.total, required this.onRefresh});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(8, 12, 16, 18),
    decoration: const BoxDecoration(
      color: AppColors.darkGreen,
      borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppMetrics.headerRadius)),
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.chevron_left_rounded,
            color: Colors.white, size: 26),
        padding: EdgeInsets.zero,
      ),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Invoices', style: AppTextStyles.headerTitle),
        const SizedBox(height: 4),
        Text('$total invoices across all users',
            style: AppTextStyles.headerSubtitle),
      ])),
      GestureDetector(
        onTap: onRefresh,
        child: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              shape: BoxShape.circle),
          child: const Icon(Icons.refresh_rounded,
              color: Colors.white, size: 20),
        ),
      ),
    ]),
  );
}

// ── Invoice card (identical to OPS invoices tab) ──────────────────────────────

class _InvoiceCard extends StatelessWidget {
  final OpsInvoice invoice;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _InvoiceCard({required this.invoice, required this.onTap,
    required this.onDelete});

  Color get _statusColor => invoice.status == 'COMPLETED'
      ? AppColors.activeText
      : invoice.status == 'PROCESSING' ? AppColors.suspendedText
      : const Color(0xFFB94040);

  Color get _statusBg => invoice.status == 'COMPLETED'
      ? AppColors.activeBg
      : invoice.status == 'PROCESSING' ? AppColors.suspendedBg
      : const Color(0xFFFBDEDA);

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(AppMetrics.cardRadius),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: [

        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            // Thumbnail
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider)),
              child: invoice.isImage
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Image.network(
                  invoice.fullImageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                  const Icon(Icons.receipt_long_rounded,
                      size: 22, color: AppColors.textSecondary),
                ),
              )
                  : const Icon(Icons.receipt_long_rounded,
                  size: 22, color: AppColors.textSecondary),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(invoice.vendorName ?? 'Unknown vendor',
                  style: AppTextStyles.nameBold.copyWith(fontSize: 14),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 3),
              Wrap(spacing: 4, runSpacing: 2, children: [
                if (invoice.invoiceDate != null)
                  Text(_fmtDate(invoice.invoiceDate),
                      style: AppTextStyles.emailSubtle.copyWith(fontSize: 11)),
                _Tag(invoice.type == 'BUSINESS' ? 'Business' : 'Personal',
                    green: invoice.type == 'BUSINESS'),
                if (invoice.paymentMethod != null)
                  _Tag(invoice.paymentMethod!),
              ]),
            ])),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              if (invoice.totalAmount != null)
                Text(
                  '${invoice.currency} ${invoice.totalAmount!.toStringAsFixed(2)}',
                  style: AppTextStyles.nameBold.copyWith(fontSize: 14),
                ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                    color: _statusBg,
                    borderRadius: BorderRadius.circular(20)),
                child: Text(
                  invoice.status == 'COMPLETED' ? 'Done' : invoice.status,
                  style: TextStyle(fontFamily: 'DMSans', fontSize: 10.5,
                      fontWeight: FontWeight.w700, color: _statusColor),
                ),
              ),
            ]),
          ]),
        ),

        // Footer row
        Container(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.divider, width: 0.8)),
          ),
          child: Row(children: [
            if (invoice.confidenceScore != null) ...[
              _ConfidenceDot(invoice.confidenceScore!),
              const SizedBox(width: 4),
              Text('${(invoice.confidenceScore! * 100).round()}%',
                  style: AppTextStyles.footerNote.copyWith(fontSize: 11)),
              const SizedBox(width: 10),
            ],
            Text(
              '${invoice.lineItems.length} item${invoice.lineItems.length == 1 ? '' : 's'}',
              style: AppTextStyles.footerNote.copyWith(fontSize: 11),
            ),
            if (invoice.fileSizeLabel.isNotEmpty) ...[
              const Text(' · ', style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 11)),
              Text(invoice.fileSizeLabel,
                  style: AppTextStyles.footerNote.copyWith(fontSize: 11)),
            ],
            const Spacer(),
            GestureDetector(
              onTap: () => _confirmDelete(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    color: const Color(0xFFFBDEDA),
                    borderRadius: BorderRadius.circular(8)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.delete_outline_rounded,
                      size: 12, color: Color(0xFFB94040)),
                  SizedBox(width: 4),
                  Text('Delete', style: TextStyle(
                      fontFamily: 'DMSans', fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFB94040))),
                ]),
              ),
            ),
          ]),
        ),
      ]),
    ),
  );

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dlg) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete invoice?', style: AppTextStyles.cardTitle),
        content: Text(
          'This will permanently remove the invoice for '
              '"${invoice.vendorName ?? 'this vendor'}".',
          style: AppTextStyles.rowLabel,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dlg).pop(),
            child: Text('Cancel', style: AppTextStyles.actionButton
                .copyWith(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () { Navigator.of(dlg).pop(); onDelete(); },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.dangerRed, elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20))),
            child: const Text('Delete', style: TextStyle(
                fontFamily: 'DMSans', fontWeight: FontWeight.w700,
                color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── Helpers (inlined from ocr_jobs_screen.dart — private symbols can't be imported) ──

String _fmtDate(String? s) {
  if (s == null || s.isEmpty || s == 'null') return '—';
  try {
    final d = DateTime.parse(s);
    const m = ['Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${m[d.month-1]} ${d.year}';
  } catch (_) { return s; }
}

class _Tag extends StatelessWidget {
  final String label;
  final bool amber, green;
  final Color? color;
  const _Tag(this.label, {this.amber = false, this.green = false, this.color});

  @override
  Widget build(BuildContext context) {
    final fg = color ?? (amber ? AppColors.suspendedText
        : green ? AppColors.activeText
        : AppColors.textSecondary);
    final bg = amber ? AppColors.suspendedBg
        : green ? AppColors.activeBg
        : AppColors.deletedBg;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(
          fontFamily: 'DMSans', fontSize: 10,
          fontWeight: FontWeight.w600, color: fg)),
    );
  }
}

class _ConfidenceDot extends StatelessWidget {
  final double score;
  const _ConfidenceDot(this.score);

  Color get _color {
    if (score >= 0.9) return AppColors.activeText;
    if (score >= 0.7) return AppColors.suspendedText;
    return const Color(0xFFB94040);
  }

  @override
  Widget build(BuildContext context) => Container(
    width: 8, height: 8,
    decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
  );
}

class _FilterRow extends StatelessWidget {
  final List<(String, String)> items;
  final String selected;
  final ValueChanged<String> onSelected;
  const _FilterRow({required this.items, required this.selected,
    required this.onSelected});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      children: items.map((item) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: GestureDetector(
          onTap: () => onSelected(item.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: item.$1 == selected
                  ? AppColors.darkGreen : AppColors.cardWhite,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: item.$1 == selected
                    ? AppColors.darkGreen : AppColors.divider,
              ),
            ),
            child: Text(item.$2, style: TextStyle(
                fontFamily: 'DMSans', fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: item.$1 == selected
                    ? Colors.white : AppColors.textSecondary)),
          ),
        ),
      )).toList(),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String label;
  const _EmptyState({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 56, height: 56,
          decoration: BoxDecoration(color: AppColors.deletedBg, shape: BoxShape.circle),
          child: Icon(icon, color: AppColors.textSecondary, size: 26)),
      const SizedBox(height: 14),
      Text(label, style: AppTextStyles.cardTitle),
      const SizedBox(height: 4),
      const Text('Pull down to refresh', style: AppTextStyles.footerNote),
    ]),
  );
}