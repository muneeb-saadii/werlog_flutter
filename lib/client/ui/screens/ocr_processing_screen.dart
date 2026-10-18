import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wellness/client/core/utils/general_functions.dart';
import 'package:wellness/client/ui/screens/profile_segment/currency_screen.dart';

import '../../core/api/api_service.dart';
import '../../core/api/endpoints.dart';
import '../../core/models/app_models_extended.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/shared_pref_helper.dart';
import 'disclaimer/disclaimer_widget.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────────────────────────────────────────

enum ProcessingStepStatus { done, active, pending }

class ProcessingStep {
  final String label;
  final ProcessingStepStatus status;
  final String? duration;
  const ProcessingStep({required this.label, required this.status, this.duration});
}

class OcrProcessingDataNew {
  final ScanType scanType;
  final String headlineText;
  final String subText;
  final List<ProcessingStep> steps;
  final Map<String, dynamic> processData;

  OcrProcessingDataNew({
    required this.scanType,
    final Map<String, dynamic>? processData,
    String? headlineText,
    String? subText,
    List<ProcessingStep>? steps,
  })  : headlineText = headlineText ?? _defaultHeadline(scanType),
        subText = subText ?? _defaultSub(scanType),
        processData = processData ?? {},
        steps = steps ??
            const [
              ProcessingStep(label: 'Uploading document',  status: ProcessingStepStatus.done,    duration: '0.4s'),
              ProcessingStep(label: 'Running OCR scan',    status: ProcessingStepStatus.active),
              ProcessingStep(label: 'Extracting fields',   status: ProcessingStepStatus.pending),
              ProcessingStep(label: 'Saving to your log',  status: ProcessingStepStatus.pending),
            ];

  static String _defaultHeadline(ScanType t) {
    switch (t) {
      case ScanType.warranty: return 'Extracting warranty data…';
      case ScanType.expense:  return 'Reading invoice…';
    }
  }

  static String _defaultSub(ScanType t) =>
      'Hold tight while we read your document and pull out all the key details';
}

class OcrJobResult {
  final String jobId;
  final String? invoiceId;
  final String status;
  final String engine;
  final int durationMs;
  final int attemptCount;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final List<OcrCompletedStep> completedSteps;
  final OcrExtracted extracted;

  OcrJobResult({
    required this.jobId,
    required this.status,
    required this.engine,
    required this.durationMs,
    required this.attemptCount,
    this.invoiceId,
    this.startedAt,
    this.completedAt,
    required this.completedSteps,
    required this.extracted,
  });

  factory OcrJobResult.fromJson(Map<String, dynamic> json) => OcrJobResult(
    jobId: json['jobId'] ?? '',
    invoiceId: json['invoiceId'] ?? '',
    status: json['status'] ?? '',
    engine: json['engine'] ?? '',
    durationMs: json['durationMs'] ?? 0,
    attemptCount: json['attemptCount'] ?? 1,
    startedAt: json['startedAt'] != null ? DateTime.tryParse(json['startedAt']) : null,
    completedAt: json['completedAt'] != null ? DateTime.tryParse(json['completedAt']) : null,
    completedSteps: (json['completedSteps'] as List? ?? [])
        .map((s) => OcrCompletedStep.fromJson(s)).toList(),
    extracted: OcrExtracted.fromJson(json['extracted'] ?? {}),
  );
}

class OcrCompletedStep {
  final String key, label, status;
  final int durationMs;
  OcrCompletedStep({required this.key, required this.label,
    required this.status, required this.durationMs});
  factory OcrCompletedStep.fromJson(Map<String, dynamic> json) =>
      OcrCompletedStep(
        key: json['key'] ?? '', label: json['label'] ?? '',
        status: json['status'] ?? '', durationMs: json['durationMs'] ?? 0,
      );
}

class OcrLineItem {
  final String description, amountFormatted;
  OcrLineItem({required this.description, required this.amountFormatted});
  factory OcrLineItem.fromJson(Map<String, dynamic> json) => OcrLineItem(
    description: json['description'] ?? '', amountFormatted: json['amountFormatted'] ?? '',
  );
}

class OcrExtracted {
  final String? vendorName;
  final String? totalAmountFormatted;
  final String? invoiceDateFormatted;
  final int lineItemCount;
  final String confidenceLabel;
  final bool needsReview;
  final String? autoCategoryName;
  final String? autoCategoryIcon;
  final List<OcrLineItem> lineItemsPreview;
  /// Currency code returned at the same level as vendorName (e.g. "PKR", "CAD").
  /// Null when the server did not detect / return a currency.
  final String? currency;

  OcrExtracted({
    this.vendorName, this.totalAmountFormatted, this.invoiceDateFormatted,
    this.lineItemCount = 0, required this.confidenceLabel,
    required this.needsReview, this.autoCategoryName, this.autoCategoryIcon,
    required this.lineItemsPreview, this.currency,
  });

  factory OcrExtracted.fromJson(Map<String, dynamic> json) => OcrExtracted(
    vendorName: json['vendorName'],
    totalAmountFormatted: json['totalAmountFormatted'],
    invoiceDateFormatted: json['invoiceDateFormatted'],
    lineItemCount: json['lineItemCount'] ?? 0,
    confidenceLabel: json['confidenceLabel'] ?? 'LOW',
    needsReview: json['needsReview'] ?? false,
    autoCategoryName: json['autoCategoryName'],
    autoCategoryIcon: json['autoCategoryIcon'],
    lineItemsPreview: (json['lineItemsPreview'] as List? ?? [])
        .map((i) => OcrLineItem.fromJson(i)).toList(),
    // "currency" lives at the same level as vendorName in the extracted object
    currency: _parseCurrencyCode(json['currency']),
  );

  /// Returns a clean 3-4 letter ISO code, or null if absent / invalid.
  static String? _parseCurrencyCode(dynamic raw) {
    if (raw == null) return null;
    final s = raw.toString().trim().toUpperCase();
    if (s.isEmpty) return null;
    if (RegExp(r'^[A-Z]{2,4}$').hasMatch(s)) return s;
    return null;
  }

