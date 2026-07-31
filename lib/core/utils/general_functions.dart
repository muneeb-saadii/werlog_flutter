import 'dart:io';

import 'package:flutter/material.dart';
import 'package:wellness/core/utils/shared_pref_helper.dart';

import '../../ui/screens/profile_segment/currency_screen.dart';
import '../widgets/restart_widget.dart';

class GeneralFunctions {


  static void restartApp() {
    RestartWidget.restartApp();
  }
  static Future<void> resetAppState() async {
    await SharedPrefHelper.saveBool(SharedPrefHelper.APP_RESTART_STATE, true);
    RestartWidget.restartApp();
  }


  // =========================================================
  // 🔥 CURRENCY SYMBOL
  // =========================================================

  static String currencySymbol = "USD";
  static Future<String> getCurrencySymbol_old() async {
    final symbol = await SharedPrefHelper.getString(
        SharedPrefHelper.selectedCurrencySymbol);
    currencySymbol = (symbol != null && symbol.isNotEmpty) ? "$symbol " : '\$';
    return (symbol != null && symbol.isNotEmpty) ? symbol : '\$';
  }
  static Future<String> getCurrencySymbol() async {
    final symbol = await SharedPrefHelper.getString(
        SharedPrefHelper.selectedCurrencyCode/*selectedCurrencySymbol*/);
    currencySymbol = (symbol != null && symbol.isNotEmpty)
        ? '${symbol} '
        : '\$ ';
    return currencySymbol.trim();
  }
  static String replaceCurrencySymbol(String text) {
    try {
      return text.replaceAll('\$', currencySymbol);
    } catch (_) {
      return text;
    }
  }

  /// Called once on first login.
  /// Detects device locale → finds matching currency in the fixed list →
  /// saves it. If region not in list, keeps $ as default.
  static Future<void> initCurrencyForNewUser() async {
    print("::initCurrencyForNewUser called");

    // Skip if user already has a saved currency (returning user)
    final existing = await SharedPrefHelper.getString(
        SharedPrefHelper.selectedCurrencyId);
    print("::initCurrencyForNewUser existing currency id => $existing");

    if (existing != null && existing.isNotEmpty) {
      print("::initCurrencyForNewUser skipping — currency already set: $existing");
      return;
    }

    // Get device locale country code e.g. "PK", "US", "GB"
    final String localeName = Platform.localeName;
    final String countryCode = localeName.split('_').last.toUpperCase();
    print("::initCurrencyForNewUser localeName => $localeName");
    print("::initCurrencyForNewUser countryCode => $countryCode");

    // Map country code → currency code
    final String? currencyCode = _countryToCurrency[countryCode];
    print("::initCurrencyForNewUser mapped currencyCode => $currencyCode");

    if (currencyCode == null) {
      print("::initCurrencyForNewUser country not in map — keeping \$ default");
      return;
    }

    // Find matching CurrencyItem in the fixed list
    final match = kCurrencies.firstWhere(
          (c) => c.code.toUpperCase() == currencyCode.toUpperCase(),
      orElse: () => const CurrencyItem(
          id: 'usd', code: 'USD', symbol: '\$',
          name: 'US Dollar', country: 'United States', region: 'Americas'),
    );
    print("::initCurrencyForNewUser matched => id:${match.id} code:${match.code} symbol:${match.symbol} name:${match.name}");

    // Save all four fields
    await SharedPrefHelper.saveString(
        SharedPrefHelper.selectedCurrencyId,     match.id);
    await SharedPrefHelper.saveString(
        SharedPrefHelper.selectedCurrencySymbol, match.symbol);
    await SharedPrefHelper.saveString(
        SharedPrefHelper.selectedCurrencyCode,   match.code);
    await SharedPrefHelper.saveString(
        SharedPrefHelper.selectedCurrencyName,   match.name);
    print("::initCurrencyForNewUser saved to SharedPref successfully");

    // Update in-memory symbol immediately
    currencySymbol = '${match.code/*symbol*/} ';
    print("::initCurrencyForNewUser in-memory currencySymbol updated => $currencySymbol");
  }

