import 'package:flutter/material.dart';

class LoadingHelper {
  static bool _isShowing = false;

  // =====================================================
  // 🔥 SHOW LOADER
  // =====================================================

  static void show(BuildContext context) {
    if (_isShowing) return;

    _isShowing = true;

    showDialog(
      context: context,
      barrierDismissible: false, // 🔥 cannot dismiss
      barrierColor: Colors.black45,
      useRootNavigator: true,

      builder: (_) {
        return WillPopScope(
          onWillPop: () async => false, // 🔥 disable back

          child: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }

  // =====================================================
  // 🔥 HIDE LOADER
  // =====================================================

  static void hide(BuildContext context) {
    if (!_isShowing) return;

    _isShowing = false;

    Navigator.of(
      context,
      rootNavigator: true,
    ).pop();
  }
}