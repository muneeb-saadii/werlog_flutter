import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────
// IMPORT YOUR SCREENS HERE
// Replace these with your actual import paths
// ─────────────────────────────────────────────────────────────────
// import 'screens/customer_dashboard_screen.dart';
// import 'screens/invoice_list_screen.dart';
// import 'screens/reports_screen.dart';
// import 'screens/profile_screen.dart';
// import 'widgets/scan_type_sheet.dart';

// ─────────────────────────────────────────────────────────────────
// TEMPORARY PLACEHOLDER SCREENS
// Delete these once you import your real screens above
// ─────────────────────────────────────────────────────────────────
class CustomerDashboardScreen extends StatelessWidget {
  const CustomerDashboardScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('Dashboard Screen', style: TextStyle(fontSize: 20)));
}

class InvoiceListScreen extends StatelessWidget {
  const InvoiceListScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('Invoices Screen', style: TextStyle(fontSize: 20)));
}

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('Reports Screen', style: TextStyle(fontSize: 20)));
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('Profile Screen', style: TextStyle(fontSize: 20)));
}


// ─────────────────────────────────────────────────────────────────
// DATA MODEL: represents one tab item (icon + label)
// ─────────────────────────────────────────────────────────────────
class _TabItem {
  final String icon;  // Emoji or icon character
  final String label; // Text shown below the icon

  const _TabItem({required this.icon, required this.label});
}

// ─────────────────────────────────────────────────────────────────
// MAIN DASHBOARD SCREEN
// This is the "shell" screen that holds all tabs + bottom bar
// ─────────────────────────────────────────────────────────────────
class MainDashboardScreen extends StatefulWidget {
  const MainDashboardScreen({super.key});

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> {
  // Tracks which tab is currently selected (0 = Dashboard, 1 = Invoices, etc.)
  int _selectedIndex = 0;

  // ── Define your 5 tabs ──────────────────────────────────────────
  // Index 2 is the centre FAB (scan button) — its icon/label are
  // never shown because it renders as a circle button instead.
  static const List<_TabItem> _tabs = [
    _TabItem(icon: '🏠', label: 'Home'),
    _TabItem(icon: '📄', label: 'Invoices'),
    _TabItem(icon: '+',  label: ''),       // ← centre FAB (index 2)
    _TabItem(icon: '📊', label: 'Reports'),
    _TabItem(icon: '👤', label: 'Profile'),
  ];

  // ── One screen widget per tab ────────────────────────────────────
  // We use IndexedStack so all screens stay alive when you switch tabs
  // (they won't reload/reset every time you come back).
  //
  // Pass any callbacks your screens need right here.
  late final List<Widget> _screens = [
    // Index 0 — Dashboard
    const CustomerDashboardScreen(
      // user: ...,
      // stats: ...,
      // onScan: ...,          ← if your screen still needs this
    ),

    // Index 1 — Invoices
    const InvoiceListScreen(
      // data: ...,
      // onItemTap: ...,
    ),

    // Index 2 — Scan (no full screen; opens a bottom sheet instead)
    // We put an empty container here so IndexedStack doesn't crash.
    // The actual UI is the bottom sheet shown in _onTabTapped().
    const SizedBox.shrink(),

    // Index 3 — Reports
    const ReportsScreen(
      // data: ...,
      // onExport: ...,
    ),

    // Index 4 — Profile
    const ProfileScreen(
      // data: ...,
      // onSettingTap: ...,
    ),
  ];

  // ── Called whenever the user taps a bottom bar item ─────────────
  void _onTabTapped(int index) {
    // Special case: index 2 is the scan FAB → show bottom sheet
    if (index == 2) {
      _showScanSheet();
      return; // Don't change _selectedIndex for the FAB
    }

    // For all other tabs, just update the selected index
    setState(() {
      _selectedIndex = index;
    });
  }

  // ── Opens the ScanTypeSheet as a modal bottom sheet ──────────────
  void _showScanSheet() {
    showModalBottomSheet(
      context: context,
      // isScrollControlled: true lets the sheet grow taller than half screen
      isScrollControlled: true,
      // Shape gives the sheet rounded top corners
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        // ── Replace this placeholder with your real ScanTypeSheet ──
        // return ScanTypeSheet(
        //   onTypeSelected: (type) { ... },
        //   onContinue: () { Navigator.pop(context); },
        // );

        // ── Placeholder ────────────────────────────────────────────
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Scan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Replace this with your ScanTypeSheet widget.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // ── Build ────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WerlogColors.background,

      // ── Body: shows the correct screen for the selected tab ──────
      // IndexedStack keeps all screens mounted so they don't reset.
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),

      // ── Bottom navigation bar ────────────────────────────────────
      // We pass bottomNavigationBar to Scaffold so it handles
      // safe-area padding (home indicator on iPhone, etc.) for free.
      bottomNavigationBar: _BottomNavBar(
        tabs: _tabs,
        selected: _selectedIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// BOTTOM NAV BAR WIDGET  (your original design, unchanged)
// ─────────────────────────────────────────────────────────────────
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
    // SafeArea makes sure the bar isn't hidden behind the iPhone home indicator
    return SafeArea(
      top: false, // Only apply safe area at the bottom
      child: Container(
        decoration: const BoxDecoration(
          color: WerlogColors.surface,
          border: Border(
            top: BorderSide(color: WerlogColors.border, width: 1),
          ),
        ),
        child: Row(
          children: List.generate(tabs.length, (i) {
            final t      = tabs[i];
            final active = i == selected;

            // ── Index 2: Centre FAB button ───────────────────────
            if (i == 2) {
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  child: Container(
                    alignment: Alignment.center,
                    child: Transform.translate(
                      // Lift the circle above the bar
                      offset: const Offset(0, -14),
                      child: Container(
                        width: 50,
                        height: 50,
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
                          // White border so the circle "pops" off the bar
                          border: Border.all(
                            color: WerlogColors.background,
                            width: 3,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          '+',
                          style: TextStyle(
                            fontSize: 26,
                            color: Colors.white,
                            fontWeight: FontWeight.w300,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }

            // ── All other tabs: icon + label ─────────────────────
            return Expanded(
              child: GestureDetector(
                onTap: () => onTap(i),
                // opaque so the tap area fills the whole Expanded cell
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8)
                      .copyWith(bottom: 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon (emoji character)
                      Text(
                        t.icon,
                        style: TextStyle(
                          fontSize: 16,
                          color: active
                              ? WerlogColors.teal
                              : WerlogColors.tabInactive,
                        ),
                      ),
                      const SizedBox(height: 3),
                      // Label
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
      ),
    );
  }
}