  /// Country code → ISO 4217 currency code
  /// Only countries covered by your fixed _kCurrencies list.
  /// Everything else falls through to $ default — no conflict.
  static List<CurrencyItem> kCurrencies = [
    CurrencyItem(id:'usd', code:'USD', symbol:'\$',  name:'US Dollar',          country:'United States',    region:'Americas'),
    CurrencyItem(id:'eur', code:'EUR', symbol:'€',   name:'Euro',               country:'Eurozone',         region:'Europe'),
    CurrencyItem(id:'gbp', code:'GBP', symbol:'£',   name:'British Pound',      country:'United Kingdom',   region:'Europe'),
    CurrencyItem(id:'pkr', code:'PKR', symbol:'₨',   name:'Pakistani Rupee',    country:'Pakistan',         region:'Asia'),
    CurrencyItem(id:'inr', code:'INR', symbol:'₹',   name:'Indian Rupee',       country:'India',            region:'Asia'),
    CurrencyItem(id:'aed', code:'AED', symbol:'د.إ', name:'UAE Dirham',         country:'United Arab Emirates', region:'Middle East'),
    CurrencyItem(id:'sar', code:'SAR', symbol:'﷼',   name:'Saudi Riyal',        country:'Saudi Arabia',     region:'Middle East'),
    CurrencyItem(id:'cad', code:'CAD', symbol:'CA\$',name:'Canadian Dollar',    country:'Canada',           region:'Americas'),
    CurrencyItem(id:'aud', code:'AUD', symbol:'A\$', name:'Australian Dollar',  country:'Australia',        region:'Oceania'),
    CurrencyItem(id:'jpy', code:'JPY', symbol:'¥',   name:'Japanese Yen',       country:'Japan',            region:'Asia'),
    CurrencyItem(id:'cny', code:'CNY', symbol:'¥',   name:'Chinese Yuan',       country:'China',            region:'Asia'),
    CurrencyItem(id:'chf', code:'CHF', symbol:'Fr',  name:'Swiss Franc',        country:'Switzerland',      region:'Europe'),
    CurrencyItem(id:'sgd', code:'SGD', symbol:'S\$', name:'Singapore Dollar',   country:'Singapore',        region:'Asia'),
    CurrencyItem(id:'myr', code:'MYR', symbol:'RM',  name:'Malaysian Ringgit',  country:'Malaysia',         region:'Asia'),
    CurrencyItem(id:'bdt', code:'BDT', symbol:'৳',   name:'Bangladeshi Taka',   country:'Bangladesh',       region:'Asia'),
    CurrencyItem(id:'qar', code:'QAR', symbol:'﷼',   name:'Qatari Riyal',       country:'Qatar',            region:'Middle East'),
    CurrencyItem(id:'kwd', code:'KWD', symbol:'KD',  name:'Kuwaiti Dinar',      country:'Kuwait',           region:'Middle East'),
    CurrencyItem(id:'omr', code:'OMR', symbol:'﷼',   name:'Omani Rial',         country:'Oman',             region:'Middle East'),
    CurrencyItem(id:'brl', code:'BRL', symbol:'R\$', name:'Brazilian Real',     country:'Brazil',           region:'Americas'),
    CurrencyItem(id:'zar', code:'ZAR', symbol:'R',   name:'South African Rand', country:'South Africa',     region:'Africa'),
    CurrencyItem(id:'nzd', code:'NZD', symbol:'NZ\$',name:'New Zealand Dollar', country:'New Zealand',      region:'Oceania'),
    CurrencyItem(id:'nok', code:'NOK', symbol:'kr',  name:'Norwegian Krone',    country:'Norway',           region:'Europe'),
    CurrencyItem(id:'sek', code:'SEK', symbol:'kr',  name:'Swedish Krona',      country:'Sweden',           region:'Europe'),
    CurrencyItem(id:'dkk', code:'DKK', symbol:'kr',  name:'Danish Krone',       country:'Denmark',          region:'Europe'),
    CurrencyItem(id:'mxn', code:'MXN', symbol:'Mex\$',name:'Mexican Peso',      country:'Mexico',           region:'Americas'),
    CurrencyItem(id:'php', code:'PHP', symbol:'₱',   name:'Philippine Peso',    country:'Philippines',      region:'Asia'),
    CurrencyItem(id:'thb', code:'THB', symbol:'฿',   name:'Thai Baht',          country:'Thailand',         region:'Asia'),
    CurrencyItem(id:'idr', code:'IDR', symbol:'Rp',  name:'Indonesian Rupiah',  country:'Indonesia',        region:'Asia'),
    CurrencyItem(id:'try', code:'TRY', symbol:'₺',   name:'Turkish Lira',       country:'Turkey',           region:'Europe'),
    CurrencyItem(id:'egp', code:'EGP', symbol:'E£',  name:'Egyptian Pound',     country:'Egypt',            region:'Africa'),
  ];

  static const Map<String, String> _countryToCurrency = {
    'US': 'USD', // United States
    'GB': 'GBP', // United Kingdom
    'PK': 'PKR', // Pakistan
    'IN': 'INR', // India
    'AE': 'AED', // UAE
    'SA': 'SAR', // Saudi Arabia
    'CA': 'CAD', // Canada
    'AU': 'AUD', // Australia
    'JP': 'JPY', // Japan
    'CN': 'CNY', // China
    'CH': 'CHF', // Switzerland
    'SG': 'SGD', // Singapore
    'MY': 'MYR', // Malaysia
    'BD': 'BDT', // Bangladesh
    'QA': 'QAR', // Qatar
    'KW': 'KWD', // Kuwait
    'OM': 'OMR', // Oman
    'BR': 'BRL', // Brazil
    'ZA': 'ZAR', // South Africa
    'NZ': 'NZD', // New Zealand
    'NO': 'NOK', // Norway
    'SE': 'SEK', // Sweden
    'DK': 'DKK', // Denmark
    'MX': 'MXN', // Mexico
    'PH': 'PHP', // Philippines
    'TH': 'THB', // Thailand
    'ID': 'IDR', // Indonesia
    'TR': 'TRY', // Turkey
    'EG': 'EGP', // Egypt
    // Eurozone countries → EUR
    'DE': 'EUR', 'FR': 'EUR', 'IT': 'EUR', 'ES': 'EUR',
    'NL': 'EUR', 'BE': 'EUR', 'AT': 'EUR', 'PT': 'EUR',
    'FI': 'EUR', 'IE': 'EUR', 'GR': 'EUR', 'LU': 'EUR',
  };

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