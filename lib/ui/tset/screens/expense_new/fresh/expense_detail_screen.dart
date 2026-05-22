import 'package:flutter/material.dart';
import 'package:wellness/ui/tset/screens/expense_new/fresh/expense_data.dart';

import '../../../../../core/api/api_service.dart';
import '../../../../../core/api/endpoints.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/general_functions.dart';
import '../../category_overview_screen.dart';

// ────────────────────────────────────────────────────────────────────
//  Invoice line-item data model  (read-only display + edit form seed)
// ────────────────────────────────────────────────────────────────────



// ════════════════════════════════════════════════════════════════════

class ExpenseDetailScreen extends StatefulWidget {
  final InvoiceItem item;
  final List<String> imageUrls;


  const ExpenseDetailScreen({
    super.key,
    required this.item,
    this.imageUrls = const [],
  });

  @override
  State<ExpenseDetailScreen> createState() => _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends State<ExpenseDetailScreen> {

  static String isoToDisplay(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/'
          '${dt.year}';
    } catch (_) {
      return iso;
    }
  }

  double get _remainingProgress {
    try {
      final s = widget.item.invoiceDate.split('/');
      final e = widget.item.invoiceDate.split('/');
      final start = DateTime(int.parse(s[2]), int.parse(s[1]), int.parse(s[0]));
      final end   = DateTime(int.parse(e[2]), int.parse(e[1]), int.parse(e[0]));
      final now   = DateTime.now();
      final total = end.difference(start).inDays;
      if (total <= 0) return 0;
      return (end.difference(now).inDays / total).clamp(0.0, 1.0);
    } catch (_) { return 0; }
  }

