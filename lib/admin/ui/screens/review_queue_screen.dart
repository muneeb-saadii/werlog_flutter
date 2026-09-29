import 'package:flutter/material.dart';
import '../../core/api/admin_api_service.dart';
import '../../core/api/admin_endpoints.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';

// ── Model ─────────────────────────────────────────────────────────────────────

class _ReviewItem {
  final String       auditId;
  final String       itemName;
  final String       aiCategory;
  final String       vendor;
  final double       confidence;
  final List<String> flags;
  final List<_Cat>   categories;  // from /admin/categories endpoint
  String?            selectedCategoryId;
  String?            selectedCategoryLabel;

  _ReviewItem({
    required this.auditId,
    required this.itemName,
    required this.aiCategory,
    required this.vendor,
    required this.confidence,
    required this.flags,
    required this.categories,
    this.selectedCategoryId,
    this.selectedCategoryLabel,
  });

  factory _ReviewItem.fromJson(Map<String, dynamic> j,
      List<_Cat> categories) {
    final flags = <String>[];
    if (j['flags']  is List)    flags.addAll((j['flags'] as List).map((e) => e.toString()));
    if (j['reason'] != null)    flags.add(j['reason'].toString());

    return _ReviewItem(
      auditId:    j['id']?.toString()           ?? '',
      itemName:   '"${j['itemName'] ?? j['name'] ?? ''}"',
      aiCategory: j['predictedCategory']?.toString()
          ?? j['aiCategory']?.toString() ?? '',
      vendor:     j['vendorName']?.toString()   ?? '',
      confidence: (j['confidence'] as num?)?.toDouble() ?? 0.0,
      flags:      flags,
      categories: categories,
      selectedCategoryId:
      categories.isNotEmpty ? categories.first.id : null,
      selectedCategoryLabel:
      categories.isNotEmpty ? categories.first.label : null,
    );
  }
}

class _Cat {
  final String id, label;
  const _Cat(this.id, this.label);
}

// ── Screen ────────────────────────────────────────────────────────────────────

class ReviewQueueScreen extends StatefulWidget {
  const ReviewQueueScreen({super.key});

  @override
  State<ReviewQueueScreen> createState() => _ReviewQueueScreenState();
}

class _ReviewQueueScreenState extends State<ReviewQueueScreen> {

  bool              _loading    = true;
  List<_ReviewItem> _items      = [];
  List<_Cat>        _categories = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      // Load categories and audit queue in parallel
      final results = await Future.wait([
        AdminApiService.get(context, AdminEndpoints.adminCategories,
            showLoader: false),
        AdminApiService.get(context, AdminEndpoints.adminAuditQueue,
            queryParams: {'limit': '50', 'includeReviewed': 'false'},
            showLoader: false),
      ]);

      debugPrint('[ReviewQueue] categories => ${results[0]?.keys}');
      debugPrint('[ReviewQueue] queue      => ${results[1]?.keys}');
      if (!mounted) return;

      // Parse categories
      _categories = [];
      final catResp = results[0];
      if (catResp != null) {
        final raw = catResp['data'] as List<dynamic>?
            ?? catResp['categories'] as List<dynamic>? ?? [];
        for (final c in raw.whereType<Map<String, dynamic>>()) {
          final id   = c['id']?.toString() ?? '';
          final name = c['name']?.toString() ?? '';
          if (id.isNotEmpty) {
            _categories.add(_Cat(id, name));
            // Subcategories
            final subs = c['subcategories'] as List<dynamic>? ?? [];
            for (final s in subs.whereType<Map<String, dynamic>>()) {
              final sid  = s['id']?.toString() ?? '';
              final sname = s['name']?.toString() ?? '';
              if (sid.isNotEmpty) {
                _categories.add(_Cat(sid, '$name › $sname'));
              }
            }
          }
        }
      }

      // Parse audit queue
      final qResp = results[1];
      if (qResp != null) {
        final raw = qResp['data'] as List<dynamic>?
            ?? qResp['items'] as List<dynamic>? ?? [];
        _items = raw
            .whereType<Map<String, dynamic>>()
            .map((j) => _ReviewItem.fromJson(j, _categories))
            .toList();
      }

    } catch (e) {
      debugPrint('[ReviewQueue] error => $e');
      if (mounted) AdminApiService.showError(context, 'Failed to load review queue');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reclassify(_ReviewItem item) async {
    if (item.selectedCategoryId == null) return;
    try {
      final resp = await AdminApiService.post(
        context,
        AdminEndpoints.adminReclassify(item.auditId),
        body: {
          'categoryId': item.selectedCategoryId,
          if (item.selectedCategoryLabel?.contains('›') == true)
            'subcategoryId': item.selectedCategoryId,
        },
        showLoader: false,
      );
      debugPrint('[ReviewQueue] reclassify => $resp');
      if (!mounted) return;
      AdminApiService.showSuccess(context, 'Reclassified + learning saved');
      setState(() => _items.remove(item));
    } catch (e) {
      debugPrint('[ReviewQueue] reclassify error => $e');
      if (mounted) AdminApiService.showError(context, 'Reclassify failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          _Header(count: _items.length),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(
                color: AppColors.accentGreen))
                : _items.isEmpty
                ? const _EmptyState()
                : RefreshIndicator(
              onRefresh: _fetch,
              color: AppColors.accentGreen,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                    AppMetrics.pagePadding, 16,
                    AppMetrics.pagePadding, 40),
                itemCount: _items.length,
                itemBuilder: (_, i) => _ReviewCard(
                  item: _items[i],
                  categories: _categories,
                  onCategoryChanged: (id, label) => setState(() {
                    _items[i].selectedCategoryId    = id;
                    _items[i].selectedCategoryLabel = label;
                  }),
                  onSkip: () =>
                      setState(() => _items.removeAt(i)),
                  onReclassify: () => _reclassify(_items[i]),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final int count;
  const _Header({required this.count});

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
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Review queue', style: AppTextStyles.headerTitle),
        const SizedBox(height: 4),
        Text('$count low-confidence classifications',
            style: AppTextStyles.headerSubtitle),
      ])),
      // Container(
      //   width: 40, height: 40,
      //   decoration: BoxDecoration(
      //       color: Colors.white.withOpacity(0.12), shape: BoxShape.circle),
      //   child: const Icon(Icons.settings_rounded, color: Colors.white, size: 20),
      // ),
    ]),
  );
}

