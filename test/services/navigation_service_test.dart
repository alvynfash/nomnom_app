import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nomnom/config/navigation_routes.dart';
import 'package:nomnom/services/navigation_service.dart';
import 'package:nomnom/widgets/main_scaffold.dart';

void main() {
  group('NavigationService', () {
    testWidgets('should navigate to valid route', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MainScaffold(
            currentScreen: const Text('Initial Screen'),
            title: 'Initial Title',
            currentRoute: 'recipes',
          ),
        ),
      );

      // Get the context
      final context = tester.element(find.byType(MainScaffold));

      // Navigate to meal planning
      NavigationService.navigateToRoute(context, 'meal_planning');
      await tester.pumpAndSettle();

      // Check that we navigated to the new screen
      expect(find.text('Meal Planning Coming Soon!'), findsOneWidget);
    });

    testWidgets(
      'should navigate to default route when invalid route provided',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MainScaffold(
              currentScreen: const Text('Initial Screen'),
              title: 'Initial Title',
              currentRoute: 'recipes',
            ),
          ),
        );

        // Get the context
        final context = tester.element(find.byType(MainScaffold));

        // Navigate to invalid route
        NavigationService.navigateToRoute(context, 'invalid_route');
        await tester.pumpAndSettle();

        // Should navigate to default route (recipes) and show error message
        expect(find.text('My Recipes'), findsOneWidget);
        expect(
          find.text('Navigation failed. Redirected to home screen.'),
          findsOneWidget,
        );
      },
    );

    testWidgets('should navigate using NavigationRoute object', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MainScaffold(
            currentScreen: const Text('Initial Screen'),
            title: 'Initial Title',
            currentRoute: 'recipes',
          ),
        ),
      );

      // Get the context
      final context = tester.element(find.byType(MainScaffold));

      // Get a route and navigate to it
      final settingsRoute = NavigationRoutes.findRouteById('settings')!;
      NavigationService.navigateToScreen(context, settingsRoute);
      await tester.pumpAndSettle();

      // Check that we navigated to settings
      expect(find.text('Settings Coming Soon!'), findsOneWidget);
    });

    testWidgets('should navigate to default route', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MainScaffold(
            currentScreen: const Text('Initial Screen'),
            title: 'Initial Title',
            currentRoute: 'settings',
          ),
        ),
      );

      // Get the context
      final context = tester.element(find.byType(MainScaffold));

      // Navigate to default route
      NavigationService.navigateToDefaultRoute(context);
      await tester.pumpAndSettle();

      // Should navigate to recipes (default route)
      expect(find.text('My Recipes'), findsOneWidget);
    });

    test('should check if route exists', () {
      expect(NavigationService.routeExists('recipes'), isTrue);
      expect(NavigationService.routeExists('meal_planning'), isTrue);
      expect(NavigationService.routeExists('settings'), isTrue);
      expect(NavigationService.routeExists('about'), isTrue);
      expect(NavigationService.routeExists('invalid_route'), isFalse);
    });

    test('should return all routes', () {
      final allRoutes = NavigationService.getAllRoutes();
      expect(allRoutes.length, equals(4));

      final routeIds = allRoutes.map((r) => r.id).toList();
      expect(routeIds, contains('recipes'));
      expect(routeIds, contains('meal_planning'));
      expect(routeIds, contains('settings'));
      expect(routeIds, contains('about'));
    });

    test('should return primary routes', () {
      final primaryRoutes = NavigationService.getPrimaryRoutes();
      expect(primaryRoutes.length, equals(2));

      final routeIds = primaryRoutes.map((r) => r.id).toList();
      expect(routeIds, contains('recipes'));
      expect(routeIds, contains('meal_planning'));

      // All should be primary
      for (final route in primaryRoutes) {
        expect(route.isPrimary, isTrue);
      }
    });

    test('should return secondary routes', () {
      final secondaryRoutes = NavigationService.getSecondaryRoutes();
      expect(secondaryRoutes.length, equals(2));

      final routeIds = secondaryRoutes.map((r) => r.id).toList();
      expect(routeIds, contains('settings'));
      expect(routeIds, contains('about'));

      // All should be secondary (not primary)
      for (final route in secondaryRoutes) {
        expect(route.isPrimary, isFalse);
      }
    });

    testWidgets('should get current route from context', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MainScaffold(
            currentScreen: const Text('Test Screen'),
            title: 'Test Title',
            currentRoute: 'meal_planning',
          ),
        ),
      );

      // Get the context from within the MainScaffold
      final context = tester.element(find.text('Test Screen'));

      // Get current route
      final currentRoute = NavigationService.getCurrentRoute(context);
      expect(currentRoute, equals('meal_planning'));
    });

    testWidgets('should return default route when MainScaffold not found', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Text('No MainScaffold'))),
      );

      // Get context from a widget that's not inside MainScaffold
      final context = tester.element(find.text('No MainScaffold'));

      // Should return default route
      final currentRoute = NavigationService.getCurrentRoute(context);
      expect(currentRoute, equals(NavigationRoutes.defaultRoute));
    });
  });
}
