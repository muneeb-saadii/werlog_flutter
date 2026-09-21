import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'category_overview_screen.dart';

class WarrantyDetailScreen extends StatelessWidget {
  final WarrantyItem item;

  const WarrantyDetailScreen({super.key, required this.item});

  // ── Data variables — replace with API ──
  // All data is stored in WarrantyItem, passed from parent.
  // Documents list — replace with API response
  static const List<Map<String, String>> _documents = [
    {'name': 'Invoice.pdf', 'size': '245 KB'},
    {'name': 'Warranty Card.pdf', 'size': '120 KB'},
  ];

  // Remaining time in months (0.0–1.0 for progress bar)
  // Remaining time progress (0.0 → 1.0)
  double get _remainingProgress {
    try {
      final startParts = item.purchaseDate.split('/');
      final endParts   = item.expiresOn.split('/');
      final startDate = DateTime(
        int.parse(startParts[2]),
        int.parse(startParts[1]),
        int.parse(startParts[0]),
      );
      final endDate = DateTime(
        int.parse(endParts[2]),
        int.parse(endParts[1]),
        int.parse(endParts[0]),
      );

      final now = DateTime.now();
      final totalDays =
          endDate.difference(startDate).inDays;
      final remainingDays =
          endDate.difference(now).inDays;
      if (totalDays <= 0) return 0;
      final progress = remainingDays / totalDays;
      return progress.clamp(0.0, 1.0);
    } catch (e) {
      return 0;
    }
  }

// Remaining label
  String get _remainingLabel {
    try {
      final endParts = item.expiresOn.split('/');
      final endDate = DateTime(
        int.parse(endParts[2]),
        int.parse(endParts[1]),
        int.parse(endParts[0]),
      );

      final now = DateTime.now();
      if (endDate.isBefore(now)) {
        return 'Expired';
      }

      int years = endDate.year - now.year;
      int months = endDate.month - now.month;

      if (endDate.day < now.day) {
        months--;
      }

      if (months < 0) {
        years--;
        months += 12;
      }

      if (years <= 0 && months <= 0) {
        final days = endDate.difference(now).inDays;
        return '$days Days Remaining';
      }
      if (years > 0 && months > 0) {
        return '$years Year, $months Month Remaining';
      }
      if (years > 0) {
        return '$years Year Remaining';
      }
      return '$months Month Remaining';
    } catch (e) {
      return 'N/A';
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WerlogColors.background,
      body: SafeArea(
        child: Column(
          children: [
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
                    const SizedBox(height: 14),
                    _buildPurchaseRow(context),
                    const SizedBox(height: 14),
                    _buildWarrantyStatusCard(context),
                    const SizedBox(height: 14),
                    _buildWarrantyInfoCard(context),
                    /*const SizedBox(height: 14),
                    _buildDocumentsSection(context),
                    const SizedBox(height: 14),
                    _buildNotesCard(context),*/
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            _buildActionBar(context),
          ],
        ),
      ),
    );
  }

