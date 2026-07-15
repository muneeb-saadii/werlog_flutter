// profile_segment/ocr_engines_screen.dart
//
// Fetches OCR engines from API on init and shows:
//   • Available engines (unlocked for current plan)
//   • Locked engines with required plan badge
//   • Recommended engine highlighted
//
// Does NOT expose the raw 'engine' field to users — only displayName is shown.

import 'package:flutter/material.dart';
import '../../../core/models/profile_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODEL
// ─────────────────────────────────────────────────────────────────────────────

class OcrEngine {
  final String engine; // internal, never shown in UI
  final String displayName;
  final String description;
  final int avgDurationSeconds;
  final bool supportsLineItems;
  final bool supportsWarrantyFields;
  final String? requiredPlanCode; // null = available on all plans

  const OcrEngine({
    required this.engine,
    required this.displayName,
    required this.description,
    required this.avgDurationSeconds,
    required this.supportsLineItems,
    required this.supportsWarrantyFields,
    this.requiredPlanCode,
  });

  factory OcrEngine.fromJson(Map<String, dynamic> j) => OcrEngine(
        engine: j['engine'] ?? '',
        displayName: j['displayName'] ?? '',
        description: j['description'] ?? '',
        avgDurationSeconds: j['avgDurationSeconds'] ?? 0,
        supportsLineItems: j['supportsLineItems'] ?? false,
        supportsWarrantyFields: j['supportsWarrantyFields'] ?? false,
        requiredPlanCode: j['requiredPlanCode'],
      );
}

class OcrEnginesData {
  final List<OcrEngine> available;
  final List<OcrEngine> locked;
  final String recommendedEngine; // internal key, resolved to displayName
  final String currentPlanCode;

  const OcrEnginesData({
    required this.available,
    required this.locked,
    required this.recommendedEngine,
    required this.currentPlanCode,
  });

  factory OcrEnginesData.fromJson(Map<String, dynamic> j) {
    final data = j['data'] as Map<String, dynamic>;
    return OcrEnginesData(
      available: (data['available'] as List? ?? [])
          .map((e) => OcrEngine.fromJson(e))
          .toList(),
      locked: (data['locked'] as List? ?? [])
          .map((e) => OcrEngine.fromJson(e))
          .toList(),
      recommendedEngine: data['recommended'] ?? '',
      currentPlanCode: data['currentPlanCode'] ?? 'FREE',
    );
  }

