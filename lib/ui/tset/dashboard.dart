import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:wellness/ui/tset/screens/home_screen.dart';
import 'package:wellness/ui/tset/screens/search_screen.dart';
import 'package:wellness/ui/tset/screens/settings_screen.dart';

import '../../core/models/app_models.dart';
import '../../core/models/app_models_extended.dart';
import '../../core/routing/AppRoutes.dart';
import '../screens/screen_04_ocr_flow.dart';
import '../screens/screen_06_dashboard.dart';
import '../screens/screen_06_list_reports_profile.dart';
import 'custom_bottom_bar.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int selectedIndex = 0;

  late final List<Widget> screens;

  @override
  void initState() {
    super.initState();
    screens = [
      CustomerDashboardScreen(
        user: UserData(name: 'Alice', plan: 'PRO'),
        stats: DashboardStats(
          totalTracked: '\$847.20',
          periodLabel: 'TOTAL TRACKED · APRIL',
          totalSubtext: 'Across 12 invoices · 2 warranties saved',
          scansUsed: 42,
          scansTotal: 1000,
          expenseAmount: '\$612',
          expenseCount: 9,
          warrantyAmount: '\$1,299',
          warrantyCount: 3,
        ),
        alert: WarrantyAlert(
          title: 'Warranty expiring in 7 days',
          subtitle: 'Apple MacBook Pro · May 24, 2026',
        ),
        transactions: defaultTransactions,
        // onScan: onScan,
        // onViewAllTransactions: onViewAllTransactions,
        // onAlertAction: onAlertAction,
        // onTabChanged: onTabChanged,
      ),
      InvoiceListScreen(
      data: InvoiceListData(),
      // currentTab: currentTab,
      // onItemTap: onItemTap,
      // onTabChanged: onTabChanged,
      ),
      const SizedBox(), // middle FAB placeholder
      ReportsScreen(
      data: ReportsData(),
      // onExport: onExport,
      // onTabChanged: onTabChanged,
      // currentTab: currentTab,
      ),
      ProfileScreen(
      data: ProfileData(),
      // onSettingTap: onSettingTap,
      // onTabChanged: onTabChanged,
      // currentTab: currentTab,
      ),
    ];
  }


  final tabs = const [
    TabItem("assets/images/tabs/home.png", "Home"),
    TabItem("assets/images/tabs/invoices.png", "Invoices"),
    TabItem("", ""), // FAB
    TabItem("assets/images/tabs/reports.png", "Reports"),
    TabItem("assets/images/tabs/profile.png", "Profile"),
  ];

  void onTabTap(int index) {
    // ✅ MIDDLE TAB → OPEN SHEET ONLY
    if (index == 2) {
      _openBottomSheet();
      return;
    }

    setState(() {
      selectedIndex = index;
    });
  }

  void _openBottomSheet() {
    /*var scanType = ScanType.warranty;
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
    );*/
    var scanType = ScanType.warranty;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,     // ✅ must be true
      enableDrag: true,
      builder: (_) {
        return ScanTypeSheet(
          // data: data,
          onTypeSelected: (type) {
            print("Selected type: $type");
            scanType = type;
          },
          onContinue: () {
            Navigator.pop(context); // close sheet
            // onContinue?.call();     // trigger external logic

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
      },
    );
    /*showModalBottomSheet(
      context: context,
      builder: (_) {
        return const SizedBox(
          height: 200,
          child: Center(
            child: Text("Hello Bottom Sheet"),
          ),
        );
      },
    );*/
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ FULL SCREEN CONTENT
      body: IndexedStack(
        index: selectedIndex,
        children: screens,
      ),

      // ✅ YOUR CUSTOM NAV
      bottomNavigationBar: CustomBottomBar(
        selected: selectedIndex,
        onTap: onTabTap,
        tabs: tabs,
      ),
    );
  }
}