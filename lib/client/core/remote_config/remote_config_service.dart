import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// Fetches Firebase Remote Config and exposes the resolved base URL.
///
/// Usage:
///   await RemoteConfigService.init();          // call once in main()
///   final url = RemoteConfigService.baseUrl;   // use anywhere
class RemoteConfigService {
  RemoteConfigService._();

  // ── Remote Config key ─────────────────────────────────────────────────────
  static const String _kAppBaseUrl = 'APP_BASE_URL';

  // ── Hard-coded fallback (used when Remote Config is unreachable) ──────────
  static const String _fallbackHost = 'https://werlog.com';

  // ── In-memory resolved values ─────────────────────────────────────────────
  static String _resolvedBaseUrl = '$_fallbackHost/api/';

  /// Full base URL including trailing `api/`.
  /// e.g. `https://werlog.com/api/`
  static String get baseUrl => _resolvedBaseUrl;

  /// Host-only URL (no path) used for image URLs.
  /// e.g. `https://werlog.com`
  static String get baseImgUrl {
    // Strip trailing slash and /api/ path to get the origin
    var url = _resolvedBaseUrl;
    // Remove trailing slash
    if (url.endsWith('/')) url = url.substring(0, url.length - 1);
    // Remove /api suffix if present
    if (url.endsWith('/api')) url = url.substring(0, url.length - 4);
    return url;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // init()  — call once in main() after Firebase.initializeApp()
  // ─────────────────────────────────────────────────────────────────────────

  static Future<void> init() async {
    try {
      final rc = FirebaseRemoteConfig.instance;

      // Set defaults so the app works even without a network connection
      await rc.setDefaults({
        _kAppBaseUrl: _fallbackHost,
      });

      // Aggressive fetch settings for development; loosen for production
      await rc.setConfigSettings(RemoteConfigSettings(
        fetchTimeout:          const Duration(seconds: 10),
        minimumFetchInterval:  kDebugMode
            ? Duration.zero            // always fresh in debug
            : const Duration(hours: 1), // cached in release
      ));

      // Fetch & activate in one call — non-throwing
      await rc.fetchAndActivate();

      _applyValues(rc);
      debugPrint('[RemoteConfig] baseUrl => $_resolvedBaseUrl');

      // Keep listening so changes propagate while the app is running
      rc.onConfigUpdated.listen((event) async {
        await rc.activate();
        _applyValues(rc);
        debugPrint('[RemoteConfig] updated => $_resolvedBaseUrl');
      });

    } catch (e) {
      // Network error, quota exceeded, etc. — fall back silently
      debugPrint('[RemoteConfig] init error (using fallback) => $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // _applyValues()  — parse the fetched value and build the baseUrl
  // ─────────────────────────────────────────────────────────────────────────

  static void _applyValues(FirebaseRemoteConfig rc) {
    String raw = rc.getString(_kAppBaseUrl).trim();

    if (raw.isEmpty) {
      raw = _fallbackHost;
      debugPrint('[RemoteConfig] APP_BASE_URL is empty — using fallback');
    }

    // Normalise: ensure no double-slash, always ends with /api/
    // Strip any trailing slash first
    if (raw.endsWith('/')) raw = raw.substring(0, raw.length - 1);

    // If the value already includes /api, use it as-is (just ensure trailing /)
    if (raw.endsWith('/api') || raw.endsWith('/api/')) {
      _resolvedBaseUrl = raw.endsWith('/') ? raw : '$raw/';
    } else {
      // Append /api/
      _resolvedBaseUrl = '$raw/api/';
    }
  }
}