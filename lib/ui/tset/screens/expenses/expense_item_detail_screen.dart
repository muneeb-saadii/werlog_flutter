import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'expense_models.dart';

// ══════════════════════════════════════════════════════════════════════════════
//  EXPENSE ITEM DETAIL SCREEN — Screen 3
//  Full breakdown of a single expense entry.
//  Navigation: ExpenseCategoryScreen → ExpenseItemDetailScreen
// ══════════════════════════════════════════════════════════════════════════════
class ExpenseItemDetailScreen extends StatelessWidget {
  final ExpenseItem item;
  final ExpenseCategory category;

  const ExpenseItemDetailScreen({
    super.key,
    required this.item,
    required this.category,
  });

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
                  _buildHeroCard(context),
                  const SizedBox(height: 14),
                  _buildAmountBreakdownCard(context),
                  const SizedBox(height: 14),
                  _buildDetailsTable(context),
                  const SizedBox(height: 14),
                  _buildDeductibilityCard(context),
                  const SizedBox(height: 14),
                  _buildAttachmentsSection(context),
                  const SizedBox(height: 14),
                  if (item.notes != null && item.notes!.isNotEmpty)
                    _buildNotesCard(context),
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

  // ── App bar ─────────────────────────────────────────────────────────────────
  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: WerlogColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: 20, color: WerlogColors.textPrimary),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.more_vert, size: 20, color: WerlogColors.textPrimary),
          onPressed: () {},
        ),
      ]),
    );
  }

  // ── Hero card — title, vendor, status ───────────────────────────────────────
  Widget _buildHeroCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: WerlogColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WerlogColors.border, width: 0.8),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
            color: item.iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: item.iconColor.withOpacity(0.2), width: 0.8),
          ),
          child: Icon(item.icon, color: item.iconColor, size: 30),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Text(item.title,
                    style: WerlogTextStyles.pageTitle.copyWith(fontSize: 17)),
              ),
              const SizedBox(width: 8),
              _StatusBadgeLarge(item.status),
            ]),
            const SizedBox(height: 4),
            Text(item.vendor, style: WerlogTextStyles.bodySmall),
            const SizedBox(height: 6),
            Row(children: [
              _CategoryPill(category: category),
              const SizedBox(width: 6),
              _TypePill(item.type),
            ]),
          ]),
        ),
      ]),
    );
  }

  // ── Amount breakdown ─────────────────────────────────────────────────────────
  Widget _buildAmountBreakdownCard(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(children: [
        _AmountChip(
          icon: Icons.payments_outlined,
          iconColor: WerlogColors.darkTeal,
          label: 'Total Amount',
          value: item.formattedAmount,
          bgColor: WerlogColors.surfaceAlt,
        ),
        const SizedBox(width: 10),
        _AmountChip(
          icon: Icons.receipt_outlined,
          iconColor: WerlogColors.teal,
          label: 'GST / HST',
          value: item.formattedGst,
          bgColor: WerlogColors.tealSurface,
        ),
        const SizedBox(width: 10),
        _AmountChip(
          icon: Icons.savings_outlined,
          iconColor: WerlogColors.teal,
          label: 'Deductible',
          value: '\$${item.deductibleAmount.toStringAsFixed(2)}',
          sub: '${item.deductiblePercent.toInt()}% of total',
          bgColor: WerlogColors.tealSurface,
        ),
        const SizedBox(width: 10),
        _AmountChip(
          icon: Icons.calculate_outlined,
          iconColor: WerlogColors.textSecondary,
          label: 'Net Cost',
          value: '\$${(item.amount - item.deductibleAmount).toStringAsFixed(2)}',
          sub: 'After deduction',
          bgColor: WerlogColors.surfaceAlt,
        ),
      ]),
    );
  }

  // ── Details table ────────────────────────────────────────────────────────────
  Widget _buildDetailsTable(BuildContext context) {
    final rows = <Map<String, String>>[
      {'label': 'Date',            'value': item.date},
      {'label': 'Month',           'value': item.month},
      {'label': 'Category',        'value': category.name},
      {'label': 'Expense Type',    'value': item.type.label},
      {'label': 'Status',          'value': item.status.label},
      if (item.invoiceRef != null && item.invoiceRef!.isNotEmpty)
        {'label': 'Invoice / Ref', 'value': item.invoiceRef!},
      {'label': 'Deductible %',    'value': '${item.deductiblePercent.toInt()}%'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: WerlogColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WerlogColors.border, width: 0.8),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Expense Details', style: WerlogTextStyles.sectionTitle),
          ),
        ),
        const Divider(height: 0.5, color: WerlogColors.borderLight),
        ...rows.asMap().entries.map((e) {
          final isLast = e.key == rows.length - 1;
          final row = e.value;
          final isStatus = row['label'] == 'Status';
          final isType   = row['label'] == 'Expense Type';
          return Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              child: Row(children: [
                Text(row['label']!,
                    style: WerlogTextStyles.caption.copyWith(color: WerlogColors.textTertiary)),
                const Spacer(),
                if (isStatus)
                  _StatusBadgeLarge(item.status)
                else if (isType)
                  _TypePill(item.type)
                else
                  Text(row['value']!,
                      style: WerlogTextStyles.txTitle.copyWith(fontSize: 12)),
              ]),
            ),
            if (!isLast) const Divider(height: 0.5, color: WerlogColors.borderLight),
          ]);
        }),
      ]),
    );
  }

  // ── Deductibility card ───────────────────────────────────────────────────────
  Widget _buildDeductibilityCard(BuildContext context) {
    final pct = item.deductiblePercent / 100;
    final isPartial = item.deductiblePercent > 0 && item.deductiblePercent < 100;
    final isNone = item.deductiblePercent == 0;

    return Container(
      decoration: BoxDecoration(
        gradient: WerlogGradients.pageHeader(),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WerlogColors.border, width: 0.8),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.percent, color: WerlogColors.teal, size: 18),
          const SizedBox(width: 8),
          Text('Tax Deductibility', style: WerlogTextStyles.sectionTitle),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isNone ? WerlogColors.coralSurface
                  : isPartial ? WerlogColors.amberSurface
                  : WerlogColors.tealSurface,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isNone ? 'Non-Deductible' : isPartial ? 'Partial' : 'Fully Deductible',
              style: WerlogTextStyles.badgeText.copyWith(
                color: isNone ? WerlogColors.coral
                    : isPartial ? WerlogColors.amber
                    : WerlogColors.teal,
                fontSize: 10,
              ),
            ),
          ),
        ]),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: WerlogColors.surfaceAlt,
            valueColor: AlwaysStoppedAnimation<Color>(
                isNone ? WerlogColors.coral : isPartial ? WerlogColors.amber : WerlogColors.teal),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 8),
        Row(children: [
          Text(
            '\$${item.deductibleAmount.toStringAsFixed(2)} deductible',
            style: WerlogTextStyles.txTitle.copyWith(
                fontSize: 12,
                color: isNone ? WerlogColors.coral : WerlogColors.teal),
          ),
          const Spacer(),
          Text(
            'of ${item.formattedAmount} total',
            style: WerlogTextStyles.caption,
          ),
        ]),
        if (isPartial) ...[
          const SizedBox(height: 8),
          Text(
            'Only ${item.deductiblePercent.toInt()}% is claimable for tax. '
            'Update the business usage % to adjust.',
            style: WerlogTextStyles.caption.copyWith(color: WerlogColors.amber),
          ),
        ],
      ]),
    );
  }

  // ── Attachments ──────────────────────────────────────────────────────────────
  Widget _buildAttachmentsSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: WerlogColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WerlogColors.border, width: 0.8),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Attachments (${item.attachmentNames.length})',
                style: WerlogTextStyles.sectionTitle),
            GestureDetector(
              onTap: () {},
              child: Text('View All', style: WerlogTextStyles.link.copyWith(fontSize: 11)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(children: [
            ...item.attachmentNames.map((name) => Padding(
              padding: const EdgeInsets.only(right: 10),
              child: _AttachmentTile(name: name),
            )),
            _AddAttachmentTile(),
          ]),
        ),
        if (item.status == ExpenseStatus.missingInfo) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: WerlogColors.amberSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: WerlogColors.amber.withOpacity(0.3), width: 0.8),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline, color: WerlogColors.amber, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(
                'Receipt or invoice is required to validate this expense.',
                style: WerlogTextStyles.caption.copyWith(color: WerlogColors.amberDark),
              )),
            ]),
          ),
        ],
      ]),
    );
  }

  // ── Notes ────────────────────────────────────────────────────────────────────
  Widget _buildNotesCard(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: WerlogColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WerlogColors.border, width: 0.8),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Notes', style: WerlogTextStyles.sectionTitle),
        const SizedBox(height: 8),
        Text(item.notes!,
            style: WerlogTextStyles.body.copyWith(fontSize: 12, color: WerlogColors.textSecondary)),
      ]),
    );
  }

  // ── Action bar ───────────────────────────────────────────────────────────────
  Widget _buildActionBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: WerlogColors.surface,
        border: const Border(top: BorderSide(color: WerlogColors.border, width: 0.8)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, -3))],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(children: [
          _ActionBtn(icon: Icons.upload_outlined, label: 'Upload Receipt',
              onTap: () {}, primary: false),
          const SizedBox(width: 10),
          _ActionBtn(icon: Icons.verified_outlined, label: 'Mark Verified',
              onTap: () {},
              primary: item.status != ExpenseStatus.verified),
          const SizedBox(width: 10),
          _ActionBtn(icon: Icons.share_outlined, label: 'Share',
              onTap: () {}, primary: false),
          const SizedBox(width: 10),
          _ActionBtn(icon: Icons.delete_outline, label: 'Delete',
              onTap: () {}, primary: false, danger: true),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  REUSABLE WIDGETS
// ─────────────────────────────────────────────────────────────────────────────
class _StatusBadgeLarge extends StatelessWidget {
  final ExpenseStatus status;
  const _StatusBadgeLarge(this.status);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: status.color.withOpacity(0.3), width: 0.8),
      ),
      child: Text(status.label,
          style: WerlogTextStyles.badgeText.copyWith(color: status.color, fontSize: 10)),
    );
  }
}

