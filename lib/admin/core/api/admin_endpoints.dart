class AdminEndpoints {
  AdminEndpoints._();

  // ── Auth ───────────────────────────────────────────────────────────
  static const String login   = 'v1/auth/login';
  static const String refresh = 'v1/auth/refresh';
  static const String me      = 'v1/auth/me';

  // ── Analytics ──────────────────────────────────────────────────────
  static const String analyticsOverview  = 'v1/admin/analytics/overview';
  static const String analyticsSignups   = 'v1/admin/analytics/signups';
  static const String analyticsOcrUsage  = 'v1/admin/analytics/ocr-usage';
  static const String analyticsTokenUsage = 'v1/admin/analytics/token-usage';   // NEW
  static const String analyticsRevenue    = 'v1/admin/analytics/revenue';        // NEW
  // per-user token usage
  static const String analyticsAllUsersTokenUsage =
      'v1/admin/analytics/users/token-usage';                                    // NEW
  static String analyticsUserTokenUsage(String userId) =>
      'v1/admin/analytics/users/$userId/token-usage';                            // NEW

  // ── Users ──────────────────────────────────────────────────────────
  static const String adminUsers = 'v1/admin/users';
  static String adminUserDetail(String id)     => 'v1/admin/users/$id';
  static String adminUserSuspend(String id)    => 'v1/admin/users/$id/suspend';
  static String adminUserReactivate(String id) => 'v1/admin/users/$id/reactivate';
  static String adminUserGrantPlan(String id)  => 'v1/admin/users/$id/grant-plan';
  static String adminUserImpersonate(String id)=> 'v1/admin/users/$id/impersonate';
  static String adminUserDelete(String id)     => 'v1/admin/users/$id';

  // Subscription invoices
  static String adminUserSubscriptionInvoices(String userId) =>
      'v1/admin/users/$userId/subscription-invoices';

  // ── Invoices ───────────────────────────────────────────────────────
  static const String adminInvoices = 'v1/admin/invoices';
  static String adminInvoiceDelete(String id) => 'v1/admin/invoices/$id';

  // ── OCR Jobs ───────────────────────────────────────────────────────
  static const String adminOcrJobs = 'v1/admin/ocr-jobs';
  static String adminOcrJobRetry(String id) => 'v1/admin/ocr-jobs/$id/retry';

  // ── Classification review ──────────────────────────────────────────
  static const String adminAuditQueue       = 'v1/admin/categories/audit';
  static const String adminCategories       = 'v1/admin/categories';
  static const String adminReloadClassifier = 'v1/admin/categories/reload';
  static String adminReclassify(String auditId) =>
      'v1/admin/categories/audit/$auditId/reclassify';

  // ── Plans ──────────────────────────────────────────────────────────
  static const String adminPlans    = 'v1/admin/plans';
  static const String adminFreePlan = 'v1/admin/plans/free';
  static String adminPlanUpdate(String id) => 'v1/admin/plans/$id';

  // ── Audit log ──────────────────────────────────────────────────────
  static const String adminAuditLogs = 'v1/admin/audit-logs';
}