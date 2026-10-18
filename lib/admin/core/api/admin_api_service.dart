import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../core/routes/admin_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../../client/core/remote_config/remote_config_service.dart'; // ← new
import '../../../client/core/theme/session_refresh_screen.dart';
import '../../../client/core/utils/shared_pref_helper.dart';
import 'admin_endpoints.dart';

// ── Loading helper (admin-scoped) ─────────────────────────────────────────────

class _AdminLoader {
  static OverlayEntry? _entry;

  static void show(BuildContext context) {
    if (_entry != null) return;
    _entry = OverlayEntry(builder: (_) => const _AdminLoaderWidget());
    Overlay.of(context).insert(_entry!);
  }

  static void hide() {
    _entry?.remove();
    _entry = null;
  }
}

class _AdminLoaderWidget extends StatelessWidget {
  const _AdminLoaderWidget();

  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: Colors.transparent,
    body: Center(
      child: CircularProgressIndicator(color: AppColors.accentGreen),
    ),
  );
}

// ── Admin API Service ─────────────────────────────────────────────────────────

class AdminApiService {

  AdminApiService._();

  // ── BASE URL  — resolved from Firebase Remote Config ─────────────────────
  //    Same source as the client ApiService so both modules always agree.
  static String get baseUrl    => RemoteConfigService.baseUrl;
  static String get baseImgUrl => RemoteConfigService.baseImgUrl;

  static bool _isRefreshing = false;

  // ── Headers ───────────────────────────────────────────────────────────────

