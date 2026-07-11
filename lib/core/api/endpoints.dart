

class Endpoints {
  // =========================================================
  // 🔥 API END POINTS
  // =========================================================

  static const String REGISTER_USER = 'v1/auth/register';
  static const String LOGIN_USER = 'v1/auth/login';
  static const String RESEND_OTP = 'v1/auth/resendOtp';
  static const String FORGET_PASSWORD = 'v1/auth/forgetPassword';
  static const String VERIFY_OTP = 'v1/auth/verifyOtp';
  static const String REFRESH_SESSION_TOKEN = 'v1/auth/refresh';

  static const String USER_MAIN_DASHBOARD = 'v1/dashboard';
  static const String WARRANTY_DASHBOARD_DETAILS = 'v1/warranty/details';
  static const String WARRANTY_CATEGORY_LIST = 'v1/warranty/';
  static const String WARRANTY_INVOICES_LIST = 'v1/warranty/invoices';
  static const String UPDATE_INVOICE_DETAILS = 'v1/warranty/update/invoice';

  static const String EXPENSE_DASHBOARD_DETAILS = 'v1/expense/details?year=';
  static const String EXPENSE_CATEGORY_DETAILS = 'v1/expense/category/';
  static const String EXPENSE_TAX_YEARS = 'v1/expense/tax-years';
  static const String UPDATE_EXPENSE_CATEGORY_TAX = 'v1/expense/update/tax';
  static const String UPDATE_EXPENSE_TYPE = 'v1/ocr/updateInvoiceType';
  static const String EXPENSE_REPORTS = 'v1/reports/expenses';

  static const String SUBSCRIPTION_PLANS = 'v1/subscription/plans';
  static const String SUBSCRIPTION_USAGE = 'v1/subscription/current';
  static const String SUBSCRIBE_PLAN = 'v1/subscription/checkout';

  static const String SCANNED_OCR_JOB_DETAILS = 'v1/ocr/jobs/';
  static const String UPLOAD_SCANNED_IMAGE = 'v1/ocr/upload';


  static const String UPDATE_USER_PROFILE = 'v1/users/updateProfile';
  static const String GET_USER_NOTIFICATIONS = 'v1/notifications'; //page=0&size=20

}