  /// Returns the best available currency code:
  /// 1. `currency` field (new — same level as vendorName)
  /// 2. Prefix of `totalAmountFormatted` (e.g. "PKR 1730.00" → "PKR")
  /// 3. null — no currency could be detected
  String? get detectedCurrencyCode {
    // Prefer the dedicated currency field
    if (currency != null && currency!.isNotEmpty) return currency;
    // Fall back to parsing the formatted total
    final raw = totalAmountFormatted?.trim();
    if (raw == null || raw.isEmpty) return null;
    final parts = raw.split(RegExp(r'\s+'));
    if (parts.length < 2) return null;
    final candidate = parts.first;
    if (RegExp(r'^[A-Z]{2,4}$').hasMatch(candidate)) return candidate;
    return null;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FAKE STATUS BAR
// ─────────────────────────────────────────────────────────────────────────────

class FakeStatusBar extends StatelessWidget {
  const FakeStatusBar({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox(height: 10);
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN SCREEN WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class OcrProcessingScreenNew extends StatefulWidget {
  final OcrProcessingDataNew? data;
  final VoidCallback? onBack;
  final VoidCallback? onProceed;

  const OcrProcessingScreenNew({super.key, this.data, this.onBack, this.onProceed});

  @override
  State<OcrProcessingScreenNew> createState() => _OcrProcessingScreenNewState();
}

class _OcrProcessingScreenNewState extends State<OcrProcessingScreenNew>
    with TickerProviderStateMixin {

  late final AnimationController _ring1, _ring2, _scanCtrl, _pulseCtrl;
  late final AnimationController _checkCircleCtrl, _checkMarkCtrl,
      _burstCtrl, _successFadeCtrl;
  late final Animation<double> _scanAnim, _pulseAnim;

  late int _totalSeconds, _remainingSeconds;
  Timer? _countdownTimer;
  late List<ProcessingStepStatus> _stepStatus;
  late List<String?> _stepDurations;
  late List<DateTime> _stepStartTimes;

  bool _isComplete = false;
  bool _isLoadingResult = false;
  OcrJobResult? _jobResult;

  OcrProcessingDataNew get _data =>
      widget.data ?? OcrProcessingDataNew(scanType: ScanType.warranty);

  @override
  void initState() {
    super.initState();

    _totalSeconds     = (int.tryParse(_data.processData['estimatedSeconds'].toString()) ?? 20) + 5;
    _remainingSeconds = _totalSeconds;
    _stepStatus    = _data.steps.map((s) => s.status).toList();
    _stepDurations = _data.steps.map((s) => s.duration).toList();
    _stepStartTimes = List.filled(_data.steps.length, DateTime.now());

    _ring1 = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
    _ring2 = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat();
    _scanCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _scanAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _scanCtrl, curve: Curves.easeInOut));
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.4, end: 1.0).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _checkCircleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _checkMarkCtrl   = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _burstCtrl       = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _successFadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _remainingSeconds--;
        _updateStepProgress();
        if (_remainingSeconds <= 0) {
          _remainingSeconds = 0;
          t.cancel();
          _completeLastStep();
          _triggerComplete();
        }
      });
    });
  }

  void _updateStepProgress() {
    final pct = 1.0 - (_remainingSeconds / _totalSeconds);
    if (pct >= 0.35 && _stepStatus[1] == ProcessingStepStatus.active) { _completeStep(1); _activateStep(2); }
    if (pct >= 0.60 && _stepStatus[2] == ProcessingStepStatus.active) { _completeStep(2); _activateStep(3); }
  }

  void _activateStep(int i) {
    if (i < _stepStatus.length) { _stepStatus[i] = ProcessingStepStatus.active; _stepStartTimes[i] = DateTime.now(); }
  }

  void _completeStep(int i) {
    if (i < _stepStatus.length) {
      _stepStatus[i] = ProcessingStepStatus.done;
      _stepDurations[i] = '${(DateTime.now().difference(_stepStartTimes[i]).inMilliseconds / 1000).toStringAsFixed(1)}s';
    }
  }

  void _completeLastStep() {
    for (int i = 0; i < _stepStatus.length; i++) {
      if (_stepStatus[i] != ProcessingStepStatus.done) _completeStep(i);
    }
  }

  void _triggerComplete() async {
    _ring1.stop(); _ring2.stop(); _scanCtrl.stop(); _pulseCtrl.stop();
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() => _isComplete = true);
    await _checkCircleCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 80));
    await _checkMarkCtrl.forward();
    _burstCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _successFadeCtrl.forward();
  }

  Future<void> _getOcrJobDetails() async {
    setState(() => _isLoadingResult = true);
    try {
      final response = await ApiService.get(
          context,
          '${Endpoints.SCANNED_OCR_JOB_DETAILS}${_data.processData['jobId']}',
          showLoader: false);

      final ok = response['result'] == '1';
      if (ok) {
        final result = OcrJobResult.fromJson(response['data'] as Map<String, dynamic>);
        setState(() { _jobResult = result; _isLoadingResult = false; });
        if (mounted) _showResultSheet(result);
      } else {
        setState(() => _isLoadingResult = false);
        if (mounted) _showErrorSnack((response['message'] ?? 'Something went wrong').toString());
      }
    } catch (e) {
      setState(() => _isLoadingResult = false);
      if (mounted) _showErrorSnack('Process interrupted. Please try again!');
    }
  }

  void _showResultSheet(OcrJobResult result) {
    final rootContext = context;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OcrResultSheet(
        result: result,
        scanType: _data.scanType,
        rootContext: rootContext,
        onDone: () => GeneralFunctions.resetAppState(),
      ),
    );
  }

  void _showErrorSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'DMSans', fontSize: 13)),
      backgroundColor: WerlogColors.coral,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  void dispose() {
    _ring1.dispose(); _ring2.dispose(); _scanCtrl.dispose(); _pulseCtrl.dispose();
    _checkCircleCtrl.dispose(); _checkMarkCtrl.dispose();
    _burstCtrl.dispose(); _successFadeCtrl.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  String get _countdownLabel {
    final m = _remainingSeconds ~/ 60, s = _remainingSeconds % 60;
    return '${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}';
  }

  double get _countdownProgress =>
      _totalSeconds > 0 ? _remainingSeconds / _totalSeconds : 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WerlogColors.background,
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: _isComplete ? Alignment.topLeft : Alignment.topCenter,
              end:   _isComplete ? Alignment.bottomRight : Alignment.bottomCenter,
              colors: [WerlogColors.background, WerlogColors.tealLightSurface, WerlogColors.background],
            ),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
            child: _isComplete
                ? _SuccessView(
              key: const ValueKey('success'),
              data: _data,
              checkCircleCtrl: _checkCircleCtrl,
              checkMarkCtrl:   _checkMarkCtrl,
              burstCtrl:       _burstCtrl,
              fadeCtrl:        _successFadeCtrl,
              isLoading:       _isLoadingResult,
              onViewData:      _getOcrJobDetails,
            )
                : _ProcessingView(
              key: const ValueKey('processing'),
              data:              _data,
              ring1:             _ring1,
              ring2:             _ring2,
              scanAnim:          _scanAnim,
              pulseAnim:         _pulseAnim,
              countdownLabel:    _countdownLabel,
              countdownProgress: _countdownProgress,
              stepStatus:        _stepStatus,
              stepDurations:     _stepDurations,
              onBack:            widget.onBack,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROCESSING VIEW  (unchanged)
// ─────────────────────────────────────────────────────────────────────────────

class _ProcessingView extends StatelessWidget {
  final OcrProcessingDataNew data;
  final AnimationController ring1, ring2;
  final Animation<double> scanAnim, pulseAnim;
  final String countdownLabel;
  final double countdownProgress;
  final List<ProcessingStepStatus> stepStatus;
  final List<String?> stepDurations;
  final VoidCallback? onBack;

  const _ProcessingView({
    super.key, required this.data, required this.ring1, required this.ring2,
    required this.scanAnim, required this.pulseAnim, required this.countdownLabel,
    required this.countdownProgress, required this.stepStatus,
    required this.stepDurations, this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
        child: GestureDetector(
          onTap: onBack,
          child: const Text('‹', style: TextStyle(fontSize: 28, color: WerlogColors.textPrimary)),
        ),
      ),
      Expanded(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          _AnimatedOrbit(ring1: ring1, ring2: ring2, scanAnim: scanAnim, pulseAnim: pulseAnim),
          const SizedBox(height: 22),
          Text(data.headlineText, style: WerlogTextStyles.sectionTitle.copyWith(fontSize: 15, letterSpacing: -0.3)),
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(data.subText, textAlign: TextAlign.center, style: WerlogTextStyles.bodySmall),
          ),
          const SizedBox(height: 22),
          _CountdownWidget(label: countdownLabel, progress: countdownProgress),
        ]),
      ),
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
            children: List.generate(data.steps.length, (i) => _StepRow(
              label: data.steps[i].label, status: stepStatus[i], duration: stepDurations[i],
            )),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(0, 6, 0, 16),
        child: Text('Close anytime — we\'ll notify when ready',
            textAlign: TextAlign.center, style: WerlogTextStyles.caption.copyWith(fontSize: 9)),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ANIMATED ORBIT  (unchanged)
