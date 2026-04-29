import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';

// ──────────────────────────────────────────────────────────────
//  SignInScreen  (screen 02 · Sign in / Sign up)
//  Pixel-faithful to mobile_01_entry_login_signup.html : screen 2
// ──────────────────────────────────────────────────────────────

// ── Configurable data ──────────────────────────────────────────
class SignInScreenData {
  String emailValue;
  String? passwordValue;
  bool isSignIn; // toggles between Sign in / Sign up tab

  SignInScreenData({
    this.emailValue    = 'muneeb@gmail.com',
    this.passwordValue = '••••••••',
    this.isSignIn      = true,
  });
}

class SignInScreen extends StatefulWidget {
  final SignInScreenData? initialData;
  final VoidCallback? onBack;
  final VoidCallback? onSubmit;
  final VoidCallback? onForgotPassword;
  final VoidCallback? onGoogleLogin;
  final VoidCallback? onAppleLogin;
  final VoidCallback? onToggleMode;

  const SignInScreen({
    super.key,
    this.initialData,
    this.onBack,
    this.onSubmit,
    this.onForgotPassword,
    this.onGoogleLogin,
    this.onAppleLogin,
    this.onToggleMode,
  });

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  late SignInScreenData _data;
  late int _tab; // 0 = sign in, 1 = sign up