  String get _remainingLabel {
    try {
      final e = widget.item.invoiceDate.split('/');
      final end = DateTime(int.parse(e[2]), int.parse(e[1]), int.parse(e[0]));
      final now = DateTime.now();
      if (end.isBefore(now)) return 'Expired';
      int years  = end.year  - now.year;
      int months = end.month - now.month;
      if (end.day < now.day) months--;
      if (months < 0) { years--; months += 12; }
      if (years <= 0 && months <= 0)
        return '${end.difference(now).inDays} Days Remaining';
      if (years > 0 && months > 0) return '$years Year, $months Month Remaining';
      if (years > 0) return '$years Year Remaining';
      return '$months Month Remaining';
    } catch (_) { return 'N/A'; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WerlogColors.background,
      body: SafeArea(
        child: Column(children: [
          _buildAppBar(context),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  _buildProductHeader(context),
                  // const SizedBox(height: 14),
                  // _buildPurchaseRow(context),
                  const SizedBox(height: 14),
                  _buildExpenseStatusCard(context),
                  const SizedBox(height: 14),
                  _buildExpenseInfoCard(context),
                  if (widget.item != null &&
                      widget.item.items.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _buildInvoiceItemsCard(context),
                  ],
                  if (widget.imageUrls.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _buildInvoiceImagesCard(context),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          _buildActionBar(context),
        ]),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: WerlogColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text('Expense Details',
              style: WerlogTextStyles.pageTitle.copyWith(fontSize: 18)),
        ),
      ]),
    );
  }

  Widget _buildProductHeader(BuildContext context) {
    return Container(
      decoration: _cardDeco(),
      padding: const EdgeInsets.all(16),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            gradient: WerlogGradients.pageHeader(),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: WerlogColors.border, width: 0.8),
          ),
          child: const Icon(Icons.laptop_mac,
              color: WerlogColors.darkTeal, size: 38),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Text(widget.item.vendorName,
                    style: WerlogTextStyles.pageTitle.copyWith(fontSize: 19)),
              ),
              // _statusBadge(widget.item.status),
            ]),
            const SizedBox(height: 4),
            Text('Serial Number', style: WerlogTextStyles.caption),
            Text(widget.item.invoiceId,
                style: WerlogTextStyles.txTitle.copyWith(fontSize: 13)),
          ]),
        ),
      ]),
    );
  }

  Widget _statusBadge(String status) {
    final configs = {
      'active':        {'label': 'Active',        'bg': WerlogColors.tealSurface,  'text': WerlogColors.teal},
      'expiring_soon': {'label': 'Expiring Soon', 'bg': WerlogColors.amberSurface, 'text': WerlogColors.amber},
      'expired':       {'label': 'Expired',       'bg': WerlogColors.coralSurface, 'text': WerlogColors.coral},
      'claimed':       {'label': 'Claimed',       'bg': WerlogColors.surfaceAlt,   'text': WerlogColors.textSecondary},
    };
    final c = configs[status] ?? configs['active']!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c['bg'] as Color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: (c['text'] as Color).withOpacity(0.3), width: 0.8),
      ),
      child: Text(c['label'] as String,
          style: WerlogTextStyles.badgeText
              .copyWith(color: c['text'] as Color, fontSize: 10)),
    );
  }

  Widget _buildPurchaseRow(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(children: [
        _infoChip(Icons.calendar_today_outlined, 'Purchased On', widget.item.invoiceDate),
        // const SizedBox(width: 10),
        // _infoChip(Icons.receipt_outlined, 'Price', widget.item.price),
        const SizedBox(width: 10),
        _infoChip(Icons.description_outlined, 'Invoice', widget.item.invoiceId),
      ]),
    );
  }

  Widget _infoChip(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: WerlogColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WerlogColors.border, width: 0.8),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03),
            blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: Row(children: [
        Icon(icon, color: WerlogColors.textTertiary, size: 14),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: WerlogTextStyles.caption.copyWith(fontSize: 9)),
          Text(value, style: WerlogTextStyles.txTitle.copyWith(fontSize: 12)),
        ]),
      ]),
    );
  }

  Widget _buildExpenseStatusCard(BuildContext context) {
    final statusColor = /*widget.item.status == 'active'
        ? */WerlogColors.teal
        /*: widget.item.status == 'expiring_soon'
            ? WerlogColors.amber
            : WerlogColors.coral*/;

    return Container(
      decoration: _cardDeco(),
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Expense Status', style: WerlogTextStyles.caption),
            const SizedBox(height: 6),
            Row(children: [
              Container(
                width: 26, height: 26,
                decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                child: Icon(
                  Icons.check,
                  color: Colors.white, size: 14,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Active',
                style: WerlogTextStyles.sectionTitle
                    .copyWith(color: statusColor, fontSize: 16),
              ),
            ]),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('Transaction Date', style: WerlogTextStyles.caption),
            Text(widget.item.invoiceDate,
                style: WerlogTextStyles.sectionTitle.copyWith(fontSize: 16)),
          ]),
        ]),
        const SizedBox(height: 12),
        /*ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _remainingProgress,
            backgroundColor: WerlogColors.surfaceAlt,
            valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(_remainingLabel,
              style: WerlogTextStyles.caption.copyWith(fontSize: 10)),
        ),*/
      ]),
    );
  }

  Widget _buildExpenseInfoCard(BuildContext context) {
    final rows = [
      // {'label': 'Expense Type', 'value': widget.item.vendorName},
      {'label': 'Provider',      'value': widget.item.vendorName},
      // {'label': 'Duration',      'value': widget.item.invoiceDate},
      {'label': 'Start Date',    'value': widget.item.invoiceDate},
      // {'label': 'End Date',      'value': widget.item.invoiceDate},
      {'label': 'Claim Support', 'value': widget.item.needsReview.toString()},
      {'label': 'Website',       'value': widget.item.websiteUrl, 'isLink': 'true'},
    ];

    return Container(
      decoration: _cardDeco(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Text('Expense Information', style: WerlogTextStyles.sectionTitle),
        ),
        const Divider(height: 0.5, color: WerlogColors.borderLight),
        ...rows.asMap().entries.map((e) {
          final isLast = e.key == rows.length - 1;
          final row = e.value;
          return Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              child: Row(children: [
                Text(row['label']!,
                    style: WerlogTextStyles.caption
                        .copyWith(color: WerlogColors.textTertiary)),
                const Spacer(),
                row['isLink'] == 'true'
                    ? Row(children: [
                        Text(row['value']!,
                            style: WerlogTextStyles.link.copyWith(fontSize: 12)),
                        const SizedBox(width: 4),
                        const Icon(Icons.open_in_new,
                            color: WerlogColors.teal, size: 12),
                      ])
                    : Text(row['value']!,
                        style: WerlogTextStyles.txTitle.copyWith(fontSize: 12)),
              ]),
            ),
            if (!isLast)
              const Divider(height: 0.5, color: WerlogColors.borderLight),
          ]);
        }).toList(),
      ]),
    );
  }

  // ── Invoice line items display card ───────────────────────────────
  Widget _buildInvoiceItemsCard(BuildContext context) {
    final inv   = widget.item;
    final items = inv.items;

    // Running total from items
    final total = items.fold(0.0, (sum, e) => sum + e.amount);

    return Container(
      decoration: _cardDeco(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Header ────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Row(children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: WerlogColors.tealSurface,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.receipt_long_rounded,
                  color: WerlogColors.teal, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Invoice Items',
                    style: WerlogTextStyles.sectionTitle),
                Text('${items.length} item${items.length == 1 ? '' : 's'} · ${inv.invoiceId}',
                    style: WerlogTextStyles.captionSmall),
              ],
            )),
            const SizedBox(width: 6),
            // Invoice status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: WerlogColors.tealSurface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: WerlogColors.teal.withOpacity(0.3),
                ),
              ),
              child: Text(
                "Scanned",
                style: WerlogTextStyles.captionSmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: WerlogColors.teal,
                ),
              ),
            ),
          ]),
        ),

        // ── Column headers ────────────────────────────────────────────
        Container(
          color: WerlogColors.background,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          child: Row(children: [
            Expanded(
              flex: 5,
              child: Text('Description',
                  style: WerlogTextStyles.captionSmall
                      .copyWith(fontWeight: FontWeight.w600)),
            ),
            SizedBox(
              width: 30,
              child: Text('Qty',
                  style: WerlogTextStyles.captionSmall
                      .copyWith(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center),
            ),
            SizedBox(
              width: 68,
              child: Text('Amount',
                  style: WerlogTextStyles.captionSmall
                      .copyWith(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.right),
            ),
          ]),
        ),

        const Divider(height: 0.5, color: WerlogColors.border),

        // ── Item rows ─────────────────────────────────────────────────
        ...items.asMap().entries.map((e) {
          final isLast = e.key == items.length - 1;
          final it = e.value;
          return Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bullet dot
                  Padding(
                    padding: const EdgeInsets.only(top: 4, right: 8),
                    child: Container(
                      width: 5, height: 5,
                      decoration: BoxDecoration(
                        color: WerlogColors.teal.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(it.description,
                            style: WerlogTextStyles.txTitle
                                .copyWith(fontSize: 12)),
                        const SizedBox(height: 2),
                        Text('Unit: ${it.unitPrice.toStringAsFixed(2)}',
                            style: WerlogTextStyles.captionSmall),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 30,
                    child: Text('×${it.quantity}',
                        style: WerlogTextStyles.captionSmall.copyWith(
                            color: WerlogColors.textSecondary),
                        textAlign: TextAlign.center),
                  ),
                  SizedBox(
                    width: 68,
                    child: Text(it.amount.toStringAsFixed(2),
                        style: WerlogTextStyles.txTitle
                            .copyWith(fontSize: 12),
                        textAlign: TextAlign.right),
                  ),
                ],
              ),
            ),
            if (!isLast)
              const Divider(height: 0.5,
                  color: WerlogColors.borderLight,
                  indent: 16, endIndent: 16),
          ]);
        }),

        // ── Total row ─────────────────────────────────────────────────
        Container(
          decoration: const BoxDecoration(
            color: WerlogColors.tealLightSurface,
            borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(16)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total',
                  style: WerlogTextStyles.sectionTitle
                      .copyWith(fontSize: 13, color: WerlogColors.teal)),
              Text(total.toStringAsFixed(2),
                  style: WerlogTextStyles.sectionTitle
                      .copyWith(fontSize: 14, color: WerlogColors.teal)),
            ],
          ),
        ),
      ]),
    );
  }

  // Invoice images horizontal list
  Widget _buildInvoiceImagesCard(BuildContext context) {
    return Container(
      decoration: _cardDeco(),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.photo_library_outlined,
              size: 15, color: WerlogColors.textTertiary),
          const SizedBox(width: 6),
          Text('Invoice Images', style: WerlogTextStyles.sectionTitle),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: WerlogColors.tealSurface,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('${widget.imageUrls.length}',
                style: WerlogTextStyles.captionSmall
                    .copyWith(color: WerlogColors.teal,
                        fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: widget.imageUrls.asMap().entries.map((e) {
              final index = e.key;
              final url   = ApiService.baseImgUrl + e.value;
              print("pop: "+url);
              return GestureDetector(
                onTap: () => _openImageViewer(context, index),
                child: Container(
                  width: 90, height: 90,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: WerlogColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: WerlogColors.border, width: 0.8),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(fit: StackFit.expand, children: [
                    Image.network(
                      url,
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, progress) => progress == null
                          ? child
                          : const Center(
                              child: SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: WerlogColors.teal),
                              ),
                            ),
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.broken_image_outlined,
                            color: WerlogColors.textTertiary, size: 26),
                      ),
                    ),
                    // Zoom hint overlay
                    Positioned(
                      bottom: 0, left: 0, right: 0,
                      child: Container(
                        height: 26,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.45),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        alignment: Alignment.bottomCenter,
                        padding: const EdgeInsets.only(bottom: 4),
                        child: const Icon(Icons.zoom_in_rounded,
                            color: Colors.white, size: 13),
                      ),
                    ),
                  ]),
                ),
              );
            }).toList(),
          ),
        ),
      ]),
    );
  }

  void _openImageViewer(BuildContext context, int initialIndex) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.92),
      builder: (_) => _ImageViewerDialog(
        urls: widget.imageUrls,
        initialIndex: initialIndex,
      ),
    );
  }

  Widget _buildActionBar(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: WerlogColors.surface,
        border: const Border(
          top: BorderSide(color: WerlogColors.border, width: 0.8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -3),
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _actionButton(
              Icons.edit_outlined,
              'Update Details',
              false,
                  () => _openUpdateSheet(context),
            ),
          ),
          /*const SizedBox(width: 10),
          _actionButton(Icons.verified_user_outlined, 'Manage Expense', false, () {}),
          const SizedBox(width: 10),
          _actionButton(Icons.share_outlined, 'Share', false, () {}),*/
        ],
      ),
    );
  }

  Widget _actionButton(
      IconData icon, String label, bool primary, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        decoration: BoxDecoration(
          color: primary ? WerlogColors.teal : WerlogColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: primary ? WerlogColors.teal : WerlogColors.border,
            width: 0.8,
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03),
              blurRadius: 4, offset: const Offset(0, 1))],
        ),
        child: Row(children: [
          Icon(icon, size: 16,
              color: primary ? Colors.white : WerlogColors.textSecondary),
          const SizedBox(width: 6),
          Text(label, style: WerlogTextStyles.txTitle.copyWith(
              fontSize: 12,
              color: primary ? Colors.white : WerlogColors.textPrimary)),
        ]),
      ),
    );
  }

  void _openUpdateSheet(BuildContext context) {
    // Seed line items from API invoiceData if available
    final seedItems = widget.item.items
        .map((e) => _LineItem(
              description: e.description,
              quantity:    e.quantity.toString(),
              unitPrice:   e.unitPrice.toStringAsFixed(2),
              amount:      e.amount.toStringAsFixed(2),
            ))
        .toList() ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UpdateExpenseSheet(
        item: widget.item,
        // invoiceData: widget.item,
        initialItems: seedItems,
        onUpdated: () {
          Navigator.pop(context); // close sheet
          Navigator.pop(context, true); // close detail screen
        },
      ),
    );
  }

  BoxDecoration _cardDeco() => BoxDecoration(
    color: WerlogColors.surface,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: WerlogColors.border, width: 0.8),
    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
        blurRadius: 8, offset: const Offset(0, 2))],
  );
}

