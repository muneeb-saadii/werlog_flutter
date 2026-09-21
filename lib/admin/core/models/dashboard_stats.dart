/// Aggregate metrics shown on the dashboard / operations overview screen.
class DashboardStats {
  final int pendingJobs;
  final int failedJobs;
  final int mrrUsd;

  final int totalUsers;
  final int newUsersThisMonth;

  final int activeUsers;
  final double activeUsersPercent;

  final int totalInvoices;
  final int invoicesLast30Days;

  final int activeSubscriptions;

  /// Daily signup counts for the last N days, oldest first.
  final List<int> signupsLast30Days;

  final int unreadNotifications;

  const DashboardStats({
    required this.pendingJobs,
    required this.failedJobs,
    required this.mrrUsd,
    required this.totalUsers,
    required this.newUsersThisMonth,
    required this.activeUsers,
    required this.activeUsersPercent,
    required this.totalInvoices,
    required this.invoicesLast30Days,
    required this.activeSubscriptions,
    required this.signupsLast30Days,
    required this.unreadNotifications,
  });
}