  /// Resolves the recommended engine key to its displayName.
  String get recommendedDisplayName {
    final all = [...available, ...locked];
    final match = all.where((e) => e.engine == recommendedEngine).firstOrNull;
    return match?.displayName ?? recommendedEngine;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class OcrEnginesScreen extends StatefulWidget {
  const OcrEnginesScreen({super.key});

  @override
  State<OcrEnginesScreen> createState() => _OcrEnginesScreenState();
}

class _OcrEnginesScreenState extends State<OcrEnginesScreen> {
  bool _loading = true;
  bool _error = false;
  OcrEnginesData? _data;

  @override
  void initState() {
    super.initState();
    _fetchEngines();
  }

  Future<void> _fetchEngines() async {
    setState(() { _loading = true; _error = false; });
    try {
      // ── Replace with your real API call ──────────────────────────────────
      // final response = await ApiService.get(context, Endpoints.OCR_ENGINES);
      // ────────────────────────────────────────────────────────────────────
      await Future.delayed(const Duration(milliseconds: 700)); // mock
      final response = {
        "result": "1",
        "data": {
          "available": [
            {
              "engine": "GPT4",
              "displayName": "Advanced AI",
              "description": "AI vision. Extracts line items, taxes, and warranty fields.",
              "avgDurationSeconds": 15,
              "supportsLineItems": true,
              "supportsWarrantyFields": true,
              "requiredPlanCode": null,
            }
          ],
          "locked": [
            {
              "engine": "TESSERACT",
              "displayName": "Basic",
              "description": "Fast on-device extraction. Best for simple receipts.",
              "avgDurationSeconds": 3,
              "supportsLineItems": false,
              "supportsWarrantyFields": false,
              "requiredPlanCode": "FREE",
            },
            {
              "engine": "GOOGLE_VISION",
              "displayName": "Enhanced",
              "description": "Cloud OCR with strong accuracy on real-world receipts.",
              "avgDurationSeconds": 7,
              "supportsLineItems": false,
              "supportsWarrantyFields": true,
              "requiredPlanCode": "BASIC",
            },
          ],
          "recommended": "GPT4",
          "currentPlanCode": "FREE",
        }
      };

      final ok = response['result'] == '1';
      if (ok && mounted) {
        setState(() {
          _data = OcrEnginesData.fromJson(response);
          _loading = false;
        });
      } else {
        setState(() { _loading = false; _error = true; });
      }
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = true; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WerlogColors.background,
      appBar: _WAppBar(title: 'OCR Engines'),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _loading
            ? const _LoadingState()
            : _error
                ? _ErrorState(onRetry: _fetchEngines)
                : _EnginesBody(data: _data!),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ENGINES BODY
// ─────────────────────────────────────────────────────────────────────────────

class _EnginesBody extends StatelessWidget {
  final OcrEnginesData data;
  const _EnginesBody({required this.data});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      children: [
        const SizedBox(height: 20),

        // ── Info banner ──────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: WerlogColors.tealLightSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: WerlogColors.teal.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: const BoxDecoration(
                    color: WerlogColors.tealSurface, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: const Icon(Icons.psychology_outlined,
                    size: 18, color: WerlogColors.teal),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Recommended for you',
                        style: TextStyle(
                          fontFamily: 'DMSans', fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: WerlogColors.textTertiary,
                          letterSpacing: 0.3,
                        )),
                    const SizedBox(height: 2),
                    Text(data.recommendedDisplayName,
                        style: const TextStyle(
                          fontFamily: 'DMSans', fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: WerlogColors.teal,
                        )),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: WerlogColors.tealSurface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(_planLabel(data.currentPlanCode),
                    style: const TextStyle(
                      fontFamily: 'DMSans', fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: WerlogColors.teal,
                    )),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // ── Available engines ────────────────────────────────────────────
        if (data.available.isNotEmpty) ...[
          _SectionHeader(
            icon: Icons.lock_open_rounded,
            label: 'Available on Your Plan',
            color: WerlogColors.teal,
          ),
          const SizedBox(height: 10),
          ...data.available.map((e) => _EngineCard(
                engine: e,
                isRecommended: e.engine == data.recommendedEngine,
                isLocked: false,
              )),
          const SizedBox(height: 24),
        ],

        // ── Locked engines ───────────────────────────────────────────────
        if (data.locked.isNotEmpty) ...[
          _SectionHeader(
            icon: Icons.lock_outline_rounded,
            label: 'Unlock with a Plan Upgrade',
            color: WerlogColors.amber,
          ),
          const SizedBox(height: 10),
          ...data.locked.map((e) => _EngineCard(
                engine: e,
                isRecommended: false,
                isLocked: true,
              )),
        ],
      ],
    );
  }

  String _planLabel(String code) {
    switch (code.toUpperCase()) {
      case 'PRO': return 'Pro Plan';
      case 'BASIC': return 'Basic Plan';
      default: return 'Free Plan';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ENGINE CARD
// ─────────────────────────────────────────────────────────────────────────────

class _EngineCard extends StatelessWidget {
  final OcrEngine engine;
  final bool isRecommended;
  final bool isLocked;

  const _EngineCard({
    required this.engine,
    required this.isRecommended,
    required this.isLocked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: isLocked ? WerlogColors.surfaceAlt : WerlogColors.surface,
        border: Border.all(
          color: isRecommended
              ? WerlogColors.teal.withOpacity(0.4)
              : WerlogColors.border,
          width: isRecommended ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              // Engine icon
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: isLocked
                      ? WerlogColors.border
                      : isRecommended
                          ? WerlogColors.tealSurface
                          : WerlogColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(
                  isLocked ? Icons.lock_rounded : Icons.auto_awesome_rounded,
                  size: 18,
                  color: isLocked
                      ? WerlogColors.textDisabled
                      : WerlogColors.teal,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(engine.displayName,
                          style: TextStyle(
                            fontFamily: 'DMSans', fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isLocked
                                ? WerlogColors.textDisabled
                                : WerlogColors.textPrimary,
                          )),
                      if (isRecommended) ...[
                        const SizedBox(width: 7),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: WerlogColors.tealSurface,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('Recommended',
                              style: TextStyle(
                                fontFamily: 'DMSans', fontSize: 9,
                                fontWeight: FontWeight.w500,
                                color: WerlogColors.teal,
                              )),
                        ),
                      ],
                    ]),
                    const SizedBox(height: 2),
                    Row(children: [
                      Icon(Icons.timer_outlined,
                          size: 11,
                          color: isLocked
                              ? WerlogColors.textDisabled
                              : WerlogColors.textTertiary),
                      const SizedBox(width: 3),
                      Text('~${engine.avgDurationSeconds}s avg',
                          style: TextStyle(
                            fontFamily: 'DMSans', fontSize: 11,
                            color: isLocked
                                ? WerlogColors.textDisabled
                                : WerlogColors.textTertiary,
                          )),
                    ]),
                  ],
                ),
              ),
              if (isLocked && engine.requiredPlanCode != null)
                _PlanPill(planCode: engine.requiredPlanCode!),
            ],
          ),

          const SizedBox(height: 10),

          // Description
          Text(engine.description,
              style: TextStyle(
                fontFamily: 'DMSans', fontSize: 12,
                color: isLocked
                    ? WerlogColors.textDisabled
                    : WerlogColors.textSecondary,
                height: 1.55,
              )),

          const SizedBox(height: 12),

          // Feature chips
          Row(children: [
            _FeatureChip(
              label: 'Line Items',
              supported: engine.supportsLineItems,
              isLocked: isLocked,
            ),
            const SizedBox(width: 8),
            _FeatureChip(
              label: 'Warranty Fields',
              supported: engine.supportsWarrantyFields,
              isLocked: isLocked,
            ),
          ]),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final String label;
  final bool supported;
  final bool isLocked;
  const _FeatureChip({required this.label, required this.supported, required this.isLocked});

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color textColor;
    final IconData icon;

    if (isLocked) {
      bg = WerlogColors.border;
      textColor = WerlogColors.textDisabled;
      icon = Icons.remove_rounded;
    } else if (supported) {
      bg = WerlogColors.tealSurface;
      textColor = WerlogColors.teal;
      icon = Icons.check_rounded;
    } else {
      bg = WerlogColors.surfaceAlt;
      textColor = WerlogColors.textTertiary;
      icon = Icons.close_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: textColor),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
              fontFamily: 'DMSans', fontSize: 10,
              fontWeight: FontWeight.w500,
              color: textColor,
            )),
      ]),
    );
  }
}

