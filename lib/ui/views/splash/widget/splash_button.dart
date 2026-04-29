import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/widgets/app_button.dart';

class SplashButton extends StatelessWidget {
  const SplashButton({super.key});

  @override
  Widget build(BuildContext context) {
    Future<void> _checkUserNavigation() async {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      int? userType = prefs.getInt("user_type");
      String? displayName = prefs.getString("display_name");
      int isSetupCompleted = prefs.getInt("isSetupCompleted") ?? 0;

      await Future.delayed(const Duration(milliseconds: 400));

      if (userType == null) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }
      if (userType == 1) {
        if (isSetupCompleted == 0) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/trainer-profile',
                (route) => false,
          );
          return;
        } else {
          Navigator.pushReplacementNamed(context, '/trainer-bottom-bar');
          return;
        }
      }
      if (userType == 2) {
        Navigator.pushReplacementNamed(context, '/admin-dashboard');
        return;
      }
      if (displayName == null || displayName.trim().isEmpty) {
        Navigator.pushReplacementNamed(context, '/name');
        return;
      }
      if (displayName.isEmpty) {
        Navigator.pushReplacementNamed(
          context,
          '/profile',
          arguments: {'name': displayName},
        );
        return;
      }
      if (isSetupCompleted == 0) {
        Navigator.pushReplacementNamed(
          context,
          '/profile',
          arguments: {'name': displayName},
        );
        return;
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }

     // Navigator.pushReplacementNamed(context, '/home');
    }

    return SizedBox(
      width: 250,
      height: 50,
      child: CustomButton(
        text: "Get Started",
        onPressed: _checkUserNavigation,

        backgroundColor: AppColor.primaryBlue,
        textColor: AppColor.white,
        borderRadius: 12,
      ),
    );
  }
}