  static Map<String, String> _headers({String? token}) => {
    'Content-Type': 'application/json',
    'Accept'      : 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  // ── Token helpers ─────────────────────────────────────────────────────────

  static String _accessToken() =>
      SharedPrefHelper.getString(SharedPrefHelper.accessToken);

  static String _refreshToken() =>
      SharedPrefHelper.getString(SharedPrefHelper.refreshToken);

  // ── GET ───────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> get(
      BuildContext context,
      String endpoint, {
        Map<String, dynamic>? queryParams,
        bool showLoader = true,
      }) async {
    try {
      if (showLoader) _AdminLoader.show(context);

      final token = _accessToken();
      var uri = Uri.parse('$baseUrl$endpoint');
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(
          queryParameters: queryParams.map((k, v) => MapEntry(k, v.toString())),
        );
      }

      debugPrint('[AdminAPI] GET  => $uri');
      debugPrint('[AdminAPI] TOKEN => ${token.substring(0, token.length.clamp(0, 20))}...');

      final response = await http.get(uri, headers: _headers(token: token));
      if (showLoader) _AdminLoader.hide();

      debugPrint('[AdminAPI] STATUS => ${response.statusCode}');
      debugPrint('[AdminAPI] BODY   => ${response.body.substring(0, response.body.length.clamp(0, 300))}');

      if (await _handleUnauthorised(context, response)) {
        return await get(context, endpoint,
            queryParams: queryParams, showLoader: showLoader);
      }

      return _parse(response);
    } on SocketException {
      if (showLoader) _AdminLoader.hide();
      debugPrint('[AdminAPI] GET NETWORK ERROR => No internet');
      throw 'No internet connection';
    } catch (e) {
      if (showLoader) _AdminLoader.hide();
      debugPrint('[AdminAPI] GET ERROR => $e');
      rethrow;
    }
  }

  // ── POST ──────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> post(
      BuildContext context,
      String endpoint, {
        Map<String, dynamic>? body,
        bool showLoader = true,
        bool useRefreshToken = false,
      }) async {
    try {
      if (showLoader) _AdminLoader.show(context);

      final token = useRefreshToken ? _refreshToken() : _accessToken();
      final uri   = Uri.parse('$baseUrl$endpoint');

      debugPrint('[AdminAPI] POST => $uri');
      debugPrint('[AdminAPI] BODY => ${jsonEncode(body)}');

      final response = await http.post(
        uri,
        headers: _headers(token: token),
        body: jsonEncode(body ?? {}),
      );
      if (showLoader) _AdminLoader.hide();

      debugPrint('[AdminAPI] STATUS => ${response.statusCode}');
      debugPrint('[AdminAPI] BODY   => ${response.body.substring(0, response.body.length.clamp(0, 300))}');

      if (!useRefreshToken && await _handleUnauthorised(context, response)) {
        return await post(context, endpoint,
            body: body, showLoader: showLoader);
      }

      return _parse(response);
    } on SocketException {
      if (showLoader) _AdminLoader.hide();
      throw 'No internet connection';
    } catch (e) {
      if (showLoader) _AdminLoader.hide();
      debugPrint('[AdminAPI] POST ERROR => $e');
      rethrow;
    }
  }

  // ── PATCH ─────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> patch(
      BuildContext context,
      String endpoint, {
        Map<String, dynamic>? body,
        bool showLoader = true,
      }) async {
    try {
      if (showLoader) _AdminLoader.show(context);

      final token = _accessToken();
      final uri   = Uri.parse('$baseUrl$endpoint');

      debugPrint('[AdminAPI] PATCH => $uri');
      debugPrint('[AdminAPI] BODY  => ${jsonEncode(body)}');

      final response = await http.patch(
        uri,
        headers: _headers(token: token),
        body: jsonEncode(body ?? {}),
      );
      if (showLoader) _AdminLoader.hide();

      debugPrint('[AdminAPI] STATUS => ${response.statusCode}');

      if (await _handleUnauthorised(context, response)) {
        return await patch(context, endpoint,
            body: body, showLoader: showLoader);
      }

      return _parse(response);
    } on SocketException {
      if (showLoader) _AdminLoader.hide();
      throw 'No internet connection';
    } catch (e) {
      if (showLoader) _AdminLoader.hide();
      rethrow;
    }
  }

  // ── DELETE ────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> delete(
      BuildContext context,
      String endpoint, {
        bool showLoader = true,
      }) async {
    try {
      if (showLoader) _AdminLoader.show(context);

      final token = _accessToken();
      final uri   = Uri.parse('$baseUrl$endpoint');

      debugPrint('[AdminAPI] DELETE => $uri');

      final response = await http.delete(uri, headers: _headers(token: token));
      if (showLoader) _AdminLoader.hide();

      debugPrint('[AdminAPI] STATUS => ${response.statusCode}');

      if (await _handleUnauthorised(context, response)) {
        return await delete(context, endpoint, showLoader: showLoader);
      }

      return _parse(response);
    } on SocketException {
      if (showLoader) _AdminLoader.hide();
      throw 'No internet connection';
    } catch (e) {
      if (showLoader) _AdminLoader.hide();
      rethrow;
    }
  }

  // ── Session refresh ───────────────────────────────────────────────────────

  static Future<bool> _tryRefreshSession(BuildContext context) async {
    if (_isRefreshing) return false;
    _isRefreshing = true;
    bool success = false;

    try {
      await Navigator.of(context, rootNavigator: true).push(
        PageRouteBuilder<void>(
          opaque: false,
          barrierDismissible: false,
          pageBuilder: (_, __, ___) => SessionRefreshScreen(
            onRefreshComplete: (responseData) async {
              final data = (responseData['data'] ?? responseData)
              as Map<String, dynamic>;
              debugPrint('[AdminAPI] REFRESH COMPLETE => saving new tokens');
              await SharedPrefHelper.saveString(
                  SharedPrefHelper.accessToken,
                  data['accessToken']?.toString() ?? '');
              await SharedPrefHelper.saveString(
                  SharedPrefHelper.refreshToken,
                  data['refreshToken']?.toString() ?? '');
              await SharedPrefHelper.saveObject(
                  SharedPrefHelper.loginData, data);
              success = true;
            },
            onSignOut: () => _navigateToLogin(context),
          ),
        ),
      );
    } catch (e) {
      debugPrint('[AdminAPI] REFRESH NAV ERROR => $e');
    } finally {
      _isRefreshing = false;
    }

    return success;
  }

  static Future<bool> _handleUnauthorised(
      BuildContext context, http.Response response) async {
    if (response.statusCode != 401 && response.statusCode != 403) return false;
    try {
      final data    = jsonDecode(response.body) as Map<String, dynamic>;
      final message = (data['message'] ?? '').toString().toLowerCase();
      final isAuth  = message.contains('access denied') ||
          message.contains('forbidden') ||
          message.contains('unauthorized') ||
          message.contains('token expired') ||
          message.contains('invalid token');
      if (!isAuth) return false;
    } catch (_) {
      return false;
    }

    debugPrint('[AdminAPI] 401 detected — attempting session refresh');
    return _tryRefreshSession(context);
  }

  static void _navigateToLogin(BuildContext context) {
    Navigator.of(context, rootNavigator: true)
        .pushNamedAndRemoveUntil(AdminRoutes.login, (r) => false);
  }

  // ── Refresh token API call ────────────────────────────────────────────────

  static Future<Map<String, dynamic>> callRefreshTokenApi() async {
    final rt = _refreshToken();
    if (rt.isEmpty) throw Exception('No refresh token. Please sign in again.');

    final uri = Uri.parse('$baseUrl${AdminEndpoints.refresh}');
    debugPrint('[AdminAPI] REFRESH TOKEN CALL => $uri');

    final response = await http.post(
      uri,
      headers: _headers(token: rt),
      body: jsonEncode({}),
    );

    debugPrint('[AdminAPI] REFRESH STATUS => ${response.statusCode}');
    debugPrint('[AdminAPI] REFRESH BODY   => ${response.body}');

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 && data['result']?.toString() == '1') {
      return data;
    }
    throw Exception(data['message']?.toString() ?? 'Session refresh failed');
  }

  // ── Response parser ───────────────────────────────────────────────────────

  static Map<String, dynamic>? _parse(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {'data': decoded};
    } catch (e) {
      debugPrint('[AdminAPI] PARSE ERROR => $e');
      return null;
    }
  }

  // ── Snackbar helpers ──────────────────────────────────────────────────────

  static void showError(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message,
          style: const TextStyle(fontFamily: 'DMSans', fontWeight: FontWeight.w500)),
      backgroundColor: AppColors.dangerRed,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(12),
    ));
  }

  static void showSuccess(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message,
          style: const TextStyle(fontFamily: 'DMSans', fontWeight: FontWeight.w500)),
      backgroundColor: AppColors.accentGreen,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(12),
    ));
  }
}