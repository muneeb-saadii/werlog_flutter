import 'package:flutter/material.dart';

import '../../core/models/app_models_extended.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';

// ──────────────────────────────────────────────────────────────
//  InvoiceDetailScreen  (screens 10 & 11)
//  Pass InvoiceDetailData — type field controls expense vs warranty.
// ──────────────────────────────────────────────────────────────
class InvoiceDetailScreen extends StatelessWidget {
  final InvoiceDetailData? data;
  final VoidCallback? onBack;
  final VoidCallback? onEdit;
  final VoidCallback? onShare;
  final VoidCallback? onMore;
  final VoidCallback? onPrimaryAction;
  final VoidCallback? onSecondaryAction;
  final void Function(int tab)? onTabChanged;
  final int currentTab;

  const InvoiceDetailScreen({
    super.key,
    this.data,
    this.onBack,
    this.onEdit,
    this.onShare,
    this.onMore,
    this.onPrimaryAction,
    this.onSecondaryAction,
    this.onTabChanged,
    this.currentTab = 1,
  });

  @override
  Widget build(BuildContext context) {
    final d      = data ?? InvoiceDetailData();
    final isWar  = d.type == InvoiceType.warranty;

    return Scaffold(
      backgroundColor: WerlogColors.background,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _DetailHeader(data: d, onBack: onBack,
                      onEdit: onEdit, onShare: onShare, onMore: onMore),

                  _ConfidenceChip(c: d.confidence),
                  if (isWar && d.warrantyBadge != null)
                    _WarrantyBadgeCard(badge: d.warrantyBadge!),
                  _LineItemsSection(
                    items: d.lineItems,
                    isWarranty: isWar,
                  ),
                  _SummaryCard(
                    rows: d.summaryRows,
                    totalPaid: d.totalPaid,
                  ),
                  _MetaGrid(
                    categoryTag:      d.categoryTag,
                    isWarranty:       isWar,
                    paymentOrWarType: isWar
                        ? (d.warrantyTypeLabel ?? '')
                        : d.paymentInfo,
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          _FooterActions(
            primary:   d.primaryButtonLabel,
            secondary: d.secondaryButtonLabel,
            onPrimary:   onPrimaryAction,
            onSecondary: onSecondaryAction,
          ),
          _BottomNav(
              selected: currentTab, onTap: onTabChanged),
        ],
      ),
    );
  }
}

// ── Header dark section ────────────────────────────────────────
class _DetailHeader extends StatelessWidget {
  final InvoiceDetailData data;
  final VoidCallback? onBack;
  final VoidCallback? onEdit;
  final VoidCallback? onShare;
  final VoidCallback? onMore;

  const _DetailHeader({
    required this.data,
    this.onBack, this.onEdit, this.onShare, this.onMore,
  });

