import 'package:flutter/material.dart';
import '../../core/api/admin_api_service.dart';
import '../../core/api/admin_endpoints.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';

// ── Model ─────────────────────────────────────────────────────────────────────

class AdminPlan {
  final String  id;
  final String  name;
  final String  code;
  final String  engine;
  final int?    scanLimit;   // null = unlimited
  final double  priceUsd;
  final bool    adsEnabled;
  final int     subscribers;
  bool          isActive;
  final bool    isPopular;
  final Map<String, dynamic> raw;

  AdminPlan({
    required this.id,
    required this.name,
    required this.code,
    required this.engine,
    this.scanLimit,
    required this.priceUsd,
    required this.adsEnabled,
    required this.subscribers,
    required this.isActive,
    this.isPopular = false,
    required this.raw,
  });

  factory AdminPlan.fromJson(Map<String, dynamic> j) {
    final limit = j['scanLimit'] ?? j['scansPerMonth'];
    return AdminPlan(
      id:          j['id']?.toString()           ?? j['planId']?.toString() ?? '',
      name:        j['name']?.toString()         ?? j['planName']?.toString() ?? '',
      code:        j['code']?.toString()         ?? j['planCode']?.toString() ?? '',
      engine:      j['engine']?.toString()       ?? j['ocrEngine']?.toString() ?? '',
      scanLimit:   limit == null ? null : (limit as num).toInt(),
      priceUsd:    (j['priceUsd'] ?? j['price'] ?? j['monthlyPrice'] as num?)?.toDouble() ?? 0,
      adsEnabled:  j['adsEnabled'] == true || j['showAds'] == true,
      subscribers: (j['subscriberCount'] ?? j['totalSubscribers'] ?? j['activeSubscriptions'] as num?)?.toInt() ?? 0,
      isActive:    j['isActive'] != false && j['active'] != false,
      isPopular:   j['isPopular'] == true || j['popular'] == true,
      raw:         j,
    );
  }

  String get scansLabel => scanLimit == null ? 'unlimited' : '$scanLimit scans/mo';
  String get priceLabel => priceUsd == 0 ? '\$0' : '\$${priceUsd % 1 == 0 ? priceUsd.toInt() : priceUsd}';
}

// ── Screen ────────────────────────────────────────────────────────────────────

class PlansBillingScreen extends StatefulWidget {
  const PlansBillingScreen({super.key});

  @override
  State<PlansBillingScreen> createState() => _PlansBillingScreenState();
}

class _PlansBillingScreenState extends State<PlansBillingScreen> {

  bool             _loading = true;
  List<AdminPlan>  _plans   = [];

  int get _paidSubscribers =>
      _plans.fold(0, (s, p) => s + p.subscribers);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final resp = await AdminApiService.get(
          context, AdminEndpoints.adminPlans, showLoader: false);
      debugPrint('[Plans] response => $resp');
      if (!mounted) return;

