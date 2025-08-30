import 'package:flutter/material.dart';
import '../models/navigation_route.dart';
import '../screens/recipe_list_screen.dart';

/// Configuration class for app navigation routes
class NavigationRoutes {
  /// Route IDs
  static const String recipes = 'recipes';
  static const String mealPlanning = 'meal_planning';
  static const String settings = 'settings';
  static const String about = 'about';

  /// Default route when app starts
  static const String defaultRoute = recipes;

  /// List of all available navigation routes
  static List<NavigationRoute> get allRoutes => [
    // Primary navigation routes
    NavigationRoute(
      id: recipes,
      title: 'Recipes',
      icon: Icons.restaurant_menu_rounded,
      screen: const RecipeListScreen(),
      isPrimary: true,
    ),
    NavigationRoute(
      id: mealPlanning,
      title: 'Meal Planning',
      icon: Icons.calendar_today_rounded,
      screen: const _PlaceholderScreen(title: 'Meal Planning'),
      isPrimary: true,
    ),

    // Secondary navigation routes
    NavigationRoute(
      id: settings,
      title: 'Settings',
      icon: Icons.settings_rounded,
      screen: const _PlaceholderScreen(title: 'Settings'),
      isPrimary: false,
    ),
    NavigationRoute(
      id: about,
      title: 'About',
      icon: Icons.info_outline_rounded,
      screen: const _PlaceholderScreen(title: 'About'),
      isPrimary: false,
    ),
  ];

  /// Get primary navigation routes (main features)
  static List<NavigationRoute> get primaryRoutes =>
      allRoutes.where((route) => route.isPrimary).toList();

  /// Get secondary navigation routes (settings, help, etc.)
  static List<NavigationRoute> get secondaryRoutes =>
      allRoutes.where((route) => !route.isPrimary).toList();

  /// Find a route by its ID
  static NavigationRoute? findRouteById(String id) {
    try {
      return allRoutes.firstWhere((route) => route.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get the default route
  static NavigationRoute get defaultNavigationRoute =>
      findRouteById(defaultRoute)!;
}

/// Placeholder screen for routes that haven't been implemented yet
class _PlaceholderScreen extends StatelessWidget {
  final String title;

  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.construction_rounded,
                size: 64,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '$title Coming Soon!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'This feature is under development and will be available in a future update.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
