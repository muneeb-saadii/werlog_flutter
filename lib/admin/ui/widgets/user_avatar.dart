import 'package:flutter/material.dart';
import '../../core/theme/app_text_styles.dart';

/// Rounded-square avatar showing a user's initials on a colored background,
/// matching the tiles used in the Users list and User details screens.
class UserAvatar extends StatelessWidget {
  final String initials;
  final Color color;
  final double size;

  const UserAvatar({
    super.key,
    required this.initials,
    required this.color,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: AppTextStyles.nameBold.copyWith(
          color: Colors.white,
          fontSize: size * 0.34,
        ),
      ),
    );
  }
}
