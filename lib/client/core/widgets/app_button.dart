import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;

  final Color backgroundColor;
  final Color textColor;

  final bool isLoading;
  final bool enabled;
  final double height;
  final double borderRadius;

  const CustomButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.backgroundColor = Colors.yellow,
    this.textColor = Colors.black,
    this.isLoading = false,
    this.enabled = true,
    this.height = 48,
    this.borderRadius = 10,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final effectiveEnabled = enabled && !isLoading && onPressed != null;

    return Opacity(
      opacity: effectiveEnabled ? 1 : 0.7,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: effectiveEnabled ? onPressed : null,
          child: Ink(
            height: height,
            width: double.infinity,
            decoration: BoxDecoration(
              color: backgroundColor, // pura background color
              borderRadius: BorderRadius.circular(borderRadius),
              // border removed
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: isLoading
                    ? LoadingAnimationWidget.staggeredDotsWave(
                  key: const ValueKey('btn-loader'),
                  color: textColor,
                  size: 28,
                )
                    : Text(
                  text,
                  key: const ValueKey('btn-text'),
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
