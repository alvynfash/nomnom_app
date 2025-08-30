import 'package:flutter/material.dart';

/// A navigation item widget for the sidebar drawer
class NavigationItem extends StatelessWidget {
  /// The icon to display
  final IconData icon;

  /// The title text to display
  final String title;

  /// Whether this item is currently selected
  final bool isSelected;

  /// Callback when the item is tapped
  final VoidCallback onTap;

  const NavigationItem({
    super.key,
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected
              ? colorScheme.onPrimaryContainer
              : colorScheme.onSurfaceVariant,
          size: 24,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isSelected
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurface,
          ),
        ),
        selected: isSelected,
        selectedTileColor: colorScheme.primaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        minLeadingWidth: 24,
        horizontalTitleGap: 24,
        onTap: onTap,
      ),
    );
  }
}
