// profile_segment/profile_models.dart
// Shared models, SharedPrefs helper, and API stubs used across profile screens.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────────────────
// USER MODEL
// ─────────────────────────────────────────────────────────────────────────────

class UserProfile {
  final String id;
  final String email;
  final String fullName;
  final String? avatarUrl;
  final String engine;
  final String role;
  final bool emailVerified;
  final bool showAds;
  final String planCode;

  const UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    this.avatarUrl,
    required this.engine,
    required this.role,
    required this.emailVerified,
    required this.showAds,
    required this.planCode,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] ?? '',
        email: json['email'] ?? '',
        fullName: json['fullName'] ?? '',
        avatarUrl: json['avatarUrl'],
        engine: json['engine'] ?? 'AI',
        role: json['role'] ?? 'ROLE_USER',
        emailVerified: json['emailVerified'] ?? false,
        showAds: json['showAds'] ?? true,
        planCode: json['planCode'] ?? 'FREE',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'fullName': fullName,
        'avatarUrl': avatarUrl,
        'engine': engine,
        'role': role,
        'emailVerified': emailVerified,
        'showAds': showAds,
        'planCode': planCode,
      };

  UserProfile copyWith({
    String? fullName,
    String? avatarUrl,
    bool clearAvatar = false,
  }) =>
      UserProfile(
        id: id,
        email: email,
        fullName: fullName ?? this.fullName,
        avatarUrl: clearAvatar ? null : (avatarUrl ?? this.avatarUrl),
        engine: engine,
        role: role,
        emailVerified: emailVerified,
        showAds: showAds,
        planCode: planCode,
      );

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }

  String get planLabel {
    switch (planCode.toUpperCase()) {
      case 'PRO':
        return 'Pro';
      case 'BASIC':
        return 'Basic';
      default:
        return 'Free';
    }
  }

  bool get isPro => planCode.toUpperCase() == 'PRO';
  bool get isFree => planCode.toUpperCase() == 'FREE';
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED PREFERENCES HELPER
// ─────────────────────────────────────────────────────────────────────────────

class ProfilePrefs {
  static const _kUser = 'werlog_user_profile';

  static Future<UserProfile?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kUser);
    if (raw == null) return null;
    try {
      return UserProfile.fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(UserProfile user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUser, jsonEncode(user.toJson()));
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUser);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

/// Standard Werlog app bar used across profile screens
class WerlogAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool centerTitle;

  const WerlogAppBar({
    super.key,
    required this.title,
    this.actions,
    this.centerTitle = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: WerlogColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: centerTitle,
      leading: Navigator.canPop(context)
          ? GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Padding(
                padding: EdgeInsets.only(left: 16),
                child: Icon(Icons.arrow_back_ios_new_rounded,
                    size: 18, color: WerlogColors.textPrimary),
              ),
            )
          : null,
      title: Text(title,
          style: const TextStyle(
            fontFamily: 'DMSans',
            fontSize: 17,
            fontWeight: FontWeight.w500,
            color: WerlogColors.textPrimary,
            letterSpacing: -0.2,
          )),
      actions: actions,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: WerlogColors.border, height: 0.5),
      ),
    );
  }
}

/// Full-width CTA button
class WerlogPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final IconData? icon;

  const WerlogPrimaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 50,
        decoration: BoxDecoration(
          color: onTap == null || isLoading
              ? WerlogColors.teal.withOpacity(0.5)
              : WerlogColors.teal,
          borderRadius: BorderRadius.circular(13),
        ),
        alignment: Alignment.center,
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 16, color: Colors.white),
                    const SizedBox(width: 7),
                  ],
                  Text(label,
                      style: const TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      )),
                ],
              ),
      ),
    );
  }
}

/// Card container with border
class WerlogCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? borderColor;

  const WerlogCard({
    super.key,
    required this.child,
    this.padding,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WerlogColors.surface,
        border: Border.all(color: borderColor ?? WerlogColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }
}

/// Input field matching Werlog design system
class WerlogTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool enabled;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffix;
  final String? errorText;
  final int? maxLines;
  final FocusNode? focusNode;

  const WerlogTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.enabled = true,
    this.obscureText = false,
    this.keyboardType,
    this.suffix,
    this.errorText,
    this.maxLines = 1,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
              fontFamily: 'DMSans',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: WerlogColors.textSecondary,
              letterSpacing: 0.3,
            )),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          enabled: enabled,
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLines: maxLines,
          focusNode: focusNode,
          style: const TextStyle(
            fontFamily: 'DMSans',
            fontSize: 14,
            color: WerlogColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontFamily: 'DMSans',
              fontSize: 14,
              color: WerlogColors.textDisabled,
            ),
            suffixIcon: suffix,
            errorText: errorText,
            filled: true,
            fillColor: enabled ? WerlogColors.surface : WerlogColors.surfaceAlt,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(color: WerlogColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(color: WerlogColors.border),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(color: WerlogColors.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide:
                  const BorderSide(color: WerlogColors.teal, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(color: WerlogColors.coral),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COLOUR IMPORT SHORTHAND  (so individual files don't need to repeat imports)
// ─────────────────────────────────────────────────────────────────────────────

class WerlogColors {
  WerlogColors._();
  static const Color darkTeal          = Color(0xFF0F2A2E);
  static const Color teal              = Color(0xFF1D9E75);
  static const Color tealLight         = Color(0xFF5DCAA5);
  static const Color tealSurface       = Color(0xFFE1F5EE);
  static const Color tealLightSurface  = Color(0xFFF5FAF8);
  static const Color blue              = Color(0xFF2563EB);
  static const Color blueSurface       = Color(0xFFEFF6FF);
  static const Color orange            = Color(0xFFF59E0B);
  static const Color orangeSurface     = Color(0xFFFFFBEB);
  static const Color amber             = Color(0xFFBA7517);
  static const Color amberSurface      = Color(0xFFFAEEDA);
  static const Color amberDark         = Color(0xFF854F0B);
  static const Color amberDeep         = Color(0xFF633806);
  static const Color coral             = Color(0xFFD85A30);
  static const Color coralSurface      = Color(0xFFFAECE7);
  static const Color coralDark         = Color(0xFF993C1D);
  static const Color background        = Color(0xFFFAFAF7);
  static const Color surface           = Color(0xFFFFFFFF);
  static const Color surfaceAlt        = Color(0xFFF1EFE8);
  static const Color border            = Color(0xFFE5E3DB);
  static const Color borderLight       = Color(0xFFEEECE4);
  static const Color textPrimary       = Color(0xFF0F2A2E);
  static const Color textSecondary     = Color(0xFF5F5E5A);
  static const Color textTertiary      = Color(0xFF888780);
  static const Color textDisabled      = Color(0xFFB4B2A9);
  static const Color textWhite         = Color(0xFFFFFFFF);
  static const Color success           = teal;
  static const Color successSurface    = tealSurface;
  static const Color warning           = amber;
  static const Color warningSurface    = amberSurface;
  static const Color danger            = coral;
  static const Color dangerSurface     = coralSurface;
  static const Color purple            = Color(0xFF7B5EA7);
  static const Color purpleSurface     = Color(0xFFF3EEF8);
  static const Color proBadgeBg        = Color(0xFF2A4A46);
  static const Color proBadgeText      = tealLight;
}
