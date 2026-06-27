// profile_segment/edit_profile_screen.dart
//
// Full profile screen — reads from SharedPreferences on init, lets user
// edit fullName + avatarUrl (camera / gallery), calls update API, saves locally.
//
// Required packages (add to pubspec.yaml):
//   shared_preferences: ^2.2.2
//   image_picker: ^1.0.7        ← handles Android 9-16 + iOS
//   cached_network_image: ^3.3.1
//
// Android: add to AndroidManifest.xml inside <manifest>:
//   <uses-permission android:name="android.permission.CAMERA" />
//   <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
//       android:maxSdkVersion="32" />
//   <uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
// Inside <application>:
//   <provider
//     android:name="androidx.core.content.FileProvider"
//     android:authorities="${applicationId}.fileprovider"
//     android:exported="false"
//     android:grantUriPermissions="true">
//     <meta-data android:name="android.support.FILE_PROVIDER_PATHS"
//       android:resource="@xml/file_paths" />
//   </provider>
// Create res/xml/file_paths.xml:
//   <paths><external-cache-path name="camera" path="." /></paths>

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../../core/api/api_service.dart';
import '../../../core/api/endpoints.dart';
import '../../../core/models/profile_models.dart';
import '../../../core/utils/shared_pref_helper.dart';
import '../camera_screen.dart';


