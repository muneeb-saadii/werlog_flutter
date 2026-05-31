import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../api/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/shared_pref_helper.dart';

// ════════════════════════════════════════════════════════════════════
//  SessionRefreshScreen
//
//  Shown as a full-screen overlay while the token refresh is in flight.
//  The caller passes [onRefreshComplete] — a Future<bool> factory that
//  performs the actual API call and SharedPref update. This screen
//  handles all visual states (refreshing → success → auto-dismiss or
//  failure → retry / sign-out).
//
//  Usage (inside _handleSessionExpired):
//
//    await Navigator.of(context).push(
//      PageRouteBuilder(
//        opaque: false,
//        pageBuilder: (_, __, ___) => SessionRefreshScreen(
//          onRefreshComplete: (newData) async {
//            await SharedPrefHelper.setString(
//                SharedPrefHelper.accessToken, newData['accessToken']);
//            await SharedPrefHelper.setString(
//                SharedPrefHelper.refreshToken, newData['refreshToken']);
//          },
//          onSignOut: () { /* clear prefs + push sign-in */ },
//        ),
//      ),
//    );
// ════════════════════════════════════════════════════════════════════

enum _RefreshState { refreshing, success, failed }

class SessionRefreshScreen extends StatefulWidget {
  /// Called when the API returns successfully.
  /// Receives the raw response map — store whatever fields you need.
  final Future<void> Function(Map<String, dynamic> responseData) onRefreshComplete;

  /// Called when the user taps "Sign Out" after a failure.
  final VoidCallback onSignOut;

  const SessionRefreshScreen({
    super.key,
    required this.onRefreshComplete,
    required this.onSignOut,
  });

  @override
  State<SessionRefreshScreen> createState() => _SessionRefreshScreenState();
}

