import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../ui/screens/screen_02_auth.dart';
import '../remote_config/remote_config_service.dart'; // ← new
import '../theme/session_refresh_screen.dart';
import '../utils/helpers.dart';
import '../utils/shared_pref_helper.dart';
import 'endpoints.dart';

class ApiService {
  // =========================================================
  // 🔥 BASE URL  — resolved from Firebase Remote Config
  //    Use the getter so every call picks up live updates
  //    (e.g. after a Remote Config refresh mid-session).
  // =========================================================

  static String get baseUrl    => RemoteConfigService.baseUrl;
  static String get baseImgUrl => RemoteConfigService.baseImgUrl;

  // =========================================================
  // 🔥 COMMON HEADERS
  // =========================================================

  static Map<String, String> headers({String? token}) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // =========================================================
  // 🔥 GET API
  // =========================================================

  static Future<dynamic> get(
      BuildContext context,
      String endpoint, {
        String? token,
        Map<String, dynamic>? queryParams,
        bool showLoader = true,
      }) async {
    try {
      if (showLoader) LoadingHelper.show(context);

      token ??= await SharedPrefHelper.getString(SharedPrefHelper.accessToken);

      Uri uri = Uri.parse('$baseUrl$endpoint');

      if (queryParams != null) {
        uri = uri.replace(
          queryParameters: queryParams.map(
                (key, value) => MapEntry(key, value.toString()),
          ),
        );
      }

      debugPrint('GET URL => $uri');
      debugPrint('TOKEN => $token');

      final response = await http.get(uri, headers: headers(token: token));

      try {
        final data       = jsonDecode(response.body);
        final statusCode = response.statusCode;

        if (statusCode == 401 || statusCode == 403) {
          final message = (data['message'] ?? '').toString().toLowerCase();
          if (message.contains('access denied') ||
              message.contains('forbidden') ||
              message.contains('unauthorized')) {

            if (showLoader) LoadingHelper.hide(context);

            final refreshed = await _tryRefreshSession(context);
            if (refreshed) {
              return await get(context, endpoint,
                  queryParams: queryParams, showLoader: showLoader);
            }

            await _handleSessionExpired(context);
            return null;
          }
        }
      } catch (e) {
        debugPrint('Session check error: $e');
      }

      return _handleResponse(response);

    } on SocketException {
      throw 'No internet connection';
    } catch (e) {
      throw e.toString();
    } finally {
      if (showLoader) LoadingHelper.hide(context);
    }
  }

  // =========================================================
  // 🔥 POST API
  // =========================================================

  static Future<dynamic> post(
      BuildContext context,
      String endpoint, {
        String? token,
        Map<String, dynamic>? body,
        bool showLoader = true,
      }) async {
    try {
      if (showLoader) LoadingHelper.show(context);

      token ??= await SharedPrefHelper.getString(SharedPrefHelper.accessToken);

      final uri = Uri.parse('$baseUrl$endpoint');

      debugPrint('POST URL => $uri');
      debugPrint('POST BODY => ${jsonEncode(body)}');

      final response = await http.post(
        uri,
        headers: headers(token: token),
        body: jsonEncode(body ?? {}),
      );

      if (showLoader) LoadingHelper.hide(context);

      try {
        final data       = jsonDecode(response.body);
        final statusCode = response.statusCode;

        if (statusCode == 401 || statusCode == 403) {
          final message = (data['message'] ?? '').toString().toLowerCase();
          if (message.contains('access denied') ||
              message.contains('forbidden') ||
              message.contains('unauthorized')) {

            final refreshed = await _tryRefreshSession(context);
            if (refreshed) {
              return await post(context, endpoint,
                  body: body, showLoader: showLoader);
            }

            await _handleSessionExpired(context);
            throw 'Session expired';
          }
        }
      } catch (e) {
        debugPrint('Session check error: $e');
      }

      return _handleResponse(response);

    } on SocketException {
      throw 'No internet connection';
    } catch (e) {
      throw e.toString();
    } finally {
      if (showLoader) LoadingHelper.hide(context);
    }
  }

