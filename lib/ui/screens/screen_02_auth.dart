import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wellness/ui/screens/screen_03_subscription.dart';
import '../../core/api/api_service.dart';
import '../../core/api/endpoints.dart';
import '../../core/models/app_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/general_functions.dart';
import '../../core/utils/shared_pref_helper.dart';
import '../../core/widgets/shared_widgets.dart';
import '../tset/screens/main_dashboard_screen.dart';

// ──────────────────────────────────────────────────────────────
//  SignInScreen  (screen 02 · Sign in / Sign up)
//  Pixel-faithful to mobile_01_entry_login_signup.html : screen 2
// ──────────────────────────────────────────────────────────────

// ── Configurable data ──────────────────────────────────────────
class SignInScreenData {
  String nameValue;
  String emailValue;
  String? passwordValue;
  bool isSignIn; // toggles between Sign in / Sign up tab

  SignInScreenData({
    this.nameValue    = '',
    this.emailValue    = '',
    this.passwordValue = '',
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
    final data = SharedPrefHelper.getObject(SharedPrefHelper.loginData);
    // print(user?['name']);

    if(data != null){
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => MainDashboardScreen()
        ),
      );
      return;
    }

    final userData = SharedPrefHelper.getObject(SharedPrefHelper.loginRememberData);
    final user = userData?['meResponse'];
    final email = user?['email'] ?? '';
    final pass = user?['password'] ?? '';
    print("saved_login:: email:"+email+", pass:"+pass);
    print("saved_login_data:: $userData");

    _data = (email!=null && pass!= null) ? SignInScreenData(emailValue: email, passwordValue: pass) : widget.initialData ?? SignInScreenData();
    _tab = _data.isSignIn ? 0 : 1;
  }

  Future<void> registerUser() async {
    try {
      final response = await ApiService.post(
        context,
        Endpoints.REGISTER_USER,
        body: {
          "email": _data.emailValue,
          "password": _data.passwordValue,
          "fullName": _data.nameValue
        }
      );

      print('\nSUCCESS => $response');

      // =====================================================
      // 🔥 SAFE RESPONSE PARSING
      // =====================================================

      handleAuthResponse(response);

    } catch (e) {
      print('ERROR => $e');
      GeneralFunctions.showError(
        context,
        "Process interrupted. Please try again!"
        ,
      );
    }
  }

  Future<void> loginUser() async {
    try {
      final response = await ApiService.post(
        context,
        Endpoints.LOGIN_USER,
        body: {
          "email": _data.emailValue,
          "password": _data.passwordValue,
        },
      );

      print('\nSUCCESS => $response');

      handleAuthResponse(response);

    } catch (e) {
      print('ERROR => $e');
      GeneralFunctions.showError(
        context,
        "Process interrupted. Please try again!"
        ,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            height: constraints.maxHeight, // ✅ force full height
            decoration: BoxDecoration(
              gradient: WerlogGradients.pageHeader(),
            ),
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight, // ✅ fill screen
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const FakeStatusBar(),
                    _Header(
                      tab: _tab,
                      onTabChange: (t) => setState(() => _tab = t),
                      onBack: widget.onBack,
                    ),
                    _Form(
                      data: _data,
                      isSignIn: _tab == 0,
                      onForgotPassword: widget.onForgotPassword,
                      onSubmit: () async {
                        await _tab == 0 ? loginUser() : registerUser();
                      },
                      // onSubmit: widget.onSubmit,
                      onGoogleLogin: widget.onGoogleLogin,
                      onAppleLogin: widget.onAppleLogin,
                      onToggleMode: widget.onToggleMode,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> handleAuthResponse(response) async {
    final result = response['result']=="1" ? true : false;

    if(result){

      GeneralFunctions.showSuccess(
        context,
        'Login successful',
      );

      final data = response['data'];
      final meResponse = data['meResponse'];
      final expiresTime = data['expiresIn'].toString();

      final bool emailVerified =
          meResponse['emailVerified'] == true;

      final String email =
          meResponse['email']?.toString() ?? '';

      // =====================================================
      // 🔥 EMAIL NOT VERIFIED
      // =====================================================

      await SharedPrefHelper.saveObject(
        SharedPrefHelper.loginData,
        data,
      );
      await SharedPrefHelper.saveString(
        SharedPrefHelper.accessToken,
        data['accessToken'],
      );

      meResponse['password'] = _data.passwordValue;
      data['meResponse'] = meResponse;
      await SharedPrefHelper.saveObject(
        SharedPrefHelper.loginRememberData,
        data,
      );

      if (!emailVerified) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EmailVerifyScreen(
              data: EmailVerifyScreenData(
                  email: email,
                  digits: ['', '', '', '', '', ''],
                  resendLabel: expiresTime
              ),

              onBack: () {
                Navigator.pop(context);
              },

              onVerify: () {
                Navigator.pop(context);

                // 🔥 continue next flow here
                // Example:
                // Navigator.pushReplacement(...)
              },
            ),
          ),
        );

        return;
      }else{
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => MainDashboardScreen()
          ),
        );
      }
    }else{
      GeneralFunctions.showError(
        context,
        response['message']
        ,
      );
    }

    // =====================================================
    // 🔥 LOGIN SUCCESS FLOW
    // =====================================================

    print('User already verified');

    // Navigate to dashboard/home
    // Example:
    // Navigator.pushReplacement(...);
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
          const SizedBox(height: 30),
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
                        style: WerlogTextStyles.body/*bodySmall*/.copyWith(
                          color: active
                              // ? WerlogColors.textPrimary
                              ? WerlogColors.tabActive
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
          const SizedBox(height: 25),
          if (!isSignIn) ...[
            _LabeledField(
              label: 'FULL NAME',
              initialValue: data.nameValue,
              keyboardType: TextInputType.text,
              onChanged: (value) {
                data.nameValue = value;
              },
            ),
            const SizedBox(height: 16),
          ],
          _LabeledField(
            label: 'EMAIL ADDRESS',
            initialValue: data.emailValue,
            keyboardType: TextInputType.emailAddress,
            onChanged: (value) {
              data.emailValue = value;
            },
          ),
          const SizedBox(height: 16),
          _LabeledField(
            label: 'PASSWORD',
            initialValue: data.passwordValue,
            obscureText: true,
            isFocused: true,
            onChanged: (value) {
              data.passwordValue = value;
            },
          ),
          // Forgot password
          if (isSignIn) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: onForgotPassword,
                child: Text('Forgot password?', style: WerlogTextStyles.link),
              ),
            ),
          ],
          const SizedBox(height: 25),
          PrimaryButton(
            text: isSignIn ? 'Sign in →' : 'Create account →',
            onTap: onSubmit,
          ),
          const SizedBox(height: 40),
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
class _LabeledField extends StatefulWidget {
  final String label;
  final String? initialValue;
  final bool obscureText;
  final bool isFocused;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  const _LabeledField({
    required this.label,
    this.initialValue,
    this.obscureText = false,
    this.isFocused = false,
    this.keyboardType,
    this.onChanged,
  });