class _TypePill extends StatelessWidget {
  final ExpenseType type;
  const _TypePill(this.type);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: type.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(type.label,
          style: WerlogTextStyles.badgeText.copyWith(color: type.color, fontSize: 10)),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  final ExpenseCategory category;
  const _CategoryPill({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: category.iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(category.icon, color: category.iconColor, size: 10),
        const SizedBox(width: 4),
        Text(category.name,
            style: WerlogTextStyles.badgeText.copyWith(color: category.iconColor, fontSize: 10)),
      ]),
    );
  }
}

class _AmountChip extends StatelessWidget {
  final IconData icon;
  final Color iconColor, bgColor;
  final String label, value;
  final String? sub;
  const _AmountChip({required this.icon, required this.iconColor,
      required this.label, required this.value, required this.bgColor, this.sub});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: WerlogColors.border, width: 0.8),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: iconColor, size: 14),
          const SizedBox(width: 6),
          Expanded(child: Text(label, style: WerlogTextStyles.caption.copyWith(fontSize: 9))),
        ]),
        const SizedBox(height: 6),
        Text(value, style: WerlogTextStyles.txTitle.copyWith(fontSize: 15, color: iconColor)),
        if (sub != null) Text(sub!, style: WerlogTextStyles.caption.copyWith(fontSize: 9)),
      ]),
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  final String name;
  const _AttachmentTile({required this.name});

  @override
  Widget build(BuildContext context) {
    final isImage = name.endsWith('.jpg') || name.endsWith('.png');
    return Container(
      width: 100, height: 96,
      decoration: BoxDecoration(
        color: WerlogColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WerlogColors.border, width: 0.8),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(
          isImage ? Icons.image_outlined : Icons.picture_as_pdf_outlined,
          color: isImage ? WerlogColors.teal : WerlogColors.coral,
          size: 28,
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(name,
              style: WerlogTextStyles.caption.copyWith(fontSize: 8),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ),
      ]),
    );
  }
}

class _AddAttachmentTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100, height: 96,
      decoration: BoxDecoration(
        color: WerlogColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WerlogColors.border, width: 0.8),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.add_circle_outline, color: WerlogColors.textTertiary, size: 26),
        const SizedBox(height: 4),
        Text('Add', style: WerlogTextStyles.caption.copyWith(fontSize: 10)),
      ]),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary, danger;
  const _ActionBtn({required this.icon, required this.label,
      required this.onTap, this.primary = false, this.danger = false});

  @override
  Widget build(BuildContext context) {
    final bgColor = primary ? WerlogColors.teal
        : danger ? WerlogColors.coralSurface
        : WerlogColors.surface;
    final fgColor = primary ? Colors.white
        : danger ? WerlogColors.coral
        : WerlogColors.textPrimary;
    final borderColor = primary ? WerlogColors.teal
        : danger ? WerlogColors.coral.withOpacity(0.3)
        : WerlogColors.border;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 0.8),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 1))],
        ),
        child: Row(children: [
          Icon(icon, size: 16, color: fgColor),
          const SizedBox(width: 6),
          Text(label, style: WerlogTextStyles.txTitle.copyWith(fontSize: 12, color: fgColor)),
        ]),
      ),
    );
  }
}
