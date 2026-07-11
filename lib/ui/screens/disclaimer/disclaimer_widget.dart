import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/shared_pref_helper.dart';

// ════════════════════════════════════════════════════════════════════
//  DisclaimerType — controls which content and behaviour is shown
// ════════════════════════════════════════════════════════════════════
enum DisclaimerType {
  /// One-time full-screen acknowledgment on first app launch.
  /// Saves a flag to SharedPrefs — never shows again after "I Understand".
  onboarding,

  /// Inline info-icon tap near any estimated tax/deduction figure.
  /// Small bottom sheet — no persistence needed.
  taxEstimate,

  /// Shown alongside low-confidence / weak OCR scan results.
  /// Small bottom sheet — no persistence needed.
  lowConfidenceScan,

  /// Shown on export / share screen before sending data to accountant.
  /// Small bottom sheet — no persistence needed.
  export,
}

// ════════════════════════════════════════════════════════════════════
//  DisclaimerWidget
//
//  Single entry point for all four disclaimer cases.
//
//  ── How to call ──────────────────────────────────────────────────
//
//  // Case 1 — Onboarding (one-time, full dialog):
//  DisclaimerWidget.show(context, type: DisclaimerType.onboarding,
//    onAcknowledged: () { /* continue to dashboard */ });
//
//  // Case 2 — Tax estimate info icon tap:
//  DisclaimerWidget.show(context, type: DisclaimerType.taxEstimate);
//
//  // Case 3 — Weak OCR result:
//  DisclaimerWidget.show(context, type: DisclaimerType.lowConfidenceScan);
//
//  // Case 4 — Export / share screen:
//  DisclaimerWidget.show(context, type: DisclaimerType.export,
//    onAcknowledged: () { /* proceed with export */ });
//
//  ── Inline info icon (Case 2) ─────────────────────────────────────
//
//  Use DisclaimerWidget.infoIcon(context) next to any tax figure:
//
//    Row(children: [
//      Text('Est. Deduction: \$420'),
//      DisclaimerWidget.infoIcon(context),
//    ])
//
//  ── Inline caption (Case 3) ──────────────────────────────────────
//
//  Use DisclaimerWidget.weakScanCaption(context) under a low-confidence result.
//
// ════════════════════════════════════════════════════════════════════

class DisclaimerWidget {

  DisclaimerWidget._();

  // ── Static show method ────────────────────────────────────────────
  /// Shows the appropriate disclaimer based on [type].
  /// [onAcknowledged] is called when the user taps the confirm button
  /// (relevant for onboarding and export types).
  static Future<void> show(
    BuildContext context, {
    required DisclaimerType type,
    VoidCallback? onAcknowledged,
  }) async {
    if (type == DisclaimerType.onboarding) {
      // Check SharedPrefs — skip if already acknowledged
      final done = await SharedPrefHelper.getBool(
              SharedPrefHelper.disclaimerAcknowledged) ??
          false;
      if (done) {
        onAcknowledged?.call();
        return;
      }
      if (!context.mounted) return;
      await _showOnboardingDialog(context, onAcknowledged: onAcknowledged);
    } else {
      if (!context.mounted) return;
      await _showBottomSheet(context, type: type,
          onAcknowledged: onAcknowledged);
    }
  }