// ─────────────────────────────────────────────────────────────────────────────

class _AnimatedOrbit extends StatelessWidget {
  final AnimationController ring1, ring2;
  final Animation<double> scanAnim, pulseAnim;

  const _AnimatedOrbit({required this.ring1, required this.ring2,
    required this.scanAnim, required this.pulseAnim});

  @override
  Widget build(BuildContext context) {
    const size = 148.0;
    return SizedBox(
      width: size, height: size,
      child: Stack(alignment: Alignment.center, children: [
        AnimatedBuilder(animation: ring1, builder: (_, __) => CustomPaint(
          size: const Size(size, size),
          painter: _RingArcPainter(progress: ring1.value, color: WerlogColors.teal,
              radius: size/2-4, strokeWidth: 2.5, arcFraction: 0.75, dotRadius: 4.5, clockwise: true),
        )),
        AnimatedBuilder(animation: ring2, builder: (_, __) => CustomPaint(
          size: const Size(size-28, size-28),
          painter: _RingArcPainter(progress: ring2.value, color: WerlogColors.amber.withOpacity(0.7),
              radius: (size-28)/2-3, strokeWidth: 2.0, arcFraction: 0.6, dotRadius: 3.5, clockwise: false),
        )),
        AnimatedBuilder(animation: scanAnim, builder: (_, __) => _DocIconWithScan(scanProgress: scanAnim.value)),
        AnimatedBuilder(animation: Listenable.merge([ring1, pulseAnim]), builder: (_, __) {
          final angle = ring1.value * 2 * math.pi - math.pi/2;
          final r = size/2-4;
          return Positioned(left: size/2+r*math.cos(angle)-5, top: size/2+r*math.sin(angle)-5,
              child: Opacity(opacity: pulseAnim.value, child: Container(
                  width: 10, height: 10, decoration: const BoxDecoration(color: WerlogColors.teal, shape: BoxShape.circle))));
        }),
        AnimatedBuilder(animation: Listenable.merge([ring2, pulseAnim]), builder: (_, __) {
          final angle = -(ring2.value*2*math.pi)+math.pi-math.pi/2;
          final r = (size-28)/2-3;
          return Positioned(left: size/2+r*math.cos(angle)-4, top: size/2+r*math.sin(angle)-4,
              child: Opacity(opacity: 1.0-(pulseAnim.value-0.4)/0.6, child: Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(color: WerlogColors.amber.withOpacity(0.8), shape: BoxShape.circle))));
        }),
      ]),
    );
  }
}

class _RingArcPainter extends CustomPainter {
  final double progress, radius, strokeWidth, arcFraction, dotRadius;
  final Color color;
  final bool clockwise;
  const _RingArcPainter({required this.progress, required this.color,
    required this.radius, required this.strokeWidth, required this.arcFraction,
    required this.dotRadius, required this.clockwise});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width/2, size.height/2);
    canvas.drawCircle(center, radius, Paint()..color=color.withOpacity(0.12)..strokeWidth=strokeWidth..style=PaintingStyle.stroke);
    final arcPaint = Paint()..color=color..strokeWidth=strokeWidth..style=PaintingStyle.stroke..strokeCap=StrokeCap.round;
    final base = -math.pi/2;
    final rot  = (clockwise?1:-1)*progress*2*math.pi;
    final start = base+rot;
    final sweep  = (clockwise?1:-1)*2*math.pi*arcFraction;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start, sweep, false, arcPaint);
    final dotAngle = start+sweep;
    canvas.drawCircle(Offset(center.dx+radius*math.cos(dotAngle), center.dy+radius*math.sin(dotAngle)), dotRadius, Paint()..color=color);
  }

  @override
  bool shouldRepaint(covariant _RingArcPainter old) => old.progress != progress;
}

class _DocIconWithScan extends StatelessWidget {
  final double scanProgress;
  const _DocIconWithScan({required this.scanProgress});

  @override
  Widget build(BuildContext context) {
    const docW = 44.0, docH = 56.0;
    return SizedBox(width: docW, height: docH, child: Stack(children: [
      Container(
        width: docW, height: docH,
        decoration: BoxDecoration(color: WerlogColors.surface, border: Border.all(color: WerlogColors.border), borderRadius: BorderRadius.circular(4)),
        padding: const EdgeInsets.all(5),
        child: Column(children: List.generate(5, (i) => Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Container(height: 2, decoration: BoxDecoration(color: WerlogColors.border, borderRadius: BorderRadius.circular(1)), width: i%2==0?double.infinity:22),
        ))),
      ),
      Positioned(top: scanProgress*(docH-2), left: 0, right: 0, child: Container(
        height: 2,
        decoration: BoxDecoration(gradient: LinearGradient(colors: [
          Colors.transparent, WerlogColors.teal.withOpacity(0.6),
          WerlogColors.teal, WerlogColors.teal.withOpacity(0.6), Colors.transparent,
        ])),
      )),
    ]));
  }
}

class _CountdownWidget extends StatelessWidget {
  final String label;
  final double progress;
  const _CountdownWidget({required this.label, required this.progress});

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    SizedBox(width: 50, height: 50, child: Stack(alignment: Alignment.center, children: [
      CustomPaint(size: const Size(50,50), painter: _CountdownRingPainter(progress: progress)),
      Text(label, style: const TextStyle(fontFamily: 'monospace', fontSize: 10, fontWeight: FontWeight.w600, color: WerlogColors.teal)),
    ])),
    const SizedBox(width: 10),
    Text('estimated time remaining', style: WerlogTextStyles.caption.copyWith(fontSize: 11)),
  ]);
}

class _CountdownRingPainter extends CustomPainter {
  final double progress;
  const _CountdownRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width/2, size.height/2);
    const radius = 22.0;
    canvas.drawCircle(center, radius, Paint()..color=WerlogColors.border..strokeWidth=3..style=PaintingStyle.stroke);
    if (progress > 0) {
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -math.pi/2, 2*math.pi*progress, false,
          Paint()..color=WerlogColors.teal..strokeWidth=3..style=PaintingStyle.stroke..strokeCap=StrokeCap.round);
    }
  }

  @override
  bool shouldRepaint(covariant _CountdownRingPainter old) => old.progress != progress;
}

