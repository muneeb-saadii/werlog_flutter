import 'package:flutter/material.dart';

import '../widgets/restart_widget.dart';

class GeneralFunctions {


  static void restartApp() {
    RestartWidget.restartApp();
  }

  // =========================================================
  // 🔥 SUCCESS SNACKBAR
  // =========================================================

  static void showSuccess(
      BuildContext context,
      String message,
      ) {
    _hideCurrent(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),

        backgroundColor: Colors.green,

        behavior: SnackBarBehavior.floating,

        margin: const EdgeInsets.all(14),

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),

        duration: const Duration(seconds: 3),
      ),
    );
  }

  // =========================================================
  // 🔥 ERROR SNACKBAR
  // =========================================================

  static void showError(
      BuildContext context,
      String message,
      ) {
    _hideCurrent(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),

        backgroundColor: Colors.redAccent,

        behavior: SnackBarBehavior.floating,

        margin: const EdgeInsets.all(14),

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),

        duration: const Duration(seconds: 3),
      ),
    );
  }

  // =========================================================
  // 🔥 INFO SNACKBAR
  // =========================================================

  static void showInfo(
      BuildContext context,
      String message,
      ) {
    _hideCurrent(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),

        backgroundColor: Colors.blueAccent,

        behavior: SnackBarBehavior.floating,

        margin: const EdgeInsets.all(14),

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),

        duration: const Duration(seconds: 3),
      ),
    );
  }

  // =========================================================
  // 🔥 HIDE CURRENT SNACKBAR
  // =========================================================

  static void _hideCurrent(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  // =========================================================
  // 🔥 KEYBOARD DISMISS
  // =========================================================

  static void hideKeyboard(BuildContext context) {
    FocusScope.of(context).unfocus();
  }

  // =========================================================
  // 🔥 SAFE STRING
  // =========================================================

  static String safeString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  // =========================================================
  // 🔥 SAFE INT
  // =========================================================

  static int safeInt(dynamic value) {
    if (value == null) return 0;

    return int.tryParse(value.toString()) ?? 0;
  }

  // =========================================================
  // 🔥 SAFE DOUBLE
  // =========================================================

  static double safeDouble(dynamic value) {
    if (value == null) return 0.0;

    return double.tryParse(value.toString()) ?? 0.0;
  }

  // =========================================================
  // 🔥 EMAIL VALIDATION
  // =========================================================

  static bool isValidEmail(String email) {
    return RegExp(
      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
    ).hasMatch(email);
  }

  // =========================================================
  // 🔥 EMPTY CHECK
  // =========================================================

  static bool isEmpty(String? value) {
    return value == null || value.trim().isEmpty;
  }
}