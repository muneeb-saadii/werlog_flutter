import 'package:flutter/material.dart';
import '../../core/data/mock_data.dart';
import '../../core/models/admin_user.dart';
import '../../core/routes/admin_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/admin_bottom_nav.dart';
import '../widgets/status_badge.dart';
import '../widgets/user_avatar.dart';

enum _UserFilter { all, active, suspended, deleted }

/// Users list screen: search, status filter chips, and a scrollable
/// list of user rows that open the User details screen when tapped.
class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  final TextEditingController _searchController = TextEditingController();
  _UserFilter _filter = _UserFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AdminUser> get _filteredUsers {
    final query = _searchController.text.trim().toLowerCase();
    return MockData.users.where((u) {
      final matchesFilter = switch (_filter) {
        _UserFilter.all => true,
        _UserFilter.active => u.status == UserStatus.active,
        _UserFilter.suspended => u.status == UserStatus.suspended,
        _UserFilter.deleted => u.status == UserStatus.deleted,
      };
      if (!matchesFilter) return false;
      if (query.isEmpty) return true;
      return u.name.toLowerCase().contains(query) || u.email.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final users = _filteredUsers;
    final suspendedCount = MockData.users.where((u) => u.status == UserStatus.suspended).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: const AdminBottomNav(currentIndex: 1),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(total: MockData.users.length, suspended: suspendedCount),
            const SizedBox(height: 15),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppMetrics.pagePadding, 0, AppMetrics.pagePadding, 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Transform.translate(
                      offset: const Offset(0, -5),
                      child: _SearchBar(controller: _searchController, onChanged: (_) => setState(() {})),
                    ),
                    const SizedBox(height: 6),
                    _FilterChips(
                      selected: _filter,
                      onSelected: (f) => setState(() => _filter = f),
                    ),
                    const SizedBox(height: AppMetrics.gapMd),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.cardWhite,
                        borderRadius: BorderRadius.circular(AppMetrics.cardRadius),
                      ),
                      child: users.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(32),
                              child: Center(
                                child: Text('No users match your search.', style: AppTextStyles.footerNote),
                              ),
                            )
                          : Column(
                              children: [
                                for (int i = 0; i < users.length; i++)
                                  _UserRow(
                                    user: users[i],
                                    showDivider: i != users.length - 1,
                                  ),
                              ],
                            ),
                    ),
                    const SizedBox(height: AppMetrics.gapMd),
                    Center(
                      child: Text(
                        'Page 1 of 65 · showing ${users.length}',
                        style: AppTextStyles.footerNote,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final int total;
  final int suspended;

  const _Header({required this.total, required this.suspended});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppMetrics.pagePadding, 16, AppMetrics.pagePadding, 48,
      ),
      decoration: const BoxDecoration(
        color: AppColors.darkGreen,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppMetrics.headerRadius),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).canPop()
                ? Navigator.of(context).pop()
                : Navigator.of(context).pushReplacementNamed(AdminRoutes.dashboard),
            icon: const Icon(Icons.chevron_left_rounded, color: Colors.white),
            padding: EdgeInsets.zero,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Users', style: AppTextStyles.headerTitle),
                const SizedBox(height: 4),
                Text('$total total · $suspended suspended', style: AppTextStyles.headerSubtitle),
              ],
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.darkGreenLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.file_download_outlined, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: AppTextStyles.rowValue.copyWith(fontWeight: FontWeight.w400),
        decoration: InputDecoration(
          hintText: 'Search name or email...',
          hintStyle: AppTextStyles.emailSubtle,
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  final _UserFilter selected;
  final ValueChanged<_UserFilter> onSelected;

  const _FilterChips({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final items = const [
      (_UserFilter.all, 'All'),
      (_UserFilter.active, 'Active'),
      (_UserFilter.suspended, 'Suspended'),
      (_UserFilter.deleted, 'Deleted'),
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (filter, label) = items[index];
          final isSelected = filter == selected;
          return ChoiceChip(
            label: Text(label),
            selected: isSelected,
            onSelected: (_) => onSelected(filter),
            showCheckmark: false,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13.5,
            ),
            selectedColor: AppColors.darkGreen,
            backgroundColor: AppColors.cardWhite,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).pushNamed(AdminRoutes.userDetail, arguments: user),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          children: [
            Row(
              children: [
                UserAvatar(initials: user.initials, color: user.avatarColor),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name, style: AppTextStyles.nameBold),
                      const SizedBox(height: 2),
                      Text(user.email, style: AppTextStyles.emailSubtle),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    StatusBadge.status(user.status),
                    const SizedBox(height: 6),
                    Text(
                      user.plan.label,
                      style: AppTextStyles.footerNote.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ],
            ),
            if (showDivider) const Padding(
              padding: EdgeInsets.only(top: 14),
              child: Divider(height: 1, color: AppColors.divider),
            ),
          ],
        ),
      ),
    );
  }
}
