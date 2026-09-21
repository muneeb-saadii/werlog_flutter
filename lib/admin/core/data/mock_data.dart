import '../models/admin_user.dart';
import '../models/dashboard_stats.dart';
import '../theme/app_colors.dart';

/// Static, in-memory sample data so every screen in this project is
/// runnable on its own without a backend.
class MockData {
  MockData._();

  static final DateTime _now = DateTime(2026, 9, 21, 9, 41);

  static final DashboardStats dashboardStats = DashboardStats(
    pendingJobs: 3,
    failedJobs: 2,
    mrrUsd: 149,
    totalUsers: 1284,
    newUsersThisMonth: 42,
    activeUsers: 1190,
    activeUsersPercent: 92.7,
    totalInvoices: 8640,
    invoicesLast30Days: 512,
    activeSubscriptions: 15,
    signupsLast30Days: const [8, 14, 10, 18, 15, 20, 17, 22, 16, 25, 19, 27],
    unreadNotifications: 3,
  );

  static final List<AdminUser> users = [
    AdminUser(
      id: 'c1ee4f2a-91b3-4d7e-9a10-9e2b4c1a50e3',
      name: 'Haseeb Ihsan',
      email: 'haseebmehar0304@gmail.com',
      status: UserStatus.active,
      plan: UserPlan.pro,
      role: 'ROLE_USER',
      verified: true,
      joined: DateTime(2026, 8, 1),
      lastLogin: _now.subtract(const Duration(hours: 2)),
      subscriptionSummary: 'Active · renews 30 Aug',
      avatarColor: AppColors.avatarPalette[0],
    ),
    AdminUser(
      id: 'a2f13d9c-4488-4b3a-8b60-1122ccaa3344',
      name: 'Unique Mgmt',
      email: 'unique@company.com',
      status: UserStatus.active,
      plan: UserPlan.free,
      role: 'ROLE_USER',
      verified: false,
      joined: DateTime(2026, 7, 12),
      lastLogin: _now.subtract(const Duration(hours: 5)),
      subscriptionSummary: 'Free plan',
      avatarColor: AppColors.avatarPalette[1],
    ),
    AdminUser(
      id: 'b7c2e5a1-1234-4abc-9def-556677889900',
      name: 'Sarah Khan',
      email: 'sarah.k@mail.com',
      status: UserStatus.suspended,
      plan: UserPlan.free,
      role: 'ROLE_USER',
      verified: true,
      joined: DateTime(2026, 5, 3),
      lastLogin: _now.subtract(const Duration(days: 6)),
      subscriptionSummary: 'Suspended · 19 Sep',
      avatarColor: AppColors.avatarPalette[2],
    ),
    AdminUser(
      id: 'd4e5f6a7-8899-4bcd-a1b2-c3d4e5f60011',
      name: 'Michael Jones',
      email: 'm.jones@work.io',
      status: UserStatus.active,
      plan: UserPlan.business,
      role: 'ROLE_ADMIN',
      verified: true,
      joined: DateTime(2026, 3, 21),
      lastLogin: _now.subtract(const Duration(minutes: 40)),
      subscriptionSummary: 'Active · renews 4 Oct',
      avatarColor: AppColors.avatarPalette[3],
    ),
    AdminUser(
      id: 'e5f6a7b8-99aa-4cde-b2c3-d4e5f6001122',
      name: 'Ayesha Raza',
      email: 'ayesha@startup.pk',
      status: UserStatus.deleted,
      plan: UserPlan.free,
      role: 'ROLE_USER',
      verified: false,
      joined: DateTime(2025, 12, 2),
      lastLogin: _now.subtract(const Duration(days: 90)),
      subscriptionSummary: 'Account deleted',
      avatarColor: AppColors.avatarPalette[4],
    ),
    AdminUser(
      id: 'f6a7b8c9-aabb-4def-c3d4-e5f600112233',
      name: 'David Lee',
      email: 'david.lee@gmail.com',
      status: UserStatus.active,
      plan: UserPlan.pro,
      role: 'ROLE_USER',
      verified: true,
      joined: DateTime(2026, 6, 18),
      lastLogin: _now.subtract(const Duration(hours: 1)),
      subscriptionSummary: 'Active · renews 18 Oct',
      avatarColor: AppColors.avatarPalette[5],
    ),
  ];
}
