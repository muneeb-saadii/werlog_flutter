import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'expense_data.dart';

// ═══════════════════════════════════════════════════════════════════════
//  SCREEN 4 — Tax Ready Summary  (Export / Tax Return Ready)
// ═══════════════════════════════════════════════════════════════════════
class TaxReadySummaryScreen extends StatelessWidget {
  const TaxReadySummaryScreen({super.key});

  // ── Data variables — replace with API response ──────────────────────
  // Year for this summary
  static const int _year = 2026;
  static const double _totalExpenses     = 28540;
  static const double _totalDeductible   = 8620;
  static const double _gstHstClaimable   = 2930;
  static const double _estimatedRefund   = 3450;
  static const int    _checklistCompletePct = 95;
  static const int    _missingReceipts   = 7;

  String _fmt(double v) =>
      '\$${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')}';

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
              child: Column(children: [
                const SizedBox(height: 16),
                _buildReadyBanner(),
                const SizedBox(height: 18),
                _buildTaxSummaryTable(context),
                const SizedBox(height: 18),
                _buildRecordsChecklist(context),
                const SizedBox(height: 18),
                _buildExportSection(context),
                /*const SizedBox(height: 18),
                _buildAddMissingBtn(context),
                const SizedBox(height: 10),
                _buildAuditTrailBtn(context),*/
                const SizedBox(height: 30),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  // ── App bar ──────────────────────────────────────────────────────────
  Widget _buildAppBar(BuildContext context) {
    return Container(
      color: WerlogColors.surface,
      padding: const EdgeInsets.fromLTRB(8, 10, 16, 10),
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18,
              color: WerlogColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        const Expanded(
          child: Text('Tax Ready Summary', textAlign: TextAlign.center,
              style: WerlogTextStyles.pageTitle),
        ),
        GestureDetector(
          onTap: () {},
          child: const Icon(Icons.ios_share_rounded, size: 20, color: WerlogColors.teal),
        ),
      ]),
    );
  }

  // ── "You're Tax Ready!" hero banner ─────────────────────────────────
  Widget _buildReadyBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: WerlogGradients.taxReady,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: WerlogColors.teal.withOpacity(0.3),
                blurRadius: 20, offset: const Offset(0, 8)),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        child: Column(children: [
          Container(
            width: 54, height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline_rounded,
                color: Colors.white, size: 30),
          ),
          const SizedBox(height: 14),
          const Text("You're Tax Ready!",
              style: TextStyle(
                fontFamily: 'DMSans', fontSize: 22, fontWeight: FontWeight.w700,
                color: Colors.white, letterSpacing: -0.3,
              )),
          const SizedBox(height: 6),
          const Text(
            'Great job! Your records look complete\nand organized for tax filing.',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'DMSans', fontSize: 13,
                color: Color(0xCCFFFFFF), height: 1.5),
          ),
        ]),
      ),
    );
  }

  // ── Tax summary table ────────────────────────────────────────────────
  Widget _buildTaxSummaryTable(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        decoration: _cardDecoration(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Text('$_year Tax Summary', style: WerlogTextStyles.sectionTitle),
          ),
          const Divider(height: 0.5, color: WerlogColors.borderLight),
          _SummaryRow(label: 'Total Expenses',          value: _fmt(_totalExpenses)),
          const Divider(height: 0.5, color: WerlogColors.borderLight),
          _SummaryRow(label: 'Total Deductible Amount', value: _fmt(_totalDeductible)),
          const Divider(height: 0.5, color: WerlogColors.borderLight),
          _SummaryRow(label: 'GST/HST Claimable',       value: _fmt(_gstHstClaimable)),
          const Divider(height: 0.5, color: WerlogColors.borderLight),
          // Highlighted row
          Container(
            decoration: BoxDecoration(
              color: WerlogColors.tealSurface,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Estimated Tax Refund / Savings',
                  style: WerlogTextStyles.summaryRowLabel),
              Text(_fmt(_estimatedRefund),
                  style: const TextStyle(
                    fontFamily: 'DMSans', fontSize: 16, fontWeight: FontWeight.w700,
                    color: WerlogColors.teal,
                  )),
            ]),
          ),
        ]),
      ),
    );
  }

  // ── Records checklist ────────────────────────────────────────────────
  Widget _buildRecordsChecklist(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        decoration: _cardDecoration(),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Records Checklist', style: WerlogTextStyles.sectionTitle),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: WerlogColors.tealSurface,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('$_checklistCompletePct% Complete',
                  style: const TextStyle(
                    fontFamily: 'DMSans', fontSize: 11, fontWeight: FontWeight.w600,
                    color: WerlogColors.teal,
                  )),
            ),
          ]),
          const SizedBox(height: 10),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _checklistCompletePct / 100,
              minHeight: 6,
              backgroundColor: WerlogColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(WerlogColors.teal),
            ),
          ),
          const SizedBox(height: 14),
          ...ExpenseData.checklist.map((item) => _ChecklistRow(item: item)),
        ]),
      ),
    );
  }

  // ── Export / share section ───────────────────────────────────────────
  Widget _buildExportSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        decoration: _cardDecoration(),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Export / Share', style: WerlogTextStyles.sectionTitle),
          const SizedBox(height: 4),
          const Text('Download your tax package or share with your accountant.',
              style: WerlogTextStyles.captionSmall),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _ExportBtn(
              icon: Icons.picture_as_pdf_rounded,
              iconColor: WerlogColors.coral,
              iconBg: WerlogColors.coralSurface,
              label: 'Tax Report\nPDF',
              onTap: () {},
            ),
            _ExportBtn(
              icon: Icons.table_chart_rounded,
              iconColor: const Color(0xFF217346),
              iconBg: const Color(0xFFE8F5E9),
              label: 'Excel\nReport',
              onTap: () {},
            ),
            _ExportBtn(
              icon: Icons.person_outline_rounded,
              iconColor: WerlogColors.blue,
              iconBg: WerlogColors.blueSurface,
              label: 'Share with\nAccountant',
              onTap: () {},
            ),
          ]),
        ]),
      ),
    );
  }

  // ── Add missing receipts CTA ─────────────────────────────────────────
  Widget _buildAddMissingBtn(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: SizedBox(
        width: double.infinity, height: 52,
        child: ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add_rounded, size: 20, color: Colors.white),
          label: Text('Add Missing Receipts ($_missingReceipts)',
              style: WerlogTextStyles.buttonGhost),
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
    );
  }

  // ── Audit trail button ───────────────────────────────────────────────
  Widget _buildAuditTrailBtn(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: SizedBox(
        width: double.infinity, height: 52,
        child: OutlinedButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: WerlogColors.border, width: 1.2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text('View Audit Trail',
              style: TextStyle(fontFamily: 'DMSans', fontSize: 14,
                  fontWeight: FontWeight.w600, color: WerlogColors.textPrimary)),
        ),
      ),
    );
  }
}