  // ── Inline info icon widget ───────────────────────────────────────
  /// Small tappable ⓘ icon — place next to any estimated tax figure.
  static Widget infoIcon(BuildContext context) {
    return GestureDetector(
      onTap: () => show(context, type: DisclaimerType.taxEstimate),
      child: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Icon(
          Icons.info_outline_rounded,
          size: 14,
          color: WerlogColors.textTertiary,
        ),
      ),
    );
  }

  /// One-line caption — place under weak/low-confidence OCR values.
  static Widget weakScanCaption(BuildContext context) {
    return GestureDetector(
      onTap: () => show(context, type: DisclaimerType.lowConfidenceScan),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.warning_amber_rounded,
            size: 11, color: WerlogColors.amber),
        const SizedBox(width: 4),
        Text(
          'Scan may be inaccurate — tap to ',
          style: TextStyle(
            fontFamily: 'DMSans',
            fontSize: 10,
            color: WerlogColors.amber,
          ),
        ),
        Text(
          'learn more',
          style: TextStyle(
            fontFamily: 'DMSans',
            fontSize: 10,
            color: WerlogColors.amber,
            decoration: TextDecoration.underline,
            decorationColor: WerlogColors.amber,
          ),
        ),
      ]),
    );
  }

  // ── Content resolver ──────────────────────────────────────────────
  static _DisclaimerContent _content(DisclaimerType type) {
    switch (type) {
      case DisclaimerType.onboarding:
        return _DisclaimerContent(
          icon:        Icons.info_outline_rounded,
          iconColor:   WerlogColors.teal,
          iconBg:      WerlogColors.tealSurface,
          title:       'Before You Begin',
          body:
              'Werlog helps you organise receipts, invoices, and warranties '
              'in one place.\n\n'
              'All tax estimates, deduction figures, and financial summaries '
              'shown in the app are for informational purposes only. '
              'Werlog does not provide tax, legal, or accounting advice.\n\n'
              'For personalised guidance please consult a qualified '
              'tax or accounting professional.',
          buttonLabel: 'I Understand — Let\'s Go',
          note:        null,
        );

      case DisclaimerType.taxEstimate:
        return _DisclaimerContent(
          icon:        Icons.calculate_outlined,
          iconColor:   WerlogColors.amber,
          iconBg:      WerlogColors.amberSurface,
          title:       'Estimate Only',
          body:
              'The figures shown here are calculated estimates based on the '
              'data you have entered.\n\n'
              'They are provided for informational purposes only and do not '
              'constitute tax, legal, or accounting advice.\n\n'
              'Tax rules vary by jurisdiction and individual circumstances. '
              'Always confirm deductions and claimable amounts with a '
              'qualified professional before filing.',
          buttonLabel: 'Got It',
          note:        '⚠️  Estimates only — not tax advice.',
        );

      case DisclaimerType.lowConfidenceScan:
        return _DisclaimerContent(
          icon:        Icons.document_scanner_outlined,
          iconColor:   WerlogColors.coral,
          iconBg:      WerlogColors.coralSurface,
          title:       'Low Confidence Scan',
          body:
              'Our AI was unable to extract all fields from this document '
              'with high confidence.\n\n'
              'The values shown may be incomplete or inaccurate. '
              'Please review each field carefully and correct any errors '
              'before saving or relying on this data for tax purposes.\n\n'
              'For best results, ensure the document is well-lit, '
              'flat, and fully within the frame when scanning.',
          buttonLabel: 'I\'ll Review It',
          note:        '🔍  Always verify low-confidence results manually.',
        );

      case DisclaimerType.export:
        return _DisclaimerContent(
          icon:        Icons.upload_file_outlined,
          iconColor:   WerlogColors.blue,
          iconBg:      WerlogColors.blueSurface,
          title:       'Before You Export',
          body:
              'This export reflects the data you entered or confirmed '
              'within Werlog.\n\n'
              'Werlog does not verify the accuracy of this data against '
              'current tax regulations, and the exported file should not '
              'be treated as a certified tax document.\n\n'
              'Share this with your accountant or tax advisor as a '
              'supporting reference only.',
          buttonLabel: 'Understood — Export',
          note:        null,
        );
    }
  }

  // ── Onboarding full dialog ────────────────────────────────────────
  static Future<void> _showOnboardingDialog(
    BuildContext context, {
    VoidCallback? onAcknowledged,
  }) async {
    final c = _content(DisclaimerType.onboarding);
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
              horizontal: 20, vertical: 40),
          child: Container(
            decoration: BoxDecoration(
              color: WerlogColors.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [

              // Icon
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: c.iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(c.icon, color: c.iconColor, size: 26),
              ),

              const SizedBox(height: 16),

              // Title
              Text(c.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'DMSans', fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: WerlogColors.textPrimary,
                  )),

              const SizedBox(height: 12),

              // Body
              Text(c.body,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'DMSans', fontSize: 13,
                    color: WerlogColors.textSecondary,
                    height: 1.65,
                  )),

              const SizedBox(height: 22),
              const Divider(color: WerlogColors.borderLight),
              const SizedBox(height: 14),

              // Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await SharedPrefHelper.saveBool(
                        SharedPrefHelper.disclaimerAcknowledged, true);
                    if (context.mounted) Navigator.pop(context);
                    onAcknowledged?.call();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WerlogColors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13)),
                    elevation: 0,
                  ),
                  child: Text(c.buttonLabel,
                      style: const TextStyle(
                        fontFamily: 'DMSans', fontSize: 14,
                        fontWeight: FontWeight.w500, color: Colors.white,
                      )),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  // ── Bottom sheet (cases 2 / 3 / 4) ───────────────────────────────
  static Future<void> _showBottomSheet(
    BuildContext context, {
    required DisclaimerType type,
    VoidCallback? onAcknowledged,
  }) async {
    final c = _content(type);
    final mq = MediaQuery.of(context);
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        constraints: BoxConstraints(
            maxHeight: mq.size.height - mq.padding.top - 16),
        decoration: const BoxDecoration(
          color: WerlogColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: EdgeInsets.fromLTRB(
            20, 0, 20, mq.padding.bottom + 24),
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

          // Icon + title row
          Row(children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: c.iconBg,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(c.icon, color: c.iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(c.title,
                  style: const TextStyle(
                    fontFamily: 'DMSans', fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: WerlogColors.textPrimary,
                  )),
            ),
          ]),

          const SizedBox(height: 14),
          const Divider(color: WerlogColors.borderLight),
          const SizedBox(height: 12),

          // Body
          Text(c.body,
              style: const TextStyle(
                fontFamily: 'DMSans', fontSize: 13,
                color: WerlogColors.textSecondary,
                height: 1.65,
              )),

          // Optional note badge
          if (c.note != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: c.iconBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: c.iconColor.withOpacity(0.2), width: 0.8),
              ),
              child: Text(c.note!,
                  style: TextStyle(
                    fontFamily: 'DMSans', fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: c.iconColor,
                  )),
            ),
          ],

          const SizedBox(height: 20),

          // Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                onAcknowledged?.call();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: c.iconColor,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13)),
                elevation: 0,
              ),
              child: Text(c.buttonLabel,
                  style: const TextStyle(
                    fontFamily: 'DMSans', fontSize: 14,
                    fontWeight: FontWeight.w500, color: Colors.white,
                  )),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Internal content model ─────────────────────────────────────────
class _DisclaimerContent {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String body;
  final String buttonLabel;
  final String? note;

  const _DisclaimerContent({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.body,
    required this.buttonLabel,
    this.note,
  });
}