  bool get _isWarranty => data.type == InvoiceType.warranty;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          decoration: BoxDecoration(
            gradient: _isWarranty
                ? WerlogGradients.warrantyHeader()
                : WerlogGradients.expenseHeader(),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status bar
              const FakeStatusBar(textColor: Colors.white),
              // Nav row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: onBack,
                    child: const Text('‹',
                        style: TextStyle(
                            fontSize: 22, color: Colors.white)),
                  ),
                  Row(
                    children: [
                      for (final item in [
                        ('✎', onEdit),
                        ('⎘', onShare),
                        ('⋯', onMore),
                      ])
                        GestureDetector(
                          onTap: item.$2,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 14),
                            child: Text(item.$1,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 16)),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // Type chip
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _isWarranty
                      ? WerlogColors.amber.withOpacity(0.20)
                      : WerlogColors.coral.withOpacity(0.20),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: _isWarranty
                        ? WerlogColors.amber.withOpacity(0.3)
                        : WerlogColors.coral.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  data.categoryLabel,
                  style: WerlogTextStyles.badgeText.copyWith(
                    color: _isWarranty
                        ? const Color(0xFFEF9F27)
                        : const Color(0xFFF0997B),
                    fontSize: 9,
                    letterSpacing: 0.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(data.vendor,
                  style: WerlogTextStyles.heroTitle
                      .copyWith(fontSize: 22)),
              const SizedBox(height: 3),
              Text(data.dateLabel,
                  style: WerlogTextStyles.heroSubtitle
                      .copyWith(fontSize: 11)),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(data.amount,
                      style: WerlogTextStyles.balanceAmount
                          .copyWith(fontSize: 32)),
                  const SizedBox(width: 4),
                  Text(data.currency,
                      style: WerlogTextStyles.balanceSub
                          .copyWith(fontSize: 13)),
                ],
              ),
            ],
          ),
        ),
        // Decorative circle
        Positioned(
          top: -50, right: -50,
          child: IgnorePointer(
            child: Container(
              width: 150, height: 150,
              decoration: BoxDecoration(
                color: (_isWarranty
                    ? WerlogColors.amber
                    : WerlogColors.coral).withOpacity(0.22),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── OCR confidence chip ────────────────────────────────────────
class _ConfidenceChip extends StatelessWidget {
  final OcrConfidenceData c;
  const _ConfidenceChip({required this.c});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -12), // 👈 same effect as negative margin
      child: Container(
        margin: const EdgeInsets.fromLTRB(18, 0, 18, 0),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          gradient: WerlogGradients.cardMint(),
          border: Border.all(
              color: WerlogColors.teal.withOpacity(0.30)),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: WerlogColors.teal,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: const Text('✓',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Extracted with ${c.confidencePct}% confidence',
                    style: WerlogTextStyles.body.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF085041)),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '${c.engineLabel} · ${c.lineItemCount} line items · ${c.statusNote}',
                    style: WerlogTextStyles.caption
                        .copyWith(color: const Color(0xFF0F6E56)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Warranty active badge ──────────────────────────────────────
class _WarrantyBadgeCard extends StatelessWidget {
  final WarrantyBadgeData badge;
  const _WarrantyBadgeCard({required this.badge});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [WerlogColors.amberSurface, WerlogColors.surface],
        ),
        border: Border.all(color: const Color(0xFFFAC775)),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          // Days circle
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: WerlogColors.surface,
              border: Border.all(
                  color: WerlogColors.amber, width: 2.5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${badge.daysRemaining}',
                  style: WerlogTextStyles.balanceAmount.copyWith(
                    color: WerlogColors.amberDeep, fontSize: 18),
                ),
                Text('DAYS',
                    style: WerlogTextStyles.labelUppercase.copyWith(
                        fontSize: 8, color: WerlogColors.amberDark)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(badge.status,
                    style: WerlogTextStyles.body.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF412402),
                    )),
                const SizedBox(height: 2),
                Text(badge.expiryText,
                    style: WerlogTextStyles.caption.copyWith(
                        color: WerlogColors.amberDark, height: 1.4)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: WerlogColors.surface,
                    border: Border.all(
                        color: WerlogColors.amber.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    'SN: ${badge.serialNumber}',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      color: WerlogColors.amberDeep,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Line items section ─────────────────────────────────────────
class _LineItemsSection extends StatelessWidget {
  final List<InvoiceLineItem> items;
  final bool isWarranty;
  const _LineItemsSection(
      {required this.items, required this.isWarranty});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isWarranty
                    ? 'PRODUCT DETAILS'
                    : 'LINE ITEMS (${items.length})',
                style: WerlogTextStyles.labelUppercase
                    .copyWith(color: WerlogColors.textSecondary),
              ),
              if (!isWarranty)
                Text('Add +',
                    style: WerlogTextStyles.link
                        .copyWith(fontSize: 10)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: WerlogColors.surface,
              border: Border.all(color: WerlogColors.border),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Column(
              children: List.generate(items.length, (i) {
                final item = items[i];
                return Column(
                  children: [
                    _LineItemRow(item: item, index: i + 1),
                    if (i < items.length - 1)
                      const Divider(
                          height: 0, thickness: 0.5,
                          color: WerlogColors.borderLight),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _LineItemRow extends StatelessWidget {
  final InvoiceLineItem item;
  final int index;
  const _LineItemRow({required this.item, required this.index});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20, height: 20,
            decoration: BoxDecoration(
              color: WerlogColors.surfaceAlt,
              borderRadius: BorderRadius.circular(5),
            ),
            alignment: Alignment.center,
            child: Text('$index',
                style: WerlogTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w500, fontSize: 9)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: WerlogTextStyles.txTitle
                        .copyWith(fontSize: 12)),
                const SizedBox(height: 2),
                Text(item.meta,
                    style: WerlogTextStyles.txDate
                        .copyWith(fontSize: 10)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.amount,
                style: WerlogTextStyles.txAmount.copyWith(
                  fontSize: 12,
                  color: item.isHighlighted
                      ? WerlogColors.teal
                      : WerlogColors.textPrimary,
                ),
              ),
              const SizedBox(height: 1),
              Text(item.unit,
                  style: WerlogTextStyles.txDate
                      .copyWith(fontSize: 9)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Summary card ───────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final List<InvoiceSummaryRow> rows;
  final String totalPaid;
  const _SummaryCard(
      {required this.rows, required this.totalPaid});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 10, 18, 0),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: WerlogColors.surface,
        border: Border.all(color: WerlogColors.border),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        children: [
          ...rows.map((r) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(r.label,
                    style: WerlogTextStyles.bodySmall
                        .copyWith(fontSize: 11)),
                Text(r.value,
                    style: WerlogTextStyles.bodySmall.copyWith(
                      fontSize: 11,
                      color: r.isDiscount
                          ? WerlogColors.teal
                          : WerlogColors.textPrimary,
                    )),
              ],
            ),
          )),
          const Divider(
              height: 16, color: Color(0xFFD3D1C7),
              thickness: 1, indent: 0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total paid',
                  style: WerlogTextStyles.body.copyWith(
                      fontWeight: FontWeight.w500, fontSize: 13)),
              Text(totalPaid,
                  style: WerlogTextStyles.body.copyWith(
                      fontWeight: FontWeight.w500, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Meta grid ─────────────────────────────────────────────────
class _MetaGrid extends StatelessWidget {
  final String categoryTag;
  final bool isWarranty;
  final String paymentOrWarType;

  const _MetaGrid({
    required this.categoryTag,
    required this.isWarranty,
    required this.paymentOrWarType,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
      child: Row(
        children: [
          Expanded(
            child: _MetaCell(
              label: 'CATEGORY',
              child: Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.symmetric(
                    horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: isWarranty
                      ? WerlogColors.tealSurface
                      : WerlogColors.coralSurface,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(categoryTag,
                    style: WerlogTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w500,
                      color: isWarranty
                          ? const Color(0xFF085041)
                          : const Color(0xFF712B13),
                    )),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _MetaCell(
              label: isWarranty ? 'WARRANTY TYPE' : 'PAYMENT',
              child: Text(paymentOrWarType,
                  style: WerlogTextStyles.body.copyWith(
                      fontSize: isWarranty ? 10 : 11,
                      fontWeight: FontWeight.w500)),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaCell extends StatelessWidget {
  final String label;
  final Widget child;
  const _MetaCell({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(11, 9, 11, 9),
      decoration: BoxDecoration(
        color: WerlogColors.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: WerlogTextStyles.labelUppercase
                  .copyWith(fontSize: 9, color: WerlogColors.textSecondary)),
          const SizedBox(height: 2),
          child,
        ],
      ),
    );
  }
}

// ── Footer action buttons ──────────────────────────────────────
class _FooterActions extends StatelessWidget {
  final String primary;
  final String secondary;
  final VoidCallback? onPrimary;
  final VoidCallback? onSecondary;

  const _FooterActions({
    required this.primary,
    required this.secondary,
    this.onPrimary,
    this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onSecondary,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 11),
                side: const BorderSide(color: WerlogColors.border),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                foregroundColor: WerlogColors.textPrimary,
              ),
              child: Text(secondary,
                  style: WerlogTextStyles.button
                      .copyWith(
                          color: WerlogColors.textPrimary, fontSize: 11)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              onPressed: onPrimary,
              style: ElevatedButton.styleFrom(
                backgroundColor: WerlogColors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: Text(primary,
                  style: WerlogTextStyles.button.copyWith(fontSize: 11)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bottom nav (reused from dashboard) ────────────────────────
class _BottomNav extends StatelessWidget {
  final int selected;
  final void Function(int)? onTap;

  const _BottomNav({required this.selected, this.onTap});

  static const _tabs = [
    ('⌂', 'Home'), ('≡', 'Invoices'), ('', ''),
    ('◔', 'Reports'), ('◯', 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: WerlogColors.surface,
        border:
            Border(top: BorderSide(color: WerlogColors.border, width: 1)),
      ),
      child: Row(
        children: List.generate(_tabs.length, (i) {
          final t      = _tabs[i];
          final active = i == selected;

          if (i == 2) {
            return Expanded(
              child: GestureDetector(
                onTap: () => onTap?.call(i),
                child: Container(
                  alignment: Alignment.center,
                  child: Transform.translate(
                    offset: const Offset(0, -14),
                    child: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: WerlogColors.teal,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: WerlogColors.teal.withOpacity(0.32),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          )
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Text('+',
                          style: TextStyle(
                              fontSize: 22,
                              color: Colors.white,
                              fontWeight: FontWeight.w300,
                              height: 1)),
                    ),
                  ),
                ),
              ),
            );
          }

          return Expanded(
            child: GestureDetector(
              onTap: () => onTap?.call(i),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 7)
                    .copyWith(bottom: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(t.$1,
                        style: TextStyle(
                            fontSize: 14,
                            color: active
                                ? WerlogColors.teal
                                : WerlogColors.tabInactive)),
                    const SizedBox(height: 2),
                    Text(t.$2,
                        style: WerlogTextStyles.tabLabel.copyWith(
                          color: active
                              ? WerlogColors.teal
                              : WerlogColors.tabInactive,
                        )),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