  @override
  State<_LabeledField> createState() => _LabeledFieldState();
}

class _LabeledFieldState extends State<_LabeledField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    // 🔥 set initial value once
    _controller = TextEditingController(
      text: widget.initialValue ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant _LabeledField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 🔥 update field if parent updates value
    if (oldWidget.initialValue != widget.initialValue &&
        widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: WerlogTextStyles.labelUppercase.copyWith(fontSize: 10),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _controller,
          obscureText: widget.obscureText,
          keyboardType: widget.keyboardType,
          style: WerlogTextStyles.body,
          onChanged: (value) {
            widget.onChanged?.call(value);
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: WerlogColors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(
                color: WerlogColors.border,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(
                color: WerlogColors.border,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: BorderSide(
                color: widget.isFocused
                    ? WerlogColors.teal
                    : WerlogColors.border,
                width: 1.5,
              ),
            ),
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
    this.email      = '',
    List<String>? digits,
    this.resendLabel = "30",
  }) : digits = digits ?? ['0', '0', '0', '0', '0', '0'];
}


class EmailVerifyScreen extends StatefulWidget {
  final EmailVerifyScreenData data;

  final VoidCallback? onBack;
  final VoidCallback? onVerify;
  final VoidCallback? onResend;

  EmailVerifyScreen({
    Key? key,
    EmailVerifyScreenData? data,
    this.onBack,
    this.onVerify,
    this.onResend,
  })  : data = data ?? EmailVerifyScreenData(),
        super(key: key);

  EmailVerifyScreen.defaults({
    Key? key,
    this.onBack,
    this.onVerify,
    this.onResend,
  })  : data = EmailVerifyScreenData(),
        super(key: key);

  @override
  State<EmailVerifyScreen> createState() =>
      _EmailVerifyScreenState();
}
class _EmailVerifyScreenState extends State<EmailVerifyScreen> {

  late int _secondsRemaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _secondsRemaining =
        int.tryParse(widget.data.resendLabel) ?? 0;

    _startTimer();
  }

  void _startTimer() {
    if (_secondsRemaining <= 0) return;

    _timer?.cancel();

    _timer = Timer.periodic(
      const Duration(seconds: 1),
          (timer) {
        if (_secondsRemaining <= 1) {
          timer.cancel();

          setState(() {
            _secondsRemaining = 0;
          });
        } else {
          setState(() {
            _secondsRemaining--;
          });
        }
      },
    );
  }

  String get formattedTime {
    final minutes =
    (_secondsRemaining ~/ 60).toString().padLeft(2, '0');

    final seconds =
    (_secondsRemaining % 60).toString().padLeft(2, '0');

    return '$minutes:$seconds';
  }

  bool get canResend => _secondsRemaining == 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var data = widget.data;
    return Scaffold(
      // backgroundColor: WerlogColors.background,
      backgroundColor: Colors.transparent,
      body: Container(
          constraints: const BoxConstraints.expand(),
        decoration: BoxDecoration(
          gradient: WerlogGradients.pageHeader(), // ✅ correct usage
        ),
        child: SingleChildScrollView(
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
              const SizedBox(height: 30),
              // OTP boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (i) {
                  final isFocused =
                      data.digits[i].isEmpty && i > 0 && data.digits[i - 1].isNotEmpty;
                  return Container(
                    width: 38,
                    height: 50,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: TextFormField(
                      initialValue: data.digits[i],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      style: WerlogTextStyles.body
                          .copyWith(fontWeight: FontWeight.w500, fontSize: 16),
                      onChanged: (value) {
                        // save value
                        data.digits[i] = value;
                        // auto next focus
                        if (value.isNotEmpty && i < 5) {
                          FocusScope.of(context).nextFocus();
                        }
                        // auto previous on delete
                        if (value.isEmpty && i > 0) {
                          FocusScope.of(context).previousFocus();
                        }
                        setState(() {});
                      },
                      decoration: InputDecoration(
                        counterText: '',
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                        filled: true,
                        fillColor: WerlogColors.tealSurface/*surface*/,
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
                                  ? WerlogColors.darkTeal
                                  : WerlogColors.border,
                              width: 1.5,
                            )),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 50),
              PrimaryButton(text: 'Verify & continue', onTap: /*widget.onVerify*/(){verifyEmail(data.email, data.digits);}),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: /*canResend
                    ? */() {
                  resendOtpCall(data.email);
                }
                    /*: null*/,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    canResend
                        ? "Didn't get it? Resend"
                        : "Didn't get it? Resend in $formattedTime",
                    textAlign: TextAlign.center,
                    style: WerlogTextStyles.link,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> resendOtpCall(String email) async {
    try {
      final response = await ApiService.post(
          context,
          Endpoints.RESEND_OTP,
          body: {
            "email": email
          }
      );
      print('\nSUCCESS => $response');

      final result = response['result']=="1" ? true : false;
      if(result){

        GeneralFunctions.showSuccess(
          context,
          'OTP re-sent!',
        );
        // final data = response['data'];
        // final expiresTime = data['otpExpiresAt'].toString();
        setState(() {
          _secondsRemaining = 900;
        });
        _startTimer();

      }else{
        GeneralFunctions.showError(
          context,
          response['message']
        );
      }

    } catch (e) {
      print('ERROR => $e');
      GeneralFunctions.showError(
        context,
        "Process interrupted. Please try again!",
      );
    }
  }

  Future<void> verifyEmail(String email, List<String> digits) async {

    final cleanedDigits = digits
        .map((e) => e.trim())
        .toList();

    final isValidOtp =
        cleanedDigits.length == 6 &&
            cleanedDigits.every((e) => e.isNotEmpty);

    if (!isValidOtp) {
      GeneralFunctions.showError(
        context,
        'Please enter complete OTP',
      );
      return;
    }

    final otp = cleanedDigits.join();
    try {
      final response = await ApiService.post(
          context,
          Endpoints.VERIFY_OTP,
          body: {
            "email": email,
            "otp": otp
          }
      );
      print('\nSUCCESS => $response');

      final result = response['result']=="1" ? true : false;
      if(result){
        GeneralFunctions.showSuccess(
          context,
          'Email verified!',
        );

        final user = SharedPrefHelper.getObject(SharedPrefHelper.loginData);
        final update = user?['meResponse'];
        update['emailVerified'] = true;
        await SharedPrefHelper.saveObject(SharedPrefHelper.loginData, user!);
        // print(user?['name']);
        final data = user?['meResponse'];

        if(data['planCode']==null || data['planCode']=='') {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    SubscriptionScreen(
                      plans: defaultPlans,
                      initialSelectedIndex: 1,
                      initialCycle: 1,
                      onSkip: () => handlePlansClick(0),
                      onContinue: (_) => handlePlansClick(2),
                      onFree: () => handlePlansClick(1),
                    )
            ),
          );
        }else{
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => MainDashboardScreen()
            ),
          );
        }

      }else{
        GeneralFunctions.showError(
            context,
            response['message']
        );
      }

    } catch (e) {
      print('ERROR => $e');
      GeneralFunctions.showError(
        context,
        "Process interrupted. Please try again!",
      );
    }
  }

  Future<void> handlePlansClick(int i) async {
    if(i==0){

    }
  }


}