  // ── App bar ───────────────────────────────
  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                size: 18, color: WerlogColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Warranty Details",
              style: WerlogTextStyles.pageTitle.copyWith(fontSize: 18),
            ),
          ),
          /*const Spacer(),
          IconButton(
            icon: const Icon(Icons.edit_outlined,
                size: 20, color: WerlogColors.textPrimary),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert,
                size: 20, color: WerlogColors.textPrimary),
            onPressed: () {},
          ),*/
        ],
      ),
    );
  }

  // ── Product header ────────────────────────
  Widget _buildProductHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: WerlogColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WerlogColors.border, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            height: 80,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(item.name,
                          style: WerlogTextStyles.pageTitle
                              .copyWith(fontSize: 19)),
                    ),
                    _statusBadge(item.status),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Serial Number',
                    style: WerlogTextStyles.caption),
                Text(item.serial,
                    style: WerlogTextStyles.txTitle.copyWith(fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    final configs = {
      'active': {'label': 'Active', 'bg': WerlogColors.tealSurface, 'text': WerlogColors.teal},
      'expiring_soon': {'label': 'Expiring Soon', 'bg': WerlogColors.amberSurface, 'text': WerlogColors.amber},
      'expired': {'label': 'Expired', 'bg': WerlogColors.coralSurface, 'text': WerlogColors.coral},
      'claimed': {'label': 'Claimed', 'bg': WerlogColors.surfaceAlt, 'text': WerlogColors.textSecondary},
    };
    final c = configs[status] ?? configs['active']!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c['bg'] as Color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: (c['text'] as Color).withOpacity(0.3), width: 0.8),
      ),
      child: Text(
        c['label'] as String,
        style: WerlogTextStyles.badgeText
            .copyWith(color: c['text'] as Color, fontSize: 10),
      ),
    );
  }

  // ── Purchase info row ─────────────────────
  Widget _buildPurchaseRow(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _infoChip(Icons.calendar_today_outlined, 'Purchased On', item.purchaseDate),
          const SizedBox(width: 10),
          _infoChip(Icons.receipt_outlined, 'Price', item.price),
          const SizedBox(width: 10),
          _infoChip(Icons.description_outlined, 'Invoice', item.invoiceNo),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: WerlogColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WerlogColors.border, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: WerlogColors.textTertiary, size: 14),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: WerlogTextStyles.caption.copyWith(fontSize: 9)),
              Text(value,
                  style: WerlogTextStyles.txTitle.copyWith(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Warranty status card ──────────────────
  Widget _buildWarrantyStatusCard(BuildContext context) {
    final statusColor = item.status == 'active'
        ? WerlogColors.teal
        : item.status == 'expiring_soon'
            ? WerlogColors.amber
            : WerlogColors.coral;

    return Container(
      decoration: BoxDecoration(
        color: WerlogColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WerlogColors.border, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Warranty Status',
                        style: WerlogTextStyles.caption),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            item.status == 'active'
                                ? Icons.check
                                : item.status == 'expiring_soon'
                                    ? Icons.timer
                                    : Icons.close,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          item.status == 'active'
                              ? 'Active'
                              : item.status == 'expiring_soon'
                                  ? 'Expiring Soon'
                                  : 'Expired',
                          style: WerlogTextStyles.sectionTitle.copyWith(
                            color: statusColor,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Expires On',
                      style: WerlogTextStyles.caption),
                  Text(item.expiresOn,
                      style:
                          WerlogTextStyles.sectionTitle.copyWith(fontSize: 16)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
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
          ),
        ],
      ),
    );
  }

  // ── Warranty info table ───────────────────
  Widget _buildWarrantyInfoCard(BuildContext context) {
    final rows = [
      {'label': 'Warranty Type', 'value': item.warrantyType},
      {'label': 'Provider', 'value': item.provider},
      {'label': 'Duration', 'value': item.duration},
      {'label': 'Start Date', 'value': item.purchaseDate},
      {'label': 'End Date', 'value': item.expiresOn},
      {'label': 'Claim Support', 'value': item.claimSupport},
      {'label': 'Website', 'value': item.website, 'isLink': 'true'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: WerlogColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WerlogColors.border, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Text('Warranty Information',
                style: WerlogTextStyles.sectionTitle),
          ),
          const Divider(height: 0.5, color: WerlogColors.borderLight),
          ...rows.asMap().entries.map((e) {
            final isLast = e.key == rows.length - 1;
            final row = e.value;
            return Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  child: Row(
                    children: [
                      Text(row['label']!,
                          style: WerlogTextStyles.caption
                              .copyWith(color: WerlogColors.textTertiary)),
                      const Spacer(),
                      row['isLink'] == 'true'
                          ? Row(
                              children: [
                                Text(row['value']!,
                                    style: WerlogTextStyles.link
                                        .copyWith(fontSize: 12)),
                                const SizedBox(width: 4),
                                const Icon(Icons.open_in_new,
                                    color: WerlogColors.teal, size: 12),
                              ],
                            )
                          : Text(row['value']!,
                              style: WerlogTextStyles.txTitle
                                  .copyWith(fontSize: 12)),
                    ],
                  ),
                ),
                if (!isLast)
                  const Divider(height: 0.5, color: WerlogColors.borderLight),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  // ── Documents section ─────────────────────
  Widget _buildDocumentsSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: WerlogColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WerlogColors.border, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Documents', style: WerlogTextStyles.sectionTitle),
              GestureDetector(
                onTap: () {},
                child: Text('View All',
                    style: WerlogTextStyles.link.copyWith(fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                ..._documents.map((doc) => Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: _docTile(doc),
                    )),
                _addDocTile(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _docTile(Map<String, String> doc) {
    return Container(
      width: 100,
      height: 96,
      decoration: BoxDecoration(
        color: WerlogColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WerlogColors.border, width: 0.8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.picture_as_pdf_outlined,
              color: WerlogColors.coral, size: 28),
          const SizedBox(height: 6),
          Text(doc['name']!,
              style: WerlogTextStyles.caption.copyWith(fontSize: 9),
              textAlign: TextAlign.center),
          Text(doc['size']!,
              style: WerlogTextStyles.caption
                  .copyWith(fontSize: 8, color: WerlogColors.textTertiary)),
        ],
      ),
    );
  }

  Widget _addDocTile() {
    return Container(
      width: 100,
      height: 96,
      decoration: BoxDecoration(
        color: WerlogColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WerlogColors.border, width: 0.8,
            style: BorderStyle.solid),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.add, color: WerlogColors.textTertiary, size: 26),
          const SizedBox(height: 4),
          Text('Add More',
              style: WerlogTextStyles.caption.copyWith(fontSize: 10)),
        ],
      ),
    );
  }

  // ── Notes ─────────────────────────────────
  Widget _buildNotesCard(BuildContext context) {
    // Notes data variable — replace with API
    const String notes = 'Extended warranty purchased from Apple Store.';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: WerlogColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WerlogColors.border, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Notes', style: WerlogTextStyles.sectionTitle),
          const SizedBox(height: 8),
          Text(notes, style: WerlogTextStyles.body.copyWith(fontSize: 12,
              color: WerlogColors.textSecondary)),
        ],
      ),
    );
  }

  // ── Bottom action bar ─────────────────────
  Widget _buildActionBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
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
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _actionButton(
                Icons.notifications_outlined, 'Update Details', false, () {}),
            const SizedBox(width: 10),
            _actionButton(Icons.verified_user_outlined, 'Claim Warranty',
                false, () {}),
            const SizedBox(width: 10),
            _actionButton(Icons.share_outlined, 'Share', false, () {}),
          ],
        ),
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 16,
                color:
                    primary ? Colors.white : WerlogColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: WerlogTextStyles.txTitle.copyWith(
                fontSize: 12,
                color: primary ? Colors.white : WerlogColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
