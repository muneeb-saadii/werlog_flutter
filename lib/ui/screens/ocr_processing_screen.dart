import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:wellness/core/utils/general_functions.dart';

import '../../core/api/api_service.dart';
import '../../core/api/endpoints.dart';
import '../../core/models/app_models_extended.dart';
import '../../core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODELS  (keep your existing ones — these mirror what your code uses)
// ─────────────────────────────────────────────────────────────────────────────

// enum ScanType { warranty, invoice, receipt, manual }

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
  final Map<String, dynamic> processData;     // e.g. 10

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
      // case ScanType.invoice:  return 'Reading invoice…';
      // case ScanType.receipt:  return 'Processing receipt…';
      // case ScanType.manual:   return 'Scanning manual…';
    }
  }

  static String _defaultSub(ScanType t) =>
      'Hold tight while we read your document and pull out all the key details';
}


class OcrJobResult {
  final String jobId;
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
    this.startedAt,
    this.completedAt,
    required this.completedSteps,
    required this.extracted,
  });

  factory OcrJobResult.fromJson(Map<String, dynamic> json) => OcrJobResult(
    jobId: json['jobId'] ?? '',
    status: json['status'] ?? '',
    engine: json['engine'] ?? '',
    durationMs: json['durationMs'] ?? 0,
    attemptCount: json['attemptCount'] ?? 1,
    startedAt: json['startedAt'] != null
        ? DateTime.tryParse(json['startedAt'])
        : null,
    completedAt: json['completedAt'] != null
        ? DateTime.tryParse(json['completedAt'])
        : null,
    completedSteps: (json['completedSteps'] as List? ?? [])
        .map((s) => OcrCompletedStep.fromJson(s))
        .toList(),
    extracted: OcrExtracted.fromJson(json['extracted'] ?? {}),
  );
}

class OcrCompletedStep {
  final String key;
  final String label;
  final String status;
  final int durationMs;

  OcrCompletedStep({
    required this.key,
    required this.label,
    required this.status,
    required this.durationMs,
  });

  factory OcrCompletedStep.fromJson(Map<String, dynamic> json) =>
      OcrCompletedStep(
        key: json['key'] ?? '',
        label: json['label'] ?? '',
        status: json['status'] ?? '',
        durationMs: json['durationMs'] ?? 0,
      );
}

class OcrLineItem {
  final String description;
  final String amountFormatted;

  OcrLineItem({required this.description, required this.amountFormatted});

  factory OcrLineItem.fromJson(Map<String, dynamic> json) => OcrLineItem(
    description: json['description'] ?? '',
    amountFormatted: json['amountFormatted'] ?? '',
  );
}

class OcrExtracted {
  final String? vendorName;
  final String? totalAmountFormatted;
  final String? invoiceDateFormatted;
  final int lineItemCount;
  final String confidenceLabel; // LOW | MEDIUM | HIGH
  final bool needsReview;
  final String? autoCategoryName;
  final String? autoCategoryIcon;
  final List<OcrLineItem> lineItemsPreview;