// Full-screen image viewer
class _ImageViewerDialog extends StatefulWidget {
  final List<String> urls;
  final int initialIndex;

  const _ImageViewerDialog({
    required this.urls,
    required this.initialIndex,
  });

  @override
  State<_ImageViewerDialog> createState() => _ImageViewerDialogState();
}

class _ImageViewerDialogState extends State<_ImageViewerDialog> {
  late int _current;
  late PageController _controller;

  @override
  void initState() {
    super.initState();
    _current    = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Stack(children: [

          // Swipeable image pages
          PageView.builder(
            controller: _controller,
            itemCount: widget.urls.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, i) => Center(
              child: GestureDetector(
                // Prevent tap-to-close when tapping on the image itself
                onTap: () {},
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4.0,
                  child: Image.network(
                    ApiService.baseImgUrl+widget.urls[i],
                    fit: BoxFit.contain,
                    loadingBuilder: (_, child, progress) => progress == null
                        ? child
                        : const Center(
                            child: CircularProgressIndicator(
                                color: WerlogColors.teal)),
                    errorBuilder: (_, __, ___) => const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white54, size: 48),
                  ),
                ),
              ),
            ),
          ),

          // Top bar: counter + close
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 0, right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_current + 1} / ${widget.urls.length}',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 12,
                          fontFamily: 'DMSans', fontWeight: FontWeight.w500),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Dot indicators
          if (widget.urls.length > 1)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 20,
              left: 0, right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.urls.length, (i) {
                  final active = i == _current;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: active ? 18 : 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: active
                          ? WerlogColors.teal
                          : Colors.white.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
        ]),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
