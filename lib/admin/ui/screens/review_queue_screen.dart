import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class ReviewItem {
  final String id;
  final String itemName;
  final String aiCategory;
  final String vendor;
  final double confidence;
  final List<String> flags;      // e.g. ['fallback', 'exact→fuzzy→miss']
  final List<String> suggestions; // suggested reclassification options

  const ReviewItem({
    required this.id,
    required this.itemName,
    required this.aiCategory,
    required this.vendor,
    required this.confidence,
    required this.flags,
    required this.suggestions,
  });

  bool get isLowConfidence => confidence < 0.5;
}

// ── Mock data ─────────────────────────────────────────────────────────────────

final _mockItems = [
  const ReviewItem(
    id: '1', itemName: '"LAPTOP GAMING ASUS"',
    aiCategory: 'Electronics', vendor: 'Canada Computers',
    confidence: 0.42,
    flags: ['fallback', 'exact→fuzzy→miss'],
    suggestions: ['Equipment › Computers & laptops', 'Electronics', 'Office Supplies'],
  ),
  const ReviewItem(
    id: '2', itemName: '"MONTHLY SUBSCRIPTION"',
    aiCategory: 'Services', vendor: 'Adobe Inc.',
    confidence: 0.61,
    flags: ['low confidence'],
    suggestions: ['Software & Subscriptions', 'Services', 'Office & Admin'],
  ),
];

// ── Screen ────────────────────────────────────────────────────────────────────

class ReviewQueueScreen extends StatefulWidget {
  const ReviewQueueScreen({super.key});

  @override
  State<ReviewQueueScreen> createState() => _ReviewQueueScreenState();
}

class _ReviewQueueScreenState extends State<ReviewQueueScreen> {
  final Map<String, String?> _selections = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          _ReviewHeader(count: _mockItems.length),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                  AppMetrics.pagePadding, 16,
                  AppMetrics.pagePadding, 40),
              itemCount: _mockItems.length,
              itemBuilder: (_, i) {
                final item = _mockItems[i];
                return _ReviewCard(
                  item: item,
                  selected: _selections[item.id] ?? item.suggestions.first,
                  onChanged: (v) => setState(
                      () => _selections[item.id] = v),
                  onSkip: () {},
                  onReclassify: () => _reclassify(item),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }

  void _reclassify(ReviewItem item) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Reclassified ${item.itemName} + learning saved'),
      backgroundColor: AppColors.accentGreen,
      duration: const Duration(seconds: 2),
    ));
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _ReviewHeader extends StatelessWidget {
  final int count;
  const _ReviewHeader({required this.count});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    decoration: const BoxDecoration(
      color: AppColors.darkGreen,
      borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppMetrics.headerRadius)),
    ),
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      GestureDetector(
        onTap: () => Navigator.pop(context),
        child: const Icon(Icons.chevron_left,
            color: AppColors.textOnDark, size: 26),
      ),
      const SizedBox(width: 8),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Review queue', style: AppTextStyles.headerTitle),
          const SizedBox(height: 4),
          Text('$count low-confidence classifications',
              style: AppTextStyles.headerSubtitle),
        ],
      )),
      _CircleAction(icon: Icons.settings_rounded, onTap: () {}),
    ]),
  );
}

// ── Review card ───────────────────────────────────────────────────────────────

class _ReviewCard extends StatelessWidget {
  final ReviewItem item;
  final String selected;
  final ValueChanged<String?> onChanged;
  final VoidCallback onSkip;
  final VoidCallback onReclassify;
  const _ReviewCard({
    required this.item,
    required this.selected,
    required this.onChanged,
    required this.onSkip,
    required this.onReclassify,
  });

  Color get _confidenceColor {
    if (item.confidence < 0.5) return const Color(0xFFB94040);
    if (item.confidence < 0.7) return AppColors.suspendedText;
    return AppColors.activeText;
  }

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: AppColors.cardWhite,
      borderRadius: BorderRadius.circular(AppMetrics.cardRadius),
      boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8, offset: const Offset(0, 2))],
    ),
    padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      // ── Top row: item name + confidence score ──────────────────────
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: Text(item.itemName,
              style: const TextStyle(
                  fontFamily: 'DMSans', fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: _confidenceColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(item.confidence.toStringAsFixed(2),
              style: TextStyle(
                  fontFamily: 'DMSans', fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _confidenceColor)),
        ),
      ]),

      const SizedBox(height: 6),

      // ── AI said ... ────────────────────────────────────────────────
      RichText(
        text: TextSpan(
          style: AppTextStyles.emailSubtle,
          children: [
            const TextSpan(text: 'GPT said '),
            TextSpan(text: item.aiCategory,
                style: AppTextStyles.emailSubtle.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            TextSpan(text: ' · vendor ${item.vendor}'),
          ],
        ),
      ),

      const SizedBox(height: 10),

      // ── Flags ──────────────────────────────────────────────────────
      Wrap(spacing: 6, runSpacing: 4, children: item.flags
          .map((f) => _FlagChip(label: f))
          .toList()),

      const SizedBox(height: 14),
      const Divider(color: AppColors.divider, height: 1),
      const SizedBox(height: 12),

      // ── Reclassify dropdown ────────────────────────────────────────
      Text('Reclassify to',
          style: AppTextStyles.rowLabel.copyWith(
              color: AppColors.textSecondary, fontSize: 13)),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selected,
            isExpanded: true,
            dropdownColor: AppColors.cardWhite,
            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                color: AppColors.darkGreen, size: 22),
            style: const TextStyle(
                fontFamily: 'DMSans', fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary),
            items: item.suggestions
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ),

      const SizedBox(height: 14),

      // ── Actions ────────────────────────────────────────────────────
      Row(children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onSkip,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.divider),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text('Skip',
                style: AppTextStyles.actionButton),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: onReclassify,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.darkGreen,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('Reclassify + learn',
                style: TextStyle(
                    fontFamily: 'DMSans',
                    fontWeight: FontWeight.w700, fontSize: 14)),
          ),
        ),
      ]),
    ]),
  );
}

class _FlagChip extends StatelessWidget {
  final String label;
  const _FlagChip({required this.label});

  bool get _isFallback => label == 'fallback';

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: _isFallback
          ? AppColors.suspendedBg
          : AppColors.deletedBg,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      if (_isFallback) ...[
        const Icon(Icons.flag_rounded,
            size: 11, color: AppColors.suspendedText),
        const SizedBox(width: 4),
      ],
      Text(label,
          style: TextStyle(
              fontFamily: 'DMSans', fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _isFallback
                  ? AppColors.suspendedText
                  : AppColors.textSecondary)),
    ]),
  );
}

class _CircleAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          shape: BoxShape.circle),
      child: Icon(icon, color: Colors.white, size: 20),
    ),
  );
}