class _StepRow extends StatelessWidget {
  final String label;
  final ProcessingStepStatus status;
  final String? duration;
  const _StepRow({required this.label, required this.status, this.duration});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      _StepDot(status: status),
      const SizedBox(width: 10),
      Expanded(child: Text(label, style: WerlogTextStyles.bodySmall.copyWith(
        fontSize: 11,
        color: status == ProcessingStepStatus.pending ? WerlogColors.textTertiary : WerlogColors.textSecondary,
      ))),
      if (duration != null)
        Text(duration!, style: WerlogTextStyles.caption.copyWith(
            color: status == ProcessingStepStatus.done ? WerlogColors.teal : WerlogColors.textTertiary)),
    ]),
  );
}

class _StepDot extends StatelessWidget {
  final ProcessingStepStatus status;
  const _StepDot({required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case ProcessingStepStatus.done:
        return Container(width: 16, height: 16,
            decoration: const BoxDecoration(color: WerlogColors.teal, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: const Text('✓', style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700)));
      case ProcessingStepStatus.active:
        return Container(width: 16, height: 16,
            decoration: BoxDecoration(shape: BoxShape.circle, color: WerlogColors.surface, border: Border.all(color: WerlogColors.teal, width: 1.5)),
            alignment: Alignment.center,
            child: Text('•', style: TextStyle(color: WerlogColors.teal, fontSize: 10, height: 1)));
      case ProcessingStepStatus.pending:
        return Container(width: 16, height: 16,
            decoration: BoxDecoration(shape: BoxShape.circle, color: WerlogColors.surfaceAlt, border: Border.all(color: WerlogColors.border)),
            alignment: Alignment.center,
            child: Text('○', style: TextStyle(color: WerlogColors.textTertiary, fontSize: 9, height: 1)));
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SUCCESS VIEW  (unchanged)
// ─────────────────────────────────────────────────────────────────────────────

class _SuccessView extends StatelessWidget {
  final OcrProcessingDataNew data;
  final AnimationController checkCircleCtrl, checkMarkCtrl, burstCtrl, fadeCtrl;
  final bool isLoading;
  final VoidCallback onViewData;

  const _SuccessView({super.key, required this.data, required this.checkCircleCtrl,
    required this.checkMarkCtrl, required this.burstCtrl, required this.fadeCtrl,
    required this.isLoading, required this.onViewData});

  @override
  Widget build(BuildContext context) {
    final circleTween = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: checkCircleCtrl, curve: Curves.easeOut));
    final markTween   = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: checkMarkCtrl, curve: Curves.easeOut));
    final burstTween  = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: burstCtrl, curve: Curves.easeOut));
    final fadeTween   = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: fadeCtrl, curve: Curves.easeOut));
    final slideTween  = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(CurvedAnimation(parent: fadeCtrl, curve: Curves.easeOut));

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SizedBox(height: 8),
      Expanded(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          SizedBox(width: 96, height: 96, child: AnimatedBuilder(
            animation: Listenable.merge([checkCircleCtrl, checkMarkCtrl, burstCtrl]),
            builder: (_, __) => CustomPaint(painter: _SuccessCheckPainter(
                circleProgress: circleTween.value, markProgress: markTween.value, burstProgress: burstTween.value)),
          )),
          const SizedBox(height: 24),
          SlideTransition(position: slideTween, child: FadeTransition(opacity: fadeTween, child: Column(children: [
            const Text('Scan Complete!', style: TextStyle(fontFamily: 'DMSans', fontSize: 22, fontWeight: FontWeight.w600, color: WerlogColors.textPrimary, letterSpacing: -0.5)),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 44),
              child: Text(
                'Your ${_scanTypeLabel(data.scanType)} details have been extracted and saved to your log.',
                textAlign: TextAlign.center,
                style: WerlogTextStyles.bodySmall.copyWith(fontSize: 12, height: 1.55),
              ),
            ),
          ]))),
          if (data.processData['remainingQuota'] != null) ...[
            const SizedBox(height: 28),
            SlideTransition(position: slideTween, child: FadeTransition(opacity: fadeTween, child: _QuotaCard(
              remaining: data.processData['remainingQuota'],
              total:     data.processData['totalQuota'] ?? data.processData['remainingQuota'],
            ))),
          ],
        ]),
      ),
      FadeTransition(opacity: fadeTween, child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
        child: _WerlogButton(label: isLoading ? 'Loading…' : 'View Extracted Data', isLoading: isLoading, onTap: isLoading ? null : onViewData),
      )),
    ]);
  }

  String _scanTypeLabel(ScanType t) {
    switch (t) {
      case ScanType.warranty: return 'invoice';
      case ScanType.expense:  return 'receipt';
    }
  }
}

class _SuccessCheckPainter extends CustomPainter {
  final double circleProgress, markProgress, burstProgress;
  const _SuccessCheckPainter({required this.circleProgress, required this.markProgress, required this.burstProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width/2, size.height/2);
    final r = size.width/2-5;
    if (circleProgress > 0) canvas.drawCircle(center, r, Paint()..color=WerlogColors.teal.withOpacity(0.10*circleProgress));
    canvas.drawArc(Rect.fromCircle(center: center, radius: r), -math.pi/2, 2*math.pi*circleProgress, false,
        Paint()..color=WerlogColors.teal..strokeWidth=2.0..style=PaintingStyle.stroke..strokeCap=StrokeCap.round);
    if (markProgress > 0) {
      final path = Path()
        ..moveTo(center.dx-18, center.dy)..lineTo(center.dx-5, center.dy+13)..lineTo(center.dx+18, center.dy-13);
      final m = path.computeMetrics().first;
      canvas.drawPath(m.extractPath(0, m.length*markProgress),
          Paint()..color=WerlogColors.teal..strokeWidth=3.0..style=PaintingStyle.stroke..strokeCap=StrokeCap.round..strokeJoin=StrokeJoin.round);
    }
    if (burstProgress > 0) {
      final bp = Paint()..color=WerlogColors.teal.withOpacity((1.0-burstProgress).clamp(0.0,1.0)*0.7)..strokeWidth=1.5..strokeCap=StrokeCap.round;
      for (int i = 0; i < 8; i++) {
        final a = i*math.pi/4;
        canvas.drawLine(Offset(center.dx+(r+4+burstProgress*6)*math.cos(a), center.dy+(r+4+burstProgress*6)*math.sin(a)),
            Offset(center.dx+(r+10+burstProgress*10)*math.cos(a), center.dy+(r+10+burstProgress*10)*math.sin(a)), bp);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SuccessCheckPainter old) =>
      old.circleProgress != circleProgress || old.markProgress != markProgress || old.burstProgress != burstProgress;
}

class _QuotaCard extends StatelessWidget {
  final int remaining, total;
  const _QuotaCard({required this.remaining, required this.total});

  @override
  Widget build(BuildContext context) {
    final fraction = total > 0 ? remaining / total : 0.0;
    final isLow    = fraction < 0.3;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: WerlogColors.surface,
          border: Border.all(color: isLow ? WerlogColors.amber.withOpacity(0.5) : WerlogColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Monthly quota', style: WerlogTextStyles.caption.copyWith(fontSize: 10, color: WerlogColors.textTertiary)),
            Text('$remaining / $total scans left', style: WerlogTextStyles.caption.copyWith(fontSize: 10, color: isLow ? WerlogColors.amber : WerlogColors.teal)),
          ]),
          const SizedBox(height: 8),
          ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(
            value: fraction, minHeight: 5,
            backgroundColor: WerlogColors.border,
            color: isLow ? WerlogColors.amber : WerlogColors.teal,
          )),
          if (isLow) ...[
            const SizedBox(height: 6),
            Text('Running low — consider upgrading your plan.', style: WerlogTextStyles.caption.copyWith(fontSize: 9, color: WerlogColors.amber)),
          ],
        ]),
      ),
    );
  }
}