// ─── Reusable widgets ──────────────────────────────────────────────────
class _SummaryRow extends StatelessWidget {
  final String label, value;
  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: WerlogTextStyles.summaryRowLabel),
        Text(value,  style: WerlogTextStyles.summaryRowValue),
      ]),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  final ChecklistItem item;
  const _ChecklistRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final isComplete = item.status == 'complete';
    final isPending  = item.status == 'pending';
    final isPartial  = item.status == 'partial';

    final iconColor = isComplete ? WerlogColors.teal
        : isPending ? WerlogColors.amber
        : WerlogColors.textTertiary;

    final trailingIcon = isComplete
        ? const Icon(Icons.check_circle_rounded, color: WerlogColors.teal, size: 19)
        : isPending
            ? const Icon(Icons.pending_outlined, color: WerlogColors.amber, size: 19)
            : const Icon(Icons.radio_button_unchecked_rounded,
                color: WerlogColors.textTertiary, size: 19);

    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(children: [
        Container(
          width: 30, height: 30,
          decoration: BoxDecoration(
            color: isComplete ? WerlogColors.tealSurface
                : isPending ? WerlogColors.amberSurface
                : WerlogColors.surfaceAlt,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(item.icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.label, style: WerlogTextStyles.body),
          if (item.detail != null)
            Text(item.detail!,
                style: WerlogTextStyles.captionSmall.copyWith(
                    color: isPartial ? WerlogColors.amber : WerlogColors.textTertiary)),
        ])),
        Row(children: [
          Text(
            isComplete ? 'Complete' : isPending ? 'Pending' : item.detail ?? '',
            style: TextStyle(
              fontFamily: 'DMSans', fontSize: 11, fontWeight: FontWeight.w500,
              color: isComplete ? WerlogColors.teal
                  : isPending ? WerlogColors.amber : WerlogColors.textTertiary,
            ),
          ),
          const SizedBox(width: 6),
          trailingIcon,
        ]),
      ]),
    );
  }
}

class _ExportBtn extends StatelessWidget {
  final IconData icon;
  final Color iconColor, iconBg;
  final String label;
  final VoidCallback onTap;
  const _ExportBtn({required this.icon, required this.iconColor,
      required this.iconBg, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        Container(
          width: 60, height: 60,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: WerlogColors.border, width: 0.8),
          ),
          child: Icon(icon, color: iconColor, size: 28),
        ),
        const SizedBox(height: 8),
        Text(label,
            textAlign: TextAlign.center,
            style: WerlogTextStyles.captionSmall.copyWith(
                color: WerlogColors.textPrimary, fontWeight: FontWeight.w500,
                height: 1.4)),
      ]),
    );
  }
}

BoxDecoration _cardDecoration() => BoxDecoration(
  color: WerlogColors.surface,
  borderRadius: BorderRadius.circular(16),
  border: Border.all(color: WerlogColors.border, width: 0.8),
  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
      blurRadius: 8, offset: const Offset(0, 2))],
);
