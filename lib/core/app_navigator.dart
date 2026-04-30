// ──────────────────────────────────────────────────────────────
//  Simple demo navigator — replace with your routing solution
//  (go_router, auto_route, etc.)
// ──────────────────────────────────────────────────────────────
import 'package:flutter/cupertino.dart';
import 'package:wellness/core/routing/AppRoutes.dart';
import 'package:wellness/ui/screens/main_dashboard_screen_old.dart';

import '../ui/screens/screen_01_welcome.dart';
import '../ui/screens/screen_02_auth.dart';
import '../ui/screens/screen_03_subscription.dart';
import '../ui/screens/screen_06_dashboard.dart';
import '../ui/tset/dashboard.dart';
import 'models/app_models.dart';
import 'models/app_models_extended.dart';

class AppNavigator extends StatefulWidget {
  const AppNavigator();

  @override
  State<AppNavigator> createState() => _AppNavigatorState();
}

class _AppNavigatorState extends State<AppNavigator> {
  int _screen = 0; // 0-based index through the demo flow

  void _next() => setState(() => _screen++);
  void _prev() => setState(() {
    if (_screen > 0) _screen--;
  });

  @override
  Widget build(BuildContext context) {
    switch (_screen) {
    // ── 01 Welcome ──────────────────────────────────────────
      case 0:
        return WelcomeScreen(
          data: WelcomeScreenData(),
          onGetStarted: _next,
          onSignIn: () => setState(() => _screen = 1),
        );

    // ── 02 Sign in ──────────────────────────────────────────
      case 1:
        return SignInScreen(
          initialData: SignInScreenData(
            emailValue:    'muneeb@gmail.com',
            passwordValue: '••••••••',
            isSignIn:      true,
          ),
          onBack:   _prev,
          onSubmit: _next,
        );

    // ── 03 Email verify ─────────────────────────────────────
      case 2:
        return EmailVerifyScreen(
          data: EmailVerifyScreenData(
            email:  'muneeb@gmail.com',
            digits: ['4', '2', '9', '', '', ''],
          ),
          onBack:   _prev,
          onVerify: _next,
        );

    // ── 04 Choose plan ──────────────────────────────────────
      case 3:
        return SubscriptionScreen(
          plans: defaultPlans,
          initialSelectedIndex: 1,
          initialCycle:         1,
          onSkip:       _next,
          onContinue:   (_) => _next(),
          onFree:       _next,
        );

    // ── 05 Checkout ─────────────────────────────────────────
      case 4:
        return CheckoutScreen(
          data:   CheckoutData(),
          onBack: _prev,
          onPay:  _next,
        );


      case 5:
        return Dashboard();
      case 15:
        return CustomerDashboardScreen(
          user:  UserData(name: 'Alice', plan: 'PRO'),
          stats: DashboardStats(
            totalTracked:   '\$847.20',
            periodLabel:    'TOTAL TRACKED · APRIL',
            totalSubtext:   'Across 12 invoices · 2 warranties saved',
            scansUsed:      42,
            scansTotal:     1000,
            expenseAmount:  '\$612',
            expenseCount:   9,
            warrantyAmount: '\$1,299',
            warrantyCount:  3,
          ),
          alert: WarrantyAlert(
            title:    'Warranty expiring in 7 days',
            subtitle: 'Apple MacBook Pro · May 24, 2026',
          ),
          transactions: defaultTransactions,
          onScan: () {
            // Launch OCR scan sheet
            var scanType = ScanType.warranty;
            AppRoutes.openScanType(
              context,
              onTypeSelected: (type) {
                print("Selected type: $type");
                scanType = type;
              },
              onContinue: () {
                print("Go to next screen");
                // Navigator.push(...)
                AppRoutes.openCameraScreen(
                  context,
                  onClose: () {
                    print("Camera closed");
                    Navigator.pop(context);
                  },
                  onCapture: () {
                    AppRoutes.openOcrProcessingScreen(
                      context,
                      data: OcrProcessingData(
                        scanType: scanType,
                        // add your captured image/file here if needed
                      ),
                      onBack: () {
                        Navigator.pop(context);
                        print("Back from OCR screen");
                      },
                    );
                  },
                  onToggleFlash: () {
                    print("Flash toggled");
                  },
                  onSwitchCamera: () {
                    print("Camera switched");
                  },
                  onGallery: () {
                    print("Gallery opened");
                  },
                );
              },
            );
            print("OCR open sheet called::");
          },
          onTabChanged: (int i){
            if(i==1){
              AppRoutes.openInvoiceList(
                context,
                currentTab: 2,
                data: InvoiceListData(),
                onItemTap: (item) {
                  print("Invoice clicked: ${item.type}");
                  AppRoutes.openInvoiceDetail(
                    context,
                    data: InvoiceDetailData(),
                    onBack: () {
                      Navigator.pop(context);
                    },
                    onEdit: () {
                      print("Edit clicked");
                    },
                    onShare: () {
                      print("Share clicked");
                    },
                    onMore: () {
                      print("More clicked");
                    },
                    onPrimaryAction: () {
                      print("Primary action");
                    },
                    onSecondaryAction: () {
                      print("Secondary action");
                    },
                    onTabChanged: (tab) {
                      print("Tab changed: $tab");
                    },
                  );
                },
                onTabChanged: (tab) {
                  print("Tab switched: $tab");
                },
              );
            }else if(i==3){
              AppRoutes.openReports(
                context,
                data: ReportsData(),
                onExport: () {
                  print("Export clicked");
                },
                onTabChanged: (tab) {
                  print("Tab changed: $tab");
                  Navigator.pop(context);
                },
              );
            }else if (i==4){
              AppRoutes.openProfile(
                context,
                data: ProfileData(),
                onSettingTap: (row) {
                  print("Tapped: $row");
                },
                onTabChanged: (tab) {
                  print("Tab: $tab");
                  Navigator.pop(context);
                },
              );
            }
          },
        );

    // ── 06 Dashboard (default) ──────────────────────────────
      default:
        return MainDashboardScreen();
    }
  }
}
