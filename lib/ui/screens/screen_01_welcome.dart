import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';

// ──────────────────────────────────────────────────────────────
//  WelcomeScreen  (screen 01 · Welcome)
//  Pixel-faithful to mobile_01_entry_login_signup.html : screen 1
// ──────────────────────────────────────────────────────────────

/// Feature bullet shown in the hero list
class _Feature {
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String description;
  final String iconEmoji;

  const _Feature({
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.iconEmoji,
  });
}

// ── Configurable data ──────────────────────────────────────────
class WelcomeScreenData {
  /// App name shown in brand row (uppercase)
  /*String appName;

  /// Brand mark letter
  String brandLetter;

  /// Hero headline — use '\n' for line breaks
  /// Coloured part comes after the plain text
  String headlinePlain;
  String headlineAccent;

  /// Hero subtitle
  String subtitle;

  /// Feature list
  List<_Feature> features;

  /// CTA button labels
  String primaryCTA;
  String secondaryCTA;*/

  final String appName;
  final String brandLetter;
  final String headlinePlain;
  final String headlineAccent;
  final String subtitle;
  final List<_Feature> features;
  final String primaryCTA;
  final String secondaryCTA;

  const WelcomeScreenData({
    this.appName       = 'WERLOG',
    this.brandLetter   = 'W',
    this.headlinePlain = 'Every receipt,\norganized in ',
    this.headlineAccent = 'seconds',
    this.subtitle = 'Snap, scan, and save — for expenses and warranties that never get lost.',
    final List<_Feature>? features,
    this.primaryCTA   = 'Get started free',
    this.secondaryCTA = 'I already have an account',
  }) : features = features ??
           const [
             _Feature(
               iconBg:    WerlogColors.tealSurface,
               iconColor: const Color(0xFF0F6E56),
               title:     'AI-powered extraction',
               description: 'Vendor, totals, taxes — automatic',
               iconEmoji: '📄',
             ),
             _Feature(
               iconBg:    WerlogColors.amberSurface,
               iconColor: WerlogColors.amberDark,
               title:     'Warranty tracking',
               description: 'Never miss an expiration date',
               iconEmoji: '🛡️',
             ),
             _Feature(
               iconBg:    WerlogColors.coralSurface,
               iconColor: WerlogColors.coralDark,
               title:     'Smart expense reports',
               description: 'Exportable CSV & PDF anytime',
               iconEmoji: '📊',
             ),
           ];
}

class WelcomeScreen extends StatelessWidget {
  final WelcomeScreenData data;
  final VoidCallback? onGetStarted;
  final VoidCallback? onSignIn;


  WelcomeScreen({
    Key? key,
    WelcomeScreenData? data,
    this.onGetStarted,
    this.onSignIn,
  })  : data = data ?? WelcomeScreenData(),
        super(key: key);

  // Dart const constructor workaround
  // ignore: use_key_in_widget_constructors
  /*const WelcomeScreen.defaults({
    Key? key,
    this.onGetStarted,
    this.onSignIn,
  })  : data = WelcomeScreenData(),
        super(key: key);*/
  WelcomeScreen.defaults({
    Key? key,
    this.onGetStarted,
    this.onSignIn,
  })  : data = WelcomeScreenData(),
        super(key: key);


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WerlogColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HeroSection(data: data),
            _FeatureList(features: data.features),
            _CTASection(
              primaryLabel:   data.primaryCTA,
              secondaryLabel: data.secondaryCTA,
              onPrimary:   onGetStarted,
              onSecondary: onSignIn,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Hero dark section ──────────────────────────────────────────
class _HeroSection extends StatelessWidget {
  final WelcomeScreenData data;
  const _HeroSection({required this.data});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(24, 50, 24, 36),
          decoration: const BoxDecoration(
            color: WerlogColors.darkTeal,
            borderRadius: BorderRadius.only(
              bottomLeft:  Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status bar
              const FakeStatusBar(textColor: Colors.white),
              const SizedBox(height: 8),
              // Brand row
              Row(
                children: [
                  /*Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: WerlogColors.teal,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      data.brandLetter,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),*/
                  SizedBox(
                    width: 30,
                    height: 30,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/images/app_logo.jpeg', // update path
                        fit: BoxFit.cover, // fills the box like your container
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    data.appName,
                    style: WerlogTextStyles.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              // Headline
              RichText(
                text: TextSpan(
                  style: WerlogTextStyles.heroTitle,
                  children: [
                    TextSpan(text: data.headlinePlain),
                    TextSpan(
                      text: data.headlineAccent,
                      style: WerlogTextStyles.heroTitle.copyWith(
                        color: WerlogColors.tealLight,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(data.subtitle, style: WerlogTextStyles.heroSubtitle),
            ],
          ),
        ),
        // Decorative circles
        /*Positioned(
          top: -40, right: -40,
          child: Container(
            width: 140, height: 140,
            decoration: BoxDecoration(
              color: WerlogColors.teal.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
          ),
        ),*/
        /*Positioned(
          bottom: -60, left: -30,
          child: Container(
            width: 160, height: 160,
            decoration: BoxDecoration(
              color: WerlogColors.amber.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
          ),
        ),*/
      ],
    );
  }
}

// ── Feature list ───────────────────────────────────────────────
class _FeatureList extends StatelessWidget {
  final List<_Feature> features;
  const _FeatureList({required this.features});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: WerlogColors.background,
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
      child: Column(
        children: List.generate(features.length, (i) {
          final f = features[i];
          return Column(
            children: [
              _FeatureRow(feature: f),
              if (i < features.length - 1)
                const Divider(
                  height: 0,
                  color: Color(0x140F2A2E),
                  thickness: 0.5,
                ),
            ],
          );
        }),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final _Feature feature;
  const _FeatureRow({required this.feature});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBox(
            background: feature.iconBg,
            size: 32, radius: 9,
            child: Text(feature.iconEmoji,
                style: const TextStyle(fontSize: 14)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(feature.title,
                    style: WerlogTextStyles.featureTitle),
                const SizedBox(height: 2),
                Text(feature.description,
                    style: WerlogTextStyles.featureDesc),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── CTA buttons ────────────────────────────────────────────────
class _CTASection extends StatelessWidget {
  final String primaryLabel;
  final String secondaryLabel;
  final VoidCallback? onPrimary;
  final VoidCallback? onSecondary;

  const _CTASection({
    required this.primaryLabel,
    required this.secondaryLabel,
    this.onPrimary,
    this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: WerlogColors.background,
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
      child: Column(
        children: [
          PrimaryButton(text: primaryLabel, onTap: onPrimary),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: onSecondary,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: RichText(
                text: TextSpan(
                  style: WerlogTextStyles.buttonGhost,
                  children: [
                    const TextSpan(text: 'I already have an '),
                    TextSpan(
                      text: 'account',
                      style: WerlogTextStyles.buttonGhost.copyWith(
                        decoration: TextDecoration.underline,
                        decorationColor: WerlogColors.teal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
