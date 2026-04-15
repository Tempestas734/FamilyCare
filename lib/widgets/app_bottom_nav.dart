import 'package:flutter/material.dart';

enum AppTab { home, calendar, settings }

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.activeTab,
    this.onHome,
    this.onCalendar,
    this.onSettings,
  });

  final AppTab activeTab;
  final VoidCallback? onHome;
  final VoidCallback? onCalendar;
  final VoidCallback? onSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F6F8).withOpacity(0.9),
          border: Border(
            top: BorderSide(color: theme.colorScheme.primary.withOpacity(0.1)),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _NavItem(
              label: 'Home',
              icon: Icons.home,
              active: activeTab == AppTab.home,
              onTap: onHome,
            ),
            _NavItem(
              label: 'Calendrier',
              icon: Icons.calendar_month,
              active: activeTab == AppTab.calendar,
              onTap: onCalendar,
            ),
            _NavItem(
              label: 'Parametres',
              icon: Icons.settings,
              active: activeTab == AppTab.settings,
              onTap: onSettings,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    this.active = false,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = active
        ? theme.colorScheme.primary
        : theme.colorScheme.primary.withOpacity(0.4);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: active ? 26 : 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontSize: 10,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
