import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

class RemoteConfigService {
  RemoteConfigService._();

  // ── Remote Config keys ────────────────────────────────────────────────────
  static const String _kAppBaseUrl        = 'APP_BASE_URL';
  static const String _kEnableAccDeletion = 'APP_ENABLE_ACC_DELETION';
  static const String _kEnableGuestLogin  = 'APP_ENABLE_GUEST_LOGIN';   // ← NEW (bool)
  static const String _kGuestEmail        = 'GUEST_USER_EMAIL';         // ← NEW (string)
  static const String _kGuestPassword     = 'GUEST_USER_PASSWORD';      // ← NEW (string)

  // ── Fallbacks (used only when Remote Config has no / empty value) ─────────
  static const String _fallbackHost          = 'https://app.werlog.com';
  static const String _fallbackGuestEmail    = 'muhammadmuneeb@gmail.com';
  static const String _fallbackGuestPassword = '12345678';

  // ── Resolved in-memory values ─────────────────────────────────────────────
  static String _resolvedBaseUrl   = '$_fallbackHost/api/';
  static bool   _enableAccDeletion = false;   // hidden by default
  static bool   _enableGuestLogin  = false;   // hidden by default
  static String _guestEmail        = _fallbackGuestEmail;
  static String _guestPassword     = _fallbackGuestPassword;

  static String get baseUrl               => _resolvedBaseUrl;
  static bool   get enableAccountDeletion => _enableAccDeletion;
  static bool   get enableGuestLogin      => _enableGuestLogin;   // ← NEW
  static String get guestEmail            => _guestEmail;         // ← NEW
  static String get guestPassword         => _guestPassword;      // ← NEW

  static String get baseImgUrl {
    var url = _resolvedBaseUrl;
    if (url.endsWith('/'))    url = url.substring(0, url.length - 1);
    if (url.endsWith('/api')) url = url.substring(0, url.length - 4);
    return url;
  }

  static Future<void> init() async {
    try {
      final rc = FirebaseRemoteConfig.instance;

      await rc.setDefaults({
        _kAppBaseUrl:        _fallbackHost,
        _kEnableAccDeletion: false,
        _kEnableGuestLogin:  false,                  // ← default false
        _kGuestEmail:        _fallbackGuestEmail,    // ← default guest creds
        _kGuestPassword:     _fallbackGuestPassword,
      });

      await rc.setConfigSettings(RemoteConfigSettings(
        fetchTimeout:         const Duration(seconds: 10),
        minimumFetchInterval: kDebugMode
            ? Duration.zero
            : const Duration(hours: 1),
      ));

      await rc.fetchAndActivate();
      _applyValues(rc);

      debugPrint('[RemoteConfig] baseUrl           => $_resolvedBaseUrl');
      debugPrint('[RemoteConfig] enableAccDeletion => $_enableAccDeletion');
      debugPrint('[RemoteConfig] enableGuestLogin  => $_enableGuestLogin');
      debugPrint('[RemoteConfig] guestEmail        => $_guestEmail');

      rc.onConfigUpdated.listen((event) async {
        await rc.activate();
        _applyValues(rc);
        debugPrint('[RemoteConfig] updated baseUrl           => $_resolvedBaseUrl');
        debugPrint('[RemoteConfig] updated enableAccDeletion => $_enableAccDeletion');
        debugPrint('[RemoteConfig] updated enableGuestLogin  => $_enableGuestLogin');
      });

    } catch (e) {
      debugPrint('[RemoteConfig] init error (using fallback) => $e');
    }
  }

  static void _applyValues(FirebaseRemoteConfig rc) {
    // ── Base URL ────────────────────────────────────────────
    String raw = rc.getString(_kAppBaseUrl).trim();
    if (raw.isEmpty) raw = _fallbackHost;
    if (raw.endsWith('/')) raw = raw.substring(0, raw.length - 1);
    if (raw.endsWith('/api') || raw.endsWith('/api/')) {
      _resolvedBaseUrl = raw.endsWith('/') ? raw : '$raw/';
    } else {
      _resolvedBaseUrl = '$raw/api/';
    }

    // ── Feature flags (real booleans in Remote Config) ──────
    _enableAccDeletion = rc.getBool(_kEnableAccDeletion);
    _enableGuestLogin  = rc.getBool(_kEnableGuestLogin);

    // ── Guest credentials — fall back if missing / blank ────
    final gEmail = rc.getString(_kGuestEmail).trim();
    final gPass  = rc.getString(_kGuestPassword);          // don't trim a password
    _guestEmail    = gEmail.isNotEmpty ? gEmail : _fallbackGuestEmail;
    _guestPassword = gPass.isNotEmpty  ? gPass  : _fallbackGuestPassword;
  }
}