//  Line item model — mirrors API "items" array entries
// ════════════════════════════════════════════════════════════════════
class _LineItem {
  TextEditingController descCtrl;
  TextEditingController qtyCtrl;
  TextEditingController unitPriceCtrl;
  TextEditingController amountCtrl;

  _LineItem({
    String description = '',
    String quantity    = '1',
    String unitPrice   = '',
    String amount      = '',
  })  : descCtrl      = TextEditingController(text: description),
        qtyCtrl       = TextEditingController(text: quantity),
        unitPriceCtrl = TextEditingController(text: unitPrice),
        amountCtrl    = TextEditingController(text: amount);

  factory _LineItem.fromJson(Map<String, dynamic> json) {
    return _LineItem(
      description: json['description']?.toString() ?? '',
      quantity:    (json['quantity'] as num?)?.toString() ?? '1',
      unitPrice:   (json['unitPrice'] as num?)?.toStringAsFixed(2) ?? '',
      amount:      (json['amount']    as num?)?.toStringAsFixed(2) ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'description': descCtrl.text.trim(),
    'quantity':    int.tryParse(qtyCtrl.text.trim()) ?? 1,
    'unitPrice':   double.tryParse(unitPriceCtrl.text.trim()) ?? 0.0,
    'amount':      double.tryParse(amountCtrl.text.trim()) ?? 0.0,
  };

  void dispose() {
    descCtrl.dispose();
    qtyCtrl.dispose();
    unitPriceCtrl.dispose();
    amountCtrl.dispose();
  }
}

// ════════════════════════════════════════════════════════════════════
//  Update Expense bottom sheet
// ════════════════════════════════════════════════════════════════════
class _UpdateExpenseSheet extends StatefulWidget {
  final InvoiceItem  item;
  final List<_LineItem> initialItems;
  final VoidCallback  onUpdated;

