import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefHelper {

  // =========================================================
  // 🔥 INSTANCE
  // =========================================================

  static SharedPreferences? _prefs;

  // =========================================================
  // 🔥 INIT
  // =========================================================

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // =========================================================
  // 🔥 KEYS
  // =========================================================

  static const String APP_RESTART_STATE = 'app_restart_state_watcher';
  static const String loginData = 'login_user_data';
  static const String loginRememberData = 'login_user_data_for_remember_me';
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String disclaimerAcknowledged = 'disclaimer_acknowledged';

  //currency selection fields:
  static const String selectedCurrencyId     = 'selected_currency_id';
  static const String selectedCurrencySymbol = 'selected_currency_symbol';
  static const String selectedCurrencyCode   = 'selected_currency_code';
  static const String selectedCurrencyName   = 'selected_currency_name';

  // above used only


  static const String userData = 'user_data';

  static const String isLoggedIn = 'is_logged_in';

  static const String themeMode = 'theme_mode';

  static const String languageCode = 'language_code';

  static const String showAds = 'show_ads';

  static const String planCode = 'plan_code';

  static const String onboardingDone =
      'onboarding_done';

  // =========================================================
  // 🔥 STRING
  // =========================================================

  static Future<bool> saveString(
      String key,
      String value,
      ) async {
    return await _prefs!.setString(key, value);
  }

  static String getString(
      String key, {
        String defaultValue = '',
      }) {
    return _prefs?.getString(key) ?? defaultValue;
  }

  // =========================================================
  // 🔥 BOOL
  // =========================================================

  static Future<bool> saveBool(
      String key,
      bool value,
      ) async {
    return await _prefs!.setBool(key, value);
  }

  static bool getBool(
      String key, {
        bool defaultValue = false,
      }) {
    return _prefs?.getBool(key) ?? defaultValue;
  }

  // =========================================================
  // 🔥 INT
  // =========================================================

  static Future<bool> saveInt(
      String key,
      int value,
      ) async {
    return await _prefs!.setInt(key, value);
  }

  static int getInt(
      String key, {
        int defaultValue = 0,
      }) {
    return _prefs?.getInt(key) ?? defaultValue;
  }

  // =========================================================
  // 🔥 DOUBLE
  // =========================================================

  static Future<bool> saveDouble(
      String key,
      double value,
      ) async {
    return await _prefs!.setDouble(key, value);
  }

  static double getDouble(
      String key, {
        double defaultValue = 0.0,
      }) {
    return _prefs?.getDouble(key) ?? defaultValue;
  }

  // =========================================================
  // 🔥 STRING LIST
  // =========================================================

  static Future<bool> saveStringList(
      String key,
      List<String> value,
      ) async {
    return await _prefs!.setStringList(key, value);
  }

  static List<String> getStringList(
      String key,
      ) {
    return _prefs?.getStringList(key) ?? [];
  }

  // =========================================================
  // 🔥 SAVE OBJECT
  // =========================================================

  static Future<bool> saveObject(
      String key,
      Map<String, dynamic> value,
      ) async {
    final jsonString = jsonEncode(value);

    return await _prefs!.setString(
      key,
      jsonString,
    );
  }

  // =========================================================
  // 🔥 GET OBJECT
  // =========================================================

  static Map<String, dynamic>? getObject(
      String key,
      ) {
    final jsonString = _prefs?.getString(key);

    if (jsonString == null || jsonString.isEmpty) {
      return null;
    }

    try {
      return jsonDecode(jsonString);
    } catch (e) {

      debugPrint(
        'SharedPref decode error => $e',
      );

      return null;
    }
  }

  // =========================================================
  // 🔥 REMOVE KEY
  // =========================================================

  static Future<bool> remove(
      String key,
      ) async {
    return await _prefs!.remove(key);
  }

  // =========================================================
  // 🔥 CURRENCY UTILS
  // =========================================================

  /// Returns the saved currency symbol, or '\$' as a safe default.
  static Future<String> getSelectedCurrencySymbol() async {
    final symbol = await getString(selectedCurrencySymbol);
    return (symbol != null && symbol.isNotEmpty) ? symbol : '\$';
  }

  /// Returns the saved currency code, or 'USD' as a safe default.
  static Future<String> getSelectedCurrencyCode() async {
    final code = await getString(selectedCurrencyCode);
    return (code != null && code.isNotEmpty) ? code : 'USD';
  }


  // =========================================================
  // 🔥 CLEAR ALL
  // =========================================================

  static Future<bool> clearAll() async {
    // Preserve these across logout/clear
    final userData    = SharedPrefHelper.getObject(SharedPrefHelper.loginRememberData);
    final refToken    = await SharedPrefHelper.getString(SharedPrefHelper.refreshToken);
    final currId      = await SharedPrefHelper.getString(SharedPrefHelper.selectedCurrencyId);
    final currSymbol  = await SharedPrefHelper.getString(SharedPrefHelper.selectedCurrencySymbol);
    final currCode    = await SharedPrefHelper.getString(SharedPrefHelper.selectedCurrencyCode);
    final currName    = await SharedPrefHelper.getString(SharedPrefHelper.selectedCurrencyName);

    final flag = await _prefs!.clear();

    // Restore preserved values
    await SharedPrefHelper.saveObject(SharedPrefHelper.loginRememberData, userData ?? {});
    await SharedPrefHelper.saveString(SharedPrefHelper.refreshToken, refToken ?? '');

    if (currId     != null) await SharedPrefHelper.saveString(SharedPrefHelper.selectedCurrencyId,     currId);
    if (currSymbol != null) await SharedPrefHelper.saveString(SharedPrefHelper.selectedCurrencySymbol, currSymbol);
    if (currCode   != null) await SharedPrefHelper.saveString(SharedPrefHelper.selectedCurrencyCode,   currCode);
    if (currName   != null) await SharedPrefHelper.saveString(SharedPrefHelper.selectedCurrencyName,   currName);

    return flag;
  }


  // =========================================================
  // 🔥 CONTAINS
  // =========================================================

  static bool contains(
      String key,
      ) {
    return _prefs!.containsKey(key);
  }
}