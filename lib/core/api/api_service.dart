import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../ui/screens/screen_02_auth.dart';
import '../utils/helpers.dart';
import '../utils/shared_pref_helper.dart';

class ApiService {
  // =========================================================
  // 🔥 BASE URL
  // =========================================================

  static const String baseUrl = 'https://werlog.com/api/';

  // =========================================================
  // 🔥 COMMON HEADERS
  // =========================================================

  static Map<String, String> headers({
    String? token,
  }) {
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

      // 🔥 SHOW LOADER
      if (showLoader) {
        LoadingHelper.show(context);
      }

      // 🔥 GET TOKEN
      token ??= await SharedPrefHelper.getString(
        SharedPrefHelper.accessToken,
      );

      Uri uri = Uri.parse('$baseUrl$endpoint');

      // 🔥 QUERY PARAMS
      if (queryParams != null) {
        uri = uri.replace(
          queryParameters: queryParams.map(
                (key, value) => MapEntry(
              key,
              value.toString(),
            ),
          ),
        );
      }

      debugPrint('GET URL => $uri');
      debugPrint('TOKEN => $token');
      debugPrint('HEADERS => ${headers(token: token)}');

      final response = await http.get(
        uri,
        headers: headers(token: token),
      );


      try {
        final data = jsonDecode(response.body);
        final statusCode = response.statusCode;

        if (statusCode == 401 || statusCode == 403) {
          final message = (data['message'] ?? '').toString().toLowerCase();

          if (message.contains('access denied') ||
              message.contains('forbidden') ||
              message.contains('unauthorized')) {

            // 🔥 IMPORTANT: hide loader BEFORE navigation
            if (showLoader) {
              LoadingHelper.hide(context);
            }

            await _handleSessionExpired(context);

            // 🔥 STOP EVERYTHING
            return null;
          }
        }
      } catch (e) {
        print(e);
      }

      return _handleResponse(response);

    } on SocketException {
      throw 'No internet connection';
    } catch (e) {
      throw e.toString();
    } finally {

      // 🔥 HIDE LOADER
      if (showLoader) {
        LoadingHelper.hide(context);
      }
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
      // 🔥 SHOW LOADER
      if (showLoader) {
        LoadingHelper.show(context);
      }
      token ??= await SharedPrefHelper.getString(SharedPrefHelper.accessToken);

      final uri = Uri.parse('$baseUrl$endpoint');

      debugPrint('POST URL => $uri');
      debugPrint('POST BODY => ${jsonEncode(body)}');

      final response = await http.post(
        uri,
        headers: headers(token: token),
        body: jsonEncode(body ?? {}),
      );

      // 🔥 HIDE LOADER
      if (showLoader) {
        LoadingHelper.hide(context);
      }


      try {
        final data = jsonDecode(response.body);
        final statusCode = response.statusCode;
        if (statusCode == 401 || statusCode == 403) {
          final message = (data['message'] ?? '').toString().toLowerCase();

          if (message.contains('access denied') ||
              message.contains('forbidden') ||
              message.contains('unauthorized')) {
            await _handleSessionExpired(context);
            throw 'Session expired';
          }
        }
      }catch (e){
        print(e.toString());
      }

      return _handleResponse(response);
    } on SocketException {
      throw 'No internet connection';
    } catch (e) {
      throw e.toString();
    }finally{
      // 🔥 HIDE LOADER
      if (showLoader) {
        LoadingHelper.hide(context);
      }
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
      final uri = Uri.parse('$baseUrl$endpoint');

      final response = await http.delete(
        uri,
        headers: headers(token: token),
      );

      return _handleResponse(response);
    } on SocketException {
      throw 'No internet connection';
    } catch (e) {
      throw e.toString();
    }
  }

  // =========================================================
  // 🔥 RESPONSE HANDLER
  // =========================================================

  static dynamic _handleResponse(http.Response response) {
    debugPrint('STATUS CODE => ${response.statusCode}');
    debugPrint('RESPONSE => ${response.body}');

    final dynamic jsonResponse = decodeJson(response.body);

    switch (response.statusCode) {
      case 200:
      case 201:
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
    try {
      return jsonDecode(source);
    } catch (e) {
      return {};
    }
  }

  static String encodeJson(Map<String, dynamic> data) {
    try {
      return jsonEncode(data);
    } catch (e) {
      return '{}';
    }
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
    } catch (e) {
      return 'Something went wrong';
    }
  }

  static bool isSuccess(dynamic response) {
    try {
      if (response == null) return false;

      if (response is Map<String, dynamic>) {
        return response['success'] == true ||
            response['status'] == true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }


  static bool _isSessionExpiredDialogShowing = false;

  static Future<void> _handleSessionExpired(BuildContext context) async {

    if (_isSessionExpiredDialogShowing) return;

    _isSessionExpiredDialogShowing = true;

    await SharedPrefHelper.clearAll();

    // final context = navigatorKey.currentContext;

    if (context == null) {
      _isSessionExpiredDialogShowing = false;
      return;
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          title: const Text('Session Expired'),
          content: const Text(
            'Your session has expired. Please sign in again.',
          ),
          actions: [
            TextButton(
              onPressed: () {


                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.of(context).pop();
                  if (!context.mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => SignInScreen(
                        initialData: SignInScreenData(
                          emailValue: '',
                          passwordValue: '',
                          nameValue: '',
                          isSignIn: true,
                        ),
                      ),
                    ),
                    (route) => false,
                  );
                });
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
    _isSessionExpiredDialogShowing = false;
  }
}