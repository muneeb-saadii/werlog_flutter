import 'package:flutter/material.dart';

import '../../core/models/app_models_extended.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';

// ──────────────────────────────────────────────────────────────
//  ScanTypeSheet  (screen 07 · Choose type)
//  Shown as a modal bottom sheet over a dimmed home screen.
// ──────────────────────────────────────────────────────────────
class ScanTypeSheet extends StatefulWidget {
  final ScanTypeSheetData? data;
  final ValueChanged<ScanType>? onTypeSelected;
  final VoidCallback? onContinue;

  const ScanTypeSheet({
    super.key,
    this.data,
    this.onTypeSelected,
    this.onContinue,
  });

  @override
  State<ScanTypeSheet> createState() => _ScanTypeSheetState();
}

class _ScanTypeSheetState extends State<ScanTypeSheet> {
  late ScanType _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.data?.selectedType ?? ScanType.warranty;
  }

  void _pick(ScanType t) {
    setState(() => _selected = t);
    widget.onTypeSelected?.call(t);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Dimmed background
          Container(
            decoration: BoxDecoration(
              gradient: WerlogGradients.sheetDimmedBg(),
            ),
            child: const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 60, left: 22),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    '(dimmed home screen behind)',
                    style: TextStyle(
                        color: Color(0x4DFAFAF7), fontSize: 11),
                  ),
                ),
              ),
            ),
          ),
          // Sheet
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: const BoxDecoration(
                color: WerlogColors.background,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(22)),
              ),
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD3D1C7),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text('What are you scanning?',
                      style: WerlogTextStyles.pageTitle
                          .copyWith(fontSize: 18)),
                  const SizedBox(height: 4),
                  Text(
                    'We\'ll capture different fields for each type',
                    style: WerlogTextStyles.bodySmall,
                  ),
                  const SizedBox(height: 18),
                  _ScanTypeOption(
                    type: ScanType.expense,
                    selected: _selected == ScanType.expense,
                    onTap: () => _pick(ScanType.expense),
                  ),
                  const SizedBox(height: 10),
                  _ScanTypeOption(
                    type: ScanType.warranty,
                    selected: _selected == ScanType.warranty,
                    onTap: () => _pick(ScanType.warranty),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: widget.onContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selected == ScanType.expense
                          ? WerlogColors.teal
                          : WerlogColors.amber,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(
                      _selected == ScanType.expense
                          ? 'Continue with Expense →'
                          : 'Continue with Warranty →',
                      style: WerlogTextStyles.button,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Type option card ───────────────────────────────────────────
class _ScanTypeOption extends StatelessWidget {
  final ScanType type;
  final bool selected;
  final VoidCallback onTap;

  const _ScanTypeOption({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  bool get _isExpense => type == ScanType.expense;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? (_isExpense ? WerlogColors.teal : WerlogColors.amber)
        : WerlogColors.border;

    final gradBg = selected
        ? (_isExpense
            ? const LinearGradient(
                begin: Alignment.topLeft, end: Alignment.centerRight,
                colors: [WerlogColors.tealSurface, WerlogColors.surface])
            : const LinearGradient(
                begin: Alignment.topLeft, end: Alignment.centerRight,
                colors: [WerlogColors.amberSurface, WerlogColors.surface]))
        : null;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: gradBg,
          color: gradBg == null ? WerlogColors.surface : null,
          border: Border.all(color: borderColor, width: 1.5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: _isExpense
                    ? WerlogColors.coralSurface
                    : WerlogColors.amberSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                _isExpense ? '◉' : '◆',
                style: TextStyle(
                  fontSize: 18,
                  color: _isExpense
                      ? WerlogColors.coralDark
                      : WerlogColors.amberDark,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isExpense ? 'Expense' : 'Warranty',
                    style: WerlogTextStyles.body
                        .copyWith(fontWeight: FontWeight.w500, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _isExpense
                        ? 'Receipts, bills & purchases'
                        : 'Electronics, appliances & devices',
                    style: WerlogTextStyles.bodySmall,
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4, runSpacing: 4,
                    children: _isExpense
                        ? ['Total', 'Tax', 'Line items']
                            .map((t) => _Tag(label: t, isWarranty: false))
                            .toList()
                        : ['Serial #', 'Warranty date', 'Model']
                            .map((t) => _Tag(label: t, isWarranty: true))
                            .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _RadioDot(active: selected, isWarranty: !_isExpense),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final bool isWarranty;
  const _Tag({required this.label, required this.isWarranty});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isWarranty
            ? WerlogColors.amber.withOpacity(0.10)
            : WerlogColors.coral.withOpacity(0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: WerlogTextStyles.badgeText.copyWith(
          color: isWarranty
              ? WerlogColors.amberDeep
              : const Color(0xFF712B13),
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  final bool active;
  final bool isWarranty;
  const _RadioDot({required this.active, required this.isWarranty});

  @override
  Widget build(BuildContext context) {
    final color =
        isWarranty ? WerlogColors.amber : WerlogColors.teal;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 20, height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? color : Colors.transparent,
        border: Border.all(
          color: active ? color : WerlogColors.border,
          width: 1.5,
        ),
      ),
      child: active
          ? const Center(
              child: CircleAvatar(
                  radius: 4, backgroundColor: Colors.white))
          : null,
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  CameraScreen  (screen 08 · Capture)
// ──────────────────────────────────────────────────────────────
class CameraScreen extends StatelessWidget {
  final CameraViewData? data;
  final VoidCallback? onClose;
  final VoidCallback? onCapture;
  final VoidCallback? onToggleFlash;
  final VoidCallback? onSwitchCamera;
  final VoidCallback? onGallery;

  const CameraScreen({
    super.key,
    this.data,
    this.onClose,
    this.onCapture,
    this.onToggleFlash,
    this.onSwitchCamera,
    this.onGallery,
  });

  @override
  Widget build(BuildContext context) {
    final d = data ?? CameraViewData();
    final isWarranty = d.scanType == ScanType.warranty;

    return Scaffold(
      backgroundColor: const Color(0xFF0D2427),
      body: Column(
        children: [
          // Status bar area
          Container(
            color: WerlogColors.darkTeal,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('9:41',
                    style: WerlogTextStyles.statusBar
                        .copyWith(color: Colors.white)),
                Text('●●●',
                    style: WerlogTextStyles.statusBar
                        .copyWith(color: Colors.white)),
              ],
            ),
          ),
          // Viewfinder
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: WerlogGradients.cameraOverlay(),
              ),
              child: Stack(
                children: [
                  // Simulated receipt document
                  /*Positioned(
                    top: 76, left: 58, right: 58, bottom: 160,
                    child: Transform.rotate(
                      angle: -0.026,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F6EC),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x4D000000),
                              blurRadius: 24, offset: Offset(0, 8))
                          ],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: _ReceiptPreview(isWarranty: isWarranty),
                      ),
                    ),
                  ),*/
                  Positioned(
                    top: 76,
                    left: 58,
                    right: 58,
                    bottom: 160,
                    child: Container(
                      color: Colors.black,
                    ),
                  ),
                  // Top controls
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: onClose,
                          child: Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Text('✕',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 14)),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: WerlogColors.amber.withOpacity(0.30),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: WerlogColors.amber.withOpacity(0.5)),
                          ),
                          child: Text(
                            isWarranty ? 'WARRANTY SCAN' : 'EXPENSE SCAN',
                            style: WerlogTextStyles.labelUppercase.copyWith(
                              color: isWarranty
                                  ? const Color(0xFFFAEEDA)
                                  : WerlogColors.coralSurface,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: onToggleFlash,
                          child: Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Text('⚡',
                                style: TextStyle(fontSize: 14)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Corner frame guides
                  Positioned(
                    top: 76, left: 28, right: 28, bottom: 144,
                    child: CustomPaint(
                      painter: _CornerFramePainter(
                          color: WerlogColors.amber),
                    ),
                  ),
                  // Hint text
                  Positioned(
                    bottom: 114, left: 0, right: 0,
                    child: Text(
                      d.hintText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xD9FFFFFF),
                        fontSize: 10,
                      ),
                    ),
                  ),
                  // Bottom controls
                  Positioned(
                    bottom: 22, left: 24, right: 24,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: onGallery,
                          child: _CamSmButton(emoji: '▦'),
                        ),
                        // Shutter
                        GestureDetector(
                          onTap: onCapture,
                          child: Container(
                            width: 64, height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 4,
                              ),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: onSwitchCamera,
                          child: _CamSmButton(emoji: '↻'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CamSmButton extends StatelessWidget {
  final String emoji;
  const _CamSmButton({required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(11),
      ),
      alignment: Alignment.center,
      child: Text(emoji,
          style: const TextStyle(fontSize: 14, color: Colors.white)),
    );
  }
}

class _ReceiptPreview extends StatelessWidget {
  final bool isWarranty;
  const _ReceiptPreview({required this.isWarranty});

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: const TextStyle(
          fontFamily: 'monospace', fontSize: 7, color: Color(0xFF444444),
          height: 1.7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('APPLE STORE',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 8, fontWeight: FontWeight.w600, height: 1)),
          const SizedBox(height: 2),
          const Text('─────────',
              textAlign: TextAlign.center),
          if (isWarranty) ...[
            const Text('MacBook Pro 14″'),
            const Text('M3 · Space Black'),
            const Text('Serial: C02XY9ABZDK3'),
            const Text(' '),
            const Text('Warranty: 1 year'),
            const Text('Expires: 03/24/2027'),
          ] else ...[
            const Text('Organic Bananas   \$4.29'),
            const Text('Greek Yogurt      \$6.99'),
            const Text('Sourdough Bread   \$5.50'),
          ],
          const Text('─────────'),
          const Text('Subtotal   1,199.00'),
          const Text('Tax          100.00'),
          const Text('TOTAL     \$1,299.00',
              style: TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// Custom painter for the 4-corner scan frame
class _CornerFramePainter extends CustomPainter {
  final Color color;
  const _CornerFramePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;
    const len = 28.0;

    void corner(Offset o, dx, dy) {
      canvas.drawLine(o, o + Offset(dx, 0), paint);
      canvas.drawLine(o, o + Offset(0, dy), paint);
    }

    corner(const Offset(-4, -4), len, len);
    corner(Offset(size.width + 4, -4), -len, len);
    corner(Offset(-4, size.height + 4), len, -len);
    corner(Offset(size.width + 4, size.height + 4), -len, -len);
  }

  @override
  bool shouldRepaint(covariant _CornerFramePainter old) =>
      old.color != color;
}

// ──────────────────────────────────────────────────────────────
//  OcrProcessingScreen  (screen 09 · Processing)
// ──────────────────────────────────────────────────────────────
class OcrProcessingScreen extends StatefulWidget {
  final OcrProcessingData? data;
  final VoidCallback? onBack;

  const OcrProcessingScreen({super.key, this.data, this.onBack});

  @override
  State<OcrProcessingScreen> createState() => _OcrProcessingScreenState();
}

class _OcrProcessingScreenState extends State<OcrProcessingScreen>
    with TickerProviderStateMixin {
  late AnimationController _ring1;
  late AnimationController _ring2;

  @override
  void initState() {
    super.initState();
    _ring1 = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat();
    _ring2 = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ring1.dispose();
    _ring2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = data;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: WerlogGradients.processingBg()),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const FakeStatusBar(),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 0),
                child: GestureDetector(
                  onTap: widget.onBack,
                  child: const Text('‹',
                      style: TextStyle(
                          fontSize: 28, color: WerlogColors.textPrimary)),
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated ring with doc icon
                    SizedBox(
                      width: 120, height: 120,
                      child: Stack(
                        children: [
                          AnimatedBuilder(
                            animation: _ring1,
                            builder: (_, __) => Transform.rotate(
                              angle: _ring1.value * 6.283,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: WerlogColors.teal,
                                    width: 2.5,
                                  ),
                                ),
                                // Mask 3/4 of the ring
                                child: CustomPaint(
                                  painter: _ArcMaskPainter(
                                      color: WerlogColors.teal),
                                ),
                              ),
                            ),
                          ),
                          AnimatedBuilder(
                            animation: _ring2,
                            builder: (_, __) => Padding(
                              padding: const EdgeInsets.all(14),
                              child: Transform.rotate(
                                angle: -_ring2.value * 6.283,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: WerlogColors.amber
                                          .withOpacity(0.6),
                                      width: 2,
                                    ),
                                  ),
                                  child: CustomPaint(
                                    painter: _ArcMaskPainter(
                                        color: WerlogColors.amber
                                            .withOpacity(0.6)),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Center(child: _DocIcon()),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(d.headlineText,
                        style: WerlogTextStyles.sectionTitle
                            .copyWith(fontSize: 15, letterSpacing: -0.3)),
                    const SizedBox(height: 4),
                    Text(d.subText,
                        textAlign: TextAlign.center,
                        style: WerlogTextStyles.bodySmall),
                  ],
                ),
              ),
              // Steps list
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 4),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                  decoration: BoxDecoration(
                    color: WerlogColors.surface,
                    border: Border.all(color: WerlogColors.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: d.steps.map((s) => _StepRow(step: s)).toList(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 6, 0, 16),
                child: Text(
                  'Close anytime — we\'ll notify when ready',
                  textAlign: TextAlign.center,
                  style: WerlogTextStyles.caption.copyWith(fontSize: 9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  OcrProcessingData get data => widget.data ?? OcrProcessingData(scanType: ScanType.warranty);
}

class _StepRow extends StatelessWidget {
  final ProcessingStep step;
  const _StepRow({required this.step});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          _StepDot(status: step.status),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              step.label,
              style: WerlogTextStyles.bodySmall.copyWith(
                fontSize: 11,
                color: step.status == ProcessingStepStatus.pending
                    ? WerlogColors.textTertiary
                    : WerlogColors.textSecondary,
              ),
            ),
          ),
          if (step.duration != null)
            Text(
              step.duration!,
              style: WerlogTextStyles.caption.copyWith(
                color: step.status == ProcessingStepStatus.done
                    ? WerlogColors.teal
                    : WerlogColors.textTertiary,
              ),
            ),
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final ProcessingStepStatus status;
  const _StepDot({required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case ProcessingStepStatus.done:
        return Container(
          width: 16, height: 16,
          decoration: const BoxDecoration(
              color: WerlogColors.teal, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: const Text('✓',
              style: TextStyle(
                  fontSize: 9, color: Colors.white,
                  fontWeight: FontWeight.w700)),
        );
      case ProcessingStepStatus.active:
        return Container(
          width: 16, height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: WerlogColors.surface,
            border: Border.all(color: WerlogColors.teal, width: 1.5),
          ),
          alignment: Alignment.center,
          child: Text('•',
              style: TextStyle(
                  color: WerlogColors.teal,
                  fontSize: 10, height: 1)),
        );
      case ProcessingStepStatus.pending:
        return Container(
          width: 16, height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: WerlogColors.surfaceAlt,
            border: Border.all(color: WerlogColors.border),
          ),
          alignment: Alignment.center,
          child: Text('○',
              style: TextStyle(
                  color: WerlogColors.textTertiary,
                  fontSize: 9, height: 1)),
        );
    }
  }
}

class _DocIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44, height: 56,
      decoration: BoxDecoration(
        color: WerlogColors.surface,
        border: Border.all(color: WerlogColors.border),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
      child: Column(
        children: List.generate(
          5,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                color: WerlogColors.border,
                borderRadius: BorderRadius.circular(1),
              ),
              width: i % 2 == 0 ? double.infinity : 26,
            ),
          ),
        ),
      ),
    );
  }
}

class _ArcMaskPainter extends CustomPainter {
  final Color color;
  const _ArcMaskPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // Transparent arc to mask 1/4 of the border ring
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 1.5;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0, 4.712, false, // 270 degrees
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ArcMaskPainter old) => old.color != color;
}
