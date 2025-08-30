import 'package:flutter/material.dart';
import '../config/navigation_routes.dart';
import '../models/navigation_route.dart';
import 'navigation_item.dart';

/// The main navigation drawer for the app
class AppDrawer extends StatelessWidget {
  /// The currently active route ID
  final String currentRoute;

  /// Callback when a navigation item is tapped
  final Function(NavigationRoute) onNavigationTap;

  const AppDrawer({
    super.key,
    required this.currentRoute,
    required this.onNavigationTap,
  });

  /// Safely handle navigation tap with error handling
  void _safeNavigationTap(BuildContext context, NavigationRoute route) {
    try {
      onNavigationTap(route);
    } catch (e) {
      debugPrint('Error in navigation tap: $e');
      // Show a brief error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not navigate to ${route.title}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Drawer(
      width: 280,
      backgroundColor: colorScheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            // Custom drawer header
            _buildDrawerHeader(context, colorScheme),

            // Primary navigation items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  // Primary navigation section
                  _buildNavigationSection(
                    context,
                    'Main',
                    NavigationRoutes.primaryRoutes,
                  ),

                  const Divider(height: 32, indent: 16, endIndent: 16),

                  // Secondary navigation section
                  _buildNavigationSection(
                    context,
                    'More',
                    NavigationRoutes.secondaryRoutes,
                  ),
                ],
              ),
            ),

            // Footer
            _buildDrawerFooter(context, colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context, ColorScheme colorScheme) {
    return Container(
      height: 80,
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // App icon and text in a row to save space
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colorScheme.onPrimary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.restaurant_rounded,
                  size: 20,
                  color: colorScheme.onPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'NomNom',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                    Text(
                      'Your Personal Cookbook',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: colorScheme.onPrimary.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationSection(
    BuildContext context,
    String sectionTitle,
    List<NavigationRoute> routes,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
          child: Text(
            sectionTitle.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
        ),

        // Navigation items
        ...routes.map(
          (route) => NavigationItem(
            icon: route.icon,
            title: route.title,
            isSelected: route.id == currentRoute,
            onTap: () => _safeNavigationTap(context, route),
          ),
        ),
      ],
    );
  }

  Widget _buildDrawerFooter(BuildContext context, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Divider(),
          const SizedBox(height: 8),
          Text(
            'NomNom v1.0.0',
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(
            'Made with ❤️ for food lovers',
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
