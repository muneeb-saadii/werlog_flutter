// profile_segment/info_screens.dart
//
// Four static information screens:
//   FaqScreen, ContactSupportScreen, TermsScreen, PrivacyPolicyScreen
//
// All share a single rich _InfoScaffold layout with expandable cards.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models/profile_models.dart'; // add url_launcher: ^6.2.5 to pubspec


// ─────────────────────────────────────────────────────────────────────────────
// FAQs
// ─────────────────────────────────────────────────────────────────────────────

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  static const _faqs = [
    _FaqItem(
      q: 'What is Werlog?',
      a: 'Werlog is an AI-powered document scanning app that extracts key details — like warranty dates, invoice amounts, and vendor information — from your documents automatically using OCR technology.',
    ),
    _FaqItem(
      q: 'How does the OCR scanning work?',
      a: 'You photograph or upload a document, and our AI engine (powered by AI Vision or other engines depending on your plan) reads and extracts structured data from it in seconds.',
    ),
    _FaqItem(
      q: 'What document types are supported?',
      a: 'We support invoices, receipts, warranty cards, and owner manuals. Support for more document types is on our roadmap.',
    ),
    _FaqItem(
      q: 'Why is confidence showing as LOW?',
      a: 'Low confidence means the engine could not clearly identify one or more fields. This can happen with low-resolution images, handwritten text, or unusual document layouts. Try rescanning with better lighting.',
    ),
    _FaqItem(
      q: 'Can I edit extracted data after scanning?',
      a: 'Yes. After a scan completes, tap any extracted field on the result screen to manually correct or fill in missing values.',
    ),
    _FaqItem(
      q: 'What is the monthly quota?',
      a: 'Each plan includes a fixed number of scans per month. Free users get a limited allowance. Upgrade to Basic or Pro for higher limits.',
    ),
    _FaqItem(
      q: 'How do I upgrade my plan?',
      a: 'Go to Profile → Your Plan, or tap the upgrade banner that appears when you are running low on quota.',
    ),
    _FaqItem(
      q: 'Is my data safe?',
      a: 'All documents are transmitted over HTTPS and processed in isolated cloud environments. We do not use your documents to train AI models. See our Privacy Policy for full details.',
    ),
    _FaqItem(
      q: 'How do I delete my account?',
      a: 'Send a deletion request from Profile → Contact Support. We will permanently erase all your data within 30 days.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return _InfoScaffold(
      title: 'FAQs',
      heroIcon: Icons.help_outline_rounded,
      heroColor: WerlogColors.purple,
      heroSurface: WerlogColors.purpleSurface,
      heroTitle: 'Frequently Asked Questions',
      heroSubtitle: 'Quick answers to common questions about Werlog.',
      child: _ExpandableList(items: _faqs),
    );
  }
}

class _FaqItem {
  final String q;
  final String a;
  const _FaqItem({required this.q, required this.a});
}

class _ExpandableList extends StatefulWidget {
  final List<_FaqItem> items;
  const _ExpandableList({required this.items});
  @override
  State<_ExpandableList> createState() => _ExpandableListState();
}

class _ExpandableListState extends State<_ExpandableList> {
  int? _open;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: widget.items.asMap().entries.map((e) {
        final i = e.key;
        final item = e.value;
        final isOpen = _open == i;
        return GestureDetector(
          onTap: () => setState(() => _open = isOpen ? null : i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: isOpen ? WerlogColors.surface : WerlogColors.surface,
              border: Border.all(
                  color: isOpen
                      ? WerlogColors.teal.withOpacity(0.3)
                      : WerlogColors.border),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(item.q,
                            style: TextStyle(
                              fontFamily: 'DMSans',
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isOpen
                                  ? WerlogColors.teal
                                  : WerlogColors.textPrimary,
                            )),
                      ),
                      const SizedBox(width: 8),
                      AnimatedRotation(
                        turns: isOpen ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(Icons.keyboard_arrow_down_rounded,
                            size: 20,
                            color: isOpen
                                ? WerlogColors.teal
                                : WerlogColors.textTertiary),
                      ),
                    ],
                  ),
                ),
                if (isOpen)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: Text(item.a,
                        style: const TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 13,
                          color: WerlogColors.textSecondary,
                          height: 1.6,
                        )),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CONTACT SUPPORT
