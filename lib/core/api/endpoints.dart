

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
  static const String UPDATE_INVOICE_DETAILS = 'v1/warranty/update/invoice';

  static const String EXPENSE_DASHBOARD_DETAILS = 'v1/expense/details?year=';
  static const String EXPENSE_CATEGORY_DETAILS = 'v1/expense/category/';
  static const String EXPENSE_TAX_YEARS = 'v1/expense/tax-years';

  static const String SCANNED_OCR_JOB_DETAILS = 'v1/ocr/jobs/';
  static const String UPLOAD_SCANNED_IMAGE = 'v1/ocr/upload';


  static const String UPDATE_USER_PROFILE = 'v1/users/updateProfile';
  static const String GET_USER_NOTIFICATIONS = 'v1/notifications'; //page=0&size=20

}