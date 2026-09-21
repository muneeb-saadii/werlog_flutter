import 'package:flutter/material.dart';

class SplashQuote extends StatelessWidget {
  const SplashQuote({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text(
      "Your health is your wealth,\nStart your wellness journey today.",
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 16,
        color: Colors.grey,
        fontStyle: FontStyle.italic,
      ),
    );
  }
}
