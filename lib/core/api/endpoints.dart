

class Endpoints {
  // =========================================================
  // 🔥 API END POINTS
  // =========================================================

  static const String REGISTER_USER = 'v1/auth/register';
  static const String LOGIN_USER = 'v1/auth/login';
  static const String RESEND_OTP = 'v1/auth/resendOtp';
  static const String VERIFY_OTP = 'v1/auth/verifyOtp';

  static const String USER_MAIN_DASHBOARD = 'v1/dashboard';
  static const String WARRANTY_DASHBOARD_DETAILS = 'v1/warranty/details';
  static const String WARRANTY_CATEGORY_LIST = 'v1/warranty/';
  static const String EXPENSE_DASHBOARD_DETAILS = 'v1/expense/details?year=2026';
  static const String EXPENSE_TAX_YEARS = 'v1/expense/tax-years';

  static const String SCANNED_OCR_JOB_DETAILS = 'v1/ocr/jobs/';
  static const String UPLOAD_SCANNED_IMAGE = 'v1/ocr/jobs';

}