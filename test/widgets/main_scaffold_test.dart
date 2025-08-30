import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nomnom/widgets/main_scaffold.dart';
import 'package:nomnom/widgets/app_drawer.dart';

void main() {
  group('MainScaffold', () {
    testWidgets('should display current screen and title', (
      WidgetTester tester,
    ) async {
      const testScreen = Text('Test Screen Content');

      await tester.pumpWidget(
        MaterialApp(
          home: MainScaffold(
            currentScreen: testScreen,
            title: 'Test Title',
            currentRoute: 'recipes',
          ),
        ),
      );

      // Check that the screen content is displayed
      expect(find.text('Test Screen Content'), findsOneWidget);

      // Check that the title is displayed in app bar
      expect(find.text('Test Title'), findsOneWidget);
    });

    testWidgets('should display app drawer when opened', (
      WidgetTester tester,
    ) async {
      const testScreen = Text('Test Screen Content');

      await tester.pumpWidget(
        MaterialApp(
          home: MainScaffold(
            currentScreen: testScreen,
            title: 'Test Title',
            currentRoute: 'recipes',
          ),
        ),
      );

      // Open the drawer
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Check that AppDrawer is present
      expect(find.byType(AppDrawer), findsOneWidget);
    });

    testWidgets('should display floating action button when provided', (
      WidgetTester tester,
    ) async {
      const testScreen = Text('Test Screen Content');
      const testFAB = FloatingActionButton(
        onPressed: null,
        child: Icon(Icons.add),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MainScaffold(
            currentScreen: testScreen,
            title: 'Test Title',
            currentRoute: 'recipes',
            floatingActionButton: testFAB,
          ),
        ),
      );

      // Check that FAB is displayed
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('should display app bar actions when provided', (
      WidgetTester tester,
    ) async {
      const testScreen = Text('Test Screen Content');
      const testActions = [
        IconButton(onPressed: null, icon: Icon(Icons.search)),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: MainScaffold(
            currentScreen: testScreen,
            title: 'Test Title',
            currentRoute: 'recipes',
            actions: testActions,
          ),
        ),
      );

      // Check that action is displayed
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('should have correct app bar styling', (
      WidgetTester tester,
    ) async {
      const testScreen = Text('Test Screen Content');

      await tester.pumpWidget(
        MaterialApp(
          home: MainScaffold(
            currentScreen: testScreen,
            title: 'Test Title',
            currentRoute: 'recipes',
          ),
        ),
      );

      // Find the AppBar
      final appBar = tester.widget<AppBar>(find.byType(AppBar));

      // Check AppBar properties
      expect(appBar.elevation, equals(0));

      // Check title styling
      final titleWidget = appBar.title as Text;
      expect(titleWidget.style?.fontWeight, equals(FontWeight.w600));
    });

    testWidgets('should open drawer when hamburger menu is tapped', (
      WidgetTester tester,
    ) async {
      const testScreen = Text('Test Screen Content');

      await tester.pumpWidget(
        MaterialApp(
          home: MainScaffold(
            currentScreen: testScreen,
            title: 'Test Title',
            currentRoute: 'recipes',
          ),
        ),
      );

      // Initially drawer should not be visible
      expect(find.text('NomNom'), findsNothing);

      // Tap the hamburger menu
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Now drawer content should be visible
      expect(find.text('NomNom'), findsOneWidget);
      expect(find.text('Your Personal Cookbook'), findsOneWidget);
    });

    testWidgets('should update current route when widget is updated', (
      WidgetTester tester,
    ) async {
      const testScreen = Text('Test Screen Content');

      await tester.pumpWidget(
        MaterialApp(
          home: MainScaffold(
            currentScreen: testScreen,
            title: 'Test Title',
            currentRoute: 'recipes',
          ),
        ),
      );

      // Open drawer to check current route
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Find the AppDrawer and check its current route
      final appDrawer = tester.widget<AppDrawer>(find.byType(AppDrawer));
      expect(appDrawer.currentRoute, equals('recipes'));

      // Update the widget with a new route
      await tester.pumpWidget(
        MaterialApp(
          home: MainScaffold(
            currentScreen: testScreen,
            title: 'Settings',
            currentRoute: 'settings',
          ),
        ),
      );

      // Check that the route was updated
      final updatedAppDrawer = tester.widget<AppDrawer>(find.byType(AppDrawer));
      expect(updatedAppDrawer.currentRoute, equals('settings'));
    });

    testWidgets('should have correct scaffold structure', (
      WidgetTester tester,
    ) async {
      const testScreen = Text('Test Screen Content');

      await tester.pumpWidget(
        MaterialApp(
          home: MainScaffold(
            currentScreen: testScreen,
            title: 'Test Title',
            currentRoute: 'recipes',
          ),
        ),
      );

      // Check that main scaffold components are present
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);

      // Open drawer to check AppDrawer
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      expect(find.byType(AppDrawer), findsOneWidget);

      // Check that the body contains our test screen
      expect(find.text('Test Screen Content'), findsOneWidget);
    });

    testWidgets('should handle null optional parameters correctly', (
      WidgetTester tester,
    ) async {
      const testScreen = Text('Test Screen Content');

      await tester.pumpWidget(
        MaterialApp(
          home: MainScaffold(
            currentScreen: testScreen,
            title: 'Test Title',
            currentRoute: 'recipes',
            // actions and floatingActionButton are null
          ),
        ),
      );

      // Should still work without optional parameters
      expect(find.text('Test Screen Content'), findsOneWidget);
      expect(find.text('Test Title'), findsOneWidget);

      // Open drawer to check AppDrawer
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      expect(find.byType(AppDrawer), findsOneWidget);
    });
  });
}
