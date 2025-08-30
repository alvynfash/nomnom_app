import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nomnom/main.dart';
import 'package:nomnom/config/navigation_routes.dart';

void main() {
  group('Navigation Integration Tests', () {
    testWidgets('should navigate to meal planning screen from drawer', (
      WidgetTester tester,
    ) async {
      // Build the app
      await tester.pumpWidget(const MainApp());
      await tester.pumpAndSettle();

      // Open the drawer
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Find and tap the meal planning navigation item
      await tester.tap(find.text('Meal Planning'));
      await tester.pumpAndSettle();

      // Verify we're on the meal planning screen
      expect(find.text('Meal Plans'), findsOneWidget);
    });

    testWidgets('should show meal planning as primary navigation route', (
      WidgetTester tester,
    ) async {
      // Test that meal planning is configured as a primary route
      final primaryRoutes = NavigationRoutes.primaryRoutes;

      expect(primaryRoutes.length, equals(2));
      expect(
        primaryRoutes.any((route) => route.id == NavigationRoutes.mealPlanning),
        isTrue,
      );
      expect(
        primaryRoutes.any((route) => route.title == 'Meal Planning'),
        isTrue,
      );
    });

    testWidgets('should find meal planning route by ID', (
      WidgetTester tester,
    ) async {
      final route = NavigationRoutes.findRouteById(
        NavigationRoutes.mealPlanning,
      );

      expect(route, isNotNull);
      expect(route!.title, equals('Meal Planning'));
      expect(route.icon, equals(Icons.calendar_today_rounded));
      expect(route.isPrimary, isTrue);
    });
  });
}