  const _UpdateExpenseSheet({
    required this.item,
    required this.initialItems,
    required this.onUpdated,
  });

  @override
  State<_UpdateExpenseSheet> createState() => _UpdateExpenseSheetState();
}

class _UpdateExpenseSheetState extends State<_UpdateExpenseSheet> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  // Basic fields
  late final TextEditingController _nameCtrl;
  late final TextEditingController _serialCtrl;
  late final TextEditingController _invoiceDateCtrl;   // display: DD/MM/YYYY
  late final TextEditingController _expiryDateCtrl;    // display: DD/MM/YYYY
  late final TextEditingController _invoiceNoCtrl;

  // Dynamic line items
  late final List<_LineItem> _items;

  @override
  void initState() {
    super.initState();
    final i = widget.item;
    _nameCtrl        = TextEditingController(text: i.vendorName);
    _serialCtrl      = TextEditingController(text: i.invoiceId);
    _invoiceNoCtrl   = TextEditingController(text: i.invoiceId);

    // Prefer ISO dates from invoiceData (more precise); fall back to InvoiceItem strings
    final inv = widget.item;
    _invoiceDateCtrl = TextEditingController(
      text: inv != null && inv.invoiceDate.isNotEmpty
          ? _ExpenseDetailScreenState.isoToDisplay(inv.invoiceDate)
          : i.invoiceDate,
    );
    _expiryDateCtrl = TextEditingController(
      text: inv != null && inv.invoiceDate.isNotEmpty
          ? _ExpenseDetailScreenState.isoToDisplay(inv.invoiceDate)
          : i.invoiceDate,
    );

    // Deep-copy initial items so controllers are fresh
    _items = widget.initialItems.isNotEmpty
        ? widget.initialItems
            .map((e) => _LineItem(
                  description: e.descCtrl.text,
                  quantity:    e.qtyCtrl.text,
                  unitPrice:   e.unitPriceCtrl.text,
                  amount:      e.amountCtrl.text,
                ))
            .toList()
        : [_LineItem()]; // start with one blank row if no data
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _serialCtrl.dispose();
    _invoiceDateCtrl.dispose();
    _expiryDateCtrl.dispose();
    _invoiceNoCtrl.dispose();
    for (final item in _items) item.dispose();
    super.dispose();
  }