class _WerlogButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  const _WerlogButton({required this.label, this.onTap, this.isLoading = false});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 50,
      decoration: BoxDecoration(color: onTap == null ? WerlogColors.teal.withOpacity(0.5) : WerlogColors.teal, borderRadius: BorderRadius.circular(13)),
      alignment: Alignment.center,
      child: isLoading
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : Text(label, style: WerlogTextStyles.button),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// OCR RESULT BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _OcrResultSheet extends StatefulWidget {
  final OcrJobResult result;
  final VoidCallback onDone;
  final ScanType scanType;
  final BuildContext rootContext;

  const _OcrResultSheet({required this.result, required this.onDone,
    required this.scanType, required this.rootContext});

  @override
  State<_OcrResultSheet> createState() => _OcrResultSheetState();
}

class _OcrResultSheetState extends State<_OcrResultSheet> {

  // ── Expense type ──────────────────────────────────────────────────────────
  String _expenseType = 'PERSONAL';
  bool   _isSavingType = false;
  bool   _typeSaved    = false;

  // ── Currency ──────────────────────────────────────────────────────────────
  // Null  → server returned no currency; user must select before saving.
  // Non-null → either detected from response or selected by user.
  String? _selectedCurrencyCode;
  bool _currencyChanged = false; // true once user picks a different currency

  bool get _isExpense => widget.scanType == ScanType.expense;

  /// True when currency was detected or the user has already chosen one.
  bool get _hasCurrency => _selectedCurrencyCode != null &&
      _selectedCurrencyCode!.isNotEmpty;

  // ── Can the user leave? ───────────────────────────────────────────────────
  // Block "Done" if:
  //   1. expense scan AND type not saved yet
  //   2. currency was changed but not yet saved
  //   3. expense scan AND currency is still null (user hasn't selected one)
  bool get _canLeave {
    if (_isExpense && _selectedCurrencyCode == null) return false;
    if (_isExpense && !_typeSaved) return false;
    if (_currencyChanged && !_typeSaved) return false;
    return true;
  }

  @override
  void initState() {
    super.initState();
    // Use the detected currency (currency field or parsed from totalAmountFormatted).
    // If null — currency is unknown; _selectedCurrencyCode stays null so the
    // widget can show the "select a currency" prompt.
    _selectedCurrencyCode = widget.result.extracted.detectedCurrencyCode;
  }

  // ── Save expense type + currency ──────────────────────────────────────────

  Future<void> _saveExpenseType() async {
    if (_selectedCurrencyCode == null) {
      // This should not happen (Save is hidden when currency is null)
      // but guard defensively
      _openCurrencyPicker();
      return;
    }
    setState(() => _isSavingType = true);
    try {
      final jobId   = widget.result.invoiceId;
      final response = await ApiService.post(
        context,
        Endpoints.UPDATE_EXPENSE_TYPE,
        body: {
          'invoiceId': jobId,
          'type':      _expenseType,
          'currency':  _selectedCurrencyCode!,  // ← safe — guarded above
        },
        showLoader: false,
      );

      final ok = response != null && response['result'] == '1';
      if (ok) {
        if (mounted) {
          setState(() => _typeSaved = true);
          GeneralFunctions.showSuccess(widget.rootContext,
              'Saved as ${_expenseType == 'PERSONAL' ? 'Personal' : 'Business'} · $_selectedCurrencyCode');
        }
      } else {
        if (mounted) {
          GeneralFunctions.showError(widget.rootContext,
              response?['message']?.toString() ?? 'Update failed.');
        }
      }
    } catch (e) {
      if (mounted) {
        GeneralFunctions.showError(widget.rootContext, 'Something went wrong.');
      }
    } finally {
      if (mounted) setState(() => _isSavingType = false);
    }
  }

  // ── Currency picker bottom sheet ──────────────────────────────────────────

