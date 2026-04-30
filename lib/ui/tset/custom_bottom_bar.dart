import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class TabItem {
  final String icon;
  final String label;

  const TabItem(this.icon, this.label);
}

class CustomBottomBar extends StatelessWidget {
  final int selected;
  final Function(int) onTap;
  final List<TabItem> tabs;

  const CustomBottomBar({
    super.key,
    required this.selected,
    required this.onTap,
    required this.tabs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 65,
      decoration: const BoxDecoration(
        color: WerlogColors.surface,
        border: Border(
          top: BorderSide(color: WerlogColors.border, width: 1),
        ),
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final t = tabs[i];
          final active = i == selected;

          // ✅ CENTER FAB (NO INDEX CHANGE)
          if (i == 2) {
            return Expanded(
              child: GestureDetector(
                onTap: () => onTap(i), // handled in parent
                child: Container(
                  alignment: Alignment.center,
                  child: Transform.translate(
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

          // ✅ NORMAL TABS
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding:
                const EdgeInsets.symmetric(vertical: 8).copyWith(bottom: 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      t.icon, // now this should be asset path instead of text
                      width: 20,
                      height: 20,
                      color: active
                          ? WerlogColors.teal
                          : WerlogColors.tabInactive,
                    ),
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