  static Future<dynamic> post_auth(
      BuildContext context,
      String endpoint, {
        String? token,
        Map<String, dynamic>? body,
        bool showLoader = true,
      }) async {
    try {
      if (showLoader) LoadingHelper.show(context);

      token ??= await SharedPrefHelper.getString(SharedPrefHelper.accessToken);

      final uri = Uri.parse('$baseUrl$endpoint');

      debugPrint('POST URL  => $uri');
      debugPrint('POST BODY => ${jsonEncode(body)}');

      final response = await http.post(
        uri,
        headers: headers(token: token),
        body: jsonEncode(body ?? {}),
      );

      if (showLoader) LoadingHelper.hide(context);

      final statusCode = response.statusCode;
      debugPrint('STATUS CODE => $statusCode');
      debugPrint('RESPONSE    => ${response.body}');

      if (statusCode == 401 || statusCode == 403) {
        try {
          final data = jsonDecode(response.body);
          final msg  = data['message']?.toString();
          throw Exception(msg != null && msg.isNotEmpty ? msg : 'Unauthorized access');
        } catch (e) {
          if (e is Exception) rethrow;
          throw Exception('Unauthorized access');
        }
      }

      return _handleResponse(response);

    } on SocketException {
      throw Exception('No internet connection');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(e.toString());
    } finally {
      if (showLoader) LoadingHelper.hide(context);
    }
  }

  // =========================================================
  // 🔥 POST FORM-DATA API
  // =========================================================

  static Future<dynamic> postFormData(
      BuildContext context,
      String endpoint, {
        String? token,
        Map<String, String>? fields,
        List<http.MultipartFile>? files,
        bool showLoader = true,
      }) async {

    try {
      if (showLoader) LoadingHelper.show(context);

      token ??= await SharedPrefHelper.getString(SharedPrefHelper.accessToken);

      final uri = Uri.parse('$baseUrl$endpoint');

      debugPrint('FORM-DATA URL    => $uri');
      debugPrint('FORM-DATA FIELDS => $fields');
      debugPrint('FORM-DATA FILES  => ${files?.length ?? 0}');

      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(headers(token: token));
      if (fields != null) request.fields.addAll(fields);
      if (files  != null && files.isNotEmpty) request.files.addAll(files);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('STATUS CODE   => ${response.statusCode}');
      debugPrint('RESPONSE BODY => ${response.body}');

      try {
        final data       = jsonDecode(response.body);
        final statusCode = response.statusCode;

        if (statusCode == 401 || statusCode == 403) {
          final message = (data['message'] ?? '').toString().toLowerCase();
          if (message.contains('access denied') ||
              message.contains('forbidden') ||
              message.contains('unauthorized')) {

            final refreshed = await _tryRefreshSession(context);
            if (refreshed) {
              return await postFormData(context, endpoint,
                  fields: fields, files: files, showLoader: showLoader);
            }

            await _handleSessionExpired(context);
            throw 'Session expired';
          }
        }
      } catch (e) {
        debugPrint('SESSION CHECK ERROR => $e');
      }

      return _handleResponse(response);

    } on SocketException {
      throw 'No internet connection';
    } catch (e) {
      throw e.toString();
    } finally {
      if (showLoader) LoadingHelper.hide(context);
    }
  }

  // =========================================================
  // 🔥 PUT API
  // =========================================================