  void _openCurrencyPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CurrencyPickerSheet(
        selectedCode: _selectedCurrencyCode ?? '',
        onSelected: (item) {
          HapticFeedback.lightImpact();
          setState(() {
            _selectedCurrencyCode = item.code;
            _currencyChanged      = true;
            _typeSaved            = false; // require re-save when currency changes
          });
        },
      ),
    );
  }

  String _formatAmountWithCurrency(String? amount, String? currencyCode) {
    var value = (amount ?? '').trim();
    if (value.isEmpty) return value;

    // Always remove any existing currency code prefix (e.g. "PKR 1730.00" → "1730.00")
    if (currencyCode != null && currencyCode.isNotEmpty) {
      value = value.replaceFirst(
        RegExp('^${RegExp.escape(currencyCode)}\\s*', caseSensitive: false), '',
      );
    }

    // Always strip leading currency symbols ($, €, £, ₹, Rs. etc.)
    value = value.replaceFirst(
      RegExp(r'^(?:[$€£¥₹₨₩₽¢]|Rs\.?|৳|₺|₴)\s*'), '',
    ).trim();

    // If no currency known, return the clean numeric value as-is
    if (currencyCode == null || currencyCode.isEmpty) return value;

    return '$currencyCode $value';
  }

  @override
  Widget build(BuildContext context) {
    final ext     = widget.result.extracted;
    final totalMs = widget.result.durationMs;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize:     0.5,
      maxChildSize:     0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: WerlogColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(children: [

          // Drag handle
          Padding(padding: const EdgeInsets.only(top: 12, bottom: 4), child: Container(
            width: 36, height: 4,
            decoration: BoxDecoration(color: WerlogColors.border, borderRadius: BorderRadius.circular(2)),
          )),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: WerlogColors.tealSurface, borderRadius: BorderRadius.circular(10)),
                alignment: Alignment.center,
                child: const Icon(Icons.description_outlined, color: WerlogColors.teal, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Extracted Details', style: WerlogTextStyles.sectionTitle.copyWith(fontSize: 15)),
                const SizedBox(height: 1),
                Text('Processed in ${(totalMs/1000).toStringAsFixed(1)}s · ${widget.result.engine}',
                    style: WerlogTextStyles.caption),
              ])),
              _ConfidenceBadge(label: ext.confidenceLabel),
            ]),
          ),

          // Low-confidence caption
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: DisclaimerWidget.weakScanCaption(context),
          ),

          const SizedBox(height: 12),
          Divider(color: WerlogColors.border, height: 1, thickness: 0.5),

          // Scrollable body
          Expanded(child: ListView(
            controller: scrollCtrl,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [

              // ── Expense type + currency (expense only) ────────────────
              if (_isExpense) ...[
                _ExpenseTypeToggle(
                  selected:  _expenseType,
                  isSaving:  _isSavingType,
                  typeSaved: _typeSaved,
                  selectedCurrencyCode: _selectedCurrencyCode,
                  currencyChanged:      _currencyChanged,
                  onChanged:   (v) => setState(() { _expenseType = v; _typeSaved = false; }),
                  onSave:      _saveExpenseType,
                  onChangeCurrency: _openCurrencyPicker,
                ),
                const SizedBox(height: 14),
              ],

              // Needs-review banner
              if (ext.needsReview) _ReviewBanner(),
              if (ext.needsReview) const SizedBox(height: 14),

              // Document info
              _SectionCard(title: 'Document Info', icon: Icons.receipt_long_outlined, children: [
                _FieldRow(label: 'Vendor',       value: ext.vendorName,            placeholder: 'Not detected'),
                // _FieldRow(label: 'Total Amount', value: _selectedCurrencyCode+" "+(ext.totalAmountFormatted ?? "0.00"),  placeholder: 'Not detected',
                _FieldRow(label: 'Total Amount', value: _formatAmountWithCurrency(ext.totalAmountFormatted, _selectedCurrencyCode,),  placeholder: 'Not detected',
                    valueColor: ext.totalAmountFormatted != null ? WerlogColors.teal : null),
                _FieldRow(label: 'Invoice Date', value: ext.invoiceDateFormatted,  placeholder: 'Not detected'),
                _FieldRow(label: 'Category',     value: ext.autoCategoryName,      placeholder: 'Uncategorized'),
                _FieldRow(label: 'Line Items',   value: '${ext.lineItemCount}',    isLast: true),
              ]),
              const SizedBox(height: 14),

              // Line items
              if (ext.lineItemsPreview.isNotEmpty) ...[
                _SectionCard(title: 'Line Items Preview', icon: Icons.list_alt_outlined, children: [
                  ...ext.lineItemsPreview.asMap().entries.map((e) =>
                      _LineItemRow(item: e.value, isLast: e.key == ext.lineItemsPreview.length-1, currencyCode: _selectedCurrencyCode ?? '')),
                ]),
                const SizedBox(height: 14),
              ],

              // Pipeline
              _SectionCard(title: 'Processing Pipeline', icon: Icons.bolt_outlined, children: [
                ...widget.result.completedSteps.asMap().entries.map((e) =>
                    _PipelineStepRow(step: e.value, isLast: e.key == widget.result.completedSteps.length-1)),
              ]),
              const SizedBox(height: 24),

              // ── Done button ────────────────────────────────────────────
              GestureDetector(
                onTap: () {
                  if (!_canLeave) {
                    if (_isExpense && _selectedCurrencyCode == null) {
                      GeneralFunctions.showError(widget.rootContext,
                          'Please select a currency before continuing.');
                      _openCurrencyPicker();
                    } else if (_isExpense && !_typeSaved) {
                      GeneralFunctions.showError(widget.rootContext,
                          _currencyChanged
                              ? 'Currency changed — please save before leaving.'
                              : 'Please save the expense type before continuing.');
                    }
                    return;
                  }

                  GeneralFunctions.forceSessionRefresh(context,
                      onComplete: () { if (mounted) setState(() {}); });
                  widget.onDone();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 50,
                  decoration: BoxDecoration(
                    color: _canLeave ? WerlogColors.teal : WerlogColors.teal.withOpacity(0.38),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  alignment: Alignment.center,
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    if (!_canLeave)
                      const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Icon(Icons.lock_outline_rounded, color: Colors.white70, size: 15),
                      ),
                    Text(
                      _canLeave ? 'Done — Back to Dashboard' : 'Save required before leaving',
                      style: WerlogTextStyles.button.copyWith(
                          color: _canLeave ? Colors.white : Colors.white70, fontSize: 13),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 24),
            ],
          )),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CURRENCY PICKER BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _CurrencyPickerSheet extends StatefulWidget {
  final String selectedCode;
  final ValueChanged<CurrencyItem> onSelected;

  const _CurrencyPickerSheet({required this.selectedCode, required this.onSelected});

  @override
  State<_CurrencyPickerSheet> createState() => _CurrencyPickerSheetState();
}

class _CurrencyPickerSheetState extends State<_CurrencyPickerSheet> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<CurrencyItem> get _filtered {
    final list = GeneralFunctions.kCurrencies;
    if (_query.isEmpty) return list;
    final q = _query.toLowerCase();
    return list.where((c) =>
    c.code.toLowerCase().contains(q) ||
        c.name.toLowerCase().contains(q) ||
        c.country.toLowerCase().contains(q)).toList();
  }

  // Group by region
  Map<String, List<CurrencyItem>> get _grouped {
    final map = <String, List<CurrencyItem>>{};
    for (final c in _filtered) {
      map.putIfAbsent(c.region, () => []).add(c);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _grouped;
    final regions = grouped.keys.toList()..sort();

    return Container(
      height: MediaQuery.of(context).size.height * 0.80,
      decoration: const BoxDecoration(
        color: WerlogColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(children: [

        // Handle
        const SizedBox(height: 12),
        Container(width: 36, height: 4,
            decoration: BoxDecoration(color: WerlogColors.border, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),

        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: WerlogColors.tealSurface, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.currency_exchange_rounded, color: WerlogColors.teal, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Select Currency', style: WerlogTextStyles.sectionTitle.copyWith(fontSize: 15)),
              Text('Detected from your document · tap to change',
                  style: WerlogTextStyles.caption),
            ])),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 30, height: 30,
                decoration: BoxDecoration(color: WerlogColors.surfaceAlt, shape: BoxShape.circle),
                child: const Icon(Icons.close_rounded, size: 14, color: WerlogColors.textSecondary),
              ),
            ),
          ]),
        ),

        const SizedBox(height: 14),

        // Search
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            decoration: BoxDecoration(
              color: WerlogColors.surface,
              border: Border.all(color: WerlogColors.border),
              borderRadius: BorderRadius.circular(11),
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              style: WerlogTextStyles.bodySmall.copyWith(fontSize: 13, color: WerlogColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search currency…',
                hintStyle: WerlogTextStyles.caption.copyWith(fontSize: 12),
                prefixIcon: const Icon(Icons.search_rounded, size: 16, color: WerlogColors.textTertiary),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 14, color: WerlogColors.textTertiary),
                    onPressed: () { _searchCtrl.clear(); setState(() => _query = ''); })
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),
        Divider(color: WerlogColors.border, height: 1, thickness: 0.5),

        // List
        Expanded(child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          itemCount: regions.fold(0, (s, r) => s! + 1 + (grouped[r]?.length ?? 0)),
          itemBuilder: (_, i) {
            int cursor = 0;
            for (final region in regions) {
              if (i == cursor) {
                // Region header
                return Padding(
                  padding: const EdgeInsets.only(top: 14, bottom: 6),
                  child: Text(region.toUpperCase(),
                      style: WerlogTextStyles.caption.copyWith(
                          fontSize: 10, letterSpacing: 0.8,
                          color: WerlogColors.textTertiary)),
                );
              }
              cursor++;
              final items = grouped[region]!;
              if (i < cursor + items.length) {
                final item   = items[i - cursor];
                final isSel  = item.code == widget.selectedCode;
                return GestureDetector(
                  onTap: () {
                    widget.onSelected(item);
                    Navigator.pop(context);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSel ? WerlogColors.tealSurface : WerlogColors.surface,
                      border: Border.all(
                        color: isSel ? WerlogColors.teal.withOpacity(0.4) : WerlogColors.border,
                        width: isSel ? 1.2 : 0.8,
                      ),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Row(children: [
                      // Symbol circle
                      Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          color: isSel ? WerlogColors.teal.withOpacity(0.15) : WerlogColors.surfaceAlt,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(item.symbol,
                            style: TextStyle(
                              fontFamily: 'DMSans', fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isSel ? WerlogColors.teal : WerlogColors.textSecondary,
                            )),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(item.name,
                            style: WerlogTextStyles.bodySmall.copyWith(
                              fontSize: 13, color: WerlogColors.textPrimary,
                              fontWeight: isSel ? FontWeight.w600 : FontWeight.w400,
                            )),
                        const SizedBox(height: 2),
                        Text(item.country,
                            style: WerlogTextStyles.caption.copyWith(fontSize: 10)),
                      ])),
                      // Code badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSel ? WerlogColors.teal : WerlogColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(item.code,
                            style: TextStyle(
                              fontFamily: 'DMSans', fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isSel ? Colors.white : WerlogColors.textTertiary,
                            )),
                      ),
                      if (isSel) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.check_circle_rounded, color: WerlogColors.teal, size: 18),
                      ],
                    ]),
                  ),
                );
              }
              cursor += items.length;
            }
            return const SizedBox.shrink();
          },
        )),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EXPENSE TYPE TOGGLE  (now includes currency row)