// ─────────────────────────────────────────────────────────────────────────────

class ContactSupportScreen extends StatefulWidget {
  const ContactSupportScreen({super.key});
  @override
  State<ContactSupportScreen> createState() => _ContactSupportScreenState();
}

class _ContactSupportScreenState extends State<ContactSupportScreen> {
  final _subjectCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  bool _sending = false;
  String _selectedCategory = 'General';

  static const _categories = [
    'General',
    'Billing & Plans',
    'Scanning Issue',
    'Account & Login',
    'Data & Privacy',
    'Feature Request',
    'Bug Report',
  ];

  Future<void> _send() async {
    if (_subjectCtrl.text.trim().isEmpty || _bodyCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please fill in all fields.'),
        backgroundColor: WerlogColors.coral,
      ));
      return;
    }
    setState(() => _sending = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _sending = false);
    _subjectCtrl.clear();
    _bodyCtrl.clear();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Message sent! We\'ll get back within 24 hours.',
          style: TextStyle(fontFamily: 'DMSans', fontSize: 13)),
      backgroundColor: WerlogColors.teal,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _InfoScaffold(
      title: 'Contact Support',
      heroIcon: Icons.support_agent_outlined,
      heroColor: WerlogColors.teal,
      heroSurface: WerlogColors.tealSurface,
      heroTitle: 'We\'re here to help',
      heroSubtitle: 'Describe your issue and we\'ll respond within 24 hours.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick contact chips
          Row(children: [
            _ContactChip(
              icon: Icons.email_outlined,
              label: 'Email us',
              onTap: () => _launch('mailto:support@werlog.app'),
            ),
            const SizedBox(width: 10),
            _ContactChip(
              icon: Icons.chat_bubble_outline_rounded,
              label: 'Live chat',
              onTap: () => _launch('https://werlog.app/chat'),
            ),
          ]),
          const SizedBox(height: 24),

          _SLabel('CATEGORY'),
          const SizedBox(height: 8),
          _CategoryDropdown(
            categories: _categories,
            selected: _selectedCategory,
            onChanged: (v) => setState(() => _selectedCategory = v),
          ),
          const SizedBox(height: 16),

          _SLabel('SUBJECT'),
          const SizedBox(height: 8),
          _InputField(
            controller: _subjectCtrl,
            hint: 'e.g. Scan failed on Android 13',
          ),
          const SizedBox(height: 16),

          _SLabel('MESSAGE'),
          const SizedBox(height: 8),
          _InputField(
            controller: _bodyCtrl,
            hint: 'Describe what happened in detail…',
            maxLines: 5,
          ),
          const SizedBox(height: 24),

          _PrimaryBtn(
            label: 'Send Message',
            isLoading: _sending,
            icon: Icons.send_rounded,
            onTap: _sending ? null : _send,
          ),

          const SizedBox(height: 20),

          // Response time note
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: WerlogColors.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: WerlogColors.border),
            ),
            child: Row(
              children: const [
                Icon(Icons.access_time_rounded,
                    size: 16, color: WerlogColors.textTertiary),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Typical response time: within 24 hours on weekdays.',
                    style: TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 12,
                      color: WerlogColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }
}

class _ContactChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ContactChip({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: WerlogColors.tealSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: WerlogColors.teal.withOpacity(0.25)),
      ),
      child: Row(children: [
        Icon(icon, size: 15, color: WerlogColors.teal),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(
          fontFamily: 'DMSans', fontSize: 12,
          fontWeight: FontWeight.w500, color: WerlogColors.teal,
        )),
      ]),
    ),
  );
}