class _SessionRefreshScreenState extends State<SessionRefreshScreen>
    with TickerProviderStateMixin {

  _RefreshState _state = _RefreshState.refreshing;
  String? _errorMessage;

  // ── Grain / sand particle animation ───────────────────────────────
  late final AnimationController _sandCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _successCtrl;

  // Rotating dots ring
  late final AnimationController _ringCtrl;
  late final Animation<double> _ringRotation;

  // Success scale-in
  late final Animation<double> _successScale;
  late final Animation<double> _successFade;

  final List<_SandParticle> _particles = [];
  static const int _particleCount = 28;

  @override
  void initState() {
    super.initState();

    // Sand flow loop (drives CustomPainter repaint)
    _sandCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    // Gentle pulse on the logo
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    // Rotating arc ring
    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _ringRotation = Tween<double>(begin: 0, end: 2 * math.pi)
        .animate(CurvedAnimation(parent: _ringCtrl, curve: Curves.linear));

    // Success animation
    _successCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _successScale = Tween<double>(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _successCtrl, curve: Curves.elasticOut));
    _successFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _successCtrl, curve: Curves.easeIn));

    // Seed particles
    final rng = math.Random(42);
    for (int i = 0; i < _particleCount; i++) {
      _particles.add(_SandParticle(
        angle:    rng.nextDouble() * 2 * math.pi,
        radius:   36 + rng.nextDouble() * 28,
        speed:    0.4 + rng.nextDouble() * 0.6,
        size:     1.5 + rng.nextDouble() * 2.5,
        opacity:  0.25 + rng.nextDouble() * 0.55,
        offset:   rng.nextDouble(),
      ));
    }

    // Kick off the refresh immediately
    _doRefresh();
  }

  @override
  void dispose() {
    _sandCtrl.dispose();
    _pulseCtrl.dispose();
    _ringCtrl.dispose();
    _successCtrl.dispose();
    super.dispose();
  }

  // ── Token refresh orchestration ────────────────────────────────────
  Future<void> _doRefresh() async {
    setState(() {
      _state = _RefreshState.refreshing;
      _errorMessage = null;
    });

    try {
      // Call the real refresh API via ApiService
      final response = await ApiService.callRefreshTokenApi();
      final responseData = response['data'];

      print("_doRefresh::REFRESH-RESPONSE: "+responseData.toString());
      // Persist the new session data locally
      await SharedPrefHelper.saveObject(
        SharedPrefHelper.loginData,
        responseData,
      );
      await SharedPrefHelper.saveString(
        SharedPrefHelper.accessToken,
        responseData['accessToken'],
      );

      if (!mounted) return;

      // Hand parsed data to the caller to persist
      await widget.onRefreshComplete(responseData);

      if (!mounted) return;

      setState(() => _state = _RefreshState.success);
      _ringCtrl.stop();
      _sandCtrl.stop();
      await _successCtrl.forward();

      // Brief success pause then auto-dismiss
      await Future.delayed(const Duration(milliseconds: 900));
      if (mounted) Navigator.of(context).pop();

    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = _RefreshState.failed;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
      _ringCtrl.stop();
      _sandCtrl.stop();
    }
  }

  // ── Build ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WerlogColors.darkTeal,
      body: SafeArea(
        child: Stack(children: [

          // ── Ambient background arcs ──────────────────────────────────
          Positioned.fill(child: _AmbientArcsPainter(ctrl: _sandCtrl)),

          // ── Main centred content ─────────────────────────────────────
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLogoArea(),
                  const SizedBox(height: 40),
                  _buildStateContent(),
                ],
              ),
            ),
          ),

          // ── Bottom brand strip ───────────────────────────────────────
          Positioned(
            bottom: 24, left: 0, right: 0,
            child: Column(children: [
              Container(
                width: 32, height: 1,
                color: Colors.white.withOpacity(0.12),
              ),
              const SizedBox(height: 12),
              Text(
                'werlog',
                style: TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.25),
                  letterSpacing: 2.0,
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  // ── Logo + sand animation area ─────────────────────────────────────
  Widget _buildLogoArea() {
    return SizedBox(
      width: 160, height: 160,
      child: Stack(alignment: Alignment.center, children: [

        // Sand particles
        AnimatedBuilder(
          animation: _sandCtrl,
          builder: (_, __) => CustomPaint(
            size: const Size(160, 160),
            painter: _SandParticlePainter(
              particles: _particles,
              progress: _sandCtrl.value,
              color: WerlogColors.teal,
            ),
          ),
        ),

        // Rotating dashed ring
        AnimatedBuilder(
          animation: _ringRotation,
          builder: (_, __) => Transform.rotate(
            angle: _ringRotation.value,
            child: CustomPaint(
              size: const Size(120, 120),
              painter: _DashedRingPainter(
                color: _state == _RefreshState.refreshing
                    ? WerlogColors.teal
                    : Colors.transparent,
                strokeWidth: 1.5,
                dashCount: 10,
              ),
            ),
          ),
        ),

        // Inner circle + icon
        AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (_, __) {
            final pulse = 1.0 + _pulseCtrl.value * 0.06;
            return Transform.scale(
              scale: _state == _RefreshState.refreshing ? pulse : 1.0,
              child: _buildCenterIcon(),
            );
          },
        ),
      ]),
    );
  }

  Widget _buildCenterIcon() {
    if (_state == _RefreshState.success) {
      return FadeTransition(
        opacity: _successFade,
        child: ScaleTransition(
          scale: _successScale,
          child: Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: WerlogColors.teal,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: WerlogColors.teal.withOpacity(0.35),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(Icons.check_rounded,
                color: Colors.white, size: 38),
          ),
        ),
      );
    }

    if (_state == _RefreshState.failed) {
      return Container(
        width: 80, height: 80,
        decoration: BoxDecoration(
          color: WerlogColors.coral.withOpacity(0.15),
          shape: BoxShape.circle,
          border: Border.all(
            color: WerlogColors.coral.withOpacity(0.5),
            width: 1.5,
          ),
        ),
        child: Icon(Icons.lock_clock_outlined,
            color: WerlogColors.coral.withOpacity(0.9), size: 32),
      );
    }

    // Refreshing state
    return Container(
      width: 80, height: 80,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        shape: BoxShape.circle,
        border: Border.all(
          color: WerlogColors.teal.withOpacity(0.3),
          width: 1.2,
        ),
      ),
      child: const Icon(Icons.lock_open_outlined,
          color: WerlogColors.teal, size: 30),
    );
  }

  // ── State-specific text + actions ──────────────────────────────────
  Widget _buildStateContent() {
    switch (_state) {
      case _RefreshState.refreshing:
        return _buildRefreshingContent();
      case _RefreshState.success:
        return _buildSuccessContent();
      case _RefreshState.failed:
        return _buildFailedContent();
    }
  }

  Widget _buildRefreshingContent() {
    return Column(children: [
      Text(
        'Refreshing Session',
        style: TextStyle(
          fontFamily: 'DMSans',
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: Colors.white.withOpacity(0.92),
          letterSpacing: -0.3,
        ),
      ),
      const SizedBox(height: 10),
      Text(
        'Your session has expired. We\'re\nrenewing it automatically for you.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'DMSans',
          fontSize: 12,
          height: 1.7,
          color: Colors.white.withOpacity(0.45),
        ),
      ),
      const SizedBox(height: 32),
      // Animated status steps
      _buildStatusStep(Icons.vpn_key_outlined,    'Verifying refresh token', true,  false),
      const SizedBox(height: 10),
      _buildStatusStep(Icons.sync_outlined,        'Requesting new session',  false, false),
      const SizedBox(height: 10),
      _buildStatusStep(Icons.save_outlined,        'Saving credentials',      false, false),
    ]);
  }

  Widget _buildSuccessContent() {
    return Column(children: [
      Text(
        'You\'re back!',
        style: TextStyle(
          fontFamily: 'DMSans',
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: Colors.white.withOpacity(0.92),
          letterSpacing: -0.3,
        ),
      ),
      const SizedBox(height: 10),
      Text(
        'Session renewed successfully.\nContinuing where you left off.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'DMSans',
          fontSize: 12,
          height: 1.7,
          color: Colors.white.withOpacity(0.45),
        ),
      ),
    ]);
  }

  Widget _buildFailedContent() {
    return Column(children: [
      Text(
        'Session Expired',
        style: TextStyle(
          fontFamily: 'DMSans',
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: Colors.white.withOpacity(0.92),
          letterSpacing: -0.3,
        ),
      ),
      const SizedBox(height: 10),
      Text(
        _errorMessage?.isNotEmpty == true
            ? _errorMessage!
            : 'Unable to renew your session.\nPlease sign in again to continue.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'DMSans',
          fontSize: 12,
          height: 1.7,
          color: Colors.white.withOpacity(0.45),
        ),
        maxLines: 3,
      ),
      const SizedBox(height: 32),
      // Retry button
      _WerlogButton(
        label: 'Try Again',
        icon: Icons.refresh_rounded,
        onTap: _doRefresh,
        primary: true,
      ),
      const SizedBox(height: 12),
      // Sign out button
      _WerlogButton(
        label: 'Sign Out',
        icon: Icons.logout_rounded,
        onTap: widget.onSignOut,
        primary: false,
      ),
    ]);
  }

  Widget _buildStatusStep(IconData icon, String label,
      bool active, bool done) {
    return AnimatedBuilder(
      animation: _sandCtrl,
      builder: (_, __) {
        final pulse = active
            ? 0.5 + 0.5 * math.sin(_sandCtrl.value * 2 * math.pi)
            : 0.0;
        return Row(children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: done
                  ? WerlogColors.teal.withOpacity(0.15)
                  : active
                      ? WerlogColors.teal.withOpacity(0.10 + 0.08 * pulse)
                      : Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: done
                    ? WerlogColors.teal.withOpacity(0.6)
                    : active
                        ? WerlogColors.teal.withOpacity(0.3 + 0.2 * pulse)
                        : Colors.white.withOpacity(0.08),
                width: 0.8,
              ),
            ),
            child: Icon(
              done ? Icons.check_rounded : icon,
              size: 13,
              color: done
                  ? WerlogColors.teal
                  : active
                      ? WerlogColors.teal.withOpacity(0.7 + 0.3 * pulse)
                      : Colors.white.withOpacity(0.2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'DMSans',
              fontSize: 12,
              color: active
                  ? Colors.white.withOpacity(0.7 + 0.25 * pulse)
                  : Colors.white.withOpacity(0.25),
            ),
          ),
        ]);
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════════
//  _RefreshTokenService  — isolated API logic
//  Returns the decoded response body map on success; throws on failure.
// ════════════════════════════════════════════════════════════════════
class _RefreshTokenService {
  static Future<Map<String, dynamic>> refresh() async {
    // These imports are already available in ApiService's file.
    // Duplicated here so this file compiles standalone.
    // In production, call ApiService directly or move this into ApiService.

    // ignore: avoid_dynamic_calls
    final refreshToken = await _readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      throw Exception('No refresh token found. Please sign in again.');
    }

