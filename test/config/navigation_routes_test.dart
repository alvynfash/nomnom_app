import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nomnom/config/navigation_routes.dart';

void main() {
  group('NavigationRoutes', () {
    test('should have correct route IDs defined', () {
      expect(NavigationRoutes.recipes, equals('recipes'));
      expect(NavigationRoutes.mealPlanning, equals('meal_planning'));
      expect(NavigationRoutes.settings, equals('settings'));
      expect(NavigationRoutes.about, equals('about'));
    });

    test('should have recipes as default route', () {
      expect(NavigationRoutes.defaultRoute, equals('recipes'));
    });

    test('should return all routes', () {
      final routes = NavigationRoutes.allRoutes;

      expect(routes, isNotEmpty);
      expect(routes.length, equals(4));

      // Check that all expected routes are present
      final routeIds = routes.map((r) => r.id).toList();
      expect(routeIds, contains('recipes'));
      expect(routeIds, contains('meal_planning'));
      expect(routeIds, contains('settings'));
      expect(routeIds, contains('about'));
    });

    test('should return primary routes correctly', () {
      final primaryRoutes = NavigationRoutes.primaryRoutes;

      expect(primaryRoutes, isNotEmpty);
      expect(primaryRoutes.length, equals(2));

      // All returned routes should be primary
      for (final route in primaryRoutes) {
        expect(route.isPrimary, isTrue);
      }

      // Check specific primary routes
      final primaryIds = primaryRoutes.map((r) => r.id).toList();
      expect(primaryIds, contains('recipes'));
      expect(primaryIds, contains('meal_planning'));
    });

    test('should return secondary routes correctly', () {
      final secondaryRoutes = NavigationRoutes.secondaryRoutes;

      expect(secondaryRoutes, isNotEmpty);
      expect(secondaryRoutes.length, equals(2));

      // All returned routes should be secondary (not primary)
      for (final route in secondaryRoutes) {
        expect(route.isPrimary, isFalse);
      }

      // Check specific secondary routes
      final secondaryIds = secondaryRoutes.map((r) => r.id).toList();
      expect(secondaryIds, contains('settings'));
      expect(secondaryIds, contains('about'));
    });

    test('should find route by ID correctly', () {
      final recipesRoute = NavigationRoutes.findRouteById('recipes');
      expect(recipesRoute, isNotNull);
      expect(recipesRoute!.id, equals('recipes'));
      expect(recipesRoute.title, equals('Recipes'));
      expect(recipesRoute.icon, equals(Icons.restaurant_menu_rounded));
      expect(recipesRoute.isPrimary, isTrue);
    });

    test('should return null for non-existent route ID', () {
      final nonExistentRoute = NavigationRoutes.findRouteById('non_existent');
      expect(nonExistentRoute, isNull);
    });

    test('should return default navigation route', () {
      final defaultRoute = NavigationRoutes.defaultNavigationRoute;
      expect(defaultRoute.id, equals('recipes'));
      expect(defaultRoute.title, equals('Recipes'));
    });

    test('should have correct route properties', () {
      final routes = NavigationRoutes.allRoutes;

      for (final route in routes) {
        // All routes should have non-empty ID and title
        expect(route.id, isNotEmpty);
        expect(route.title, isNotEmpty);

        // All routes should have a valid icon
        expect(route.icon, isNotNull);

        // All routes should have a screen widget
        expect(route.screen, isNotNull);
      }
    });

    test('should have unique route IDs', () {
      final routes = NavigationRoutes.allRoutes;
      final routeIds = routes.map((r) => r.id).toList();
      final uniqueIds = routeIds.toSet();

      expect(routeIds.length, equals(uniqueIds.length));
    });
  });
}
