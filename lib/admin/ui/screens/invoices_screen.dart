import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/admin_bottom_nav.dart';

// ── Models ────────────────────────────────────────────────────────────────────

enum InvoiceStatus { completed, processing, failed }

class AdminInvoice {
  final String id;
  final String vendorName;
  final String user;
  final String date;
  final String category;
  final double? amount;
  final InvoiceStatus status;

  const AdminInvoice({
    required this.id,
    required this.vendorName,
    required this.user,
    required this.date,
    required this.category,
    this.amount,
    required this.status,
  });
}

// ── Mock data ─────────────────────────────────────────────────────────────────

final _mockInvoices = [
  const AdminInvoice(id: '1', vendorName: 'Canada Computers Inc.',
      user: 'Haseeb I.', date: '29 Jul', category: 'Equipment',
      amount: 3277, status: InvoiceStatus.completed),
  const AdminInvoice(id: '2', vendorName: 'Uber Eats',
      user: 'David L.', date: '28 Jul', category: 'Meals',
      amount: 54.20, status: InvoiceStatus.completed),
  const AdminInvoice(id: '3', vendorName: 'Shell Fuel',
      user: 'Michael J.', date: '28 Jul', category: 'Vehicle',
      amount: 88.00, status: InvoiceStatus.processing),
  const AdminInvoice(id: '4', vendorName: 'Unknown vendor',
      user: 'Sarah K.', date: '27 Jul', category: 'needs review',
      amount: null, status: InvoiceStatus.failed),
  const AdminInvoice(id: '5', vendorName: 'Amazon Web Services',
      user: 'Unique M.', date: '26 Jul', category: 'Software',
      amount: 210.00, status: InvoiceStatus.completed),
];

// ── Screen ────────────────────────────────────────────────────────────────────

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  InvoiceStatus? _filter;

  List<AdminInvoice> get _filtered => _filter == null
      ? _mockInvoices
      : _mockInvoices.where((i) => i.status == _filter).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: const AdminBottomNav(currentIndex: 3),
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          _InvoicesHeader(total: _mockInvoices.length),
          _FilterChips(
            selected: _filter,
            onSelected: (s) => setState(() => _filter = s),
          ),
          Expanded(
            child: _filtered.isEmpty
                ? _EmptyState()
                : Column(children: [
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                            AppMetrics.pagePadding, 8,
                            AppMetrics.pagePadding, 100),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) => const Divider(
                            height: 1, indent: 72, color: AppColors.divider),
                        itemBuilder: (_, i) => _InvoiceRow(
                          invoice: _filtered[i],
                          onTap: () => _showActions(_filtered[i]),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Text('Tap a row to view or delete',
                          style: AppTextStyles.footerNote),
                    ),
                  ]),
          ),
        ]),
      ),
    );
  }

  void _showActions(AdminInvoice inv) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardWhite,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _InvoiceActionSheet(invoice: inv),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _InvoicesHeader extends StatelessWidget {
  final int total;
  const _InvoicesHeader({required this.total});

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
          Text('Invoices', style: AppTextStyles.headerTitle),
          const SizedBox(height: 4),
          Text('8,640 total across all users',
              style: AppTextStyles.headerSubtitle),
        ],
      )),
      _CircleAction(icon: Icons.search_rounded, onTap: () {}),
    ]),
  );
}

// ── Filter chips ──────────────────────────────────────────────────────────────