    final uri = Uri.parse('${_baseUrl}${_refreshEndpoint}');

    final response = await _httpPost(
      uri: uri,
      bearerToken: refreshToken,   // send the refresh token as bearer
      body: {'refreshToken': refreshToken},
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = _decodeJson(response.body);
      if (data is Map<String, dynamic>) return data;
      throw Exception('Unexpected response format from server.');
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Refresh token is invalid or expired.');
    } else {
      final data = _decodeJson(response.body);
      final msg  = (data is Map) ? (data['message'] ?? 'Server error') : 'Server error';
      throw Exception(msg.toString());
    }
  }

  // ── Thin helpers so this file has no direct imports ────────────────

  static const String _baseUrl          = 'https://werlog.com/api/';
  // Replace with Endpoints.REFRESH_SESSION_TOKEN value
  static const String _refreshEndpoint  = 'auth/refresh-token';

  static Future<String?> _readRefreshToken() async {
    // Delegate to SharedPrefHelper in your project:
    //   return SharedPrefHelper.getString(SharedPrefHelper.refreshToken);
    //
    // Stub — replace with real implementation:
    return null; // ← replace
  }

  static Future<dynamic> _httpPost({
    required Uri uri,
    required String bearerToken,
    required Map<String, dynamic> body,
  }) async {
    // In production use: http.post(uri, headers: ApiService.headers(token: bearerToken), body: jsonEncode(body))
    // Stub — replace with real implementation:
    throw UnimplementedError('Replace _httpPost stub with ApiService.post or http.post');
  }

  static dynamic _decodeJson(String src) {
    try {
      // ignore: avoid_dynamic_calls
      return _jsonDecode(src);
    } catch (_) {
      return {};
    }
  }

  // ignore: non_constant_identifier_names
  static dynamic _jsonDecode(String src) {
    // Delegates to dart:convert jsonDecode — avoids import in this snippet.
    // In the real file this file lives in the same package so just use jsonDecode directly.
    throw UnimplementedError('Import dart:convert and call jsonDecode directly');
  }
}