// ─────────────────────────────────────────────────────────────────────────────

class _ExpenseTypeToggle extends StatelessWidget {
  final String  selected;
  final bool    isSaving;
  final bool    typeSaved;
  final String? selectedCurrencyCode; // null = not yet detected by server
  final bool    currencyChanged;
  final ValueChanged<String> onChanged;
  final VoidCallback onSave;
  final VoidCallback onChangeCurrency;

  const _ExpenseTypeToggle({
    required this.selected,
    required this.isSaving,
    required this.typeSaved,
    required this.selectedCurrencyCode, // nullable — null means not yet detected
    required this.currencyChanged,
    required this.onChanged,
    required this.onSave,
    required this.onChangeCurrency,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: WerlogColors.surface,
        border: Border.all(color: WerlogColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Section label
        Row(children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(color: WerlogColors.tealSurface, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.tune_rounded, size: 14, color: WerlogColors.teal),
          ),
          const SizedBox(width: 9),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Expense Type', style: WerlogTextStyles.sectionTitle.copyWith(fontSize: 13)),
            Text('Is this a personal or business expense?', style: WerlogTextStyles.caption),
          ]),
        ]),

        const SizedBox(height: 12),

        // Toggle pills
        Container(
          height: 44,
          decoration: BoxDecoration(color: WerlogColors.surfaceAlt, borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.all(3),
          child: Row(children: [
            _TypePill(label: 'Personal', icon: Icons.person_outline_rounded,
                selected: selected == 'PERSONAL', color: WerlogColors.blue,
                colorBg: WerlogColors.blueSurface, onTap: () => onChanged('PERSONAL')),
            const SizedBox(width: 3),
            _TypePill(label: 'Business', icon: Icons.business_center_outlined,
                selected: selected == 'BUSINESS', color: WerlogColors.teal,
                colorBg: WerlogColors.tealSurface, onTap: () => onChanged('BUSINESS')),
          ]),
        ),

        const SizedBox(height: 12),
        Divider(color: WerlogColors.borderLight, height: 1, thickness: 0.5),
        const SizedBox(height: 12),

        // ── Currency row ──────────────────────────────────────────────────
        Row(children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(color: WerlogColors.tealSurface,
                borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.currency_exchange_rounded,
                size: 14, color: WerlogColors.teal),
          ),
          const SizedBox(width: 9),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Currency', style: WerlogTextStyles.sectionTitle.copyWith(fontSize: 13)),
              Text(
                selectedCurrencyCode == null
                    ? 'Not detected — tap to select'
                    : currencyChanged ? 'Changed — tap Save to apply'
                    : 'Detected from document',
                style: WerlogTextStyles.caption.copyWith(
                  color: selectedCurrencyCode == null
                      ? WerlogColors.coral
                      : currencyChanged ? WerlogColors.amberDark
                      : null,
                ),
              ),
            ],
          )),
          // ── Badge + action button ─────────────────────────────────────
          GestureDetector(
            onTap: onChangeCurrency,
            child: Row(children: [
              if (selectedCurrencyCode != null) ...[
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: currencyChanged
                        ? WerlogColors.teal : WerlogColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: currencyChanged
                          ? WerlogColors.teal : WerlogColors.border,
                    ),
                  ),
                  child: Text(selectedCurrencyCode!,
                      style: TextStyle(
                        fontFamily: 'DMSans', fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: currencyChanged
                            ? Colors.white : WerlogColors.textPrimary,
                      )),
                ),
                const SizedBox(width: 8),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  // Red tint when no currency yet — draws attention
                  color: selectedCurrencyCode == null
                      ? WerlogColors.coralSurface : WerlogColors.tealSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selectedCurrencyCode == null
                        ? WerlogColors.coral.withOpacity(0.4)
                        : WerlogColors.teal.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  selectedCurrencyCode == null ? 'SELECT' : 'CHANGE',
                  style: WerlogTextStyles.caption.copyWith(
                      fontSize: 10,
                      color: selectedCurrencyCode == null
                          ? WerlogColors.coral : WerlogColors.teal,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5),
                ),
              ),
            ]),
          ),
        ]),

        // ── "Must select currency" warning (shown when null) ──────────────
        if (selectedCurrencyCode == null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: WerlogColors.coralSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: WerlogColors.coral.withOpacity(0.35)),
            ),
            child: Row(children: [
              const Icon(Icons.warning_amber_rounded,
                  size: 14, color: WerlogColors.coral),
              const SizedBox(width: 7),
              Expanded(child: Text(
                'Currency not detected. Please select a currency before saving.',
                style: WerlogTextStyles.caption.copyWith(
                    fontSize: 10.5, color: WerlogColors.coral, height: 1.4),
              )),
            ]),
          ),
        ],

        // ── "Currency changed" hint (shown when changed but not yet saved) ─
        if (selectedCurrencyCode != null && currencyChanged) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: WerlogColors.amberSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: WerlogColors.amber.withOpacity(0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline, size: 13, color: WerlogColors.amber),
              const SizedBox(width: 6),
              Text('Currency changed — tap Save to apply.',
                  style: WerlogTextStyles.caption.copyWith(
                      fontSize: 10, color: WerlogColors.amberDark)),
            ]),
          ),
        ],

        const SizedBox(height: 12),

        // Save button — hidden when currency not yet selected OR already saved
        if (!typeSaved && selectedCurrencyCode != null)
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: isSaving ? null : onSave,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 42,
                decoration: BoxDecoration(
                  color: isSaving
                      ? WerlogColors.teal.withOpacity(0.5) : WerlogColors.teal,
                  borderRadius: BorderRadius.circular(11),
                ),
                alignment: Alignment.center,
                child: isSaving
                    ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                    : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.check_circle_outline_rounded,
                      color: Colors.white, size: 15),
                  const SizedBox(width: 6),
                  Text(
                    'Save as ${selected == 'PERSONAL' ? 'Personal' : 'Business'}'
                        ' · ${selectedCurrencyCode!}',
                    style: WerlogTextStyles.button.copyWith(fontSize: 13),
                  ),
                ]),
              ),
            ),
          ),

        // Saved indicator
        if (typeSaved) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: WerlogColors.tealSurface,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: WerlogColors.teal.withOpacity(0.3)),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.check_circle_rounded,
                  color: WerlogColors.teal, size: 15),
              const SizedBox(width: 7),
              Text(
                'Saved — ${selected == 'PERSONAL' ? 'Personal' : 'Business'}'
                    '${selectedCurrencyCode != null ? ' · $selectedCurrencyCode' : ''}',
                style: WerlogTextStyles.bodySmall.copyWith(
                    fontSize: 12, color: WerlogColors.teal,
                    fontWeight: FontWeight.w500),
              ),
            ]),
          ),
        ],
      ]),
    );
  }
}