class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  UserProfile? _user;
  bool _loading = true;
  bool _saving = false;

  final _nameCtrl = TextEditingController();
  File? _pickedImage;         // local file selected from camera/gallery
  String? _avatarUrlOverride; // if user picked an image we upload and get back a URL

  bool get _isDirty {
    if (_user == null) return false;
    if (_pickedImage != null) return true;
    if (_nameCtrl.text.trim() != _user!.fullName) return true;
    return false;
  }

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    // final user = await ProfilePrefs.load();
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

    if (mounted) {
      setState(() {
        _user = myUser;
        _nameCtrl.text = _user!.fullName;
        _loading = false;
      });
    }
  }

  // ── Image picker ────────────────────────────────────────────────────────────
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    try {
      final xFile = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (xFile != null && mounted) {
        setState(() => _pickedImage = File(xFile.path));
      }
    } catch (e) {
      if (mounted) _showSnack('Could not access ${source == ImageSource.camera ? 'camera' : 'gallery'}. Check permissions.', isError: true);
    }
  }

  void _showAvatarOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: WerlogColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                    color: WerlogColors.border,
                    borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 18),
              Text('Update Profile Photo',
                  style: const TextStyle(
                    fontFamily: 'DMSans', fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: WerlogColors.textPrimary,
                  )),
              const SizedBox(height: 18),
              _SheetOption(
                icon: Icons.camera_alt_outlined,
                label: 'Take a photo',
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 10),
              _SheetOption(
                icon: Icons.photo_library_outlined,
                label: 'Choose from gallery',
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_user?.avatarUrl != null || _pickedImage != null) ...[
                const SizedBox(height: 10),
                _SheetOption(
                  icon: Icons.delete_outline_rounded,
                  label: 'Remove photo',
                  color: WerlogColors.coral,
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _pickedImage = null);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Save / update API ───────────────────────────────────────────────────────
  Future<void> _saveProfile() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _showSnack('Full name cannot be empty.', isError: true);
      return;
    }

    setState(() => _saving = true);

    try {

      final response = await ApiService.uploadImage(
        context,
        Endpoints.UPDATE_USER_PROFILE,
        _pickedImage!,
        'file',
        // extraFields: {'currency': 'USD'},
      );

      final result = response['result'] == "1";

      if (result && mounted) {

        // final updated = _user!.copyWith(fullName: name);
        // await ProfilePrefs.save(updated);
        // setState(() {
        //   _user = updated;
        //   _pickedImage = null;
        //   _saving = false;
        // });
        _showSnack('Profile updated successfully!');
        Navigator.of(context).pop();
      } else {
        setState(() => _saving = false);
        _showSnack('Update failed. Please try again.', isError: true);
      }
    } catch (e) {
      setState(() => _saving = false);
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
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: WerlogColors.background,
        body: Center(
            child: CircularProgressIndicator(color: WerlogColors.teal)),
      );
    }

    final user = _user!;

    return Scaffold(
      backgroundColor: WerlogColors.background,
      appBar: WerlogAppBar(
        title: 'My Profile',
        actions: [
          if (_isDirty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: GestureDetector(
                onTap: _saving ? null : _saveProfile,
                child: _saving
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                            color: WerlogColors.teal, strokeWidth: 2))
                    : const Text('Save',
                        style: TextStyle(
                          fontFamily: 'DMSans', fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: WerlogColors.teal,
                        )),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          // ── Hero avatar section ─────────────────────────────────────────
          const SizedBox(height: 28),
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: _showAvatarOptions,
                  child: Stack(
                    children: [
                      _Avatar(
                        user: user,
                        localFile: _pickedImage,
                        size: 88,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(
                            color: WerlogColors.teal,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: WerlogColors.background, width: 2),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.camera_alt_rounded,
                              size: 13, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(user.fullName,
                    style: const TextStyle(
                      fontFamily: 'DMSans', fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: WerlogColors.textPrimary,
                      letterSpacing: -0.3,
                    )),
                /*const SizedBox(height: 4),
                _PlanBadge(planCode: user.planCode),*/
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── Editable section ────────────────────────────────────────────
          _SectionLabel('Personal Info'),
          const SizedBox(height: 10),
          WerlogCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                WerlogTextField(
                  controller: _nameCtrl,
                  label: 'FULL NAME',
                  hint: 'Your full name',
                  keyboardType: TextInputType.name,
                ),
                const SizedBox(height: 16),
                WerlogTextField(
                  controller: TextEditingController(text: user.email),
                  label: 'EMAIL',
                  enabled: false,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Read-only info section ──────────────────────────────────────
          _SectionLabel('Account Details'),
          const SizedBox(height: 10),
          WerlogCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.verified_user_outlined,
                  label: 'Email Verified',
                  value: user.emailVerified ? 'Verified' : 'Not verified',
                  valueColor: user.emailVerified
                      ? WerlogColors.teal
                      : WerlogColors.coral,
                  isFirst: true,
                ),
                _InfoRow(
                  icon: Icons.manage_accounts_outlined,
                  label: 'Role',
                  value: user.role == 'ROLE_USER' ? 'User' : user.role,
                ),
                /*_InfoRow(
                  icon: Icons.psychology_outlined,
                  label: 'OCR Engine',
                  value: user.engine,
                ),*/
                _InfoRow(
                  icon: Icons.workspace_premium_outlined,
                  label: 'Plan',
                  value: user.planLabel,
                  valueColor: WerlogColors.teal,
                ),
                _InfoRow(
                  icon: Icons.ads_click_outlined,
                  label: 'Ads',
                  value: user.showAds ? 'Enabled' : 'Disabled',
                  isLast: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── Save button (bottom) ────────────────────────────────────────
          AnimatedOpacity(
            opacity: _isDirty ? 1 : 0,
            duration: const Duration(milliseconds: 200),
            child: WerlogPrimaryButton(
              label: 'Save Changes',
              isLoading: _saving,
              onTap: _isDirty ? _saveProfile : null,
              icon: Icons.check_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SUB-WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final UserProfile user;
  final File? localFile;
  final double size;

  const _Avatar({required this.user, this.localFile, this.size = 60});

  @override
  Widget build(BuildContext context) {
    ImageProvider? imageProvider;
    if (localFile != null) {
      imageProvider = FileImage(localFile!);
    } else if (user.avatarUrl != null && user.avatarUrl!.isNotEmpty) {
      imageProvider = NetworkImage(user.avatarUrl!);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: WerlogColors.tealSurface,
        border: Border.all(color: WerlogColors.border, width: 2),
        image: imageProvider != null
            ? DecorationImage(image: imageProvider, fit: BoxFit.cover)
            : null,
      ),
      alignment: Alignment.center,
      child: imageProvider == null
          ? Text(user.initials,
              style: TextStyle(
                fontFamily: 'DMSans',
                fontSize: size * 0.32,
                fontWeight: FontWeight.w600,
                color: WerlogColors.teal,
              ))
          : null,
    );
  }
}

class _PlanBadge extends StatelessWidget {
  final String planCode;
  const _PlanBadge({required this.planCode});

  @override
  Widget build(BuildContext context) {
    final isPro = planCode.toUpperCase() == 'PRO';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: isPro ? WerlogColors.tealSurface : WerlogColors.surfaceAlt,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isPro
                ? WerlogColors.teal.withOpacity(0.3)
                : WerlogColors.border),
      ),
      child: Text(
        isPro ? '✦ Pro Plan' : 'Free Plan',
        style: TextStyle(
          fontFamily: 'DMSans',
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: isPro ? WerlogColors.teal : WerlogColors.textTertiary,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text.toUpperCase(),
        style: const TextStyle(
          fontFamily: 'DMSans',
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: WerlogColors.textTertiary,
          letterSpacing: 0.8,
        ));
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool isFirst;
  final bool isLast;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Icon(icon, size: 16, color: WerlogColors.textTertiary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(label,
                    style: const TextStyle(
                      fontFamily: 'DMSans', fontSize: 13,
                      color: WerlogColors.textPrimary,
                    )),
              ),
              Text(value,
                  style: TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: valueColor ?? WerlogColors.textSecondary,
                  )),
            ],
          ),
        ),
        if (!isLast)
          Padding(
            padding: const EdgeInsets.only(left: 42),
            child: Container(height: 0.5, color: WerlogColors.borderLight),
          ),
      ],
    );
  }
}

class _SheetOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _SheetOption({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? WerlogColors.textPrimary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color != null
              ? WerlogColors.coralSurface
              : WerlogColors.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: c),
            const SizedBox(width: 12),
            Text(label,
                style: TextStyle(
                  fontFamily: 'DMSans', fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: c,
                )),
          ],
        ),
      ),
    );
  }
}

// Re-export shared widgets so callers don't need a separate import
class WerlogAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool centerTitle;
  const WerlogAppBar({super.key, required this.title, this.actions, this.centerTitle = false});
  @override
  Size get preferredSize => const Size.fromHeight(56);
  @override
  Widget build(BuildContext context) => AppBar(
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
            ))
        : null,
    title: Text(title,
        style: const TextStyle(
          fontFamily: 'DMSans', fontSize: 17, fontWeight: FontWeight.w500,
          color: WerlogColors.textPrimary, letterSpacing: -0.2,
        )),
    actions: actions,
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(1),
      child: Container(color: WerlogColors.border, height: 0.5),
    ),
  );
}