  OcrExtracted({
    this.vendorName,
    this.totalAmountFormatted,
    this.invoiceDateFormatted,
    this.lineItemCount = 0,
    required this.confidenceLabel,
    required this.needsReview,
    this.autoCategoryName,
    this.autoCategoryIcon,
    required this.lineItemsPreview,
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
        .map((i) => OcrLineItem.fromJson(i))
        .toList(),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// THEME  (mirrors WerlogColors / WerlogTextStyles / WerlogGradients)
// ─────────────────────────────────────────────────────────────────────────────

/*abstract class WerlogColors {
  static const Color background    = Color(0xFF0D1117);
  static const Color surface       = Color(0xFF111820);
  static const Color surfaceAlt    = Color(0xFF161C24);
  static const Color border        = Color(0xFF1E2B38);
  static const Color teal          = Color(0xFF2EA89E);
  static const Color tealLight     = Color(0xFF4ECDC4);
  static const Color amber         = Color(0xFFD4930A);
  static const Color textPrimary   = Color(0xFFC9D1D9);
  static const Color textSecondary = Color(0xFF7D9BA8);
  static const Color textTertiary  = Color(0xFF3D5060);
  static const Color success       = Color(0xFF2EA89E);
}*/

/*abstract class WerlogGradients {
  static LinearGradient processingBg() => const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0D1117), Color(0xFF0A1520), Color(0xFF0D1117)],
    stops: [0.0, 0.5, 1.0],
  );
  static LinearGradient successBg() => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D1117), Color(0xFF091A18), Color(0xFF0D1117)],
    stops: [0.0, 0.5, 1.0],
  );
}*/

/*abstract class WerlogTextStyles {
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 16, fontWeight: FontWeight.w600,
    color: WerlogColors.textPrimary, letterSpacing: -0.4,
  );
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12, color: WerlogColors.textSecondary,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 10, color: WerlogColors.textTertiary,
  );
}*/

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

  const OcrProcessingScreenNew({
    super.key,
    this.data,
    this.onBack,
    this.onProceed,
  });

  @override
  State<OcrProcessingScreenNew> createState() => _OcrProcessingScreenNewState();
}

class _OcrProcessingScreenNewState extends State<OcrProcessingScreenNew>
    with TickerProviderStateMixin {

  // ── Ring spin controllers ──────────────────────────────────────────────────
  late final AnimationController _ring1;  // outer ring, continuous CW
  late final AnimationController _ring2;  // inner ring, continuous CCW

  // ── Scan-line (doc icon) ───────────────────────────────────────────────────
  late final AnimationController _scanCtrl;
  late final Animation<double> _scanAnim;

  // ── Pulse for the orbit dots ───────────────────────────────────────────────
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  // ── Countdown ─────────────────────────────────────────────────────────────
  late int _totalSeconds;
  late int _remainingSeconds;
  Timer? _countdownTimer;

  // ── Step state (0-3) ──────────────────────────────────────────────────────
  // index 0 starts as "done", 1 as "active", 2-3 as "pending"
  late List<ProcessingStepStatus> _stepStatus;
  late List<String?> _stepDurations;
  late List<DateTime> _stepStartTimes;

  // ── Completion ────────────────────────────────────────────────────────────
  bool _isComplete = false;

  // ── Success-screen animations ─────────────────────────────────────────────
  late final AnimationController _checkCircleCtrl;
  late final AnimationController _checkMarkCtrl;
  late final AnimationController _burstCtrl;
  late final AnimationController _successFadeCtrl;

  // ─────────────────────────────────────────────────────────────────────────
  bool _isLoadingResult = false;
  OcrJobResult? _jobResult;
  OcrProcessingDataNew get _data =>
      widget.data ?? OcrProcessingDataNew(scanType: ScanType.warranty);

  @override
  void initState() {
    super.initState();

    _totalSeconds    = int.tryParse(_data.processData['estimatedSeconds'].toString()) ?? 25;
    _totalSeconds    += 5;
    _remainingSeconds = _totalSeconds;

    // Seed step states from the data model
    _stepStatus = _data.steps
        .map((s) => s.status)
        .toList();
    _stepDurations = _data.steps.map((s) => s.duration).toList();
    _stepStartTimes = List.filled(_data.steps.length, DateTime.now());

    // ── Ring controllers ────────────────────────────────────────────────────
    _ring1 = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat();

    _ring2 = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat();   // intentionally NOT reverse — we negate angle in painter

    // ── Scan line ──────────────────────────────────────────────────────────
    _scanCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _scanAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _scanCtrl, curve: Curves.easeInOut));

    // ── Pulse ──────────────────────────────────────────────────────────────
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    // ── Success controllers (not started yet) ──────────────────────────────
    _checkCircleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _checkMarkCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _burstCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _successFadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));

    // ── Start countdown ────────────────────────────────────────────────────
    _startCountdown();
  }

  // ── Countdown logic ────────────────────────────────────────────────────────
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

    // Step milestones: 0=done from start, 1 active→done at 35%, 2 at 60%, 3 at 82%
    if (pct >= 0.35 && _stepStatus[1] == ProcessingStepStatus.active) {
      _completeStep(1);
      _activateStep(2);
    }
    if (pct >= 0.60 && _stepStatus[2] == ProcessingStepStatus.active) {
      _completeStep(2);
      _activateStep(3);
    }
  }

  void _activateStep(int i) {
    if (i < _stepStatus.length) {
      _stepStatus[i] = ProcessingStepStatus.active;
      _stepStartTimes[i] = DateTime.now();
    }
  }

  void _completeStep(int i) {
    if (i < _stepStatus.length) {
      _stepStatus[i] = ProcessingStepStatus.done;
      final elapsed = DateTime.now().difference(_stepStartTimes[i]);
      _stepDurations[i] = '${(elapsed.inMilliseconds / 1000).toStringAsFixed(1)}s';
    }
  }

  void _completeLastStep() {
    // Mark the remaining active/pending steps as done
    for (int i = 0; i < _stepStatus.length; i++) {
      if (_stepStatus[i] != ProcessingStepStatus.done) {
        _completeStep(i);
      }
    }
  }

  void _triggerComplete() async {
    // Stop processing animations
    _ring1.stop();
    _ring2.stop();
    _scanCtrl.stop();
    _pulseCtrl.stop();

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() => _isComplete = true);

    // Sequence: circle draw → checkmark draw → burst → fade in text
    await _checkCircleCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 80));
    await _checkMarkCtrl.forward();
    _burstCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _successFadeCtrl.forward();
  }


  // ── API call ───────────────────────────────────────────────────────────
  Future<void> _getOcrJobDetails() async {
    setState(() => _isLoadingResult = true);
    try {
      // ── Replace with your actual call: ────────────────────────────────
      final response = await ApiService.get(
        context,
        "${Endpoints.SCANNED_OCR_JOB_DETAILS}${_data.processData['jobId']}",
        showLoader: false
      );
      // ── Mock for wiring / preview: ────────────────────────────────────
      /*await Future.delayed(const Duration(milliseconds: 900));
      final response = {
        "result": "1",
        "data": {
          "jobId": "58281bba-cd91-4931-8eb1-32021bbe0df5",
          "status": "COMPLETED",
          "engine": "GPT4",
          "durationMs": 6378,
          "attemptCount": 1,
          "startedAt": "2026-05-13T17:28:46.908245Z",
          "completedAt": "2026-05-13T17:28:53.286656Z",
          "completedSteps": [
            {"key": "uploaded",     "label": "Uploaded securely", "status": "DONE", "durationMs": 400},
            {"key": "preprocessed", "label": "Image enhanced",    "status": "DONE", "durationMs": 900},
            {"key": "extracted",    "label": "Text extracted",    "status": "DONE", "durationMs": 5078},
            {"key": "parsed",       "label": "Fields parsed",     "status": "DONE", "durationMs": 200},
            {"key": "saved",        "label": "Saved to library",  "status": "DONE", "durationMs": 100},
          ],
          "extracted": {
            "vendorName": null,
            "totalAmountFormatted": null,
            "invoiceDateFormatted": null,
            "lineItemCount": 0,
            "confidenceLabel": "LOW",
            "needsReview": true,
            "autoCategoryName": null,
            "autoCategoryIcon": null,
            "lineItemsPreview": [
              {"description": "string", "amountFormatted": "string"}
            ],
          }
        }
      };*/
      // ─────────────────────────────────────────────────────────────────

      final ok = response['result'] == "1";
      if (ok) {
        final result = OcrJobResult.fromJson(
            response['data'] as Map<String, dynamic>);
        setState(() {
          _jobResult = result;
          _isLoadingResult = false;
        });
        // Open result sheet
        if (mounted) _showResultSheet(result);
      } else {
        setState(() => _isLoadingResult = false);
        if (mounted) {
          _showErrorSnack(
              (response['message'] ?? 'Something went wrong').toString());
        }
      }
    } catch (e) {
      setState(() => _isLoadingResult = false);
      if (mounted) {
        _showErrorSnack('Process interrupted. Please try again!');
      }
    }
  }

  void _showResultSheet(OcrJobResult result) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OcrResultSheet(
        result: result,
        onDone: () {
          // Pop the sheet + all screens back to dashboard
          // Navigator.of(context).pop();
          GeneralFunctions.resetAppState();
        },
      ),
    );
  }

  void _showErrorSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(fontFamily: 'DMSans', fontSize: 13)),
      backgroundColor: WerlogColors.coral,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }


  @override
  void dispose() {
    _ring1.dispose();
    _ring2.dispose();
    _scanCtrl.dispose();
    _pulseCtrl.dispose();
    _checkCircleCtrl.dispose();
    _checkMarkCtrl.dispose();
    _burstCtrl.dispose();
    _successFadeCtrl.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  String get _countdownLabel {
    final m = _remainingSeconds ~/ 60;
    final s = _remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double get _countdownProgress =>
      _totalSeconds > 0 ? _remainingSeconds / _totalSeconds : 0.0;

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WerlogColors.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: _isComplete
              ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              WerlogColors.background,
              WerlogColors.tealLightSurface,
              WerlogColors.background,
            ],
          )
              : LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              WerlogColors.background,
              WerlogColors.tealLightSurface,
              WerlogColors.background,
            ],
          ),
        ),
        child: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (child, anim) =>
                FadeTransition(opacity: anim, child: child),
            child: _isComplete
                ? _SuccessView(
                    key: const ValueKey('success'),
                    data: _data,
                    checkCircleCtrl: _checkCircleCtrl,
                    checkMarkCtrl: _checkMarkCtrl,
                    burstCtrl: _burstCtrl,
                    fadeCtrl: _successFadeCtrl,
                    isLoading: _isLoadingResult,
                    onViewData: _getOcrJobDetails,
                  )
                : _ProcessingView(
                    key: const ValueKey('processing'),
                    data: _data,
                    ring1: _ring1,
                    ring2: _ring2,
                    scanAnim: _scanAnim,
                    pulseAnim: _pulseAnim,
                    countdownLabel: _countdownLabel,
                    countdownProgress: _countdownProgress,
                    stepStatus: _stepStatus,
                    stepDurations: _stepDurations,
                    onBack: widget.onBack,
                  ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROCESSING VIEW
// ─────────────────────────────────────────────────────────────────────────────

class _ProcessingView extends StatelessWidget {
  final OcrProcessingDataNew data;
  final AnimationController ring1;
  final AnimationController ring2;
  final Animation<double> scanAnim;
  final Animation<double> pulseAnim;
  final String countdownLabel;
  final double countdownProgress;
  final List<ProcessingStepStatus> stepStatus;
  final List<String?> stepDurations;
  final VoidCallback? onBack;

  const _ProcessingView({
    super.key,
    required this.data,
    required this.ring1,
    required this.ring2,
    required this.scanAnim,
    required this.pulseAnim,
    required this.countdownLabel,
    required this.countdownProgress,
    required this.stepStatus,
    required this.stepDurations,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // const FakeStatusBar(),
        // Back button
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
          child: GestureDetector(
            onTap: onBack,
            child: const Text('‹',
                style: TextStyle(fontSize: 28, color: WerlogColors.textPrimary)),
          ),
        ),

        // Central animation zone
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _AnimatedOrbit(
                ring1: ring1,
                ring2: ring2,
                scanAnim: scanAnim,
                pulseAnim: pulseAnim,
              ),
              const SizedBox(height: 22),
              Text(data.headlineText,
                  style: WerlogTextStyles.sectionTitle
                      .copyWith(fontSize: 15, letterSpacing: -0.3)),
              const SizedBox(height: 5),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(data.subText,
                    textAlign: TextAlign.center,
                    style: WerlogTextStyles.bodySmall),
              ),
              const SizedBox(height: 22),
              // Countdown row
              _CountdownWidget(
                label: countdownLabel,
                progress: countdownProgress,
              ),
            ],
          ),
        ),

        // Steps card
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
                label: data.steps[i].label,
                status: stepStatus[i],
                duration: stepDurations[i],
              )),
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ANIMATED ORBIT  (the spinning rings + doc + scan line + orbit dots)
// ─────────────────────────────────────────────────────────────────────────────

