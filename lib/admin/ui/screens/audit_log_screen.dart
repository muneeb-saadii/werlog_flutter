import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';

// ── Models ────────────────────────────────────────────────────────────────────

enum AuditCategory { users, plans, invoices, ocr }

class AuditEntry {
  final String id;
  final String action;
  final String actor;
  final String detail;
  final String timeAgo;
  final AuditCategory category;

  const AuditEntry({
    required this.id,
    required this.action,
    required this.actor,
    required this.detail,
    required this.timeAgo,
    required this.category,
  });
}

// ── Mock data ─────────────────────────────────────────────────────────────────

final _mockEntries = [
  const AuditEntry(
    id: '1', action: 'USER_SUSPENDED', actor: 'admin@werlog',
    detail: 'sarah.k@mail.com', timeAgo: '2m',
    category: AuditCategory.users,
  ),
  const AuditEntry(
    id: '2', action: 'PLAN_GRANTED', actor: 'admin@werlog',
    detail: 'PRO → David L.', timeAgo: '1h',
    category: AuditCategory.plans,
  ),
  const AuditEntry(
    id: '3', action: 'OCR_JOB_RETRIED', actor: 'admin@werlog',
    detail: 'job #778', timeAgo: '3h',
    category: AuditCategory.ocr,
  ),
  const AuditEntry(
    id: '4', action: 'USER_IMPERSONATED', actor: 'admin@werlog',
    detail: 'haseeb...@gmail', timeAgo: '5h',
    category: AuditCategory.users,
  ),
  const AuditEntry(
    id: '5', action: 'PLAN_UPDATED', actor: 'admin@werlog',
    detail: 'PRO price', timeAgo: '1d',
    category: AuditCategory.plans,
  ),
  const AuditEntry(
    id: '6', action: 'INVOICE_DELETED', actor: 'admin@werlog',
    detail: '#ARMI00801304', timeAgo: '1d',
    category: AuditCategory.invoices,
  ),
];

// ── Screen ────────────────────────────────────────────────────────────────────

class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  AuditCategory? _filter;

  List<AuditEntry> get _filtered => _filter == null
      ? _mockEntries
      : _mockEntries.where((e) => e.category == _filter).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          _AuditHeader(),
          _FilterChips(
              selected: _filter,
              onSelected: (c) => setState(() => _filter = c)),
          Expanded(
            child: _filtered.isEmpty
                ? _EmptyState()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(
                        AppMetrics.pagePadding, 8,
                        AppMetrics.pagePadding, 40),
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.cardWhite,
                          borderRadius:
                              BorderRadius.circular(AppMetrics.cardRadius),
                          boxShadow: [BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: Column(
                          children: _filtered.asMap().entries.map((e) {
                            final isLast = e.key == _filtered.length - 1;
                            return Column(children: [
                              _AuditRow(entry: e.value),
                              if (!isLast) const Divider(
                                  height: 1, indent: 72,
                                  color: AppColors.divider),
                            ]);
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
          ),
        ]),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _AuditHeader extends StatelessWidget {
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
          Text('Audit log', style: AppTextStyles.headerTitle),
          const SizedBox(height: 4),
          Text('every admin action, tracked',
              style: AppTextStyles.headerSubtitle),
        ],
      )),
      _CircleAction(icon: Icons.search_rounded, onTap: () {}),
    ]),
  );
}

// ── Filter chips ──────────────────────────────────────────────────────────────

class _FilterChips extends StatelessWidget {
  final AuditCategory? selected;
  final ValueChanged<AuditCategory?> onSelected;
  const _FilterChips({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 52,
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        _Chip(label: 'All', active: selected == null,
            onTap: () => onSelected(null)),
        const SizedBox(width: 8),
        _Chip(label: 'Users', active: selected == AuditCategory.users,
            onTap: () => onSelected(AuditCategory.users)),
        const SizedBox(width: 8),
        _Chip(label: 'Plans', active: selected == AuditCategory.plans,
            onTap: () => onSelected(AuditCategory.plans)),
        const SizedBox(width: 8),
        _Chip(label: 'Invoices', active: selected == AuditCategory.invoices,
            onTap: () => onSelected(AuditCategory.invoices)),
      ],
    ),
  );
}

class _Chip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: active ? AppColors.darkGreen : AppColors.cardWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: active ? AppColors.darkGreen : AppColors.divider),
      ),
      child: Text(label,
          style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 13, fontWeight: FontWeight.w600,
              color: active ? Colors.white : AppColors.textSecondary)),
    ),
  );
}

// ── Audit row ─────────────────────────────────────────────────────────────────

class _AuditRow extends StatelessWidget {
  final AuditEntry entry;
  const _AuditRow({required this.entry});

  _AuditIconCfg get _cfg {
    switch (entry.category) {
      case AuditCategory.users:
        if (entry.action.contains('SUSPEND')) {
          return _AuditIconCfg(Icons.power_settings_new_rounded,
              const Color(0xFFFBDEDA), const Color(0xFFB94040));
        }
        return _AuditIconCfg(Icons.remove_red_eye_rounded,
            AppColors.proBg, AppColors.proText);
      case AuditCategory.plans:
        if (entry.action.contains('GRANTED')) {
          return _AuditIconCfg(Icons.auto_awesome_rounded,
              AppColors.activeBg, AppColors.activeText);
        }
        return _AuditIconCfg(Icons.label_rounded,
            AppColors.suspendedBg, AppColors.suspendedText);
      case AuditCategory.ocr:
        return _AuditIconCfg(Icons.autorenew_rounded,
            AppColors.proBg, AppColors.proText);
      case AuditCategory.invoices:
        return _AuditIconCfg(Icons.delete_outline_rounded,
            const Color(0xFFFBDEDA), const Color(0xFFB94040));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cfg = _cfg;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
              color: cfg.bg,
              borderRadius: BorderRadius.circular(12)),
          child: Icon(cfg.icon, color: cfg.fg, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(entry.action,
                style: AppTextStyles.nameBold.copyWith(
                    fontSize: 13, letterSpacing: 0.3)),
            const SizedBox(height: 3),
            Text('${entry.actor} · ${entry.detail}',
                style: AppTextStyles.emailSubtle,
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        )),
        const SizedBox(width: 8),
        Text(entry.timeAgo,
            style: AppTextStyles.footerNote.copyWith(
                color: AppColors.textSecondary)),
      ]),
    );
  }
}

class _AuditIconCfg {
  final IconData icon;
  final Color bg, fg;
  const _AuditIconCfg(this.icon, this.bg, this.fg);
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.history_rounded, size: 52, color: AppColors.textSecondary),
      const SizedBox(height: 12),
      Text('No logs', style: AppTextStyles.statLabel),
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
