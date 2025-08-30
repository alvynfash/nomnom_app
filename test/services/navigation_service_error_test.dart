import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nomnom/config/navigation_routes.dart';
import 'package:nomnom/models/navigation_route.dart';
import 'package:nomnom/services/navigation_service.dart';
import 'package:nomnom/widgets/main_scaffold.dart';

void main() {
  group('NavigationService Error Handling', () {
    testWidgets('should handle invalid route ID gracefully', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    final success = await NavigationService.navigateToRoute(
                      context,
                      'invalid-route',
                    );
                    expect(success, isFalse);
                  },
                  child: const Text('Navigate'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Should show error message
      expect(
        find.text('Navigation failed. Redirected to home screen.'),
        findsOneWidget,
      );
    });

    testWidgets('should handle navigation with unmounted context', (
      tester,
    ) async {
      late BuildContext capturedContext;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              capturedContext = context;
              return const Scaffold(body: Text('Test'));
            },
          ),
        ),
      );

      // Remove the widget to unmount context
      await tester.pumpWidget(const SizedBox());

      // Try to navigate with unmounted context
      final success = await NavigationService.navigateToRoute(
        capturedContext,
        'recipes',
      );

      expect(success, isFalse);
    });

    testWidgets('should show critical error dialog for severe failures', (
      tester,
    ) async {
      // Create a route with placeholder screen
      final invalidRoute = NavigationRoute(
        id: 'invalid',
        title: 'Invalid',
        icon: Icons.error,
        screen: const Text('Invalid Screen'),
        isPrimary: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    await NavigationService.navigateToScreen(
                      context,
                      invalidRoute,
                    );
                  },
                  child: const Text('Navigate'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Should show critical error dialog
      expect(find.text('Navigation Error'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
      expect(find.text('Close App'), findsOneWidget);
    });

    testWidgets('should handle drawer close errors gracefully', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    // This should not throw even without a drawer
                    NavigationService.safeCloseDrawer(context);
                  },
                  child: const Text('Close Drawer'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Should complete without errors
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    test('NavigationException should format correctly', () {
      const exception = NavigationException(
        'Test error',
        routeId: 'test-route',
      );

      expect(exception.toString(), equals('NavigationException: Test error'));
      expect(exception.message, equals('Test error'));
      expect(exception.routeId, equals('test-route'));
    });

    testWidgets('should show recovery message with retry action', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    await NavigationService.navigateToRoute(
                      context,
                      'non-existent-route',
                    );
                  },
                  child: const Text('Navigate'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Should show recovery message with retry action
      expect(
        find.text(
          'Could not open non-existent-route. Redirected to home screen.',
        ),
        findsOneWidget,
      );
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('should handle successful navigation to default route', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    final success =
                        await NavigationService.navigateToDefaultRoute(context);
                    expect(success, isTrue);
                  },
                  child: const Text('Navigate to Default'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Should navigate to default route successfully
      expect(find.byType(MainScaffold), findsOneWidget);
    });

    testWidgets('should validate route properties before navigation', (
      tester,
    ) async {
      // Create route with valid screen
      final validRoute = NavigationRoutes.findRouteById('recipes')!;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    final success = await NavigationService.navigateToScreen(
                      context,
                      validRoute,
                    );
                    expect(success, isTrue);
                  },
                  child: const Text('Navigate'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Should navigate successfully
      expect(find.byType(MainScaffold), findsOneWidget);
    });
  });

  group('NavigationService Utility Methods', () {
    test('should correctly identify existing routes', () {
      expect(NavigationService.routeExists('recipes'), isTrue);
      expect(NavigationService.routeExists('meal-planning'), isTrue);
      expect(NavigationService.routeExists('settings'), isTrue);
      expect(NavigationService.routeExists('non-existent'), isFalse);
    });

    test('should return all routes correctly', () {
      final allRoutes = NavigationService.getAllRoutes();
      expect(allRoutes.length, equals(NavigationRoutes.allRoutes.length));
      expect(
        allRoutes.map((r) => r.id),
        containsAll(['recipes', 'meal-planning', 'settings']),
      );
    });

    test('should return primary routes correctly', () {
      final primaryRoutes = NavigationService.getPrimaryRoutes();
      expect(primaryRoutes.every((route) => route.isPrimary), isTrue);
      expect(
        primaryRoutes.map((r) => r.id),
        containsAll(['recipes', 'meal-planning']),
      );
    });

    test('should return secondary routes correctly', () {
      final secondaryRoutes = NavigationService.getSecondaryRoutes();
      expect(secondaryRoutes.every((route) => !route.isPrimary), isTrue);
      expect(secondaryRoutes.map((r) => r.id), contains('settings'));
    });
  });
}
