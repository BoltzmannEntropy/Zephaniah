import 'package:flutter/material.dart';

class Sidebar extends StatelessWidget {
  final int selectedIndex;
  final void Function(int) onNavigate;
  final int downloadCount;

  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onNavigate,
    this.downloadCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: 220,
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: Column(
        children: [
          // Logo/Title
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF8F00),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.search_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Zephaniah',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'The Epstein Archiver',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: 8),
          // Navigation items - new order for archive-first workflow
          _NavItem(
            icon: Icons.archive_rounded,
            label: 'Archives',
            isSelected: selectedIndex == 0,
            onTap: () => onNavigate(0),
          ),
          _NavItem(
            icon: Icons.photo_library_rounded,
            label: 'Library',
            isSelected: selectedIndex == 1,
            onTap: () => onNavigate(1),
          ),
          _NavItem(
            icon: Icons.search_rounded,
            label: 'Search',
            isSelected: selectedIndex == 2,
            onTap: () => onNavigate(2),
          ),
          const Divider(indent: 16, endIndent: 16, height: 24),
          _NavItem(
            icon: Icons.download_rounded,
            label: 'Queue',
            isSelected: selectedIndex == 3,
            onTap: () => onNavigate(3),
            badge: downloadCount > 0 ? downloadCount.toString() : null,
          ),
          _NavItem(
            icon: Icons.settings_rounded,
            label: 'Settings',
            isSelected: selectedIndex == 4,
            onTap: () => onNavigate(4),
          ),
          _NavItem(
            icon: Icons.workspace_premium_rounded,
            label: 'Pro',
            isSelected: selectedIndex == 5,
            onTap: () => onNavigate(5),
          ),
          _NavItem(
            icon: Icons.info_outline_rounded,
            label: 'About',
            isSelected: selectedIndex == 6,
            onTap: () => onNavigate(6),
          ),
          const Spacer(),
          // Version
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'v1.0.0',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final String? badge;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: isSelected ? colorScheme.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isSelected
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurface.withValues(alpha: 0.9),
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF8F00),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badge!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