      if (resp != null) {
        final raw = resp['data'];
        List<dynamic> list = raw is List ? raw : [];
        _plans = list
            .whereType<Map<String, dynamic>>()
            .map(AdminPlan.fromJson)
            .toList();
      }
    } catch (e) {
      debugPrint('[Plans] error => $e');
      if (mounted) AdminApiService.showError(context, 'Failed to load plans');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Toggle active ─────────────────────────────────────────────────────────

  Future<void> _toggleActive(AdminPlan plan, bool value) async {
    setState(() => plan.isActive = value);
    try {
      final resp = await AdminApiService.patch(
        context,
        AdminEndpoints.adminPlanUpdate(plan.id),
        body: {'isActive': value},
        showLoader: false,
      );
      debugPrint('[Plans] toggle ${plan.id} => $resp');
      if (!mounted) return;
      AdminApiService.showSuccess(context,
          '${plan.name} ${value ? 'activated' : 'deactivated'}');
    } catch (e) {
      // Revert on failure
      setState(() => plan.isActive = !value);
      if (mounted) AdminApiService.showError(context, 'Update failed');
    }
  }

  // ── Edit plan ─────────────────────────────────────────────────────────────

  void _showEditSheet(AdminPlan plan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardWhite,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _PlanFormSheet(
        plan: plan,
        onSave: (body) => _updatePlan(plan.id, body),
        onDelete: () => _deletePlan(plan),
      ),
    );
  }

  // ── Create plan ───────────────────────────────────────────────────────────

  void _showCreateSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardWhite,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _PlanFormSheet(
        plan: null,
        onSave: (body) => _createPlan(body),
        onDelete: null,
      ),
    );
  }

  Future<void> _createPlan(Map<String, dynamic> body) async {
    try {
      final resp = await AdminApiService.post(
          context, AdminEndpoints.adminPlans, body: body, showLoader: false);
      debugPrint('[Plans] create => $resp');
      if (!mounted) return;
      AdminApiService.showSuccess(context, 'Plan created');
      _fetch();
    } catch (e) {
      if (mounted) AdminApiService.showError(context, 'Create failed');
    }
  }

  Future<void> _updatePlan(String id, Map<String, dynamic> body) async {
    try {
      final resp = await AdminApiService.patch(
          context, AdminEndpoints.adminPlanUpdate(id),
          body: body, showLoader: false);
      debugPrint('[Plans] update $id => $resp');
      if (!mounted) return;
      AdminApiService.showSuccess(context, 'Plan updated');
      _fetch();
    } catch (e) {
      if (mounted) AdminApiService.showError(context, 'Update failed');
    }
  }

  Future<void> _deletePlan(AdminPlan plan) async {
    final dialogCtx = context;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text('Delete ${plan.name}?',
            style: AppTextStyles.cardTitle),
        content: Text(
            'This will permanently remove the plan. '
                'Users on this plan will not be immediately affected.',
            style: AppTextStyles.rowLabel),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('Cancel',
                  style: AppTextStyles.actionButton.copyWith(
                      color: AppColors.textSecondary))),
          ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.dangerRed, elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20))),
              child: const Text('Delete', style: TextStyle(
                  fontFamily: 'DMSans', fontWeight: FontWeight.w700,
                  color: Colors.white))),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    try {
      await AdminApiService.delete(
          dialogCtx, AdminEndpoints.adminPlanUpdate(plan.id),
          showLoader: false);
      if (!mounted) return;
      AdminApiService.showSuccess(context, '${plan.name} deleted');
      _fetch();
    } catch (e) {
      if (mounted) AdminApiService.showError(context, 'Delete failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          _Header(
              planCount: _plans.length,
              paidSubscribers: _paidSubscribers),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(
                color: AppColors.accentGreen))
                : RefreshIndicator(
              onRefresh: _fetch,
              color: AppColors.accentGreen,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                    AppMetrics.pagePadding, 16,
                    AppMetrics.pagePadding, 100),
                itemCount: _plans.length + 1,
                itemBuilder: (_, i) {
                  if (i == _plans.length) {
                    return _CreateButton(onTap: _showCreateSheet);
                  }
                  final plan = _plans[i];
                  return _PlanCard(
                    plan: plan,
                    onToggle: (v) => _toggleActive(plan, v),
                    onTap: () => _showEditSheet(plan),
                  );
                },
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Plan form sheet (create + edit) ───────────────────────────────────────────

class _PlanFormSheet extends StatefulWidget {
  final AdminPlan? plan;         // null = create mode
  final Future<void> Function(Map<String, dynamic>) onSave;
  final VoidCallback? onDelete;

  const _PlanFormSheet({this.plan, required this.onSave, this.onDelete});

  @override
  State<_PlanFormSheet> createState() => _PlanFormSheetState();
}

class _PlanFormSheetState extends State<_PlanFormSheet> {

  late final TextEditingController _nameCtrl;
  late final TextEditingController _codeCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _scansCtrl;
  late final TextEditingController _engineCtrl;
  late bool _adsEnabled;
  late bool _isActive;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.plan;
    _nameCtrl   = TextEditingController(text: p?.name ?? '');
    _codeCtrl   = TextEditingController(text: p?.code ?? '');
    _priceCtrl  = TextEditingController(text: p?.priceUsd.toString() ?? '0');
    _scansCtrl  = TextEditingController(
        text: p?.scanLimit?.toString() ?? '');
    _engineCtrl = TextEditingController(text: p?.engine ?? 'GPT4');
    _adsEnabled = p?.adsEnabled ?? false;
    _isActive   = p?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _codeCtrl.dispose(); _priceCtrl.dispose();
    _scansCtrl.dispose(); _engineCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty || _codeCtrl.text.trim().isEmpty) {
      AdminApiService.showError(context, 'Name and code are required');
      return;
    }
    setState(() => _saving = true);
    final body = <String, dynamic>{
      'name':       _nameCtrl.text.trim(),
      'code':       _codeCtrl.text.trim().toUpperCase(),
      'priceUsd':   double.tryParse(_priceCtrl.text) ?? 0.0,
      'engine':     _engineCtrl.text.trim(),
      'adsEnabled': _adsEnabled,
      'isActive':   _isActive,
      if (_scansCtrl.text.isNotEmpty)
        'scanLimit': int.tryParse(_scansCtrl.text),
    };
    Navigator.pop(context);
    await widget.onSave(body);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.plan != null;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4,
              decoration: BoxDecoration(color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text(isEdit ? 'Edit ${widget.plan!.name}' : 'Create new plan',
              style: AppTextStyles.cardTitle),
          const SizedBox(height: 20),

          _Field(ctrl: _nameCtrl,   label: 'Plan name',   hint: 'e.g. Professional'),
          const SizedBox(height: 12),
          _Field(ctrl: _codeCtrl,   label: 'Plan code',   hint: 'e.g. PRO',
              enabled: !isEdit), // code cannot be changed after creation
          const SizedBox(height: 12),
          _Field(ctrl: _priceCtrl,  label: 'Price (USD)', hint: '9.99',
              keyboardType: TextInputType.number),
          const SizedBox(height: 12),
          _Field(ctrl: _scansCtrl,  label: 'Scan limit',
              hint: 'Leave blank for unlimited',
              keyboardType: TextInputType.number),
          const SizedBox(height: 12),
          _Field(ctrl: _engineCtrl, label: 'OCR engine',  hint: 'GPT4 or Tesseract'),
          const SizedBox(height: 14),

          // Toggles
          _Toggle(label: 'Show ads', value: _adsEnabled,
              onChanged: (v) => setState(() => _adsEnabled = v)),
          _Toggle(label: 'Active (available to users)', value: _isActive,
              onChanged: (v) => setState(() => _isActive = v)),

          const SizedBox(height: 20),
          const Divider(color: AppColors.divider),
          const SizedBox(height: 12),

          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkGreen, elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14))),
              child: _saving
                  ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
                  : Text(isEdit ? 'Save changes' : 'Create plan',
                  style: const TextStyle(fontFamily: 'DMSans',
                      fontWeight: FontWeight.w700, fontSize: 15,
                      color: Colors.white)),
            ),
          ),

          // Delete (edit mode only)
          if (isEdit && widget.onDelete != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onDelete!();
                },
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.dangerBorder),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
                child: const Text('Delete plan',
                    style: TextStyle(fontFamily: 'DMSans',
                        fontWeight: FontWeight.w600, fontSize: 14,
                        color: AppColors.dangerRed)),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label, hint;
  final TextInputType keyboardType;
  final bool enabled;

  const _Field({
    required this.ctrl,
    required this.label,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) => TextField(
    controller: ctrl,
    enabled: enabled,
    keyboardType: keyboardType,
    style: AppTextStyles.rowValue,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: AppTextStyles.rowLabel,
      hintStyle: AppTextStyles.emailSubtle,
      filled: true,
      fillColor: enabled ? AppColors.background : AppColors.deletedBg,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
              color: AppColors.accentGreen, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 13),
    ),
  );
}

