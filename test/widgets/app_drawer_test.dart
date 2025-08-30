import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nomnom/models/navigation_route.dart';
import 'package:nomnom/widgets/app_drawer.dart';
import 'package:nomnom/widgets/navigation_item.dart';

void main() {
  group('AppDrawer', () {
    testWidgets('should display drawer header with app branding', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppDrawer(
              currentRoute: 'recipes',
              onNavigationTap: (route) {},
            ),
          ),
        ),
      );

      // Check app name and subtitle
      expect(find.text('NomNom'), findsOneWidget);
      expect(find.text('Your Personal Cookbook'), findsOneWidget);

      // Check app icon
      expect(find.byIcon(Icons.restaurant_rounded), findsOneWidget);
    });

    testWidgets('should display all navigation items', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppDrawer(
              currentRoute: 'recipes',
              onNavigationTap: (route) {},
            ),
          ),
        ),
      );

      // Check that all navigation items are displayed
      expect(find.text('Recipes'), findsOneWidget);
      expect(find.text('Meal Planning'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);

      // Check navigation item widgets
      expect(find.byType(NavigationItem), findsNWidgets(4));
    });

    testWidgets('should display section headers', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppDrawer(
              currentRoute: 'recipes',
              onNavigationTap: (route) {},
            ),
          ),
        ),
      );

      // Check section headers
      expect(find.text('MAIN'), findsOneWidget);
      expect(find.text('MORE'), findsOneWidget);
    });

    testWidgets('should highlight current route', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppDrawer(
              currentRoute: 'recipes',
              onNavigationTap: (route) {},
            ),
          ),
        ),
      );

      // Find all NavigationItem widgets
      final navigationItems = tester.widgetList<NavigationItem>(
        find.byType(NavigationItem),
      );

      // Check that the recipes item is selected
      final recipesItem = navigationItems.firstWhere(
        (item) => item.title == 'Recipes',
      );
      expect(recipesItem.isSelected, isTrue);

      // Check that other items are not selected
      final otherItems = navigationItems.where(
        (item) => item.title != 'Recipes',
      );
      for (final item in otherItems) {
        expect(item.isSelected, isFalse);
      }
    });

    testWidgets('should call onNavigationTap when item is tapped', (
      WidgetTester tester,
    ) async {
      NavigationRoute? tappedRoute;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppDrawer(
              currentRoute: 'recipes',
              onNavigationTap: (route) => tappedRoute = route,
            ),
          ),
        ),
      );

      // Tap on Meal Planning item
      await tester.tap(find.text('Meal Planning'));
      await tester.pump();

      // Check that the callback was called with correct route
      expect(tappedRoute, isNotNull);
      expect(tappedRoute!.id, equals('meal_planning'));
      expect(tappedRoute!.title, equals('Meal Planning'));
    });

    testWidgets('should display footer with version info', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppDrawer(
              currentRoute: 'recipes',
              onNavigationTap: (route) {},
            ),
          ),
        ),
      );

      // Check footer content
      expect(find.text('NomNom v1.0.0'), findsOneWidget);
      expect(find.text('Made with ❤️ for food lovers'), findsOneWidget);
    });

    testWidgets('should have correct drawer width', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppDrawer(
              currentRoute: 'recipes',
              onNavigationTap: (route) {},
            ),
          ),
        ),
      );

      // Check drawer width
      final drawer = tester.widget<Drawer>(find.byType(Drawer));
      expect(drawer.width, equals(280));
    });

    testWidgets('should have divider between sections', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppDrawer(
              currentRoute: 'recipes',
              onNavigationTap: (route) {},
            ),
          ),
        ),
      );

      // Check that dividers are present
      expect(find.byType(Divider), findsAtLeastNWidgets(1));
    });

    testWidgets('should handle different current routes', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppDrawer(
              currentRoute: 'settings',
              onNavigationTap: (route) {},
            ),
          ),
        ),
      );

      // Find all NavigationItem widgets
      final navigationItems = tester.widgetList<NavigationItem>(
        find.byType(NavigationItem),
      );

      // Check that the settings item is selected
      final settingsItem = navigationItems.firstWhere(
        (item) => item.title == 'Settings',
      );
      expect(settingsItem.isSelected, isTrue);

      // Check that other items are not selected
      final otherItems = navigationItems.where(
        (item) => item.title != 'Settings',
      );
      for (final item in otherItems) {
        expect(item.isSelected, isFalse);
      }
    });
  });
}
