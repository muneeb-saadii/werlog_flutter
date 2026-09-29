import 'package:flutter/material.dart';
import '../../core/api/admin_api_service.dart';
import '../../core/api/admin_endpoints.dart';
import '../../core/models/admin_user.dart';
import '../../core/routes/admin_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/admin_bottom_nav.dart';
import '../widgets/status_badge.dart';
import '../widgets/user_avatar.dart';

class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {

  final _searchCtrl   = TextEditingController();
  String _statusFilter = '';
  int    _page         = 0;
  int    _totalCount   = 0;
  bool   _loading      = true;

  List<AdminUser> _all      = [];
  List<AdminUser> _filtered = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
    _searchCtrl.addListener(_applyLocalFilter);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_applyLocalFilter);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final resp = await AdminApiService.get(
        context,
        AdminEndpoints.adminUsers,
        queryParams: {
          if (_statusFilter.isNotEmpty) 'status': _statusFilter,
          'search': _searchCtrl.text.trim(),
          'page': '$_page', 'size': '100',
        },
        showLoader: false,
      );
      debugPrint('[Users] response keys => ${resp?.keys}');
      if (!mounted) return;

      if (resp != null) {
        final raw = resp['data'];
        List<dynamic> content = [];
        if (raw is List) {
          content     = raw;
          _totalCount = raw.length;
        } else if (raw is Map<String, dynamic>) {
          content     = raw['content'] as List<dynamic>? ?? [];
          _totalCount = (raw['totalElements'] as num?)?.toInt() ?? content.length;
        }
        _all = content
            .whereType<Map<String, dynamic>>()
            .map(_mapUser)
            .toList();
        _applyLocalFilter();
      }
    } catch (e) {
      debugPrint('[Users] error => $e');
      if (mounted) AdminApiService.showError(context, 'Failed to load users');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyLocalFilter() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filtered = _all.where((u) {
        if (q.isEmpty) return true;
        return u.name.toLowerCase().contains(q) ||
            u.email.toLowerCase().contains(q);
      }).toList();
    });
  }

  AdminUser _mapUser(Map<String, dynamic> u) {
    UserStatus status;
    switch ((u['status'] ?? '').toString().toUpperCase()) {
      case 'SUSPENDED': status = UserStatus.suspended; break;
      case 'DELETED':   status = UserStatus.deleted;   break;
      default:          status = UserStatus.active;
    }
    UserPlan plan;
    switch ((u['planCode'] ?? '').toString().toUpperCase()) {
      case 'PRO':      plan = UserPlan.pro;      break;
      case 'BUSINESS': plan = UserPlan.business; break;
      default:         plan = UserPlan.free;
    }
    final idx = _all.length % AppColors.avatarPalette.length;
    return AdminUser(
      id:                  u['id']?.toString()       ?? '',
      name:                u['fullName']?.toString() ?? u['name']?.toString() ?? '',
      email:               u['email']?.toString()    ?? '',
      status:              status,
      plan:                plan,
      role:                u['role']?.toString()     ?? '',
      verified:            u['emailVerified'] == true,
      joined:              _parseDate(u['createdAt']),
      lastLogin:           _parseDate(u['lastLoginAt'] ?? u['updatedAt']),
      subscriptionSummary: u['subscriptionSummary']?.toString() ?? plan.label,
      avatarColor:         AppColors.avatarPalette[idx],
    );
  }

  DateTime _parseDate(dynamic v) {
    if (v == null) return DateTime.now();
    try { return DateTime.parse(v.toString()); } catch (_) { return DateTime.now(); }
  }

  int get _suspended => _all.where((u) => u.status == UserStatus.suspended).length;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        bottomNavigationBar: const AdminBottomNav(currentIndex: 1),
        body: SafeArea(
          bottom: false,
          child: Column(children: [
            _Header(
              total:     _totalCount,
              suspended: _suspended,
              onRefresh: _fetch,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                    AppMetrics.pagePadding, 0,
                    AppMetrics.pagePadding, 24),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

                  // Search bar
                  _SearchBar(
                    controller: _searchCtrl,
                    onClear:    () { _searchCtrl.clear(); _applyLocalFilter(); },
                  ),

                  const SizedBox(height: 8),

                  // Filter chips
                  _FilterChips(
                    selected:   _statusFilter,
                    onSelected: (f) {
                      setState(() { _statusFilter = f; _page = 0; });
                      _fetch();
                    },
                  ),

                  const SizedBox(height: AppMetrics.gapMd),

                  if (_loading)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(
                          color: AppColors.accentGreen),
                    ))
                  else if (_filtered.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                          color: AppColors.cardWhite,
                          borderRadius: BorderRadius.circular(AppMetrics.cardRadius)),
                      child: const Center(child: Text('No users found.',
                          style: AppTextStyles.footerNote)),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                          color: AppColors.cardWhite,
                          borderRadius: BorderRadius.circular(AppMetrics.cardRadius)),
                      child: Column(children: [
                        for (int i = 0; i < _filtered.length; i++)
                          _UserRow(
                            user:        _filtered[i],
                            showDivider: i < _filtered.length - 1,
                          ),
                      ]),
                    ),

                  const SizedBox(height: AppMetrics.gapMd),
                  Center(child: Text(
                    'Showing ${_filtered.length} of $_totalCount users',
                    style: AppTextStyles.footerNote,
                  )),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Header with refresh button ────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final int total, suspended;
  final VoidCallback onRefresh;
  const _Header({required this.total, required this.suspended,
    required this.onRefresh});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(8, 16, 16, 24),
    decoration: const BoxDecoration(
      color: AppColors.darkGreen,
      borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppMetrics.headerRadius)),
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      IconButton(
        onPressed: () => Navigator.of(context).canPop()
            ? Navigator.of(context).pop()
            : Navigator.of(context).pushReplacementNamed(AdminRoutes.dashboard),
        icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 26),
        padding: EdgeInsets.zero,
      ),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Users', style: AppTextStyles.headerTitle),
        const SizedBox(height: 4),
        Text('$total total · $suspended suspended',
            style: AppTextStyles.headerSubtitle),
      ])),
      // ── Refresh button ──────────────────────────────────────────────
      GestureDetector(
        onTap: onRefresh,
        child: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              shape: BoxShape.circle),
          child: const Icon(Icons.refresh_rounded,
              color: Colors.white, size: 20),
        ),
      ),
    ]),
  );
}

