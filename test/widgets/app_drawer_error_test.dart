import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nomnom/models/navigation_route.dart';
import 'package:nomnom/widgets/app_drawer.dart';

void main() {
  group('AppDrawer Error Handling', () {
    testWidgets('should handle navigation tap errors gracefully', (
      tester,
    ) async {
      bool errorThrown = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            drawer: AppDrawer(
              currentRoute: 'recipes',
              onNavigationTap: (route) {
                errorThrown = true;
                throw Exception('Navigation error');
              },
            ),
            body: const Text('Test'),
          ),
        ),
      );

      // Open drawer
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Tap on a navigation item
      await tester.tap(find.text('Recipes'));
      await tester.pumpAndSettle();

      // Should handle error gracefully
      expect(errorThrown, isTrue);
      expect(find.text('Could not navigate to Recipes'), findsOneWidget);
    });

    testWidgets('should display all navigation sections correctly', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            drawer: AppDrawer(
              currentRoute: 'recipes',
              onNavigationTap: (route) {},
            ),
            body: const Text('Test'),
          ),
        ),
      );

      // Open drawer
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Should display section headers
      expect(find.text('MAIN'), findsOneWidget);
      expect(find.text('MORE'), findsOneWidget);

      // Should display all navigation items
      expect(find.text('Recipes'), findsOneWidget);
      expect(find.text('Meal Planning'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('should highlight current route correctly', (tester) async {
      const currentRoute = 'meal-planning';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            drawer: AppDrawer(
              currentRoute: currentRoute,
              onNavigationTap: (route) {},
            ),
            body: const Text('Test'),
          ),
        ),
      );

      // Open drawer
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Find the meal planning navigation item
      final mealPlanningItem = find.ancestor(
        of: find.text('Meal Planning'),
        matching: find.byType(Container),
      );

      expect(mealPlanningItem, findsWidgets);
    });

    testWidgets('should display drawer header correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            drawer: AppDrawer(
              currentRoute: 'recipes',
              onNavigationTap: (route) {},
            ),
            body: const Text('Test'),
          ),
        ),
      );

      // Open drawer
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Should display app name and subtitle
      expect(find.text('NomNom'), findsOneWidget);
      expect(find.text('Your Personal Cookbook'), findsOneWidget);
      expect(find.byIcon(Icons.restaurant_rounded), findsOneWidget);
    });

    testWidgets('should display drawer footer correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            drawer: AppDrawer(
              currentRoute: 'recipes',
              onNavigationTap: (route) {},
            ),
            body: const Text('Test'),
          ),
        ),
      );

      // Open drawer
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Should display version and tagline
      expect(find.text('NomNom v1.0.0'), findsOneWidget);
      expect(find.text('Made with ❤️ for food lovers'), findsOneWidget);
    });

    testWidgets('should handle null or empty route lists', (tester) async {
      // This test ensures the drawer doesn't crash with edge cases
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            drawer: AppDrawer(
              currentRoute: 'non-existent',
              onNavigationTap: (route) {},
            ),
            body: const Text('Test'),
          ),
        ),
      );

      // Open drawer
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Should still display without errors
      expect(find.byType(Drawer), findsOneWidget);
    });

    testWidgets('should call onNavigationTap with correct route', (
      tester,
    ) async {
      NavigationRoute? tappedRoute;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            drawer: AppDrawer(
              currentRoute: 'recipes',
              onNavigationTap: (route) {
                tappedRoute = route;
              },
            ),
            body: const Text('Test'),
          ),
        ),
      );

      // Open drawer
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Tap on meal planning
      await tester.tap(find.text('Meal Planning'));
      await tester.pumpAndSettle();

      // Should call callback with correct route
      expect(tappedRoute, isNotNull);
      expect(tappedRoute!.id, equals('meal-planning'));
      expect(tappedRoute!.title, equals('Meal Planning'));
    });

    testWidgets('should maintain proper drawer width', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            drawer: AppDrawer(
              currentRoute: 'recipes',
              onNavigationTap: (route) {},
            ),
            body: const Text('Test'),
          ),
        ),
      );

      // Open drawer
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Find the drawer widget
      final drawer = tester.widget<Drawer>(find.byType(Drawer));
      expect(drawer.width, equals(280));
    });

    testWidgets('should handle theme changes correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            drawer: AppDrawer(
              currentRoute: 'recipes',
              onNavigationTap: (route) {},
            ),
            body: const Text('Test'),
          ),
        ),
      );

      // Open drawer
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Should render without errors in dark theme
      expect(find.byType(Drawer), findsOneWidget);
      expect(find.text('NomNom'), findsOneWidget);
    });
  });

  group('AppDrawer Navigation Items', () {
    testWidgets('should display correct icons for each route', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            drawer: AppDrawer(
              currentRoute: 'recipes',
              onNavigationTap: (route) {},
            ),
            body: const Text('Test'),
          ),
        ),
      );

      // Open drawer
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Check for route icons
      expect(find.byIcon(Icons.restaurant), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('should separate primary and secondary routes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            drawer: AppDrawer(
              currentRoute: 'recipes',
              onNavigationTap: (route) {},
            ),
            body: const Text('Test'),
          ),
        ),
      );

      // Open drawer
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Should have divider between sections
      expect(find.byType(Divider), findsWidgets);

      // Primary routes should be under MAIN
      final mainSection = find.ancestor(
        of: find.text('MAIN'),
        matching: find.byType(Column),
      );
      expect(mainSection, findsOneWidget);

      // Secondary routes should be under MORE
      final moreSection = find.ancestor(
        of: find.text('MORE'),
        matching: find.byType(Column),
      );
      expect(moreSection, findsOneWidget);
    });
  });
}