class _Toggle extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _Toggle({required this.label, required this.value,
    required this.onChanged});

  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Text(label, style: AppTextStyles.rowLabel)),
    Switch.adaptive(value: value, onChanged: onChanged,
        activeColor: AppColors.accentGreen),
  ]);
}

// ── Plan card ─────────────────────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  final AdminPlan plan;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTap;
  const _PlanCard({required this.plan, required this.onToggle,
    required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(AppMetrics.cardRadius),
        border: Border.all(
          color: plan.isPopular ? AppColors.accentGreen : Colors.transparent,
          width: plan.isPopular ? 2 : 0,
        ),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(plan.name, style: AppTextStyles.cardTitle),
                if (plan.isPopular) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                        color: AppColors.activeBg,
                        borderRadius: BorderRadius.circular(20)),
                    child: Text('popular',
                        style: AppTextStyles.badgeText.copyWith(
                            color: AppColors.activeText, fontSize: 11)),
                  ),
                ],
              ]),
              const SizedBox(height: 4),
              Text('code: ${plan.code} · ${plan.engine} · ${plan.scansLabel}',
                  style: AppTextStyles.emailSubtle),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(plan.priceLabel, style: AppTextStyles.cardTitle),
              const SizedBox(height: 6),
              Switch.adaptive(
                  value: plan.isActive,
                  onChanged: onToggle,
                  activeColor: AppColors.accentGreen),
            ]),
          ]),
        ),
        const Divider(height: 1, indent: 16, endIndent: 16,
            color: AppColors.divider),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          child: Row(children: [
            _Pill(
              label: plan.adsEnabled ? 'ads on' : 'no ads',
              bg: plan.adsEnabled ? AppColors.suspendedBg : AppColors.activeBg,
              fg: plan.adsEnabled ? AppColors.suspendedText : AppColors.activeText,
            ),
            const SizedBox(width: 8),
            _Pill(
              label: '${plan.subscribers} subscribers',
              bg: AppColors.proBg, fg: AppColors.proText,
            ),
          ]),
        ),
      ]),
    ),
  );
}

class _Pill extends StatelessWidget {
  final String label;
  final Color bg, fg;
  const _Pill({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(color: bg,
        borderRadius: BorderRadius.circular(20)),
    child: Text(label,
        style: AppTextStyles.badgeText.copyWith(color: fg, fontSize: 12)),
  );
}

class _Header extends StatelessWidget {
  final int planCount, paidSubscribers;
  const _Header({required this.planCount, required this.paidSubscribers});

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
        const Text('Plans & billing', style: AppTextStyles.headerTitle),
        const SizedBox(height: 4),
        Text('$planCount plans · $paidSubscribers paid subscribers',
            style: AppTextStyles.headerSubtitle),
      ])),
    ]),
  );
}

class _CreateButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CreateButton({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
          color: AppColors.darkGreen,
          borderRadius: BorderRadius.circular(AppMetrics.cardRadius)),
      alignment: Alignment.center,
      child: const Text('+ Create new plan',
          style: TextStyle(fontFamily: 'DMSans', fontSize: 16,
              fontWeight: FontWeight.w700, color: Colors.white)),
    ),
  );
}