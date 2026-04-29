import 'package:flutter/material.dart';

import '../../core/models/app_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';

// ──────────────────────────────────────────────────────────────
//  CustomerDashboardScreen  (screen 06 · Dashboard)
//  Pixel-faithful to mobile_03_customer_dashboard.html
// ──────────────────────────────────────────────────────────────

class CustomerDashboardScreen extends StatefulWidget {
  final UserData?      user;
  final DashboardStats? stats;
  final WarrantyAlert?  alert;
  final List<TransactionItem>? transactions;

  /// Callback when the floating scan FAB is tapped
  final VoidCallback? onScan;
  final VoidCallback? onViewAllTransactions;
  final VoidCallback? onAlertAction;
  final void Function(int index)? onTabChanged;

  const CustomerDashboardScreen({
    super.key,
    this.user,
    this.stats,
    this.alert,
    this.transactions,
    this.onScan,
    this.onViewAllTransactions,
    this.onAlertAction,
    this.onTabChanged,
  });

  @override
  State<CustomerDashboardScreen> createState() =>
      _CustomerDashboardScreenState();
}

class _CustomerDashboardScreenState
    extends State<CustomerDashboardScreen> {
  int _tab = 0;

  // ── Bottom tab config ────────────────────────────────────────
  static const List<_TabItem> _tabs = [
    _TabItem(icon: '⌂', label: 'Home'),
    _TabItem(icon: '≡', label: 'Invoices'),
    _TabItem(icon: '',  label: ''),        // centre FAB placeholder
    _TabItem(icon: '◔', label: 'Reports'),
    _TabItem(icon: '◯', label: 'Profile'),
  ];

  void _onTabTap(int i) {
    if (i == 2) {
      widget.onScan?.call();
      return;
    }else if (i==3) {

    }
    setState(() => _tab = i);
    widget.onTabChanged?.call(i);
  }

  @override
  Widget build(BuildContext context) {
    final user  = widget.user  ?? UserData();
    final stats = widget.stats ?? DashboardStats();
    final alert = widget.alert ?? WarrantyAlert();
    final txns  = widget.transactions ?? defaultTransactions;

    return Scaffold(
      backgroundColor: WerlogColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const FakeStatusBar(),
                    _TopBar(user: user),
                    _BalanceCard(user: user, stats: stats),
                    _QuickCards(stats: stats),
                    if (alert.isVisible) _AlertBanner(alert: alert, onAction: widget.onAlertAction),
                    SectionHeader(
                      title: 'Recent invoices',
                      action: 'See all ›',
                      onAction: widget.onViewAllTransactions,
                    ),
                    _TransactionList(transactions: txns),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            _BottomNavBar(
              tabs:      _tabs,
              selected:  _tab,
              onTap:     _onTabTap,
              onScan:    widget.onScan,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Top bar ────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final UserData user;
  const _TopBar({required this.user});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Good morning,', style: WerlogTextStyles.dashboardGreeting),
              const SizedBox(height: 1),
              Text('${user.name} 👋',
                  style: WerlogTextStyles.dashboardName),
            ],
          ),
          _NotificationBell(),
        ],
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: WerlogColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: WerlogColors.border),
          ),
          alignment: Alignment.center,
          child: const Text('🔔', style: TextStyle(fontSize: 15)),
        ),
        Positioned(
          top: 8, right: 9,
          child: Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              color: WerlogColors.coral,
              shape: BoxShape.circle,
              border: Border.all(color: WerlogColors.background, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Balance hero card ──────────────────────────────────────────
class _BalanceCard extends StatelessWidget {
  final UserData user;
  final DashboardStats stats;
  const _BalanceCard({required this.user, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: WerlogColors.darkTeal,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: label + PRO badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(stats.periodLabel,
                      style: WerlogTextStyles.balanceLabel),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: WerlogColors.tealLight.withOpacity(0.20),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      user.plan,
                      style: WerlogTextStyles.badgeText.copyWith(
                        color: WerlogColors.tealLight,
                        fontSize: 9,
                        letterSpacing: 0.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(stats.totalTracked,
                  style: WerlogTextStyles.balanceAmount),
              const SizedBox(height: 3),
              Text(stats.totalSubtext,
                  style: WerlogTextStyles.balanceSub),
              // Quota strip
              Container(
                margin: const EdgeInsets.only(top: 14),
                padding: const EdgeInsets.only(top: 12),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(
                        color: Color(0x1AFFFFFF), width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    RichText(
                      text: TextSpan(
                        style: WerlogTextStyles.balanceSub,
                        children: [
                          TextSpan(
                            text: '${stats.scansUsed}',
                            style: WerlogTextStyles.balanceSub.copyWith(
                              color: WerlogColors.tealLight,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          TextSpan(
                              text: '/${stats.scansTotal} scans'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ThinProgressBar(
                          value: stats.scanProgress),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${stats.scansTotal - stats.scansUsed} left',
                      style: WerlogTextStyles.balanceSub.copyWith(
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Deco circles
        Positioned(
          top: 18 - 30, right: 20 - 30,
          child: IgnorePointer(
            child: Container(
              width: 140, height: 140,
              decoration: BoxDecoration(
                color: WerlogColors.teal.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -50, right: 50,
          child: IgnorePointer(
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                color: WerlogColors.amber.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Quick access cards (2-column) ─────────────────────────────
class _QuickCards extends StatelessWidget {
  final DashboardStats stats;
  const _QuickCards({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: _QuickCard(
              iconBg:   WerlogColors.coralSurface,
              iconEmoji: '◉',
              iconColor: WerlogColors.coralDark,
              title: 'Expenses',
              detail: '${stats.expenseAmount} · ${stats.expenseCount} items',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _QuickCard(
              iconBg:   WerlogColors.amberSurface,
              iconEmoji: '◆',
              iconColor: WerlogColors.amberDark,
              title: 'Warranties',
              detail:
                  '${stats.warrantyAmount} · ${stats.warrantyCount} items',
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickCard extends StatelessWidget {
  final Color iconBg;
  final String iconEmoji;
  final Color iconColor;
  final String title;
  final String detail;

  const _QuickCard({
    required this.iconBg,
    required this.iconEmoji,
    required this.iconColor,
    required this.title,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: WerlogColors.surface,
        border: Border.all(color: WerlogColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(iconEmoji,
                style: TextStyle(fontSize: 15, color: iconColor)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: WerlogTextStyles.quickTitle),
                const SizedBox(height: 1),
                Text(detail, style: WerlogTextStyles.quickDetail),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Alert banner ───────────────────────────────────────────────
class _AlertBanner extends StatelessWidget {
  final WarrantyAlert alert;
  final VoidCallback? onAction;
  const _AlertBanner({required this.alert, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: WerlogColors.amberSurface,
        border: const Border(
          left: BorderSide(color: WerlogColors.amber, width: 3),
        ),
        borderRadius: const BorderRadius.only(
          topRight:    Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: WerlogColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: const Text('◆',
                style: TextStyle(
                    color: WerlogColors.amber, fontSize: 14)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alert.title, style: WerlogTextStyles.alertTitle),
                const SizedBox(height: 1),
                Text(alert.subtitle, style: WerlogTextStyles.alertSub),
              ],
            ),
          ),
          GestureDetector(
            onTap: onAction,
            child: Text('View ›',
                style: WerlogTextStyles.alertTitle
                    .copyWith(fontSize: 10)),
          ),
        ],
      ),
    );
  }
}

// ── Transaction list ───────────────────────────────────────────
class _TransactionList extends StatelessWidget {
  final List<TransactionItem> transactions;
  const _TransactionList({required this.transactions});

  static const Map<TxType, Color> _iconBg = {
    TxType.expense:  WerlogColors.coralSurface,
    TxType.warranty: WerlogColors.tealSurface,
  };

  static const Map<TxType, Color> _iconColor = {
    TxType.expense:  WerlogColors.coralDark,
    TxType.warranty: Color(0xFF0F6E56),
  };

  static const Map<TxType, String> _typeLabel = {
    TxType.expense:  'EXPENSE',
    TxType.warranty: 'WARRANTY',
  };

  static const Map<TxType, Color> _tagBg = {
    TxType.expense:  WerlogColors.coralSurface,
    TxType.warranty: WerlogColors.amberSurface,
  };

  static const Map<TxType, Color> _tagColor = {
    TxType.expense:  WerlogColors.coralDark,
    TxType.warranty: WerlogColors.amberDark,
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: List.generate(transactions.length, (i) {
          final tx = transactions[i];
          return Column(
            children: [
              _TxRow(
                tx:        tx,
                iconBg:    _iconBg[tx.type]!,
                iconColor: _iconColor[tx.type]!,
                typeLabel: _typeLabel[tx.type]!,
                tagBg:     _tagBg[tx.type]!,
                tagColor:  _tagColor[tx.type]!,
              ),
              if (i < transactions.length - 1)
                const Divider(
                    height: 0, thickness: 0.5,
                    color: WerlogColors.borderLight),
            ],
          );
        }),
      ),
    );
  }
}

class _TxRow extends StatelessWidget {
  final TransactionItem tx;
  final Color iconBg;
  final Color iconColor;
  final String typeLabel;
  final Color tagBg;
  final Color tagColor;

  const _TxRow({
    required this.tx,
    required this.iconBg,
    required this.iconColor,
    required this.typeLabel,
    required this.tagBg,
    required this.tagColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          IconBox(
            background: iconBg, size: 38, radius: 11,
            child: Text(tx.iconEmoji,
                style: const TextStyle(fontSize: 15)),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.label,
                    style: WerlogTextStyles.txTitle,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: tagBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(typeLabel,
                          style: WerlogTextStyles.badgeText
                              .copyWith(color: tagColor)),
                    ),
                    const SizedBox(width: 4),
                    Text(tx.category, style: WerlogTextStyles.txMeta),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(tx.amount, style: WerlogTextStyles.txAmount),
              const SizedBox(height: 1),
              Text(tx.dateLabel, style: WerlogTextStyles.txDate),
            ],
          ),
        ],
      ),
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
