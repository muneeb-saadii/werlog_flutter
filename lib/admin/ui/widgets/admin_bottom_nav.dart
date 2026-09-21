import 'package:flutter/material.dart';
import '../../core/routes/admin_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Bottom tab bar — Home · Users · Ops (raised) · Invoices · More
/// currentIndex: 0=Home 1=Users 2=Ops 3=Invoices 4=More
class AdminBottomNav extends StatelessWidget {
  final int currentIndex;
  const AdminBottomNav({super.key, required this.currentIndex});

  void _go(BuildContext context, String route) {
    if (ModalRoute.of(context)?.settings.name == route) return;
    Navigator.of(context).pushReplacementNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardWhite,
        border: Border(top: BorderSide(color: AppColors.divider, width: 1)),
      ),
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _NavItem(icon: Icons.grid_view_rounded, label: 'Home',
              selected: currentIndex == 0,
              onTap: () => _go(context, AdminRoutes.dashboard)),
          _NavItem(icon: Icons.adjust_rounded, label: 'Users',
              selected: currentIndex == 1,
              onTap: () => _go(context, AdminRoutes.usersList)),
          _OpsNavItem(
              selected: currentIndex == 2,
              onTap: () => _go(context, AdminRoutes.ocrJobs)),
          _NavItem(icon: Icons.receipt_long_rounded, label: 'Invoices',
              selected: currentIndex == 3,
              onTap: () => _go(context, AdminRoutes.invoices)),
          _NavItem(icon: Icons.menu_rounded, label: 'More',
              selected: currentIndex == 4,
              onTap: () => _go(context, AdminRoutes.more)),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label,
      required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.accentGreen : AppColors.textSecondary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 3),
          Text(label,
              style: AppTextStyles.navLabel.copyWith(color: color)),
        ]),
      ),
    );
  }
}

class _OpsNavItem extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  const _OpsNavItem({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    customBorder: const CircleBorder(),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 52, height: 52,
        decoration: BoxDecoration(
          color: selected ? AppColors.accentGreen : AppColors.darkGreen,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.autorenew_rounded,
            color: Colors.white, size: 24),
      ),
      const SizedBox(height: 3),
      Text('Ops',
          style: AppTextStyles.navLabel.copyWith(
              color: selected
                  ? AppColors.accentGreen
                  : AppColors.darkGreen)),
    ]),
  );
}
