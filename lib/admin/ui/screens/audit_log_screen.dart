import 'package:flutter/material.dart';
import '../../core/api/admin_api_service.dart';
import '../../core/api/admin_endpoints.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';

// ── Model ─────────────────────────────────────────────────────────────────────

class _AuditEntry {
  final String id;
  final String action;
  final String actor;
  final String detail;
  final String timeAgo;

  const _AuditEntry({
    required this.id,
    required this.action,
    required this.actor,
    required this.detail,
    required this.timeAgo,
  });

  factory _AuditEntry.fromJson(Map<String, dynamic> j) {
    return _AuditEntry(
      id:      j['id']?.toString()          ?? '',
      action:  j['action']?.toString()      ?? '',
      actor:   j['actorEmail']?.toString()  ?? j['actor']?.toString() ?? 'admin',
      detail:  _buildDetail(j),
      timeAgo: _relTime(j['createdAt']?.toString()),
    );
  }

  static String _buildDetail(Map<String, dynamic> j) {
    final parts = <String>[];
    if (j['targetEmail'] != null) parts.add(j['targetEmail'].toString());
    if (j['targetId']    != null && parts.isEmpty)
      parts.add(j['targetId'].toString());
    if (j['metadata']    != null) {
      try {
        final m = j['metadata'] as Map<String, dynamic>;
        final v = m.values.first?.toString() ?? '';
        if (v.isNotEmpty) parts.add(v);
      } catch (_) {}
    }
    return parts.join(' · ');
  }

  static String _relTime(String? s) {
    if (s == null) return '';
    try {
      final diff = DateTime.now().difference(DateTime.parse(s));
      if (diff.inMinutes < 60)  return '${diff.inMinutes}m';
      if (diff.inHours   < 24)  return '${diff.inHours}h';
      return '${diff.inDays}d';
    } catch (_) { return ''; }
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────

class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {

  bool              _loading = true;
  List<_AuditEntry> _entries = [];
  String            _filter  = '';  // '' | USER | PLAN | INVOICE

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final resp = await AdminApiService.get(
        context,
        AdminEndpoints.adminAuditLogs,
        queryParams: {
          if (_filter.isNotEmpty) 'targetType': _filter,
          'page': '0', 'size': '50',
        },
        showLoader: false,
      );
      debugPrint('[AuditLog] response keys => ${resp?.keys}');
      if (!mounted) return;

      if (resp != null) {
        final raw = resp['data'];
        List<dynamic> list = [];
        if (raw is List) {
          list = raw;
        } else if (raw is Map<String, dynamic>) {
          list = raw['content'] as List<dynamic>? ?? [];
        }
        _entries = list
            .whereType<Map<String, dynamic>>()
            .map(_AuditEntry.fromJson)
            .toList();
      }
    } catch (e) {
      debugPrint('[AuditLog] error => $e');
      if (mounted) AdminApiService.showError(context, 'Failed to load audit log');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          _Header(),
          _FilterRow(
            selected: _filter,
            onSelected: (f) { setState(() => _filter = f); _fetch(); },
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(
                color: AppColors.accentGreen))
                : _entries.isEmpty
                ? const _EmptyState()
                : RefreshIndicator(
              onRefresh: _fetch,
              color: AppColors.accentGreen,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppMetrics.pagePadding, 8,
                    AppMetrics.pagePadding, 40),
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardWhite,
                      borderRadius: BorderRadius.circular(
                          AppMetrics.cardRadius),
                      boxShadow: [BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2))],
                    ),
                    child: Column(
                      children: _entries
                          .asMap()
                          .entries
                          .map((e) => Column(children: [
                        _AuditRow(entry: e.value),
                        if (e.key < _entries.length - 1)
                          const Divider(height: 1,
                              indent: 72,
                              color: AppColors.divider),
                      ])).toList(),
                    ),
                  ),
                ],
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
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Audit log', style: AppTextStyles.headerTitle),
        SizedBox(height: 4),
        Text('Every admin action, tracked',
            style: AppTextStyles.headerSubtitle),
      ])),
      // Container(
      //   width: 40, height: 40,
      //   decoration: BoxDecoration(
      //       color: Colors.white.withOpacity(0.12), shape: BoxShape.circle),
      //   child: const Icon(Icons.search_rounded, color: Colors.white, size: 20),
      // ),
    ]),
  );
}

class _FilterRow extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;
  const _FilterRow({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 52,
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        for (final item in [
          ('', 'All'), ('USER', 'Users'),
          ('PLAN', 'Plans'), ('INVOICE', 'Invoices'),
        ])
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _Chip(label: item.$2,
                active: selected == item.$1,
                onTap: () => onSelected(item.$1)),
          ),
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
          style: TextStyle(fontFamily: AppTextStyles.fontFamily,
              fontSize: 13, fontWeight: FontWeight.w600,
              color: active ? Colors.white : AppColors.textSecondary)),
    ),
  );
}

class _AuditRow extends StatelessWidget {
  final _AuditEntry entry;
  const _AuditRow({required this.entry});

  _IconCfg get _cfg {
    final a = entry.action.toUpperCase();
    if (a.contains('SUSPEND'))     return _IconCfg(Icons.power_settings_new_rounded, const Color(0xFFFBDEDA), const Color(0xFFB94040));
    if (a.contains('IMPERSONAT')) return _IconCfg(Icons.remove_red_eye_rounded, AppColors.proBg, AppColors.proText);
    if (a.contains('PLAN'))       return _IconCfg(Icons.auto_awesome_rounded, AppColors.activeBg, AppColors.activeText);
    if (a.contains('RETRIED'))    return _IconCfg(Icons.autorenew_rounded, AppColors.proBg, AppColors.proText);
    if (a.contains('DELETE') || a.contains('DELETED')) return _IconCfg(Icons.delete_outline_rounded, const Color(0xFFFBDEDA), const Color(0xFFB94040));
    if (a.contains('UPDATE'))     return _IconCfg(Icons.label_rounded, AppColors.suspendedBg, AppColors.suspendedText);
    return _IconCfg(Icons.history_rounded, AppColors.deletedBg, AppColors.textSecondary);
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
              color: cfg.bg, borderRadius: BorderRadius.circular(12)),
          child: Icon(cfg.icon, color: cfg.fg, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(entry.action,
              style: AppTextStyles.nameBold.copyWith(
                  fontSize: 13, letterSpacing: 0.3)),
          const SizedBox(height: 3),
          Text('${entry.actor}${entry.detail.isNotEmpty ? " · ${entry.detail}" : ""}',
              style: AppTextStyles.emailSubtle,
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ])),
        const SizedBox(width: 8),
        Text(entry.timeAgo,
            style: AppTextStyles.footerNote.copyWith(
                color: AppColors.textSecondary)),
      ]),
    );
  }
}

class _IconCfg {
  final IconData icon;
  final Color bg, fg;
  const _IconCfg(this.icon, this.bg, this.fg);
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => const Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.history_rounded, size: 52, color: AppColors.textSecondary),
      SizedBox(height: 12),
      Text('No audit logs', style: AppTextStyles.statLabel),
    ]),
  );
}