class _CategoryDropdown extends StatelessWidget {
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onChanged;
  const _CategoryDropdown({required this.categories, required this.selected, required this.onChanged});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(
      color: WerlogColors.surface,
      border: Border.all(color: WerlogColors.border),
      borderRadius: BorderRadius.circular(11),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: selected,
        isExpanded: true,
        style: const TextStyle(
          fontFamily: 'DMSans', fontSize: 14, color: WerlogColors.textPrimary,
        ),
        items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
        onChanged: (v) { if (v != null) onChanged(v); },
      ),
    ),
  );
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  const _InputField({required this.controller, required this.hint, this.maxLines = 1});
  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    maxLines: maxLines,
    style: const TextStyle(fontFamily: 'DMSans', fontSize: 14, color: WerlogColors.textPrimary),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontFamily: 'DMSans', fontSize: 14, color: WerlogColors.textDisabled),
      filled: true,
      fillColor: WerlogColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: const BorderSide(color: WerlogColors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: const BorderSide(color: WerlogColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: const BorderSide(color: WerlogColors.teal, width: 1.5)),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// TERMS & CONDITIONS
// ─────────────────────────────────────────────────────────────────────────────

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  static const _sections = [
    _DocSection('1. Acceptance of Terms',
        'By accessing or using Werlog, you agree to be bound by these Terms and Conditions. If you do not agree, please do not use the service.'),
    _DocSection('2. Description of Service',
        'Werlog provides AI-powered document scanning and data extraction services. Features vary by subscription plan. We reserve the right to modify or discontinue any feature at our discretion.'),
    _DocSection('3. User Accounts',
        'You are responsible for maintaining the confidentiality of your account credentials. You must notify us immediately of any unauthorized access. You may not share your account with others.'),
    _DocSection('4. Acceptable Use',
        'You agree not to use Werlog for any unlawful purpose, to scan documents you do not have rights to, to attempt to reverse-engineer the service, or to interfere with system integrity.'),
    _DocSection('5. Subscription and Billing',
        'Paid plans are billed in advance on a monthly basis. Refunds are not provided for partial periods. Downgrading your plan takes effect at the next billing cycle.'),
    _DocSection('6. Intellectual Property',
        'All content, design, and software comprising the Werlog service is owned by Werlog and protected by applicable intellectual property laws. You may not reproduce or distribute any part without written consent.'),
    _DocSection('7. Data and Privacy',
        'Your use of the service is also governed by our Privacy Policy. By using Werlog, you consent to the collection and use of your data as described therein.'),
    _DocSection('8. Limitation of Liability',
        'To the maximum extent permitted by law, Werlog shall not be liable for any indirect, incidental, or consequential damages arising from your use of the service.'),
    _DocSection('9. Termination',
        'We may suspend or terminate your account at any time for violation of these terms. You may close your account at any time by contacting support.'),
    _DocSection('10. Changes to Terms',
        'We reserve the right to update these Terms at any time. Continued use of the service after changes constitutes acceptance of the new Terms.'),
    _DocSection('11. Contact',
        'For any questions about these Terms, contact us at legal@werlog.app.'),
  ];

  @override
  Widget build(BuildContext context) {
    return _InfoScaffold(
      title: 'Terms & Conditions',
      heroIcon: Icons.gavel_rounded,
      heroColor: WerlogColors.amber,
      heroSurface: WerlogColors.amberSurface,
      heroTitle: 'Terms & Conditions',
      heroSubtitle: 'Last updated: May 2026',
      child: Column(
        children: _sections
            .map((s) => _DocBlock(section: s))
            .toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRIVACY POLICY
// ─────────────────────────────────────────────────────────────────────────────

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const _sections = [
    _DocSection('1. Information We Collect',
        'We collect information you provide directly (name, email, documents you upload), information generated by your use of the service (scan history, usage patterns), and device information (model, OS version, app version).'),
    _DocSection('2. How We Use Your Information',
        'We use your information to provide and improve the service, process your scans, send transactional notifications, respond to support requests, and comply with legal obligations. We do not sell your personal data.'),
    _DocSection('3. Document Data',
        'Documents you upload are processed temporarily in our cloud environment and then deleted after extraction is complete. Extracted data (vendor names, amounts, dates) is stored in your account. You can delete this at any time.'),
    _DocSection('4. AI Processing',
        'Your documents may be processed by third-party AI services (such as OpenAI\'s AI Vision API). These services operate under strict data processing agreements and do not use your documents to train their models.'),
    _DocSection('5. Data Sharing',
        'We do not share your personal data with third parties except as necessary to provide the service, comply with law, or protect rights. We never sell data to advertisers.'),
    _DocSection('6. Data Retention',
        'We retain your account data while your account is active. Extracted document data is kept until you delete it. Raw uploaded files are deleted immediately after processing.'),
    _DocSection('7. Security',
        'We use industry-standard security measures including HTTPS encryption, isolated processing environments, and regular security audits. No method of transmission is 100% secure; we cannot guarantee absolute security.'),
    _DocSection('8. Your Rights',
        'Depending on your jurisdiction, you may have rights to access, correct, delete, or export your personal data. To exercise these rights, contact privacy@werlog.app.'),
    _DocSection('9. Children\'s Privacy',
        'Werlog is not directed at children under 13. We do not knowingly collect personal information from children. If you believe a child has provided us data, contact us to have it removed.'),
    _DocSection('10. Cookies & Tracking',
        'Our mobile app does not use browser cookies. We may use anonymous analytics (e.g. crash reporting) to improve performance. You can opt out in Settings.'),
    _DocSection('11. Changes to This Policy',
        'We may update this policy periodically. We will notify you of material changes via in-app notification or email at least 14 days before they take effect.'),
    _DocSection('12. Contact',
        'Privacy questions: privacy@werlog.app\nWerlog, 123 Tech Street, Lahore, Pakistan.'),
  ];

  @override
  Widget build(BuildContext context) {
    return _InfoScaffold(
      title: 'Privacy Policy',
      heroIcon: Icons.shield_outlined,
      heroColor: WerlogColors.blue,
      heroSurface: WerlogColors.blueSurface,
      heroTitle: 'Privacy Policy',
      heroSubtitle: 'Last updated: May 2026',
      child: Column(
        children: _sections
            .map((s) => _DocBlock(section: s))
            .toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED SCAFFOLD FOR INFO SCREENS
// ─────────────────────────────────────────────────────────────────────────────

class _InfoScaffold extends StatelessWidget {
  final String title;
  final IconData heroIcon;
  final Color heroColor;
  final Color heroSurface;
  final String heroTitle;
  final String heroSubtitle;
  final Widget child;

  const _InfoScaffold({
    required this.title,
    required this.heroIcon,
    required this.heroColor,
    required this.heroSurface,
    required this.heroTitle,
    required this.heroSubtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WerlogColors.background,
      appBar: _WAppBar(title: title),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
        children: [
          // Hero banner
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            decoration: BoxDecoration(
              color: heroSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: heroColor.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: heroColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(heroIcon, size: 24, color: heroColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(heroTitle,
                          style: TextStyle(
                            fontFamily: 'DMSans', fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: heroColor,
                          )),
                      const SizedBox(height: 3),
                      Text(heroSubtitle,
                          style: const TextStyle(
                            fontFamily: 'DMSans', fontSize: 12,
                            color: WerlogColors.textSecondary, height: 1.4,
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED SMALL WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _DocSection {
  final String title;
  final String body;
  const _DocSection(this.title, this.body);
}

class _DocBlock extends StatelessWidget {
  final _DocSection section;
  const _DocBlock({required this.section});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: WerlogColors.surface,
      border: Border.all(color: WerlogColors.border),
      borderRadius: BorderRadius.circular(13),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(section.title,
            style: const TextStyle(
              fontFamily: 'DMSans', fontSize: 13,
              fontWeight: FontWeight.w600,
              color: WerlogColors.textPrimary,
            )),
        const SizedBox(height: 7),
        Text(section.body,
            style: const TextStyle(
              fontFamily: 'DMSans', fontSize: 13,
              color: WerlogColors.textSecondary, height: 1.65,
            )),
      ],
    ),
  );
}

class _SLabel extends StatelessWidget {
  final String text;
  const _SLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
        fontFamily: 'DMSans', fontSize: 10, fontWeight: FontWeight.w500,
        color: WerlogColors.textTertiary, letterSpacing: 0.8,
      ));
}

class _PrimaryBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final IconData? icon;
  const _PrimaryBtn({required this.label, this.onTap, this.isLoading = false, this.icon});
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
    title: Text(title, style: const TextStyle(
      fontFamily: 'DMSans', fontSize: 17, fontWeight: FontWeight.w500,
      color: WerlogColors.textPrimary, letterSpacing: -0.2,
    )),
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(1),
      child: Container(color: WerlogColors.border, height: 0.5),
    ),
  );
}