class _FilterChips extends StatelessWidget {
  final InvoiceStatus? selected;
  final ValueChanged<InvoiceStatus?> onSelected;
  const _FilterChips({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 52,
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        _Chip(label: 'All', active: selected == null,
            onTap: () => onSelected(null)),
        const SizedBox(width: 8),
        _Chip(label: 'Completed', active: selected == InvoiceStatus.completed,
            onTap: () => onSelected(InvoiceStatus.completed)),
        const SizedBox(width: 8),
        _Chip(label: 'Processing', active: selected == InvoiceStatus.processing,
            onTap: () => onSelected(InvoiceStatus.processing)),
        const SizedBox(width: 8),
        _Chip(label: 'Failed', active: selected == InvoiceStatus.failed,
            onTap: () => onSelected(InvoiceStatus.failed)),
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

// ── Invoice row ───────────────────────────────────────────────────────────────

class _InvoiceRow extends StatelessWidget {
  final AdminInvoice invoice;
  final VoidCallback onTap;
  const _InvoiceRow({required this.invoice, required this.onTap});

  _StatusCfg get _cfg {
    switch (invoice.status) {
      case InvoiceStatus.completed:
        return _StatusCfg(AppColors.activeBg, AppColors.activeText, 'Done');
      case InvoiceStatus.processing:
        return _StatusCfg(AppColors.suspendedBg, AppColors.suspendedText, 'Processing');
      case InvoiceStatus.failed:
        return _StatusCfg(const Color(0xFFFBDEDA), const Color(0xFFB94040), 'Failed');
    }
  }

  Color get _iconBg {
    switch (invoice.status) {
      case InvoiceStatus.completed: return AppColors.activeBg;
      case InvoiceStatus.processing: return AppColors.suspendedBg;
      case InvoiceStatus.failed: return const Color(0xFFFBDEDA);
    }
  }

  Color get _iconFg {
    switch (invoice.status) {
      case InvoiceStatus.completed: return AppColors.activeText;
      case InvoiceStatus.processing: return AppColors.suspendedText;
      case InvoiceStatus.failed: return const Color(0xFFB94040);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cfg = _cfg;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
                color: _iconBg,
                borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.receipt_long_rounded,
                color: _iconFg, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(invoice.vendorName,
                  style: AppTextStyles.nameBold.copyWith(fontSize: 15),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 3),
              Text('${invoice.user} · ${invoice.date} · ${invoice.category}',
                  style: AppTextStyles.emailSubtle,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          )),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(
              invoice.amount != null
                  ? '\$${invoice.amount!.toStringAsFixed(invoice.amount! == invoice.amount!.truncate().toDouble() ? 0 : 2)}'
                  : '—',
              style: AppTextStyles.nameBold.copyWith(fontSize: 15),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: cfg.bg, borderRadius: BorderRadius.circular(20)),
              child: Text(cfg.label,
                  style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 11.5, fontWeight: FontWeight.w700,
                      color: cfg.fg)),
            ),
          ]),
        ]),
      ),
    );
  }
}

class _StatusCfg {
  final Color bg, fg;
  final String label;
  const _StatusCfg(this.bg, this.fg, this.label);
}

// ── Action sheet ──────────────────────────────────────────────────────────────

class _InvoiceActionSheet extends StatelessWidget {
  final AdminInvoice invoice;
  const _InvoiceActionSheet({required this.invoice});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 36, height: 4,
        decoration: BoxDecoration(
            color: AppColors.divider,
            borderRadius: BorderRadius.circular(2)),
      ),
      const SizedBox(height: 16),
      Text(invoice.vendorName, style: AppTextStyles.cardTitle),
      const SizedBox(height: 4),
      Text('${invoice.user} · ${invoice.date}',
          style: AppTextStyles.emailSubtle),
      const SizedBox(height: 20),
      _SheetAction(
        icon: Icons.visibility_outlined,
        label: 'View invoice details',
        onTap: () => Navigator.pop(context),
      ),
      const Divider(color: AppColors.divider),
      _SheetAction(
        icon: Icons.delete_outline_rounded,
        label: 'Delete invoice',
        danger: true,
        onTap: () => Navigator.pop(context),
      ),
    ]),
  );
}

class _SheetAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool danger;
  final VoidCallback onTap;
  const _SheetAction({required this.icon, required this.label,
      this.danger = false, required this.onTap});

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    leading: Icon(icon,
        color: danger ? AppColors.dangerRed : AppColors.textPrimary),
    title: Text(label,
        style: danger
            ? AppTextStyles.actionButtonDanger
            : AppTextStyles.actionButton),
  );
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.receipt_long_rounded,
          size: 52, color: AppColors.textSecondary),
      const SizedBox(height: 12),
      Text('No invoices', style: AppTextStyles.statLabel),
    ]),
  );
}

class _CircleAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          shape: BoxShape.circle),
      child: Icon(icon, color: Colors.white, size: 20),
    ),
  );
}