  static Future<dynamic> put(
      String endpoint, {
        String? token,
        Map<String, dynamic>? body,
      }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await http.put(
        uri,
        headers: headers(token: token),
        body: jsonEncode(body ?? {}),
      );
      return _handleResponse(response);
    } on SocketException {
      throw 'No internet connection';
    } catch (e) {
      throw e.toString();
    }
  }

  // =========================================================
  // 🔥 DELETE API
  // =========================================================

  static Future<dynamic> delete(
      String endpoint, {
        String? token,
      }) async {
    try {
      final uri      = Uri.parse('$baseUrl$endpoint');
      final response = await http.delete(uri, headers: headers(token: token));
      return _handleResponse(response);
    } on SocketException {
      throw 'No internet connection';
    } catch (e) {
      throw e.toString();
    }
  }

  // =========================================================
  // 🔥 UPLOAD SINGLE IMAGE
  // =========================================================

  static Future<dynamic> uploadImage(
      BuildContext context,
      String endpoint,
      File imageFile,
      String fileParamName, {
        Map<String, String>? extraFields,
        bool showLoader = true,
      }) async {
    try {
      if (showLoader) LoadingHelper.show(context);

      final token = await SharedPrefHelper.getString(SharedPrefHelper.accessToken);
      final uri   = Uri.parse('$baseUrl$endpoint');

      final request = http.MultipartRequest('POST', uri)
        ..headers.addAll({
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        });

      if (extraFields != null) request.fields.addAll(extraFields);

      final mimeType = _getMimeType(imageFile.path);
      request.files.add(await http.MultipartFile.fromPath(
        fileParamName,
        imageFile.path,
        contentType: http.MediaType(mimeType[0], mimeType[1]),
      ));

      debugPrint('UPLOAD URL      => $uri');
      debugPrint('FILE PARAM NAME => $fileParamName');

      final streamedResponse = await request.send();
      final response         = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);

    } on SocketException {
      throw 'No internet connection';
    } catch (e) {
      throw e.toString();
    } finally {
      if (showLoader) LoadingHelper.hide(context);
    }
  }

  // =========================================================
  // 🔥 UPLOAD MULTIPLE IMAGES
  // =========================================================

  static Future<dynamic> uploadImages(
      BuildContext context,
      String endpoint,
      List<File> imageFiles,
      String fileParamName, {
        Map<String, String>? extraFields,
        bool showLoader = true,
      }) async {
    try {
      if (showLoader) LoadingHelper.show(context);

      final token = await SharedPrefHelper.getString(SharedPrefHelper.accessToken);
      final uri   = Uri.parse('$baseUrl$endpoint');

      final request = http.MultipartRequest('POST', uri)
        ..headers.addAll({
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        });

      if (extraFields != null) request.fields.addAll(extraFields);

      for (final file in imageFiles) {
        final mimeType = _getMimeType(file.path);
        request.files.add(await http.MultipartFile.fromPath(
          '$fileParamName[]',
          file.path,
          contentType: http.MediaType(mimeType[0], mimeType[1]),
        ));
      }

      debugPrint('UPLOAD URL => $uri');
      debugPrint('FILE COUNT => ${imageFiles.length}');

      final streamedResponse = await request.send();
      final response         = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);

    } on SocketException {
      throw 'No internet connection';
    } catch (e) {
      throw e.toString();
    } finally {
      if (showLoader) LoadingHelper.hide(context);
    }
  }

  // =========================================================
  // 🔥 MIME TYPE HELPER
  // =========================================================

  static List<String> _getMimeType(String filePath) {
    final ext = filePath.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg': case 'jpeg': return ['image', 'jpeg'];
      case 'png':              return ['image', 'png'];
      case 'gif':              return ['image', 'gif'];
      case 'webp':             return ['image', 'webp'];
      case 'heic':             return ['image', 'heic'];
      default:                 return ['application', 'octet-stream'];
    }
  }

  // =========================================================
  // 🔥 RESPONSE HANDLER
  // =========================================================

  static dynamic _handleResponse(http.Response response) {
    debugPrint('STATUS CODE => ${response.statusCode}');
    debugPrint('RESPONSE    => ${response.body}');

    final dynamic jsonResponse = decodeJson(response.body);

    switch (response.statusCode) {
      case 200: case 201:
      return jsonResponse;
      case 400:
        throw getErrorMessage(jsonResponse);
      case 401:
        throw 'Unauthorized access';
      case 404:
        throw 'API not found';
      case 500:
        throw 'Internal server error';
      default:
        throw getErrorMessage(jsonResponse);
    }
  }

  // =========================================================
  // 🔥 JSON UTILS
  // =========================================================

  static dynamic decodeJson(String source) {
    try { return jsonDecode(source); } catch (e) { return {}; }
  }

  static String encodeJson(Map<String, dynamic> data) {
    try { return jsonEncode(data); } catch (e) { return '{}'; }
  }

  static String getErrorMessage(dynamic response) {
    try {
      if (response == null) return 'Something went wrong';
      if (response is Map<String, dynamic>) {
        return response['message']?.toString() ??
            response['error']?.toString() ??
            'Something went wrong';
      }
      return 'Something went wrong';
    } catch (e) { return 'Something went wrong'; }
  }

  static bool isSuccess(dynamic response) {
    try {
      if (response == null) return false;
      if (response is Map<String, dynamic>) {
        return response['success'] == true || response['status'] == true;
      }
      return false;
    } catch (e) { return false; }
  }

  // =========================================================
  // 🔥 SESSION REFRESH
  // =========================================================

  static bool _isRefreshingSession = false;

  static Future<bool> _tryRefreshSession(BuildContext context) async {
    if (_isRefreshingSession) return false;
    _isRefreshingSession = true;

    bool success = false;

    try {
      await Navigator.of(context, rootNavigator: true).push(
        PageRouteBuilder<void>(
          opaque: false,
          barrierDismissible: false,
          pageBuilder: (_, __, ___) => SessionRefreshScreen(
            onRefreshComplete: (responseData) async {
              debugPrint('SESSION REFRESH SUCCESS => $responseData');
              success = true;
            },
            onSignOut: () {
              _navigateToSignIn(context);
            },
          ),
        ),
      );
    } catch (e) {
      debugPrint('Session refresh navigation error: $e');
    } finally {
      _isRefreshingSession = false;
    }

    return success;
  }

  // =========================================================
  // 🔥 REFRESH TOKEN API CALL
  // =========================================================

  static Future<Map<String, dynamic>> callRefreshTokenApi() async {
    final refreshToken =
    await SharedPrefHelper.getString(SharedPrefHelper.refreshToken);

    if (refreshToken == null || refreshToken.isEmpty) {
      throw Exception('No refresh token found. Please sign in again.');
    }

    final uri = Uri.parse('$baseUrl${Endpoints.REFRESH_SESSION_TOKEN}');

    debugPrint('REFRESH TOKEN URL   => $uri');
    debugPrint('REFRESH TOKEN VALUE => $refreshToken');

    final response = await http.post(
      uri,
      headers: headers(token: refreshToken),
      body: jsonEncode({'refreshToken': refreshToken}),
    );

    debugPrint('REFRESH STATUS => ${response.statusCode}');
    debugPrint('REFRESH BODY   => ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = decodeJson(response.body);
      if (data is Map<String, dynamic>) return data;
      throw Exception('Unexpected response format from server.');
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Refresh token is invalid or expired.');
    } else {
      final data = decodeJson(response.body);
      final msg  = (data is Map) ? (data['message'] ?? 'Server error') : 'Server error';
      throw Exception(msg.toString());
    }
  }

  // =========================================================
  // 🔥 SESSION EXPIRED FALLBACK
  // =========================================================

  static bool _isSessionExpiredDialogShowing = false;

  static Future<void> _handleSessionExpired(BuildContext context) async {
    if (_isSessionExpiredDialogShowing) return;
    _isSessionExpiredDialogShowing = true;

    await SharedPrefHelper.clearAll();

    if (!context.mounted) {
      _isSessionExpiredDialogShowing = false;
      return;
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Session Expired'),
        content: const Text(
          'Your session could not be renewed. Please sign in again.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.of(context).pop();
                if (!context.mounted) return;
                _navigateToSignIn(context);
              });
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
    _isSessionExpiredDialogShowing = false;
  }

  static void _navigateToSignIn(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => SignInScreen(
          initialData: SignInScreenData(
            emailValue:    '',
            passwordValue: '',
            nameValue:     '',
            isSignIn:      true,
          ),
        ),
      ),
          (route) => false,
    );
  }
}