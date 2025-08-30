import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nomnom/main.dart';

void main() {
  group('Sidebar Navigation Integration Tests', () {
    testWidgets('should navigate between screens using sidebar', (
      WidgetTester tester,
    ) async {
      // Start the app
      await tester.pumpWidget(const MainApp());
      await tester.pumpAndSettle();

      // Should start on recipes screen
      expect(find.text('My Recipes'), findsOneWidget);

      // Open the sidebar
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Verify sidebar is open and shows navigation items
      expect(find.text('NomNom'), findsOneWidget);
      expect(find.text('Your Personal Cookbook'), findsOneWidget);
      expect(
        find.text('Recipes'),
        findsAtLeastNWidgets(1),
      ); // May appear in app bar and sidebar
      expect(find.text('Meal Planning'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);

      // Navigate to Meal Planning (tap the first occurrence)
      await tester.tap(find.text('Meal Planning').first);
      await tester.pumpAndSettle();

      // Should be on meal planning screen
      expect(find.text('Meal Planning Coming Soon!'), findsOneWidget);

      // Open sidebar again
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Navigate to Settings (tap the first occurrence)
      await tester.tap(find.text('Settings').first);
      await tester.pumpAndSettle();

      // Should be on settings screen
      expect(find.text('Settings Coming Soon!'), findsOneWidget);

      // Open sidebar again
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Navigate back to Recipes (tap the first occurrence)
      await tester.tap(find.text('Recipes').first);
      await tester.pumpAndSettle();

      // Should be back on recipes screen
      expect(find.text('My Recipes'), findsOneWidget);
    });

    testWidgets('should close sidebar when tapping outside', (
      WidgetTester tester,
    ) async {
      // Start the app
      await tester.pumpWidget(const MainApp());
      await tester.pumpAndSettle();

      // Open the sidebar
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Verify sidebar is open
      expect(find.text('NomNom'), findsOneWidget);

      // Tap outside the sidebar (on the main content area)
      await tester.tapAt(const Offset(400, 300)); // Tap on the right side
      await tester.pumpAndSettle();

      // Sidebar should be closed (NomNom text should not be visible)
      expect(find.text('NomNom'), findsNothing);
      expect(
        find.text('My Recipes'),
        findsOneWidget,
      ); // Still on recipes screen
    });

    testWidgets('should maintain app bar styling and functionality', (
      WidgetTester tester,
    ) async {
      // Start the app
      await tester.pumpWidget(const MainApp());
      await tester.pumpAndSettle();

      // Check app bar is present and styled correctly
      final appBars = tester.widgetList<AppBar>(find.byType(AppBar));
      expect(appBars.length, greaterThanOrEqualTo(1));
      final appBar = appBars.first;
      expect(appBar.elevation, equals(0));

      // Check hamburger menu icon is present
      expect(find.byIcon(Icons.menu), findsOneWidget);

      // Navigate to different screen and check app bar updates
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Settings').first);
      await tester.pumpAndSettle();

      // App bar should show new title (check for the coming soon message instead)
      expect(find.text('Settings Coming Soon!'), findsOneWidget);
      expect(
        find.byIcon(Icons.menu),
        findsOneWidget,
      ); // Hamburger menu still present
    });

    testWidgets('should handle rapid navigation correctly', (
      WidgetTester tester,
    ) async {
      // Start the app
      await tester.pumpWidget(const MainApp());
      await tester.pumpAndSettle();

      // Rapidly navigate between screens
      for (int i = 0; i < 3; i++) {
        // Open sidebar
        await tester.tap(find.byIcon(Icons.menu));
        await tester.pumpAndSettle();

        // Navigate to meal planning
        await tester.tap(find.text('Meal Planning').first);
        await tester.pumpAndSettle();

        // Open sidebar again
        await tester.tap(find.byIcon(Icons.menu));
        await tester.pumpAndSettle();

        // Navigate back to recipes
        await tester.tap(find.text('Recipes').first);
        await tester.pumpAndSettle();
      }

      // Should end up on recipes screen without errors
      expect(find.text('My Recipes'), findsOneWidget);
    });
  });
}
