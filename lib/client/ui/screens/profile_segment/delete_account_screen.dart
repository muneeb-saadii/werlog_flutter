import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../../../client/core/api/api_service.dart';
import '../../../../client/core/api/endpoints.dart';
import '../../../../client/core/remote_config/remote_config_service.dart';
import '../../../../client/core/theme/app_theme.dart';
import '../../../../client/core/utils/general_functions.dart';
import '../../../../client/core/utils/shared_pref_helper.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  DELETE ACCOUNT SCREEN
//  Shown from Profile when APP_ENABLE_ACC_DELETION == true.
//
//  Flow:
//    1. Warning screen  — user reads what will happen, taps "Continue"
//    2. Confirm screen  — final "Yes, delete" / "Cancel" choice
//    3. API call        — POST v1/public/users/{userId}/suspend (no auth needed)
//    4. Clear session   — SharedPrefHelper.clearAll() + restartApp()
// ─────────────────────────────────────────────────────────────────────────────

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {

  // ── UI state ──────────────────────────────────────────────────────────────
  _Step _step     = _Step.warning;
  bool  _loading  = false;
  String? _errorMsg;

  // ── Colours (matching Werlog theme) ───────────────────────────────────────
  static const Color _red      = Color(0xFFC0392B);
  static const Color _redLight = Color(0xFFFDF2F2);
  static const Color _redBorder= Color(0xFFF5C0BC);
  static const Color _amber    = Color(0xFFB7570A);
  static const Color _amberLt  = Color(0xFFFEF6EC);
  static const Color _teal     = WerlogColors.teal;
  static const Color _tealLt   = WerlogColors.tealSurface;

  // ── Proceed to confirm step ───────────────────────────────────────────────

  void _goToConfirm() => setState(() { _step = _Step.confirm; _errorMsg = null; });

  // ── API: suspend account ──────────────────────────────────────────────────

  Future<void> _requestDeletion() async {
    setState(() { _loading = true; _errorMsg = null; });

    try {
      // Read userId from saved session
      final loginData = SharedPrefHelper.getObject(SharedPrefHelper.loginData);
      final meResponse = loginData?['meResponse'] as Map<String, dynamic>?;
      final userId = meResponse?['id']?.toString()
                  ?? meResponse?['userId']?.toString()
                  ?? '';

      if (userId.isEmpty) {
        // Fallback: read from the flat loginData
        final flatId = loginData?['id']?.toString() ?? '';
        if (flatId.isEmpty) {
          setState(() {
            _errorMsg = 'Could not identify your account. '
                'Please contact support@werlog.com.';
            _loading = false;
          });
          return;
        }
      }

      final resolvedId = userId.isNotEmpty
          ? userId
          : (loginData?['id']?.toString() ?? '');

      debugPrint('[DeleteAccount] Suspending userId => $resolvedId');
      debugPrint('[DeleteAccount] URL => '
          '${RemoteConfigService.baseUrl}${Endpoints.publicSuspendUser(resolvedId)}');

      // Public endpoint — no Authorization header needed
      final uri = Uri.parse(
          '${RemoteConfigService.baseUrl}${Endpoints.publicSuspendUser(resolvedId)}');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept':       'application/json',
        },
        body: jsonEncode({}),
      );

      debugPrint('[DeleteAccount] status => ${response.statusCode}');
      debugPrint('[DeleteAccount] body   => ${response.body}');

      final data = jsonDecode(response.body) as Map<String, dynamic>? ?? {};
      final ok   = response.statusCode == 200 ||
                   response.statusCode == 204 ||
                   data['result']?.toString() == '1' ||
                   data['status']?.toString().toLowerCase() == 'success';

      final alreadySuspended = (data['message'] ?? '')
          .toString().toLowerCase().contains('suspended');

      if (ok || alreadySuspended) {
        // ── Success: clear session and restart to login screen ────────────
        await SharedPrefHelper.clearAll();
        if (!mounted) return;
        setState(() { _step = _Step.success; _loading = false; });
      } else {
        setState(() {
          _errorMsg = data['message']?.toString()
              ?? 'Something went wrong. Please try again or contact support.';
          _loading = false;
        });
      }

    } catch (e) {
      debugPrint('[DeleteAccount] error => $e');
      setState(() {
        _errorMsg = 'Connection error. Please check your internet and try again.';
        _loading  = false;
      });
    }
  }

  // ── Sign out after success ────────────────────────────────────────────────

  void _signOutAndRestart() {
    SharedPrefHelper.clearAll();
    GeneralFunctions.restartApp();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WerlogColors.background,
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(gradient: WerlogGradients.pageHeader()),
          child: Column(children: [
            // const FakeStatusBar(),
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                          begin: const Offset(0, 0.06), end: Offset.zero)
                          .animate(anim),
                      child: child,
                    ),
                  ),
                  child: _buildStep(),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
      child: Row(children: [
        GestureDetector(
          onTap: () {
            if (_step == _Step.confirm) {
              setState(() => _step = _Step.warning);
            } else if (_step != _Step.success) {
              Navigator.of(context).pop();
            }
          },
          child: Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: WerlogColors.surface,
              border: Border.all(color: WerlogColors.border),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(
              _step == _Step.success ? Icons.close : Icons.arrow_back,
              size: 18,
              color: WerlogColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text('Delete Account', style: WerlogTextStyles.pageTitle),
      ]),
    );
  }

  // ── Step router ───────────────────────────────────────────────────────────

  Widget _buildStep() {
    switch (_step) {
      case _Step.warning: return _buildWarningStep();
      case _Step.confirm: return _buildConfirmStep();
      case _Step.success: return _buildSuccessStep();
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  STEP 1 — Warning
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildWarningStep() {
    return Column(
      key: const ValueKey('warning'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [

        // ── Big alert banner ────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _redLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _redBorder),
          ),
          child: Column(children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: _red.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Text('🗑️', style: TextStyle(fontSize: 30)),
            ),
            const SizedBox(height: 14),
            Text(
              'Permanently Delete Account',
              style: WerlogTextStyles.sectionTitle.copyWith(
                  color: _red, fontSize: 16, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'This action is irreversible. Once deleted, your data '
              'cannot be recovered by anyone, including our support team.',
              style: WerlogTextStyles.bodySmall.copyWith(
                  color: const Color(0xFF8B2620), height: 1.55),
              textAlign: TextAlign.center,
            ),
          ]),
        ),

        const SizedBox(height: 16),

        // ── What will be deleted ─────────────────────────────────────────
        _InfoCard(
          title: 'What will be deleted',
          icon: '⚠️',
          borderColor: _redBorder,
          bgColor: _redLight,
          children: const [
            _BulletItem('All your receipts and invoices'),
            _BulletItem('All warranty records'),
            _BulletItem('All expense data and reports'),
            _BulletItem('Your account and login credentials'),
            _BulletItem('Personal settings and preferences'),
          ],
        ),

        const SizedBox(height: 12),

        // ── Timeline ───────────────────────────────────────────────────────
        _InfoCard(
          title: 'What happens after you confirm',
          icon: '📋',
          borderColor: WerlogColors.border,
          bgColor: WerlogColors.surface,
          children: const [
            _TimelineItem(
              emoji: '⏸️',
              title: 'Immediately — Account suspended',
              body:  'Your account is locked and you are signed out.',
            ),
            _TimelineItem(
              emoji: '🔄',
              title: 'Within 24 hours — Last chance',
              body:  'Email support@werlog.com to restore your account.',
            ),
            _TimelineItem(
              emoji: '🗑️',
              title: 'After 24 hours — Permanent deletion',
              body:  'All data is wiped from our servers. Cannot be undone.',
              isLast: true,
            ),
          ],
        ),

        const SizedBox(height: 20),

        // ── Amber info note ────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: _amberLt,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFF5C99A)),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('ℹ️', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 10),
            Expanded(child: Text(
              'If you subscribed to a paid plan, cancelling your '
              'subscription before deleting your account is recommended '
              'to avoid future charges.',
              style: WerlogTextStyles.caption.copyWith(
                  color: _amber, fontSize: 12, height: 1.5),
            )),
          ]),
        ),

        const SizedBox(height: 24),

        // ── Continue button ────────────────────────────────────────────────
        _DangerButton(
          label: 'I understand — Continue',
          onTap: _goToConfirm,
          loading: false,
        ),

        const SizedBox(height: 12),

        // ── Cancel ─────────────────────────────────────────────────────────
        _GhostButton(
          label: 'Cancel — Keep my account',
          onTap: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  STEP 2 — Final confirmation
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildConfirmStep() {
    return Column(
      key: const ValueKey('confirm'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [

        // ── Critical warning card ──────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _redLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _redBorder, width: 1.5),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Text('🚨', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Text('Are you absolutely sure?',
                  style: WerlogTextStyles.sectionTitle.copyWith(
                      color: _red, fontSize: 15, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 12),
            _ConfirmCheckPoint(
                text: 'I know all my data will be permanently deleted.'),
            _ConfirmCheckPoint(
                text: 'I understand this cannot be undone after 24 hours.'),
            _ConfirmCheckPoint(
                text: 'I have read the deletion timeline and I am ready.'),
          ]),
        ),

        const SizedBox(height: 16),

        // ── Error message ──────────────────────────────────────────────────
        if (_errorMsg != null) ...[
          _AlertBanner(
            type: _AlertType.error,
            title: 'Request failed',
            body: _errorMsg!,
          ),
          const SizedBox(height: 14),
        ],

        // ── Final delete button ────────────────────────────────────────────
        _DangerButton(
          label: 'Yes, permanently delete my account',
          onTap: _loading ? null : _requestDeletion,
          loading: _loading,
        ),

        const SizedBox(height: 12),

        // ── Cancel ─────────────────────────────────────────────────────────
        _GhostButton(
          label: '← No, keep my account',
          onTap: _loading
              ? null
              : () => setState(() { _step = _Step.warning; _errorMsg = null; }),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  STEP 3 — Success
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildSuccessStep() {
    return Column(
      key: const ValueKey('success'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [

        // ── Icon ──────────────────────────────────────────────────────────
        Center(
          child: Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: _redLight,
              shape: BoxShape.circle,
              border: Border.all(color: _redBorder, width: 2),
            ),
            alignment: Alignment.center,
            child: const Text('🔒', style: TextStyle(fontSize: 36)),
          ),
        ),

        const SizedBox(height: 20),

        Text('Account Deletion Requested',
            style: WerlogTextStyles.sectionTitle.copyWith(
                color: _red, fontSize: 18, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center),

        const SizedBox(height: 8),

        Text(
          'Your account has been suspended and is scheduled '
          'for permanent deletion.',
          style: WerlogTextStyles.bodySmall
              .copyWith(color: WerlogColors.textSecondary, height: 1.6),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 20),

        // ── Success banner ─────────────────────────────────────────────────
        _AlertBanner(
          type: _AlertType.success,
          title: 'Request received',
          body:  'Your account is suspended. You are now signed out '
                 'of all devices.',
        ),

        const SizedBox(height: 12),

        // ── Timeline recap ─────────────────────────────────────────────────
        _InfoCard(
          title: 'Deletion timeline',
          icon: '📋',
          borderColor: WerlogColors.border,
          bgColor: WerlogColors.surface,
          children: const [
            _TimelineItem(
              emoji: '⏸️',
              title: 'Now — Suspended',
              body:  'Account locked, sign-in disabled across all devices.',
            ),
            _TimelineItem(
              emoji: '🔄',
              title: '< 24 hours — Restore window',
              body:  'Email support@werlog.com to cancel deletion.',
            ),
            _TimelineItem(
              emoji: '🗑️',
              title: 'After 24 hours — Permanently deleted',
              body:  'All data wiped. Cannot be recovered.',
              isLast: true,
            ),
          ],
        ),

        const SizedBox(height: 12),

        // ── Amber note ─────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: _amberLt,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFF5C99A)),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('⚠️', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 10),
            Expanded(child: Text(
              'Changed your mind? Email support@werlog.com within '
              '24 hours. After that, deletion is permanent.',
              style: WerlogTextStyles.caption.copyWith(
                  color: _amber, fontSize: 12, height: 1.5),
            )),
          ]),
        ),

        const SizedBox(height: 24),

        // ── Sign out button ────────────────────────────────────────────────
        GestureDetector(
          onTap: _signOutAndRestart,
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: WerlogColors.teal,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text('Return to Sign In',
                style: WerlogTextStyles.button.copyWith(color: Colors.white)),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  STEP ENUM
// ─────────────────────────────────────────────────────────────────────────────

enum _Step { warning, confirm, success }

// ─────────────────────────────────────────────────────────────────────────────
//  SHARED SMALL WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

enum _AlertType { success, warning, error, info }

class _AlertBanner extends StatelessWidget {
  final _AlertType type;
  final String title, body;
  const _AlertBanner({required this.type, required this.title, required this.body});

  Color get _bg => switch (type) {
    _AlertType.success => WerlogColors.tealSurface,
    _AlertType.warning => const Color(0xFFFEF6EC),
    _AlertType.error   => const Color(0xFFFDF2F2),
    _AlertType.info    => const Color(0xFFEEF3FC),
  };

  Color get _border => switch (type) {
    _AlertType.success => const Color(0xFFA8D5BC),
    _AlertType.warning => const Color(0xFFF5C99A),
    _AlertType.error   => const Color(0xFFF5C0BC),
    _AlertType.info    => const Color(0xFFC5D8F8),
  };

  Color get _text => switch (type) {
    _AlertType.success => const Color(0xFF0F6E56),
    _AlertType.warning => const Color(0xFFB7570A),
    _AlertType.error   => const Color(0xFFC0392B),
    _AlertType.info    => const Color(0xFF1A4FA0),
  };

  String get _emoji => switch (type) {
    _AlertType.success => '✅',
    _AlertType.warning => '⚠️',
    _AlertType.error   => '❌',
    _AlertType.info    => 'ℹ️',
  };

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
    decoration: BoxDecoration(
      color: _bg,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _border),
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(_emoji, style: const TextStyle(fontSize: 15)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: WerlogTextStyles.bodySmall.copyWith(
            color: _text, fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 2),
        Text(body, style: WerlogTextStyles.caption.copyWith(
            color: _text, fontSize: 12, height: 1.5)),
      ])),
    ]),
  );
}