  @override
  void initState() {
    super.initState();
    _data = widget.initialData ?? SignInScreenData();
    _tab = _data.isSignIn ? 0 : 1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WerlogColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const FakeStatusBar(),
            _Header(
              tab:       _tab,
              onTabChange: (t) => setState(() => _tab = t),
              onBack:    widget.onBack,
            ),
            _Form(
              data:              _data,
              isSignIn:          _tab == 0,
              onForgotPassword:  widget.onForgotPassword,
              onSubmit:          widget.onSubmit,
              onGoogleLogin:     widget.onGoogleLogin,
              onAppleLogin:      widget.onAppleLogin,
              onToggleMode:      widget.onToggleMode,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ─────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final int tab;
  final ValueChanged<int> onTabChange;
  final VoidCallback? onBack;

  const _Header({required this.tab, required this.onTabChange, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 32, 22, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onBack,
            child: const Text('‹',
                style: TextStyle(
                    fontSize: 28, color: WerlogColors.textPrimary)),
          ),
          const SizedBox(height: 12),
          Text(tab == 0 ? 'Welcome back' : 'Create account',
              style: WerlogTextStyles.pageTitle),
          const SizedBox(height: 4),
          Text(
            tab == 0
                ? 'Sign in to sync your receipts across devices'
                : 'Create your Werlog account to get started',
            style: WerlogTextStyles.bodySmall,
          ),
          const SizedBox(height: 20),
          // Segmented tab
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: WerlogColors.surfaceAlt,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: ['Sign in', 'Sign up'].asMap().entries.map((e) {
                final active = e.key == tab;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onTabChange(e.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: active
                            ? WerlogColors.surface
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: active
                            ? [
                                BoxShadow(
                                  color:
                                      WerlogColors.textPrimary.withOpacity(0.06),
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                )
                              ]
                            : null,
                      ),
                      child: Text(
                        e.value,
                        style: WerlogTextStyles.bodySmall.copyWith(
                          color: active
                              ? WerlogColors.textPrimary
                              : WerlogColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Form body ──────────────────────────────────────────────────
class _Form extends StatelessWidget {
  final SignInScreenData data;
  final bool isSignIn;
  final VoidCallback? onForgotPassword;
  final VoidCallback? onSubmit;
  final VoidCallback? onGoogleLogin;
  final VoidCallback? onAppleLogin;
  final VoidCallback? onToggleMode;

  const _Form({
    required this.data,
    required this.isSignIn,
    this.onForgotPassword,
    this.onSubmit,
    this.onGoogleLogin,
    this.onAppleLogin,
    this.onToggleMode,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _LabeledField(
            label: 'EMAIL ADDRESS',
            initialValue: data.emailValue,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14),
          _LabeledField(
            label: 'PASSWORD',
            initialValue: data.passwordValue,
            obscureText: true,
            isFocused: true,
          ),
          // Forgot password
          if (isSignIn) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: onForgotPassword,
                child: Text('Forgot password?', style: WerlogTextStyles.link),
              ),
            ),
          ],
          const SizedBox(height: 20),
          PrimaryButton(
            text: isSignIn ? 'Sign in →' : 'Create account →',
            onTap: onSubmit,
          ),
          const OrDivider(),
          Row(
            children: [
              SocialButton(
                // logo: _GoogleLogo(),
                logo: const Icon(Icons.apple,
                    color: WerlogColors.textPrimary, size: 16),
                label: 'Google',
                onTap: onGoogleLogin,
              ),
              const SizedBox(width: 10),
              SocialButton(
                logo: const Icon(Icons.apple,
                    color: WerlogColors.textPrimary, size: 16),
                label: 'Apple',
                onTap: onAppleLogin,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Labeled text field ─────────────────────────────────────────
class _LabeledField extends StatelessWidget {
  final String label;
  final String? initialValue;
  final bool obscureText;
  final bool isFocused;
  final TextInputType? keyboardType;

  const _LabeledField({
    required this.label,
    this.initialValue,
    this.obscureText = false,
    this.isFocused   = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: WerlogTextStyles.labelUppercase.copyWith(fontSize: 10)),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: initialValue,
          obscureText:  obscureText,
          keyboardType: keyboardType,
          style: WerlogTextStyles.body,
          decoration: InputDecoration(
            filled: true,
            fillColor: WerlogColors.surface,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide:
                    const BorderSide(color: WerlogColors.border)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide:
                    const BorderSide(color: WerlogColors.border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: BorderSide(
                  color: isFocused
                      ? WerlogColors.teal
                      : WerlogColors.border,
                  width: 1.5,
                )),
          ),
        ),
      ],
    );
  }
}

// ── Google logo widget ─────────────────────────────────────────
class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 14,
      height: 14,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double r  = size.width / 2;

    void arc(double startAngle, double sweepAngle, Color color) {
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.28;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.7),
        startAngle, sweepAngle, false, paint);
    }
    // Simplified four-colour dots
    arc(-1.2, 1.7, const Color(0xFF4285F4));
    arc(0.5,  1.6, const Color(0xFF34A853));
    arc(2.1,  1.6, const Color(0xFFFBBC05));
    arc(3.7,  1.7, const Color(0xFFEA4335));
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ──────────────────────────────────────────────────────────────
//  EmailVerifyScreen  (screen 03 · Verify email)
//  Pixel-faithful to mobile_01_entry_login_signup.html : screen 3
// ──────────────────────────────────────────────────────────────

class EmailVerifyScreenData {
  /// Email address shown in the "SENT TO" box
  String email;

  /// Pre-filled OTP digits (length 6). Use empty string for blank.
  List<String> digits;

  /// Countdown label
  String resendLabel;

  EmailVerifyScreenData({
    this.email      = 'muneeb@gmail.com',
    List<String>? digits,
    this.resendLabel = "Didn't get it? Resend in 30s",
  }) : digits = digits ?? ['0', '0', '0', '0', '0', '0'];
}

class EmailVerifyScreen extends StatelessWidget {
  final EmailVerifyScreenData data;
  final VoidCallback? onBack;
  final VoidCallback? onVerify;
  final VoidCallback? onResend;

  /*const*/ EmailVerifyScreen({
    // super.key,
    Key? key,
    EmailVerifyScreenData? data,
    this.onBack,
    this.onVerify,
    this.onResend,
  }) : data = data ?? EmailVerifyScreenData(),
        super(key: key);


  // ignore: use_key_in_widget_constructors
  /*const*/ EmailVerifyScreen.defaults({Key? key, this.onBack, this.onVerify, this.onResend})
      : data = EmailVerifyScreenData(),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WerlogColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 32, 22, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const FakeStatusBar(),
            const SizedBox(height: 24),
            // Checkmark illustration
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: WerlogColors.tealSurface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: WerlogColors.tealLight.withOpacity(0.6),
                        width: 1,
                        style: BorderStyle.solid,
                      ),
                    ),
                  ),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: WerlogColors.teal,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Text('✓',
                        style: TextStyle(
                            fontSize: 28,
                            color: Colors.white,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Text('Check your inbox',
                textAlign: TextAlign.center,
                style: WerlogTextStyles.pageTitle),
            const SizedBox(height: 6),
            Text(
              'We sent a 6-digit verification code to confirm your email.',
              textAlign: TextAlign.center,
              style: WerlogTextStyles.bodySmall,
            ),
            const SizedBox(height: 24),
            // Email display box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: WerlogColors.surface,
                border: Border.all(color: WerlogColors.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text('SENT TO',
                      style: WerlogTextStyles.labelUppercase.copyWith(
                          fontSize: 10,
                          color: WerlogColors.textTertiary)),
                  const SizedBox(height: 2),
                  Text(data.email,
                      style: WerlogTextStyles.body.copyWith(
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // OTP boxes
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (i) {
                final isFocused =
                    data.digits[i].isEmpty && i > 0 && data.digits[i - 1].isNotEmpty;
                return Container(
                  width: 38,
                  height: 44,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: TextFormField(
                    initialValue: data.digits[i],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    style: WerlogTextStyles.body
                        .copyWith(fontWeight: FontWeight.w500, fontSize: 16),
                    decoration: InputDecoration(
                      counterText: '',
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 12),
                      filled: true,
                      fillColor: WerlogColors.surface,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(11),
                          borderSide:
                              const BorderSide(color: WerlogColors.border)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(11),
                          borderSide:
                              const BorderSide(color: WerlogColors.border)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(11),
                          borderSide: BorderSide(
                            color: isFocused
                                ? WerlogColors.teal
                                : WerlogColors.border,
                            width: 1.5,
                          )),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            PrimaryButton(text: 'Verify & continue', onTap: onVerify),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: onResend,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  data.resendLabel,
                  textAlign: TextAlign.center,
                  style: WerlogTextStyles.link,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