class _TypePill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color, colorBg;
  final VoidCallback onTap;

  const _TypePill({required this.label, required this.icon, required this.selected,
    required this.color, required this.colorBg, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: double.infinity,
        decoration: BoxDecoration(
          color: selected ? colorBg : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: selected ? color.withOpacity(0.3) : Colors.transparent, width: 0.8),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 14, color: selected ? color : WerlogColors.textTertiary),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(
            fontFamily: 'DMSans', fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? color : WerlogColors.textTertiary,
          )),
        ]),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// REMAINING SHARED WIDGETS  (unchanged from original)
// ─────────────────────────────────────────────────────────────────────────────

class _ConfidenceBadge extends StatelessWidget {
  final String label;
  const _ConfidenceBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    Color bg, text;
    switch (label.toUpperCase()) {
      case 'HIGH':   bg = WerlogColors.tealSurface;  text = WerlogColors.teal;  break;
      case 'MEDIUM': bg = WerlogColors.amberSurface; text = WerlogColors.amber; break;
      default:       bg = WerlogColors.coralSurface; text = WerlogColors.coral;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text('${label[0]}${label.substring(1).toLowerCase()} confidence',
          style: TextStyle(fontFamily: 'DMSans', fontSize: 10, fontWeight: FontWeight.w500, color: text)),
    );
  }
}

class _ReviewBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
    decoration: BoxDecoration(
      color: WerlogColors.amberSurface,
      border: Border.all(color: WerlogColors.amber.withOpacity(0.35)),
      borderRadius: BorderRadius.circular(11),
    ),
    child: Row(children: [
      const Icon(Icons.info_outline, color: WerlogColors.amber, size: 16),
      const SizedBox(width: 10),
      Expanded(child: Text('Some fields may need manual review — confidence is low.',
          style: WerlogTextStyles.caption.copyWith(color: WerlogColors.amberDark, height: 1.4))),
    ]),
  );
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
        color: WerlogColors.surface, border: Border.all(color: WerlogColors.border),
        borderRadius: BorderRadius.circular(13)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          child: Row(children: [
            Icon(icon, size: 14, color: WerlogColors.teal),
            const SizedBox(width: 7),
            Text(title, style: WerlogTextStyles.sectionTitle),
          ])),
      Divider(color: WerlogColors.borderLight, height: 1, thickness: 0.5),
      Padding(padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
          child: Column(children: children)),
    ]),
  );
}

class _FieldRow extends StatelessWidget {
  final String label;
  final String? value;
  final String placeholder;
  final bool isLast;
  final Color? valueColor;

  const _FieldRow({required this.label, this.value, this.placeholder = '—',
    this.isLast = false, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.isNotEmpty;
    return Column(children: [
      Padding(padding: const EdgeInsets.symmetric(vertical: 9), child: Row(children: [
        Text(label, style: WerlogTextStyles.caption),
        const Spacer(),
        Text(hasValue ? value! : placeholder, style: WerlogTextStyles.bodySmall.copyWith(
          fontSize: 12,
          fontWeight: hasValue ? FontWeight.w500 : FontWeight.w400,
          color: hasValue ? (valueColor ?? WerlogColors.textPrimary) : WerlogColors.textDisabled,
        )),
      ])),
      if (!isLast) Divider(color: WerlogColors.borderLight, height: 1, thickness: 0.5),
    ]);
  }
}

class _LineItemRow extends StatelessWidget {
  final OcrLineItem item;
  final bool isLast;
  final String currencyCode;
  const _LineItemRow({required this.item, this.isLast = false, this.currencyCode = ''});

  /// Prepends the currency code if the amount doesn't already start with it.
  // String get _displayAmount {
  //   final amt = item.amountFormatted.trim();
  //   if (amt.isEmpty) return amt;
  //   if (currencyCode.isEmpty) return amt;
  //   // Avoid doubling e.g. "PKR PKR 1730.00"
  //   if (amt.toUpperCase().startsWith(currencyCode.toUpperCase())) return amt;
  //   return '$currencyCode $amt';
  // }
  String get _displayAmount {
    var amt = item.amountFormatted.trim();
    if (amt.isEmpty) return amt;

    // Remove currency code prefix if present
    if (currencyCode.isNotEmpty) {
      amt = amt.replaceFirst(
        RegExp('^${RegExp.escape(currencyCode)}\\s*', caseSensitive: false), '',
      ).trim();
    }

    // Always strip leading currency symbols ($, €, £, ₹, Rs. etc.)
    amt = amt.replaceFirst(
      RegExp(r'^(?:[$€£¥₹₨₩₽¢]|Rs\.?|৳|₺|₴)\s*'), '',
    ).trim();

    // Return with code prefix, or bare number if no code
    if (currencyCode.isEmpty) return amt;
    return '$currencyCode $amt';
  }

  @override
  Widget build(BuildContext context) => Column(children: [
    Padding(padding: const EdgeInsets.symmetric(vertical: 9), child: Row(children: [
      const Icon(Icons.fiber_manual_record, size: 5, color: WerlogColors.textTertiary),
      const SizedBox(width: 8),
      Expanded(child: Text(item.description, style: WerlogTextStyles.bodySmall.copyWith(fontSize: 12))),
      Text(_displayAmount, style: WerlogTextStyles.bodySmall.copyWith(
          fontSize: 12, fontWeight: FontWeight.w500, color: WerlogColors.textPrimary)),
    ])),
    if (!isLast) Divider(color: WerlogColors.borderLight, height: 1, thickness: 0.5),
  ]);
}

class _PipelineStepRow extends StatelessWidget {
  final OcrCompletedStep step;
  final bool isLast;
  const _PipelineStepRow({required this.step, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    final ms = step.durationMs;
    final duration = ms >= 1000 ? '${(ms/1000).toStringAsFixed(1)}s' : '${ms}ms';
    return Column(children: [
      Padding(padding: const EdgeInsets.symmetric(vertical: 9), child: Row(children: [
        Container(width: 18, height: 18,
            decoration: const BoxDecoration(color: WerlogColors.tealSurface, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: const Icon(Icons.check, size: 10, color: WerlogColors.teal)),
        const SizedBox(width: 10),
        Expanded(child: Text(step.label, style: WerlogTextStyles.bodySmall.copyWith(fontSize: 12))),
        Text(duration, style: WerlogTextStyles.caption.copyWith(color: WerlogColors.teal)),
      ])),
      if (!isLast) Divider(color: WerlogColors.borderLight, height: 1, thickness: 0.5),
    ]);
  }
}