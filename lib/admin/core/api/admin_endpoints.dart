/// All admin-side API endpoint paths.
/// Prefix with [AdminApiService.baseUrl] before use.
class AdminEndpoints {
  AdminEndpoints._();

  // ── Auth (shared with client) ─────────────────────────────────────
  static const String login   = 'v1/auth/login';
  static const String refresh = 'v1/auth/refresh';
  static const String me      = 'v1/auth/me';

  // ── Analytics ─────────────────────────────────────────────────────
  static const String analyticsOverview = 'v1/admin/analytics/overview';
  static const String analyticsSignups  = 'v1/admin/analytics/signups';
  static const String analyticsOcrUsage = 'v1/admin/analytics/ocr-usage';

  // ── Users ──────────────────────────────────────────────────────────
  static const String adminUsers  = 'v1/admin/users';           // GET list
  // Detail / update / delete: v1/admin/users/{id}
  static String adminUserDetail(String id)     => 'v1/admin/users/$id';
  static String adminUserSuspend(String id)    => 'v1/admin/users/$id/suspend';
  static String adminUserReactivate(String id) => 'v1/admin/users/$id/reactivate';
  static String adminUserGrantPlan(String id)  => 'v1/admin/users/$id/grant-plan';
  static String adminUserImpersonate(String id)=> 'v1/admin/users/$id/impersonate';
  static String adminUserDelete(String id)     => 'v1/admin/users/$id';

  // ── Invoices ───────────────────────────────────────────────────────
  static const String adminInvoices = 'v1/admin/invoices';      // GET list
  static String adminInvoiceDelete(String id) => 'v1/admin/invoices/$id';

  // ── OCR Jobs ───────────────────────────────────────────────────────
  static const String adminOcrJobs = 'v1/admin/ocr-jobs';       // GET list
  static String adminOcrJobRetry(String id) => 'v1/admin/ocr-jobs/$id/retry';

  // ── Classification review ──────────────────────────────────────────
  static const String adminAuditQueue = 'v1/admin/categories/audit';
  static String adminReclassify(String auditId) =>
      'v1/admin/categories/audit/$auditId/reclassify';
  static const String adminCategories      = 'v1/admin/categories';
  static const String adminReloadClassifier = 'v1/admin/categories/reload';

  // ── Plans ──────────────────────────────────────────────────────────
  static const String adminPlans    = 'v1/admin/plans';          // GET/POST
  static const String adminFreePlan = 'v1/admin/plans/free';     // GET/PUT
  static String adminPlanUpdate(String id) => 'v1/admin/plans/$id'; // PATCH/DELETE

  // ── Audit log ──────────────────────────────────────────────────────
  static const String adminAuditLogs = 'v1/admin/audit-logs';
}