// ════════════════════════════════════════════════════════════════════
//  Button widget
// ════════════════════════════════════════════════════════════════════
class _WerlogButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool primary;

  const _WerlogButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: primary
              ? WerlogColors.teal
              : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: primary
                ? WerlogColors.teal
                : Colors.white.withOpacity(0.12),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16,
                color: primary ? Colors.white : Colors.white.withOpacity(0.6)),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: primary
                      ? Colors.white
                      : Colors.white.withOpacity(0.65),
                )),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
//  Sand particle data
// ════════════════════════════════════════════════════════════════════
class _SandParticle {
  final double angle;
  final double radius;
  final double speed;
  final double size;
  final double opacity;
  final double offset; // phase offset 0–1

  const _SandParticle({
    required this.angle,
    required this.radius,
    required this.speed,
    required this.size,
    required this.opacity,
    required this.offset,
  });
}

// ════════════════════════════════════════════════════════════════════
//  Sand particle painter
// ════════════════════════════════════════════════════════════════════
class _SandParticlePainter extends CustomPainter {
  final List<_SandParticle> particles;
  final double progress; // 0–1 looping
  final Color color;

  const _SandParticlePainter({
    required this.particles,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint  = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      // Each particle orbits at its own speed + phase offset
      final t     = (progress * p.speed + p.offset) % 1.0;
      final angle = p.angle + t * 2 * math.pi;
      final x     = center.dx + math.cos(angle) * p.radius;
      final y     = center.dy + math.sin(angle) * p.radius;

      // Fade in / out based on y position (bottom = brighter)
      final yFactor = (y - center.dy + p.radius) / (p.radius * 2);
      final alpha   = (p.opacity * yFactor.clamp(0.1, 1.0) * 255).round();

      paint.color = color.withAlpha(alpha);
      canvas.drawCircle(Offset(x, y), p.size / 2, paint);
    }
  }

  @override
  bool shouldRepaint(_SandParticlePainter old) => old.progress != progress;
}

// ════════════════════════════════════════════════════════════════════
//  Dashed rotating ring painter
// ════════════════════════════════════════════════════════════════════
class _DashedRingPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final int dashCount;

  const _DashedRingPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (color == Colors.transparent) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth;
    final paint  = Paint()
      ..color       = color.withOpacity(0.4)
      ..style       = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap   = StrokeCap.round;

    final dashAngle = (2 * math.pi) / dashCount;
    final gapFrac   = 0.35; // gap fraction of each segment

    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * dashAngle;
      final sweepAngle = dashAngle * (1 - gapFrac);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedRingPainter old) => old.color != color;
}

// ════════════════════════════════════════════════════════════════════
//  Ambient arcs background painter (full-screen subtle arcs)
// ════════════════════════════════════════════════════════════════════
class _AmbientArcsPainter extends StatelessWidget {
  final AnimationController ctrl;
  const _AmbientArcsPainter({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) => CustomPaint(
        painter: _AmbientArcCustomPainter(progress: ctrl.value),
      ),
    );
  }
}

class _AmbientArcCustomPainter extends CustomPainter {
  final double progress;
  const _AmbientArcCustomPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style       = PaintingStyle.stroke
      ..strokeWidth = 0.6;

    // Three slow-rotating large arcs in the background
    final arcs = [
      (size.width * 1.1, 0.08, 0.0),
      (size.width * 0.85, 0.05, 0.33),
      (size.width * 0.65, 0.04, 0.66),
    ];

    for (final (radius, opacity, phase) in arcs) {
      final angle = (progress + phase) * 2 * math.pi * 0.18;
      paint.color = WerlogColors.teal.withOpacity(opacity);
      canvas.drawArc(
        Rect.fromCircle(
            center: Offset(size.width * 0.5, size.height * 0.45),
            radius: radius),
        angle,
        math.pi * 1.1,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_AmbientArcCustomPainter old) =>
      old.progress != progress;
}
