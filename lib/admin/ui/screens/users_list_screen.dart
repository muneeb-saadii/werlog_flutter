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

  final _searchCtrl = TextEditingController();
  String _statusFilter = '';   // '' = All
  int    _page         = 0;
  int    _totalCount   = 0;
  bool   _loading      = true;

  List<AdminUser> _users = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
    _searchCtrl.addListener(() => _debounceSearch());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  DateTime? _lastSearch;
  void _debounceSearch() {
    _lastSearch = DateTime.now();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (DateTime.now().difference(_lastSearch!) >=
          const Duration(milliseconds: 490)) {
        _page = 0;
        _fetch();
      }
    });
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
          'page':   '$_page',
          'size':   '20',
        },
        showLoader: false,
      );
      debugPrint('[Users] response => $resp');
      if (!mounted) return;

      if (resp != null) {
        // ── API returns data as a List directly (not wrapped in a Map) ──
        final raw = resp['data'];

        List<dynamic> content = [];
        int total = 0;

        if (raw is List) {
          // Flat list: {"result":"1","data":[{...},{...}]}
          content = raw;
          total   = raw.length;
        } else if (raw is Map<String, dynamic>) {
          // Paginated: {"result":"1","data":{"content":[...],"totalElements":N}}
          content = raw['content'] as List<dynamic>?
              ?? raw['users']   as List<dynamic>?
              ?? [];
          total   = (raw['totalElements'] as num?)?.toInt()
              ?? (raw['total']         as num?)?.toInt()
              ?? content.length;
        }

        _totalCount = total;
        _users = content
            .whereType<Map<String, dynamic>>()
            .map(_mapUser)
            .toList();
      }
    } catch (e) {
      debugPrint('[Users] error => $e');
      if (mounted) AdminApiService.showError(context, 'Failed to load users');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  AdminUser _mapUser(Map<String, dynamic> u) {
    UserStatus status;
    switch ((u['status'] ?? u['accountStatus'] ?? '').toString().toUpperCase()) {
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
    final idx = (_users.length) % AppColors.avatarPalette.length;
    return AdminUser(
      id:                  u['id']?.toString()        ?? '',
      name:                u['fullName']?.toString()  ?? u['name']?.toString() ?? '',
      email:               u['email']?.toString()     ?? '',
      status:              status,
      plan:                plan,
      role:                u['role']?.toString()      ?? '',
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

  int get _suspended => _users.where((u) => u.status == UserStatus.suspended).length;

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
          _Header(total: _totalCount, suspended: _suspended),
          const SizedBox(height: 15),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                  AppMetrics.pagePadding, 0, AppMetrics.pagePadding, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Transform.translate(
                    offset: const Offset(0, -5),
                    child: _SearchBar(
                        controller: _searchCtrl,
                        onChanged: (_) {}),
                  ),
                  const SizedBox(height: 6),
                  _FilterChips(
                    selected: _statusFilter,
                    onSelected: (f) {
                      setState(() { _statusFilter = f; _page = 0; });
                      _fetch();
                    },
                  ),
                  const SizedBox(height: AppMetrics.gapMd),
                  if (_loading)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(
                          color: AppColors.accentGreen),
                    ))
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.cardWhite,
                        borderRadius:
                            BorderRadius.circular(AppMetrics.cardRadius),
                      ),
                      child: _users.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(32),
                              child: Center(child: Text(
                                  'No users found.',
                                  style: AppTextStyles.footerNote)))
                          : Column(children: [
                              for (int i = 0; i < _users.length; i++)
                                _UserRow(
                                  user: _users[i],
                                  showDivider: i != _users.length - 1,
                                ),
                            ]),
                    ),
                  const SizedBox(height: AppMetrics.gapMd),
                  Center(child: Text(
                    'Page ${_page + 1} · showing ${_users.length} of $_totalCount',
                    style: AppTextStyles.footerNote,
                  )),
                ],
              ),
            ),
          ),
        ]),
      ),
    ),
    );

  }
}

// ── Sub-widgets (unchanged from static version) ───────────────────────────────

class _Header extends StatelessWidget {
  final int total, suspended;
  const _Header({required this.total, required this.suspended});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(
        AppMetrics.pagePadding, 16, AppMetrics.pagePadding, 48),
    decoration: const BoxDecoration(
      color: AppColors.darkGreen,
      borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppMetrics.headerRadius)),
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      IconButton(
        onPressed: () => Navigator.of(context).canPop()
            ? Navigator.of(context).pop()
            : Navigator.of(context)
                .pushReplacementNamed(AdminRoutes.dashboard),
        icon: const Icon(Icons.chevron_left_rounded, color: Colors.white),
        padding: EdgeInsets.zero,
      ),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Users', style: AppTextStyles.headerTitle),
        const SizedBox(height: 4),
        Text('$total total · $suspended suspended',
            style: AppTextStyles.headerSubtitle),
      ])),
      // Container(
      //   width: 44, height: 44,
      //   decoration: BoxDecoration(
      //       color: AppColors.darkGreenLight,
      //       borderRadius: BorderRadius.circular(14)),
      //   child: const Icon(Icons.file_download_outlined,
      //       color: Colors.white, size: 20),
      // ),
    ]),
  );
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16)),
    child: TextField(
      controller: controller, onChanged: onChanged,
      style: AppTextStyles.rowValue.copyWith(fontWeight: FontWeight.w400),
      decoration: InputDecoration(
        hintText: 'Search name or email...',
        hintStyle: AppTextStyles.emailSubtle,
        prefixIcon: const Icon(Icons.search_rounded,
            color: AppColors.textSecondary),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
    ),
  );
}

class _FilterChips extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;
  const _FilterChips({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final items = [('', 'All'), ('ACTIVE', 'Active'),
        ('SUSPENDED', 'Suspended'), ('DELETED', 'Deleted')];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (val, label) = items[i];
          final isSel = val == selected;
          return ChoiceChip(
            label: Text(label),
            selected: isSel,
            onSelected: (_) => onSelected(val),
            showCheckmark: false,
            labelStyle: TextStyle(
                color: isSel ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w600, fontSize: 13.5),
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
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(user.name, style: AppTextStyles.nameBold),
            const SizedBox(height: 2),
            Text(user.email, style: AppTextStyles.emailSubtle),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            StatusBadge.status(user.status),
            const SizedBox(height: 6),
            Text(user.plan.label, style: AppTextStyles.footerNote
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