class _PlanPill extends StatelessWidget {
  final String planCode;
  const _PlanPill({required this.planCode});

  @override
  Widget build(BuildContext context) {
    final label = planCode == 'FREE'
        ? 'Free'
        : planCode == 'BASIC'
            ? 'Basic'
            : 'Pro';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: WerlogColors.amberSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: WerlogColors.amber.withOpacity(0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.lock_rounded, size: 9, color: WerlogColors.amber),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
              fontFamily: 'DMSans', fontSize: 10,
              fontWeight: FontWeight.w500,
              color: WerlogColors.amber,
            )),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATES
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();
  @override
  Widget build(BuildContext context) => const Center(
    child: CircularProgressIndicator(color: WerlogColors.teal),
  );
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.cloud_off_outlined,
            size: 48, color: WerlogColors.textDisabled),
        const SizedBox(height: 16),
        const Text('Could not load engines',
            style: TextStyle(
              fontFamily: 'DMSans', fontSize: 15,
              fontWeight: FontWeight.w500,
              color: WerlogColors.textPrimary,
            )),
        const SizedBox(height: 6),
        const Text('Check your connection and try again.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'DMSans', fontSize: 13,
              color: WerlogColors.textSecondary,
            )),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: onRetry,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: WerlogColors.teal,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('Try Again',
                style: TextStyle(
                  fontFamily: 'DMSans', fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                )),
          ),
        ),
      ]),
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _SectionHeader({required this.icon, required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 14, color: color),
    const SizedBox(width: 6),
    Text(label.toUpperCase(),
        style: TextStyle(
          fontFamily: 'DMSans', fontSize: 10,
          fontWeight: FontWeight.w500,
          color: color, letterSpacing: 0.6,
        )),
  ]);
}

class _WAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  const _WAppBar({required this.title});
  @override
  Size get preferredSize => const Size.fromHeight(56);
  @override
  Widget build(BuildContext context) => AppBar(
    backgroundColor: WerlogColors.background,
    elevation: 0,
    scrolledUnderElevation: 0,
    leading: GestureDetector(
      onTap: () => Navigator.pop(context),
      child: const Padding(
        padding: EdgeInsets.only(left: 16),
        child: Icon(Icons.arrow_back_ios_new_rounded,
            size: 18, color: WerlogColors.textPrimary),
      ),
    ),
    title: Text(title, style: const TextStyle(
      fontFamily: 'DMSans', fontSize: 17, fontWeight: FontWeight.w500,
      color: WerlogColors.textPrimary, letterSpacing: -0.2,
    )),
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(1),
      child: Container(color: WerlogColors.border, height: 0.5),
    ),
  );
}
