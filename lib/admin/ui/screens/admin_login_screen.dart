import 'package:flutter/material.dart';
import '../../../client/core/utils/shared_pref_helper.dart';
import '../../core/api/admin_api_service.dart';
import '../../core/api/admin_endpoints.dart';
import '../../core/routes/admin_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';

/// Admin-only login screen.
/// After successful login, checks role == ROLE_SUPER_ADMIN before
/// allowing entry to the admin dashboard.
class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {

  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey      = GlobalKey<FormState>();

  bool _loading       = false;
  bool _obscure       = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ── Login ──────────────────────────────────────────────────────────

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final response = await AdminApiService.post(
        context,
        AdminEndpoints.login,
        body: {
          'email':    _emailCtrl.text.trim(),
          'password': _passwordCtrl.text,
        },
        showLoader: false,
      );

      if (!mounted) return;

      debugPrint('[AdminLogin] response => $response');

      if (response == null) {
        AdminApiService.showError(context, 'No response from server.');
        return;
      }

      final result = response['result']?.toString();
      if (result != '1') {
        AdminApiService.showError(
            context,
            response['message']?.toString() ?? 'Login failed.');
        return;
      }

      final data       = response['data'] as Map<String, dynamic>? ?? {};
      final meResponse = data['meResponse'] as Map<String, dynamic>? ?? {};
      final role       = meResponse['role']?.toString() ?? '';

      debugPrint('[AdminLogin] role => $role');

      if (role != 'ROLE_SUPER_ADMIN') {
        AdminApiService.showError(
            context, 'Access denied. Super admin account required.');
        return;
      }

      // ── Save session ───────────────────────────────────────────────
      await SharedPrefHelper.saveString(
          SharedPrefHelper.accessToken,
          data['accessToken']?.toString() ?? '');
      await SharedPrefHelper.saveString(
          SharedPrefHelper.refreshToken,
          data['refreshToken']?.toString() ?? '');
      await SharedPrefHelper.saveObject(SharedPrefHelper.loginData, data);

      debugPrint('[AdminLogin] login success — navigating to dashboard');

      if (!mounted) return;
      Navigator.of(context)
          .pushNamedAndRemoveUntil(AdminRoutes.dashboard, (r) => false);

    } catch (e) {
      debugPrint('[AdminLogin] error => $e');
      if (mounted) {
        AdminApiService.showError(context,
            e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppMetrics.pagePadding),
        child: Column(children: [
          const SizedBox(height: 40),

          // ── Brand header ───────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.darkGreen,
              borderRadius: BorderRadius.circular(AppMetrics.cardRadius),
            ),
            child: Column(children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  color: AppColors.accentGreen.withOpacity(0.25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shield_rounded,
                    color: Colors.white, size: 30),
              ),
              const SizedBox(height: 16),
              const Text('Admin Panel',
                  style: AppTextStyles.headerTitle),
              const SizedBox(height: 4),
              const Text('Sign in with your super admin account',
                  style: AppTextStyles.headerSubtitle,
                  textAlign: TextAlign.center),
            ]),
          ),

          const SizedBox(height: 28),

          // ── Form ───────────────────────────────────────────────────
          Form(
            key: _formKey,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(AppMetrics.cardRadius),
              ),
              child: Column(children: [

                // Email
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: AppTextStyles.rowValue,
                  decoration: _inputDecoration(
                      label: 'Email', icon: Icons.email_outlined),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Email is required' : null,
                ),

                const SizedBox(height: 14),

                // Password
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscure,
                  style: AppTextStyles.rowValue,
                  decoration: _inputDecoration(
                    label: 'Password', icon: Icons.lock_outline_rounded,
                  ).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppColors.textSecondary, size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'Password is required' : null,
                ),

                const SizedBox(height: 22),

                // Submit
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.darkGreen,
                      disabledBackgroundColor:
                          AppColors.darkGreen.withOpacity(0.5),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5))
                        : const Text('Sign In',
                            style: TextStyle(
                                fontFamily: 'DMSans',
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                  ),
                ),
              ]),
            ),
          ),

          const SizedBox(height: 24),

          Text('Werlog Admin · Restricted access',
              style: AppTextStyles.footerNote,
              textAlign: TextAlign.center),
        ]),
      ),
    ),
  );

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) =>
      InputDecoration(
        labelText: label,
        labelStyle: AppTextStyles.rowLabel,
        prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.accentGreen, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 14),
      );
}