// ── Search bar with clear button ──────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onClear;
  const _SearchBar({required this.controller, required this.onClear});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14)),
    child: TextField(
      controller: controller,
      style: AppTextStyles.rowValue.copyWith(fontWeight: FontWeight.w400),
      decoration: InputDecoration(
        hintText: 'Search by name or email…',
        hintStyle: AppTextStyles.emailSubtle,
        prefixIcon: const Icon(Icons.search_rounded,
            color: AppColors.textSecondary, size: 20),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (_, v, __) => v.text.isEmpty
              ? const SizedBox.shrink()
              : IconButton(
              icon: const Icon(Icons.clear_rounded,
                  color: AppColors.textSecondary, size: 18),
              onPressed: onClear),
        ),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
    ),
  );
}

// ── Filter chips ──────────────────────────────────────────────────────────────

class _FilterChips extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;
  const _FilterChips({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final items = [('', 'All'), ('ACTIVE', 'Active'),
      ('SUSPENDED', 'Suspended'), ('DELETED', 'Deleted')];
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final isSel = items[i].$1 == selected;
          return ChoiceChip(
            label: Text(items[i].$2),
            selected: isSel,
            onSelected: (_) => onSelected(items[i].$1),
            showCheckmark: false,
            labelStyle: TextStyle(
                color: isSel ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w600, fontSize: 13),
            selectedColor: AppColors.darkGreen,
            backgroundColor: AppColors.cardWhite,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            side: BorderSide.none,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          );
        },
      ),
    );
  }
}

// ── User row ──────────────────────────────────────────────────────────────────

class _UserRow extends StatelessWidget {
  final AdminUser user;
  final bool showDivider;
  const _UserRow({required this.user, required this.showDivider});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => Navigator.of(context)
        .pushNamed(AdminRoutes.userDetail, arguments: user),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(children: [
        Row(children: [
          UserAvatar(initials: user.initials, color: user.avatarColor),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.name, style: AppTextStyles.nameBold),
              const SizedBox(height: 2),
              Text(user.email, style: AppTextStyles.emailSubtle),
            ],
          )),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            StatusBadge.status(user.status),
            const SizedBox(height: 6),
            Text(user.plan.label,
                style: AppTextStyles.footerNote
                    .copyWith(fontWeight: FontWeight.w700)),
          ]),
        ]),
        if (showDivider) const Padding(
          padding: EdgeInsets.only(top: 14),
          child: Divider(height: 1, color: AppColors.divider),
        ),
      ]),
    ),
  );
}