class _AnimatedOrbit extends StatelessWidget {
  final AnimationController ring1;
  final AnimationController ring2;
  final Animation<double> scanAnim;
  final Animation<double> pulseAnim;

  const _AnimatedOrbit({
    required this.ring1,
    required this.ring2,
    required this.scanAnim,
    required this.pulseAnim,
  });

  @override
  Widget build(BuildContext context) {
    const size = 148.0;
    return SizedBox(
      width: size, height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ── Outer ring (teal, CW) ──
          AnimatedBuilder(
            animation: ring1,
            builder: (_, __) => CustomPaint(
              size: const Size(size, size),
              painter: _RingArcPainter(
                progress: ring1.value,
                color: WerlogColors.teal,
                radius: size / 2 - 4,
                strokeWidth: 2.5,
                arcFraction: 0.75,
                dotRadius: 4.5,
                clockwise: true,
              ),
            ),
          ),

          // ── Inner ring (amber, CCW) ──
          AnimatedBuilder(
            animation: ring2,
            builder: (_, __) => CustomPaint(
              size: const Size(size - 28, size - 28),
              painter: _RingArcPainter(
                progress: ring2.value,
                color: WerlogColors.amber.withOpacity(0.7),
                radius: (size - 28) / 2 - 3,
                strokeWidth: 2.0,
                arcFraction: 0.6,
                dotRadius: 3.5,
                clockwise: false,
              ),
            ),
          ),

          // ── Doc icon with scan line ──
          AnimatedBuilder(
            animation: scanAnim,
            builder: (_, __) => _DocIconWithScan(scanProgress: scanAnim.value),
          ),

          // ── Orbit pulse dot (outer) ──
          AnimatedBuilder(
            animation: Listenable.merge([ring1, pulseAnim]),
            builder: (_, __) {
              final angle = ring1.value * 2 * math.pi - math.pi / 2;
              final r = size / 2 - 4;
              final cx = size / 2 + r * math.cos(angle);
              final cy = size / 2 + r * math.sin(angle);
              return Positioned(
                left: cx - 5,
                top: cy - 5,
                child: Opacity(
                  opacity: pulseAnim.value,
                  child: Container(
                    width: 10, height: 10,
                    decoration: const BoxDecoration(
                      color: WerlogColors.teal,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            },
          ),

          // ── Orbit pulse dot (inner, offset) ──
          AnimatedBuilder(
            animation: Listenable.merge([ring2, pulseAnim]),
            builder: (_, __) {
              // offset by 180° from ring2 direction
              final angle = -(ring2.value * 2 * math.pi) + math.pi - math.pi / 2;
              final r = (size - 28) / 2 - 3;
              final cx = size / 2 + r * math.cos(angle);
              final cy = size / 2 + r * math.sin(angle);
              return Positioned(
                left: cx - 4,
                top: cy - 4,
                child: Opacity(
                  opacity: 1.0 - (pulseAnim.value - 0.4) / 0.6,
                  child: Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      color: WerlogColors.amber.withOpacity(0.8),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RING ARC PAINTER  — draws a partial arc + leading dot, properly rotating
// ─────────────────────────────────────────────────────────────────────────────

class _RingArcPainter extends CustomPainter {
  final double progress;   // 0..1
  final Color color;
  final double radius;
  final double strokeWidth;
  final double arcFraction; // 0..1 how much of the circle is filled
  final double dotRadius;
  final bool clockwise;

  const _RingArcPainter({
    required this.progress,
    required this.color,
    required this.radius,
    required this.strokeWidth,
    required this.arcFraction,
    required this.dotRadius,
    required this.clockwise,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Track
    final trackPaint = Paint()
      ..color = color.withOpacity(0.12)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, trackPaint);

    // Arc
    final arcPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final baseAngle = -math.pi / 2;
    final rotateAngle = (clockwise ? 1 : -1) * progress * 2 * math.pi;
    final startAngle = baseAngle + rotateAngle;
    final sweepAngle = (clockwise ? 1 : -1) * 2 * math.pi * arcFraction;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      arcPaint,
    );

    // Leading dot
    final dotAngle = startAngle + sweepAngle;
    final dotX = center.dx + radius * math.cos(dotAngle);
    final dotY = center.dy + radius * math.sin(dotAngle);
    final dotPaint = Paint()..color = color;
    canvas.drawCircle(Offset(dotX, dotY), dotRadius, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _RingArcPainter old) =>
      old.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// DOC ICON WITH SCAN LINE
// ─────────────────────────────────────────────────────────────────────────────

class _DocIconWithScan extends StatelessWidget {
  final double scanProgress; // 0..1
  const _DocIconWithScan({required this.scanProgress});

  @override
  Widget build(BuildContext context) {
    const docW = 44.0, docH = 56.0;
    return SizedBox(
      width: docW, height: docH,
      child: Stack(
        children: [
          Container(
            width: docW, height: docH,
            decoration: BoxDecoration(
              color: WerlogColors.surface,//Alt,
              border: Border.all(color: WerlogColors.border),
              borderRadius: BorderRadius.circular(4),
            ),
            padding: const EdgeInsets.all(5),
            child: Column(
              children: List.generate(5, (i) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: WerlogColors.border,
                    borderRadius: BorderRadius.circular(1),
                  ),
                  width: i % 2 == 0 ? double.infinity : 22,
                ),
              )),
            ),
          ),
          // Scan line
          Positioned(
            top: scanProgress * (docH - 2),
            left: 0, right: 0,
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    WerlogColors.teal.withOpacity(0.6),
                    WerlogColors.teal,
                    WerlogColors.teal.withOpacity(0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COUNTDOWN WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class _CountdownWidget extends StatelessWidget {
  final String label;
  final double progress; // 1.0 → 0.0

  const _CountdownWidget({required this.label, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 50, height: 50,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(50, 50),
                painter: _CountdownRingPainter(progress: progress),
              ),
              Text(label,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: WerlogColors.teal,
                  )),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text('estimated time remaining',
            style: WerlogTextStyles.caption.copyWith(fontSize: 11))//TextStyle(fontSize: 11, color: WerlogColors.textTertiary)),
      ],
    );
  }
}

class _CountdownRingPainter extends CustomPainter {
  final double progress; // 1.0 full → 0.0 empty
  const _CountdownRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const radius = 22.0;

    // Track
    canvas.drawCircle(center, radius,
        Paint()
          ..color = WerlogColors.border
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke);

    // Fill arc (drains from full to empty)
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..color = WerlogColors.teal
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CountdownRingPainter old) =>
      old.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP ROW  (used in processing view)
// ─────────────────────────────────────────────────────────────────────────────

class _StepRow extends StatelessWidget {
  final String label;
  final ProcessingStepStatus status;
  final String? duration;

  const _StepRow({
    required this.label,
    required this.status,
    this.duration,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          _StepDot(status: status),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: WerlogTextStyles.bodySmall.copyWith(
                  fontSize: 11,
                  color: status == ProcessingStepStatus.pending
                      ? WerlogColors.textTertiary
                      : WerlogColors.textSecondary,
                )),
          ),
          if (duration != null)
            Text(duration!,
                style: WerlogTextStyles.caption.copyWith(
                  color: status == ProcessingStepStatus.done
                      ? WerlogColors.teal
                      : WerlogColors.textTertiary,
                )),
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
              style: TextStyle(color: WerlogColors.teal, fontSize: 10, height: 1)),
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
                  color: WerlogColors.textTertiary, fontSize: 9, height: 1)),
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SUCCESS VIEW
// ─────────────────────────────────────────────────────────────────────────────

class _SuccessView extends StatelessWidget {
  final OcrProcessingDataNew data;
  final AnimationController checkCircleCtrl;
  final AnimationController checkMarkCtrl;
  final AnimationController burstCtrl;
  final AnimationController fadeCtrl;
  final bool isLoading;
  final VoidCallback onViewData;


  const _SuccessView({
    super.key,
    required this.data,
    required this.checkCircleCtrl,
    required this.checkMarkCtrl,
    required this.burstCtrl,
    required this.fadeCtrl,
    required this.isLoading,
    required this.onViewData,
  });

  @override
  Widget build(BuildContext context) {
    final circleTween = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: checkCircleCtrl, curve: Curves.easeOut));
    final markTween = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: checkMarkCtrl, curve: Curves.easeOut));
    final burstTween = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: burstCtrl, curve: Curves.easeOut));
    final fadeTween = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: fadeCtrl, curve: Curves.easeOut));
    final slideOffsetTween = Tween<Offset>(
        begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: fadeCtrl, curve: Curves.easeOut));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // const FakeStatusBar(),
        const SizedBox(height: 8),

        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Animated check circle + burst ──
              SizedBox(
                width: 96, height: 96,
                child: AnimatedBuilder(
                  animation: Listenable.merge(
                      [checkCircleCtrl, checkMarkCtrl, burstCtrl]),
                  builder: (_, __) => CustomPaint(
                    painter: _SuccessCheckPainter(
                      circleProgress: circleTween.value,
                      markProgress: markTween.value,
                      burstProgress: burstTween.value,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Headline + subtitle ──
              SlideTransition(
                position: slideOffsetTween,
                child: FadeTransition(
                  opacity: fadeTween,
                  child: Column(
                    children: [
                      const Text('Scan Complete!',
                          style: TextStyle(
                            fontFamily: 'DMSans',
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: WerlogColors.textPrimary,
                            letterSpacing: -0.5,
                          )),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 44),
                        child: Text(
                          // 'Your document has been processed.\nTap below to view the extracted details.',
                          'Your ${_scanTypeLabel(data.scanType)} details have been extracted and saved to your log.',
                          textAlign: TextAlign.center,
                          style: WerlogTextStyles.bodySmall
                              .copyWith(fontSize: 12, height: 1.55),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Quota card ──
              if (data.processData['remainingQuota'] != null) ...[
                const SizedBox(height: 28),
                SlideTransition(
                  position: slideOffsetTween,
                  child: FadeTransition(
                    opacity: fadeTween,
                    child: _QuotaCard(
                      remaining: data.processData['remainingQuota'],
                      total: data.processData['totalQuota'] ?? data.processData['remainingQuota'],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // ── Proceed button ──
        FadeTransition(
          opacity: fadeTween,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
            child: _WerlogButton(
              label: isLoading ? 'Loading…' : 'View Extracted Data',
              isLoading: isLoading,
              onTap: isLoading ? null : onViewData,
            ),
          ),
        ),
      ],
    );
  }

  String _scanTypeLabel(ScanType t) {
    switch (t) {
      case ScanType.warranty: return 'invoice';
      case ScanType.expense:  return 'receipt';
      // case ScanType.invoice:  return 'invoice';
      // case ScanType.receipt:  return 'receipt';
      // case ScanType.manual:   return 'manual';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SUCCESS CHECK PAINTER
// ─────────────────────────────────────────────────────────────────────────────

class _SuccessCheckPainter extends CustomPainter {
  final double circleProgress;
  final double markProgress;
  final double burstProgress;

  const _SuccessCheckPainter({
    required this.circleProgress,
    required this.markProgress,
    required this.burstProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 5;

    // Glow fill
    if (circleProgress > 0) {
      canvas.drawCircle(center, r,
          Paint()..color = WerlogColors.teal.withOpacity(0.10 * circleProgress));
    }

    // Circle outline
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r),
      -math.pi / 2,
      2 * math.pi * circleProgress,
      false,
      Paint()
        ..color = WerlogColors.teal
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Checkmark (path-length animation)
    if (markProgress > 0) {
      final path = Path()
        ..moveTo(center.dx - 18, center.dy)
        ..lineTo(center.dx - 5, center.dy + 13)
        ..lineTo(center.dx + 18, center.dy - 13);

      final pathMetrics = path.computeMetrics().first;
      final extractPath = pathMetrics.extractPath(
          0, pathMetrics.length * markProgress);

      canvas.drawPath(
          extractPath,
          Paint()
            ..color = WerlogColors.teal
            ..strokeWidth = 3.0
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round);
    }

    // Burst lines (8 directions, fade out)
    if (burstProgress > 0) {
      final burstOpacity = (1.0 - burstProgress).clamp(0.0, 1.0);
      final burstPaint = Paint()
        ..color = WerlogColors.teal.withOpacity(burstOpacity * 0.7)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;

      for (int i = 0; i < 8; i++) {
        final angle = i * math.pi / 4;
        final innerR = r + 4 + burstProgress * 6;
        final outerR = r + 10 + burstProgress * 10;
        canvas.drawLine(
          Offset(center.dx + innerR * math.cos(angle),
              center.dy + innerR * math.sin(angle)),
          Offset(center.dx + outerR * math.cos(angle),
              center.dy + outerR * math.sin(angle)),
          burstPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SuccessCheckPainter old) =>
      old.circleProgress != circleProgress ||
      old.markProgress != markProgress ||
      old.burstProgress != burstProgress;
}

// ─────────────────────────────────────────────────────────────────────────────
// QUOTA CARD
// ─────────────────────────────────────────────────────────────────────────────

class _QuotaCard extends StatelessWidget {
  final int remaining;
  final int total;
  const _QuotaCard({required this.remaining, required this.total});

  @override
  Widget build(BuildContext context) {
    final fraction = total > 0 ? remaining / total : 0.0;
    final isLow = fraction < 0.3;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: WerlogColors.surface,
          border: Border.all(
            color: isLow
                ? WerlogColors.amber.withOpacity(0.5)
                : WerlogColors.border,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Monthly quota',
                    style: WerlogTextStyles.caption
                        .copyWith(fontSize: 10, color: WerlogColors.textTertiary)),
                Text('$remaining / $total scans left',
                    style: WerlogTextStyles.caption.copyWith(
                      fontSize: 10,
                      color: isLow ? WerlogColors.amber : WerlogColors.teal,
                    )),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 5,
                backgroundColor: WerlogColors.border,
                color: isLow ? WerlogColors.amber : WerlogColors.teal,
              ),
            ),
            if (isLow) ...[
              const SizedBox(height: 6),
              Text('Running low — consider upgrading your plan.',
                  style: WerlogTextStyles.caption
                      .copyWith(fontSize: 9, color: WerlogColors.amber)),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WERLOG BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class _WerlogButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  const _WerlogButton({required this.label, this.onTap, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 50,
        decoration: BoxDecoration(
          color: onTap == null
              ? WerlogColors.teal.withOpacity(0.5)
              : WerlogColors.teal,
          borderRadius: BorderRadius.circular(13),
        ),
        alignment: Alignment.center,
        child: isLoading
            ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
                color: Colors.white, strokeWidth: 2))
            : Text(label, style: WerlogTextStyles.button),
      ),
    );
  }
}




// ─────────────────────────────────────────────────────────────────────────────
// OCR RESULT BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _OcrResultSheet extends StatelessWidget {
  final OcrJobResult result;
  final VoidCallback onDone;

  const _OcrResultSheet({required this.result, required this.onDone});

  @override
  Widget build(BuildContext context) {
    final ext = result.extracted;
    final totalMs = result.durationMs;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: WerlogColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // ── Drag handle ──
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: WerlogColors.border,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),

            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                        color: WerlogColors.tealSurface,
                        borderRadius: BorderRadius.circular(10)),
                    alignment: Alignment.center,
                    child: const Icon(Icons.description_outlined,
                        color: WerlogColors.teal, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Extracted Details',
                            style: WerlogTextStyles.sectionTitle
                                .copyWith(fontSize: 15)),
                        const SizedBox(height: 1),
                        Text(
                            'Processed in ${(totalMs / 1000).toStringAsFixed(1)}s · ${result.engine}',
                            style: WerlogTextStyles.caption),
                      ],
                    ),
                  ),
                  // Confidence badge
                  _ConfidenceBadge(label: ext.confidenceLabel),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Divider(color: WerlogColors.border, height: 1, thickness: 0.5),

            // ── Scrollable body ──
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  // Needs-review banner
                  if (ext.needsReview)
                    _ReviewBanner(),

                  if (ext.needsReview) const SizedBox(height: 14),

                  // ── Extracted fields card ──
                  _SectionCard(
                    title: 'Document Info',
                    icon: Icons.receipt_long_outlined,
                    children: [
                      _FieldRow(
                          label: 'Vendor',
                          value: ext.vendorName,
                          placeholder: 'Not detected'),
                      _FieldRow(
                          label: 'Total Amount',
                          value: ext.totalAmountFormatted,
                          placeholder: 'Not detected',
                          valueColor: ext.totalAmountFormatted != null
                              ? WerlogColors.teal
                              : null),
                      _FieldRow(
                          label: 'Invoice Date',
                          value: ext.invoiceDateFormatted,
                          placeholder: 'Not detected'),
                      _FieldRow(
                          label: 'Category',
                          value: ext.autoCategoryName,
                          placeholder: 'Uncategorized'),
                      _FieldRow(
                          label: 'Line Items',
                          value: '${ext.lineItemCount}',
                          isLast: true),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ── Line items preview ──
                  if (ext.lineItemsPreview.isNotEmpty)
                    _SectionCard(
                      title: 'Line Items Preview',
                      icon: Icons.list_alt_outlined,
                      children: [
                        ...ext.lineItemsPreview
                            .asMap()
                            .entries
                            .map((e) => _LineItemRow(
                          item: e.value,
                          isLast:
                          e.key == ext.lineItemsPreview.length - 1,
                        )),
                      ],
                    ),
                  if (ext.lineItemsPreview.isNotEmpty) const SizedBox(height: 14),

                  // ── Processing steps ──
                  _SectionCard(
                    title: 'Processing Pipeline',
                    icon: Icons.bolt_outlined,
                    children: [
                      ...result.completedSteps.asMap().entries.map((e) =>
                          _PipelineStepRow(
                            step: e.value,
                            isLast:
                            e.key == result.completedSteps.length - 1,
                          )),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Done button ──
                  GestureDetector(
                    onTap: onDone,
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                          color: WerlogColors.teal,
                          borderRadius: BorderRadius.circular(13)),
                      alignment: Alignment.center,
                      child: Text('Done — Back to Dashboard',
                          style: WerlogTextStyles.button),
                    ),
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

// ── Confidence badge ──────────────────────────────────────────────────────────

class _ConfidenceBadge extends StatelessWidget {
  final String label; // LOW | MEDIUM | HIGH
  const _ConfidenceBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    Color bg, text;
    switch (label.toUpperCase()) {
      case 'HIGH':
        bg = WerlogColors.tealSurface;
        text = WerlogColors.teal;
        break;
      case 'MEDIUM':
        bg = WerlogColors.amberSurface;
        text = WerlogColors.amber;
        break;
      default:
        bg = WerlogColors.coralSurface;
        text = WerlogColors.coral;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        '${label[0]}${label.substring(1).toLowerCase()} confidence',
        style: TextStyle(
            fontFamily: 'DMSans',
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: text),
      ),
    );
  }
}

// ── Needs-review banner ───────────────────────────────────────────────────────

class _ReviewBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: WerlogColors.amberSurface,
        border: Border.all(color: WerlogColors.amber.withOpacity(0.35)),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline,
              color: WerlogColors.amber, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Some fields may need manual review — confidence is low.',
              style: WerlogTextStyles.caption.copyWith(
                  color: WerlogColors.amberDark, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section card ─────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard(
      {required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: WerlogColors.surface,
        border: Border.all(color: WerlogColors.border),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                Icon(icon, size: 14, color: WerlogColors.teal),
                const SizedBox(width: 7),
                Text(title, style: WerlogTextStyles.sectionTitle),
              ],
            ),
          ),
          Divider(
              color: WerlogColors.borderLight,
              height: 1,
              thickness: 0.5),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

// ── Field row ─────────────────────────────────────────────────────────────────

class _FieldRow extends StatelessWidget {
  final String label;
  final String? value;
  final String placeholder;
  final bool isLast;
  final Color? valueColor;

  const _FieldRow({
    required this.label,
    this.value,
    this.placeholder = '—',
    this.isLast = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.isNotEmpty;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            children: [
              Text(label, style: WerlogTextStyles.caption),
              const Spacer(),
              Text(
                hasValue ? value! : placeholder,
                style: WerlogTextStyles.bodySmall.copyWith(
                  fontSize: 12,
                  fontWeight:
                  hasValue ? FontWeight.w500 : FontWeight.w400,
                  color: hasValue
                      ? (valueColor ?? WerlogColors.textPrimary)
                      : WerlogColors.textDisabled,
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
              color: WerlogColors.borderLight,
              height: 1,
              thickness: 0.5),
      ],
    );
  }
}

// ── Line item row ─────────────────────────────────────────────────────────────

class _LineItemRow extends StatelessWidget {
  final OcrLineItem item;
  final bool isLast;
  const _LineItemRow({required this.item, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            children: [
              const Icon(Icons.fiber_manual_record,
                  size: 5, color: WerlogColors.textTertiary),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(item.description,
                      style: WerlogTextStyles.bodySmall
                          .copyWith(fontSize: 12))),
              Text(item.amountFormatted,
                  style: WerlogTextStyles.bodySmall.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: WerlogColors.textPrimary)),
            ],
          ),
        ),
        if (!isLast)
          Divider(
              color: WerlogColors.borderLight,
              height: 1,
              thickness: 0.5),
      ],
    );
  }
}

// ── Pipeline step row ─────────────────────────────────────────────────────────

class _PipelineStepRow extends StatelessWidget {
  final OcrCompletedStep step;
  final bool isLast;
  const _PipelineStepRow({required this.step, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    final ms = step.durationMs;
    final duration = ms >= 1000
        ? '${(ms / 1000).toStringAsFixed(1)}s'
        : '${ms}ms';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                    color: WerlogColors.tealSurface,
                    shape: BoxShape.circle),
                alignment: Alignment.center,
                child: const Icon(Icons.check,
                    size: 10, color: WerlogColors.teal),
              ),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(step.label,
                      style: WerlogTextStyles.bodySmall
                          .copyWith(fontSize: 12))),
              Text(duration,
                  style: WerlogTextStyles.caption
                      .copyWith(color: WerlogColors.teal)),
            ],
          ),
        ),
        if (!isLast)
          Divider(
              color: WerlogColors.borderLight,
              height: 1,
              thickness: 0.5),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Expose WerlogColors.amberDark for use in this file
// (already defined in your theme — this reference just confirms it exists)
// ─────────────────────────────────────────────────────────────────────────────
// WerlogColors.amberDark = Color(0xFF854F0B)  ✓