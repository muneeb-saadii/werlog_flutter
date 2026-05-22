// profile_segment/reset_password_screen.dart
//
// Reset password — shows disabled email, old password, new password,
// confirm password fields. Calls POST API on submit and saves session.

import 'package:flutter/material.dart';
import '../../../core/models/profile_models.dart';
import '../../../core/utils/shared_pref_helper.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  UserProfile? _user;
  bool _initLoading = true;
  bool _saving = false;

  final _formKey = GlobalKey<FormState>();
  final _oldPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _showOld = false;
  bool _showNew = false;
  bool _showConfirm = false;

  // Track password strength
  PasswordStrength _strength = PasswordStrength.none;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _newPassCtrl.addListener(_onNewPassChanged);
  }

  Future<void> _loadUser() async {
    final data = SharedPrefHelper.getObject(SharedPrefHelper.loginData);
    final user = data?['meResponse'];
    print("user profile data: "+user.toString());
    final email = user?['email'] ?? '';
    final myUser = UserProfile(
      id: user?['id'] ?? '',
      email: email,
      fullName: user?['fullName'] ?? '',
      engine: user?['engine'] ?? '',
      role: user?['role'] ?? '',
      emailVerified: user?['emailVerified'] ?? '',
      showAds: user?['showAds'] ?? '',
      planCode: user?['planCode'] ?? '',
    );

    if (mounted) setState(() { _user = myUser; _initLoading = false; });
  }

  void _onNewPassChanged() {
    final s = _evalStrength(_newPassCtrl.text);
    if (s != _strength) setState(() => _strength = s);
  }

  PasswordStrength _evalStrength(String p) {
    if (p.isEmpty) return PasswordStrength.none;
    int score = 0;
    if (p.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(p)) score++;
    if (RegExp(r'[0-9]').hasMatch(p)) score++;
    if (RegExp(r'[!@#\$%^&*]').hasMatch(p)) score++;
    if (score <= 1) return PasswordStrength.weak;
    if (score == 2) return PasswordStrength.fair;
    if (score == 3) return PasswordStrength.good;
    return PasswordStrength.strong;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      // ── Replace with your real API call ──────────────────────────────────
      // final response = await ApiService.post(context, Endpoints.RESET_PASSWORD, {
      //   'oldPassword': _oldPassCtrl.text,
      //   'newPassword': _newPassCtrl.text,
      // });
      // final ok = response['result'] == '1';
      // ────────────────────────────────────────────────────────────────────
      await Future.delayed(const Duration(milliseconds: 900)); // mock
      const ok = true;

      if (!mounted) return;

      if (ok) {
        setState(() => _saving = false);
        _oldPassCtrl.clear();
        _newPassCtrl.clear();
        _confirmCtrl.clear();
        _showSnack('Password updated successfully!');
        Navigator.pop(context);
      } else {
        setState(() => _saving = false);
        _showSnack('Incorrect current password.', isError: true);
      }
    } catch (e) {
      setState(() => _saving = false);
      _showSnack('Something went wrong. Please try again.', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'DMSans', fontSize: 13)),
      backgroundColor: isError ? WerlogColors.coral : WerlogColors.teal,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  void dispose() {
    _oldPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_initLoading) {
      return const Scaffold(
        backgroundColor: WerlogColors.background,
        body: Center(child: CircularProgressIndicator(color: WerlogColors.teal)),
      );
    }

    return Scaffold(
      backgroundColor: WerlogColors.background,
      appBar: _WAppBar(title: 'Reset Password'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: [
            // ── Header illustration ───────────────────────────────────────
            Center(
              child: Container(
                width: 68, height: 68,
                decoration: BoxDecoration(
                  color: WerlogColors.tealSurface,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.lock_reset_rounded,
                    size: 32, color: WerlogColors.teal),
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text('Update your password',
                  style: TextStyle(
                    fontFamily: 'DMSans', fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: WerlogColors.textPrimary, letterSpacing: -0.3,
                  )),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                'Choose a strong, unique password\nto keep your account secure.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'DMSans', fontSize: 13,
                  color: WerlogColors.textSecondary, height: 1.55,
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ── Email (disabled) ──────────────────────────────────────────
            _FieldLabel('EMAIL'),
            const SizedBox(height: 6),
            _DisabledField(
              value: _user?.email ?? '',
              icon: Icons.email_outlined,
            ),

            const SizedBox(height: 20),

            // ── Old password ──────────────────────────────────────────────
            _FieldLabel('CURRENT PASSWORD'),
            const SizedBox(height: 6),
            _PassField(
              controller: _oldPassCtrl,
              hint: 'Enter current password',
              show: _showOld,
              onToggle: () => setState(() => _showOld = !_showOld),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Current password is required';
                return null;
              },
            ),

            const SizedBox(height: 20),

            // ── New password ──────────────────────────────────────────────
            _FieldLabel('NEW PASSWORD'),
            const SizedBox(height: 6),
            _PassField(
              controller: _newPassCtrl,
              hint: 'Min. 8 characters',
              show: _showNew,
              onToggle: () => setState(() => _showNew = !_showNew),
              validator: (v) {
                if (v == null || v.length < 8) return 'At least 8 characters required';
                return null;
              },
            ),
            if (_strength != PasswordStrength.none) ...[
              const SizedBox(height: 8),
              _StrengthBar(strength: _strength),
            ],

            const SizedBox(height: 20),

            // ── Confirm password ──────────────────────────────────────────
            _FieldLabel('CONFIRM NEW PASSWORD'),
            const SizedBox(height: 6),
            _PassField(
              controller: _confirmCtrl,
              hint: 'Re-enter new password',
              show: _showConfirm,
              onToggle: () => setState(() => _showConfirm = !_showConfirm),
              validator: (v) {
                if (v != _newPassCtrl.text) return 'Passwords do not match';
                return null;
              },
            ),

            const SizedBox(height: 32),

            // ── Submit ────────────────────────────────────────────────────
            _PrimaryButton(
              label: 'Update Password',
              isLoading: _saving,
              icon: Icons.lock_rounded,
              onTap: _saving ? null : _submit,
            ),

            const SizedBox(height: 16),

            // ── Tips ──────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: WerlogColors.blueSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: WerlogColors.blue.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Row(
                    children: [
                      Icon(Icons.tips_and_updates_outlined,
                          size: 14, color: WerlogColors.blue),
                      SizedBox(width: 6),
                      Text('Password tips',
                          style: TextStyle(
                            fontFamily: 'DMSans', fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: WerlogColors.blue,
                          )),
                    ],
                  ),
                  SizedBox(height: 8),
                  _TipRow('At least 8 characters long'),
                  _TipRow('Mix uppercase and lowercase letters'),
                  _TipRow('Include numbers and symbols (!@#\$)'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PASSWORD STRENGTH
// ─────────────────────────────────────────────────────────────────────────────

enum PasswordStrength { none, weak, fair, good, strong }

class _StrengthBar extends StatelessWidget {
  final PasswordStrength strength;
  const _StrengthBar({required this.strength});

  @override
  Widget build(BuildContext context) {
    final segments = 4;
    final filled = strength.index; // weak=1 fair=2 good=3 strong=4
    final Color activeColor;
    final String label;
    switch (strength) {
      case PasswordStrength.weak:
        activeColor = WerlogColors.coral;
        label = 'Weak';
        break;
      case PasswordStrength.fair:
        activeColor = WerlogColors.amber;
        label = 'Fair';
        break;
      case PasswordStrength.good:
        activeColor = WerlogColors.tealLight;
        label = 'Good';
        break;
      case PasswordStrength.strong:
        activeColor = WerlogColors.teal;
        label = 'Strong';
        break;
      default:
        activeColor = WerlogColors.border;
        label = '';
    }

    return Row(
      children: [
        Expanded(
          child: Row(
            children: List.generate(segments, (i) {
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: i < segments - 1 ? 4 : 0),
                  decoration: BoxDecoration(
                    color: i < filled ? activeColor : WerlogColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: 10),
        Text(label,
            style: TextStyle(
              fontFamily: 'DMSans', fontSize: 11,
              fontWeight: FontWeight.w500,
              color: activeColor,
            )),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LOCAL WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _WAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  const _WAppBar({required this.title});
  @override
  Size get preferredSize => const Size.fromHeight(56);
  @override
  Widget build(BuildContext context) => AppBar(
    backgroundColor: WerlogColors.background,
    elevation: 0,
    scrolledUnderElevation: 0,
    leading: GestureDetector(
      onTap: () => Navigator.pop(context),
      child: const Padding(
        padding: EdgeInsets.only(left: 16),
        child: Icon(Icons.arrow_back_ios_new_rounded,
            size: 18, color: WerlogColors.textPrimary),
      ),
    ),
    title: Text(title,
        style: const TextStyle(
          fontFamily: 'DMSans', fontSize: 17, fontWeight: FontWeight.w500,
          color: WerlogColors.textPrimary, letterSpacing: -0.2,
        )),
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(1),
      child: Container(color: WerlogColors.border, height: 0.5),
    ),
  );
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
        fontFamily: 'DMSans', fontSize: 10, fontWeight: FontWeight.w500,
        color: WerlogColors.textTertiary, letterSpacing: 0.8,
      ));
}

class _DisabledField extends StatelessWidget {
  final String value;
  final IconData icon;
  const _DisabledField({required this.value, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: WerlogColors.surfaceAlt,
        border: Border.all(color: WerlogColors.borderLight),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: WerlogColors.textDisabled),
          const SizedBox(width: 10),
          Text(value,
              style: const TextStyle(
                fontFamily: 'DMSans', fontSize: 14,
                color: WerlogColors.textDisabled,
              )),
        ],
      ),
    );
  }
}

class _PassField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool show;
  final VoidCallback onToggle;
  final String? Function(String?)? validator;

  const _PassField({
    required this.controller,
    required this.hint,
    required this.show,
    required this.onToggle,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: !show,
      validator: validator,
      style: const TextStyle(
        fontFamily: 'DMSans', fontSize: 14, color: WerlogColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontFamily: 'DMSans', fontSize: 14, color: WerlogColors.textDisabled,
        ),
        suffixIcon: GestureDetector(
          onTap: onToggle,
          child: Icon(
            show ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 18, color: WerlogColors.textTertiary,
          ),
        ),
        filled: true,
        fillColor: WerlogColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: WerlogColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: WerlogColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: WerlogColors.teal, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: WerlogColors.coral),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: WerlogColors.coral, width: 1.5),
        ),
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  final String text;
  const _TipRow(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      children: [
        const Icon(Icons.check_circle_outline_rounded,
            size: 12, color: WerlogColors.blue),
        const SizedBox(width: 6),
        Text(text,
            style: const TextStyle(
              fontFamily: 'DMSans', fontSize: 11,
              color: WerlogColors.blue,
            )),
      ],
    ),
  );
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final IconData? icon;
  const _PrimaryButton({required this.label, this.onTap, this.isLoading = false, this.icon});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
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
          ? const SizedBox(width: 20, height: 20,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : Row(mainAxisSize: MainAxisSize.min, children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: Colors.white),
                const SizedBox(width: 7),
              ],
              Text(label, style: const TextStyle(
                fontFamily: 'DMSans', fontSize: 14,
                fontWeight: FontWeight.w500, color: Colors.white,
              )),
            ]),
    ),
  );
}