class _InfoCard extends StatelessWidget {
  final String title, icon;
  final Color borderColor, bgColor;
  final List<Widget> children;

  const _InfoCard({
    required this.title, required this.icon,
    required this.borderColor, required this.bgColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: borderColor),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
        child: Row(children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Text(title, style: WerlogTextStyles.labelUppercase.copyWith(
              fontSize: 10, color: WerlogColors.textSecondary)),
        ]),
      ),
      const Divider(height: 1, thickness: 0.5, color: WerlogColors.borderLight),
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        child: Column(children: children),
      ),
    ]),
  );
}

class _BulletItem extends StatelessWidget {
  final String text;
  const _BulletItem(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Padding(
        padding: EdgeInsets.only(top: 4),
        child: Icon(Icons.circle, size: 5, color: Color(0xFFC0392B)),
      ),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: WerlogTextStyles.caption.copyWith(
          fontSize: 12, color: const Color(0xFF8B2620), height: 1.5))),
    ]),
  );
}

class _TimelineItem extends StatelessWidget {
  final String emoji, title, body;
  final bool isLast;
  const _TimelineItem({
    required this.emoji, required this.title, required this.body,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Column(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
              color: WerlogColors.surfaceAlt,
              shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(emoji, style: const TextStyle(fontSize: 14)),
        ),
        if (!isLast) Container(
          width: 1.5, height: 22,
          color: WerlogColors.border,
          margin: const EdgeInsets.only(top: 2, bottom: 2),
        ),
      ]),
      const SizedBox(width: 12),
      Expanded(
        child: Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 6),
            Text(title, style: WerlogTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600, fontSize: 12, height: 1.3)),
            const SizedBox(height: 2),
            Text(body, style: WerlogTextStyles.caption.copyWith(
                fontSize: 11.5, height: 1.4)),
          ]),
        ),
      ),
    ],
  );
}

