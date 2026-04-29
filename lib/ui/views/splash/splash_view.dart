import 'dart:io';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:wellness/ui/views/splash/widget/splash_button.dart';
import 'package:wellness/ui/views/splash/widget/splash_logo.dart';
import 'package:wellness/ui/views/splash/widget/splash_quote.dart';
import 'package:wellness/ui/views/splash/widget/splash_title.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  _SplashViewState createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    super.initState();
    _fetchLinkAndSave();
  }

  Future<void> _fetchLinkAndSave() async {
    try {
      /*var dio = Dio();
      final response = await dio.get(
        'https://teachme.campuscore.store/get_base_link.php?key=787898',
      );*/

      // if (response.statusCode == 200 && response.data['status'] == 'success') {
        String link = "http://72.60.193.11:4000";
        // link = "https://15bf-2407-d000-11-14cc-792d-cc22-a29b-9687.ngrok-free.app";
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('app_link', link);

        print('Link saved: $link');
      /*} else {
        print('Failed to get the link: ${response.data["message"]}');
      }*/
    } catch (e) {
      print('Error fetching link: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        exit(0);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              SplashLogo(),
              SizedBox(height: 100),
              SplashTitle(),
              SizedBox(height: 8),
              SplashQuote(),
              SizedBox(height: 20),
              SplashButton(),
            ],
          ),
        ),
      ),
    );
  }
}