  // ── Date helpers ───────────────────────────────────────────────────

  /// Converts "DD/MM/YYYY" display value → "YYYY-MM-DDT00:00:00Z" ISO string.
  /// Falls back to an empty string if the input can't be parsed.
  String _toIso(String displayDate) {
    try {
      final parts = displayDate.trim().split('/');
      if (parts.length != 3) return '';
      final day   = parts[0].padLeft(2, '0');
      final month = parts[1].padLeft(2, '0');
      final year  = parts[2];
      return '${year}-${month}-${day}T00:00:00Z';
    } catch (_) {
      return '';
    }
  }

  // ── API submit ─────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);

    try {
      final body = {
        'id':          /*widget.invoiceData?.id ??*/ widget.item.invoiceId,
        'name':        _nameCtrl.text.trim(),
        'serialno':    _serialCtrl.text.trim(),
        'invoiceno':   _invoiceNoCtrl.text.trim(),
        'invoiceDate': _toIso(_invoiceDateCtrl.text),
        'expiryDate':  _toIso(_expiryDateCtrl.text),
        'items':       _items.map((e) => e.toJson()).toList(),
      };

      final response = await ApiService.post(
        context,
        Endpoints.UPDATE_INVOICE_DETAILS,
        body: body,
        showLoader: false,
      );

      if (response != null && response['result'] == '1') {
        widget.onUpdated();
      } else {
        setState(() => _loading = false);
        if (mounted) {
          GeneralFunctions.showError(
            context,
            response?['message']?.toString() ?? 'Update failed. Please try again.',
          );
        }
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        GeneralFunctions.showError(
            context, 'Something went wrong. Please try again.');
      }
    }
  }

  // ── Build ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final mq         = MediaQuery.of(context);
    final bottom     = mq.viewInsets.bottom;
    final statusBar  = mq.padding.top;
    // Leave at least the status-bar height + 16 dp gap visible above the sheet
    final maxHeight  = mq.size.height - statusBar - 16;

    return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Container(
          decoration: const BoxDecoration(
            color: WerlogColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(20, 0, 20, bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [

            // Drag handle
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: WerlogColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header row
            Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: WerlogColors.tealSurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.edit_outlined,
                    color: WerlogColors.teal, size: 17),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Update Details',
                      style: WerlogTextStyles.sectionTitle.copyWith(fontSize: 15)),
                  Text('Edit expense information below',
                      style: WerlogTextStyles.captionSmall),
                ],
              )),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: WerlogColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.close_rounded,
                      color: WerlogColors.textSecondary, size: 16),
                ),
              ),
            ]),

        const SizedBox(height: 16),
        const Divider(color: WerlogColors.borderLight),
        const SizedBox(height: 4),

        // Scrollable form
        Flexible(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Basic fields ─────────────────────────────────────
                  _field(_nameCtrl,        'Provider Name',  Icons.inventory_2_outlined, required: true),
                  // _field(_serialCtrl,      'Serial No.',    Icons.numbers_outlined),
                  _field(_invoiceNoCtrl,   'Invoice No.',   Icons.receipt_outlined),
                  _field(_invoiceDateCtrl, 'Invoice Date',  Icons.calendar_today_outlined,
                      hint: 'DD/MM/YYYY'),
                  /*_field(_expiryDateCtrl,  'Expiry Date',   Icons.event_outlined,
                      hint: 'DD/MM/YYYY'),*/

                  const SizedBox(height: 6),

                  // ── Items section header ──────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        const Icon(Icons.list_alt_rounded,
                            size: 15, color: WerlogColors.textTertiary),
                        const SizedBox(width: 6),
                        Text('Line Items',
                            style: WerlogTextStyles.sectionTitle
                                .copyWith(fontSize: 13)),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: WerlogColors.tealSurface,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('${_items.length}',
                              style: WerlogTextStyles.captionSmall.copyWith(
                                  color: WerlogColors.teal,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ]),
                      GestureDetector(
                        onTap: () => setState(() => _items.add(_LineItem())),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: WerlogColors.tealSurface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: WerlogColors.teal.withOpacity(0.3)),
                          ),
                          child: Row(children: [
                            const Icon(Icons.add_rounded,
                                size: 13, color: WerlogColors.teal),
                            const SizedBox(width: 4),
                            Text('Add Item',
                                style: WerlogTextStyles.captionSmall.copyWith(
                                    color: WerlogColors.teal,
                                    fontWeight: FontWeight.w600)),
                          ]),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // ── Item cards ────────────────────────────────────────
                  ..._items.asMap().entries.map((e) {
                    final idx  = e.key;
                    final item = e.value;
                    return _buildItemCard(idx, item);
                  }),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Update button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: WerlogColors.teal,
              disabledBackgroundColor: WerlogColors.teal.withOpacity(0.6),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: _loading
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white),
                  )
                : const Text('Update',
                    style: TextStyle(
                      fontFamily: 'DMSans', fontSize: 14,
                      fontWeight: FontWeight.w600, color: Colors.white,
                    )),
          ),
        ),
          ]),
        ),   // end Container
    );   // end ConstrainedBox
  }

  // ── Item card widget ───────────────────────────────────────────────
  Widget _buildItemCard(int idx, _LineItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: WerlogColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WerlogColors.border, width: 0.8),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Card header: index badge + remove button
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: WerlogColors.darkTeal.withOpacity(0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('Item ${idx + 1}',
                style: WerlogTextStyles.captionSmall.copyWith(
                    color: WerlogColors.darkTeal,
                    fontWeight: FontWeight.w600)),
          ),
          if (_items.length > 1)
            GestureDetector(
              onTap: () => setState(() {
                item.dispose();
                _items.removeAt(idx);
              }),
              child: Container(
                width: 26, height: 26,
                decoration: BoxDecoration(
                  color: WerlogColors.coralSurface,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Icon(Icons.close_rounded,
                    size: 13, color: WerlogColors.coral),
              ),
            ),
        ]),

        const SizedBox(height: 8),

        // Description — full width
        _field(item.descCtrl, 'Description', Icons.short_text_rounded,
            required: true),

        // Qty | Unit Price | Amount — 3 columns
        Row(children: [
          Expanded(
            flex: 2,
            child: _field(item.qtyCtrl, 'Qty', Icons.tag_rounded,
                keyboardType: TextInputType.number, required: true),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: _field(item.unitPriceCtrl, 'Unit Price',
                Icons.attach_money_rounded,
                keyboardType: TextInputType.number),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: _field(item.amountCtrl, 'Amount',
                Icons.calculate_outlined,
                keyboardType: TextInputType.number),
          ),
        ]),
      ]),
    );
  }

  // ── Text field helper ──────────────────────────────────────────────
  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    String? hint,
    bool required = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        style: WerlogTextStyles.txTitle.copyWith(fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, size: 16, color: WerlogColors.textTertiary),
          labelStyle: WerlogTextStyles.caption
              .copyWith(color: WerlogColors.textSecondary),
          hintStyle: WerlogTextStyles.captionSmall,
          filled: true,
          fillColor: WerlogColors.surface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: WerlogColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: WerlogColors.border, width: 0.8),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: WerlogColors.teal, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: WerlogColors.coral, width: 1),
          ),
        ),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty)
                ? '$label is required'
                : null
            : null,
      ),
    );
  }
}