class _ReviewCard extends StatelessWidget {
  final _ReviewItem item;
  final List<_Cat>  categories;
  final void Function(String id, String label) onCategoryChanged;
  final VoidCallback onSkip;
  final VoidCallback onReclassify;

  const _ReviewCard({
    required this.item,
    required this.categories,
    required this.onCategoryChanged,
    required this.onSkip,
    required this.onReclassify,
  });

  Color get _confColor {
    if (item.confidence < 0.5)  return const Color(0xFFB94040);
    if (item.confidence < 0.7)  return AppColors.suspendedText;
    return AppColors.activeText;
  }

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: AppColors.cardWhite,
      borderRadius: BorderRadius.circular(AppMetrics.cardRadius),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
          blurRadius: 8, offset: const Offset(0, 2))],
    ),
    padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      // Title + score
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Text(item.itemName,
            style: const TextStyle(fontFamily: 'DMSans', fontSize: 15,
                fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
              color: _confColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8)),
          child: Text(item.confidence.toStringAsFixed(2),
              style: TextStyle(fontFamily: 'DMSans', fontSize: 12,
                  fontWeight: FontWeight.w700, color: _confColor)),
        ),
      ]),

      const SizedBox(height: 6),

      // AI said
      if (item.aiCategory.isNotEmpty)
        RichText(text: TextSpan(
          style: AppTextStyles.emailSubtle,
          children: [
            const TextSpan(text: 'GPT said '),
            TextSpan(text: item.aiCategory,
                style: AppTextStyles.emailSubtle.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            if (item.vendor.isNotEmpty)
              TextSpan(text: ' · vendor ${item.vendor}'),
          ],
        )),

      if (item.flags.isNotEmpty) ...[
        const SizedBox(height: 10),
        Wrap(spacing: 6, runSpacing: 4,
            children: item.flags.map((f) => _FlagChip(label: f)).toList()),
      ],

      const SizedBox(height: 14),
      const Divider(color: AppColors.divider, height: 1),
      const SizedBox(height: 12),

      // Reclassify dropdown
      Text('Reclassify to',
          style: AppTextStyles.rowLabel.copyWith(fontSize: 13)),
      const SizedBox(height: 8),

      if (categories.isEmpty)
        const Text('No categories loaded',
            style: AppTextStyles.footerNote)
      else
        Container(
          decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider)),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: item.selectedCategoryId,
              isExpanded: true,
              dropdownColor: AppColors.cardWhite,
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: AppColors.darkGreen, size: 22),
              style: const TextStyle(fontFamily: 'DMSans', fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
              items: categories.map((c) => DropdownMenuItem(
                  value: c.id, child: Text(c.label))).toList(),
              onChanged: (v) {
                if (v == null) return;
                final label = categories
                    .firstWhere((c) => c.id == v,
                    orElse: () => _Cat(v, v))
                    .label;
                onCategoryChanged(v, label);
              },
            ),
          ),
        ),

      const SizedBox(height: 14),

      Row(children: [
        Expanded(child: OutlinedButton(
          onPressed: onSkip,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.divider),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24)),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: Text('Skip', style: AppTextStyles.actionButton),
        )),
        const SizedBox(width: 12),
        Expanded(flex: 2, child: ElevatedButton(
          onPressed: categories.isEmpty ? null : onReclassify,
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.darkGreen,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              padding: const EdgeInsets.symmetric(vertical: 12)),
          child: const Text('Reclassify + learn',
              style: TextStyle(fontFamily: 'DMSans',
                  fontWeight: FontWeight.w700, fontSize: 14,
                  color: Colors.white)),
        )),
      ]),
    ]),
  );
}

class _FlagChip extends StatelessWidget {
  final String label;
  const _FlagChip({required this.label});

  bool get _isFallback => label.toLowerCase() == 'fallback';

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
        color: _isFallback ? AppColors.suspendedBg : AppColors.deletedBg,
        borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      if (_isFallback) ...[
        const Icon(Icons.flag_rounded, size: 11,
            color: AppColors.suspendedText),
        const SizedBox(width: 4),
      ],
      Text(label,
          style: TextStyle(fontFamily: 'DMSans', fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _isFallback
                  ? AppColors.suspendedText
                  : AppColors.textSecondary)),
    ]),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => const Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.check_circle_outline_rounded,
          size: 52, color: AppColors.accentGreen),
      SizedBox(height: 12),
      Text('All caught up!', style: AppTextStyles.statLabel),
      SizedBox(height: 4),
      Text('No items pending review.',
          style: AppTextStyles.footerNote),
    ]),
  );
}