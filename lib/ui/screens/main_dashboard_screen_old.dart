
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:wellness/core/models/app_models_extended.dart';
import 'package:wellness/ui/screens/screen_06_dashboard.dart';
import 'package:wellness/ui/screens/screen_06_list_reports_profile.dart';

import '../../core/routing/AppRoutes.dart';
import '../../core/theme/app_theme.dart';

class MainDashboardScreen extends StatefulWidget {
  const MainDashboardScreen({super.key});

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> {
  int _tab = 0;

  // ── Bottom tab config ────────────────────────────────────────
  static const List<_TabItem> _tabs = [
    _TabItem(icon: '⌂', label: 'Home'),
    _TabItem(icon: '≡', label: 'Invoices'),
    _TabItem(icon: '',  label: ''),        // centre FAB placeholder
    _TabItem(icon: '◔', label: 'Reports'),
    _TabItem(icon: '◯', label: 'Profile'),
  ];

  void _onTabTap(int index) {
    setState(() => _tab = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          CustomerDashboardScreen(
            onScan: _openScanSheet,
            onTabChanged: (int i){
                  setState(() => _tab = i);
            },
          ),

          InvoiceListScreen(
            currentTab: 1,
            onTabChanged: _onTabTap,
          ),

          Container(), // index 2 if unused

          ReportsScreen(
            currentTab: 3,
            onTabChanged: _onTabTap,
          ),

          ProfileScreen(
            currentTab: 4,
            onTabChanged: _onTabTap,
          ),
        ],
      ),

      bottomNavigationBar: _BottomNavBar(
        selected: _tab,
        onTap: _onTabTap,
        onScan: _openScanSheet, tabs: _tabs,
      ),
    );
  }


  void _openScanSheet() {
    var scanType= ScanType.warranty;
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
  }
}


// ── Bottom navigation bar ─────────────────────────────────────
class _TabItem {
  final String icon;
  final String label;
  const _TabItem({required this.icon, required this.label});
}

class _BottomNavBar extends StatelessWidget {
  final List<_TabItem> tabs;
  final int selected;
  final ValueChanged<int> onTap;
  final VoidCallback? onScan;

  const _BottomNavBar({
    required this.tabs,
    required this.selected,
    required this.onTap,
    this.onScan,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: WerlogColors.surface,
        border: Border(
            top: BorderSide(color: WerlogColors.border, width: 1)),
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final t      = tabs[i];
          final active = i == selected;

          // Centre FAB
          if (i == 2) {
            return Expanded(
              child: GestureDetector(
                onTap: () => onTap(i),
                child: Container(
                  alignment: Alignment.center,
                  child: Transform.translate(
                    offset: const Offset(0, -14),
                    child: Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(
                        color: WerlogColors.teal,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: WerlogColors.teal.withOpacity(0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                        border: Border.all(
                            color: WerlogColors.background, width: 3),
                      ),
                      alignment: Alignment.center,
                      child: const Text('+',
                          style: TextStyle(
                              fontSize: 26,
                              color: Colors.white,
                              fontWeight: FontWeight.w300,
                              height: 1.0)),
                    ),
                  ),
                ),
              ),
            );
          }

          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8)
                    .copyWith(bottom: 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(t.icon,
                        style: TextStyle(
                            fontSize: 16,
                            color: active
                                ? WerlogColors.teal
                                : WerlogColors.tabInactive)),
                    const SizedBox(height: 3),
                    Text(
                      t.label,
                      style: WerlogTextStyles.tabLabel.copyWith(
                        color: active
                            ? WerlogColors.teal
                            : WerlogColors.tabInactive,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}