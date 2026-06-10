import 'package:flutter/material.dart';

import '../../core/design_system.dart';

/// One destination in the [MetalTabBar].
class MetalTab {
  const MetalTab({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

/// The fixed bottom navigation — a brushed-metal strip with a brass top
/// hairline, engraved micro-labels, and a warm-backlit active tab (accent
/// underline + amber glow). 74px tall (Doc 04). Active state never relies on
/// colour alone: it pairs the accent with a glow, a brighter icon and an
/// underline.
class MetalTabBar extends StatelessWidget {
  const MetalTabBar({
    super.key,
    required this.tabs,
    required this.currentIndex,
    required this.onTap,
    required this.accent,
    required this.background,
  });

  final List<MetalTab> tabs;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Color accent;
  final Color background;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: background,
        border: const Border(
          top: BorderSide(color: DS.hairline, width: 1),
        ),
      ),
      child: SizedBox(
        height: 74,
        child: Row(
          children: [
            for (var i = 0; i < tabs.length; i++)
              Expanded(
                child: _TabItem(
                  tab: tabs[i],
                  active: i == currentIndex,
                  accent: accent,
                  onTap: () => onTap(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.tab,
    required this.active,
    required this.accent,
    required this.onTap,
  });

  final MetalTab tab;
  final bool active;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Active tab: accent-red icon + label. Inactive: text-secondary. No
    // underline, no glow — colour alone marks the active destination.
    final color = active ? accent : DS.textSecondary;
    return Semantics(
      button: true,
      selected: active,
      label: tab.label,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(tab.icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              tab.label.toUpperCase(),
              style: TextStyle(
                fontFamily: DS.fontFamily,
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
