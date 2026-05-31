// forgot_password_screen.dart
//
// Forgot password — collects the user's email, calls the API, then
// navigates to EmailVerifyScreen on success.

import 'package:flutter/material.dart';
import 'package:wellness/ui/screens/screen_02_auth.dart';
import '../../../core/api/api_service.dart';
import '../../../core/api/endpoints.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/general_functions.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _emailCtrl  = TextEditingController();
  bool _sending     = false;

  // ── API ────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _sending = true);

    try {
      final email = _emailCtrl.text.trim();

      final response = await ApiService.post(
        context,
        Endpoints.FORGET_PASSWORD,
        body: {'email': email},
        showLoader: false,
      );

      if (!mounted) return;

      if (response != null && response['result'] == '1') {
        setState(() => _sending = false);

        // Pull expiry label from response if the API provides it,
        // otherwise fall back to a sensible default string.
        /*final expiresTime =
            response['data']?['expiresIn']?.toString() ??
            response['data']?['expiry']?.toString()    ??
            'Expires in 10 minutes';*/

        // Navigate to EmailVerifyScreen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EmailVerifyScreen(
              data: EmailVerifyScreenData(
                email:       email,
                digits:      ['', '', '', '', '', ''],
                // resendLabel: expiresTime,
              ),
              onBack: () => Navigator.pop(context),
              onVerify: () {
                Navigator.pop(context);
                // 🔥 continue next flow here — e.g. push reset-password screen
                // Navigator.pushReplacement(context,
                //   MaterialPageRoute(builder: (_) => ResetPasswordScreen()));
              },
            ),
          ),
        );
      } else {
        setState(() => _sending = false);
        _showSnack(
          response?['message']?.toString() ?? 'Failed to send reset email.',
          isError: true,
        );
      }
    } catch (e) {
      setState(() => _sending = false);
      _showSnack('Something went wrong. Please try again.', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(fontFamily: 'DMSans', fontSize: 13)),
      backgroundColor: isError ? WerlogColors.coral : WerlogColors.teal,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WerlogColors.background,
      appBar: _WAppBar(title: 'Forgot Password'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: [

            // ── Header illustration ───────────────────────────────────
            Center(
              child: Container(
                width: 68, height: 68,
                decoration: const BoxDecoration(
                  color: WerlogColors.tealSurface,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.lock_open_rounded,
                    size: 32, color: WerlogColors.teal),
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text('Forgot your password?',
                  style: TextStyle(
                    fontFamily: 'DMSans', fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: WerlogColors.textPrimary, letterSpacing: -0.3,
                  )),
            ),
            const SizedBox(height: 6),
            const Center(
              child: Text(
                'Enter the email address linked to\nyour account and we\'ll send a code.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'DMSans', fontSize: 13,
                  color: WerlogColors.textSecondary, height: 1.55,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ── Email field ───────────────────────────────────────────
            _FieldLabel('EMAIL ADDRESS'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _sending ? null : _submit(),
              style: const TextStyle(
                fontFamily: 'DMSans', fontSize: 14,
                color: WerlogColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'you@example.com',
                hintStyle: const TextStyle(
                  fontFamily: 'DMSans', fontSize: 14,
                  color: WerlogColors.textDisabled,
                ),
                prefixIcon: const Icon(Icons.email_outlined,
                    size: 18, color: WerlogColors.textTertiary),
                filled: true,
                fillColor: WerlogColors.surface,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 13),
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
                  borderSide: const BorderSide(
                      color: WerlogColors.teal, width: 1.5),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(11),
                  borderSide: const BorderSide(color: WerlogColors.coral),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(11),
                  borderSide: const BorderSide(
                      color: WerlogColors.coral, width: 1.5),
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Email address is required';
                }
                final emailRegex =
                    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                if (!emailRegex.hasMatch(v.trim())) {
                  return 'Enter a valid email address';
                }
                return null;
              },
            ),

            const SizedBox(height: 32),

            // ── Submit button ─────────────────────────────────────────
            _PrimaryButton(
              label: 'Send Reset Code',
              isLoading: _sending,
              icon: Icons.send_rounded,
              onTap: _sending ? null : _submit,
            ),

            const SizedBox(height: 20),

            // ── Back to sign in ────────────────────────────────────────
            Center(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontFamily: 'DMSans', fontSize: 13,
                      color: WerlogColors.textSecondary,
                    ),
                    children: [
                      TextSpan(text: 'Remember your password? '),
                      TextSpan(
                        text: 'Sign In',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: WerlogColors.teal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ── Info card ─────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: WerlogColors.blueSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: WerlogColors.blue.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Row(children: [
                    Icon(Icons.info_outline_rounded,
                        size: 14, color: WerlogColors.blue),
                    SizedBox(width: 6),
                    Text('What happens next?',
                        style: TextStyle(
                          fontFamily: 'DMSans', fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: WerlogColors.blue,
                        )),
                  ]),
                  SizedBox(height: 8),
                  _InfoRow('A 6-digit code will be sent to your email'),
                  _InfoRow('Enter the code on the next screen'),
                  _InfoRow('The code expires after a short time'),
                  _InfoRow('Check your spam folder if you don\'t see it'),
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
// LOCAL WIDGETS  (same patterns as reset_password_screen.dart)
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

class _InfoRow extends StatelessWidget {
  final String text;
  const _InfoRow(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(children: [
      const Icon(Icons.check_circle_outline_rounded,
          size: 12, color: WerlogColors.blue),
      const SizedBox(width: 6),
      Expanded(
        child: Text(text,
            style: const TextStyle(
              fontFamily: 'DMSans', fontSize: 11,
              color: WerlogColors.blue,
            )),
      ),
    ]),
  );
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final IconData? icon;

  const _PrimaryButton({
    required this.label,
    this.onTap,
    this.isLoading = false,
    this.icon,
  });

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
          ? const SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2))
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