class _ConfirmCheckPoint extends StatelessWidget {
  final String text;
  const _ConfirmCheckPoint({required this.text});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Padding(
        padding: EdgeInsets.only(top: 2),
        child: Icon(Icons.check_circle_outline_rounded,
            size: 15, color: Color(0xFFC0392B)),
      ),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: WerlogTextStyles.caption.copyWith(
          fontSize: 12, color: const Color(0xFF8B2620), height: 1.5))),
    ]),
  );
}

class _DangerButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  const _DangerButton({required this.label, this.onTap, this.loading = false});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: 48,
      decoration: BoxDecoration(
        color: onTap == null
            ? const Color(0xFFC0392B).withOpacity(0.45)
            : const Color(0xFFC0392B),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: loading
          ? const SizedBox(width: 20, height: 20,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2.5))
          : Text(label,
              style: WerlogTextStyles.button.copyWith(
                  color: Colors.white, fontSize: 13.5)),
    ),
  );
}

class _GhostButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _GhostButton({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 46,
      decoration: BoxDecoration(
        color: WerlogColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WerlogColors.border),
      ),
      alignment: Alignment.center,
      child: Text(label, style: WerlogTextStyles.body.copyWith(
          fontSize: 13, color: WerlogColors.textSecondary,
          fontWeight: FontWeight.w500)),
    ),
  );
}
