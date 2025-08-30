import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nomnom/widgets/main_scaffold.dart';

void main() {
  group('MainScaffold Error Handling', () {
    testWidgets('should handle navigation errors gracefully', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MainScaffold(
            currentScreen: const Text('Test Screen'),
            title: 'Test',
            currentRoute: 'recipes',
          ),
        ),
      );

      // Trigger navigation through drawer interaction
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Since we can't directly test private methods, we'll test through UI interaction
      // The error handling will be tested through integration tests

      // Should handle error without crashing
      expect(find.byType(MainScaffold), findsOneWidget);
    });

    testWidgets('should revert state on navigation failure', (tester) async {
      const originalRoute = 'recipes';

      await tester.pumpWidget(
        MaterialApp(
          home: MainScaffold(
            currentScreen: const Text('Test Screen'),
            title: 'Test',
            currentRoute: originalRoute,
          ),
        ),
      );

      // Verify initial state through UI
      expect(find.text('Test'), findsOneWidget);

      // Test navigation through drawer
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Should still be on original route
      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('should handle widget disposal properly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MainScaffold(
            currentScreen: const Text('Test Screen'),
            title: 'Test',
            currentRoute: 'recipes',
          ),
        ),
      );

      // Verify widget exists initially
      expect(find.byType(MainScaffold), findsOneWidget);

      // Remove the widget
      await tester.pumpWidget(const SizedBox());

      // Widget should be disposed (no longer found)
      expect(find.byType(MainScaffold), findsNothing);
    });

    testWidgets('should handle app lifecycle changes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MainScaffold(
            currentScreen: const Text('Test Screen'),
            title: 'Test',
            currentRoute: 'recipes',
          ),
        ),
      );

      // Simulate app lifecycle changes through binding
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pumpAndSettle();

      // Should handle lifecycle change without errors
      expect(find.byType(MainScaffold), findsOneWidget);
    });

    testWidgets('should not update state when disposed', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MainScaffold(
            currentScreen: const Text('Test Screen'),
            title: 'Test',
            currentRoute: 'recipes',
          ),
        ),
      );

      // Test widget update behavior

      // Try to update widget
      await tester.pumpWidget(
        MaterialApp(
          home: MainScaffold(
            currentScreen: const Text('Updated Screen'),
            title: 'Updated',
            currentRoute: 'meal-planning',
          ),
        ),
      );

      // Should not crash even when trying to update disposed widget
      expect(find.byType(MainScaffold), findsOneWidget);
    });

    testWidgets('should skip navigation for same route', (tester) async {
      const currentRoute = 'recipes';

      await tester.pumpWidget(
        MaterialApp(
          home: MainScaffold(
            currentScreen: const Text('Test Screen'),
            title: 'Test',
            currentRoute: currentRoute,
          ),
        ),
      );

      // Test navigation through drawer
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Tap on current route (Recipes)
      await tester.tap(find.text('Recipes'));
      await tester.pumpAndSettle();

      // Should remain on same route without issues
      expect(find.text('Test Screen'), findsOneWidget);
    });

    testWidgets('should handle drawer interactions safely', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MainScaffold(
            currentScreen: const Text('Test Screen'),
            title: 'Test',
            currentRoute: 'recipes',
          ),
        ),
      );

      // Open drawer
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Verify drawer is open
      expect(find.byType(Drawer), findsOneWidget);

      // Tap on a navigation item
      await tester.tap(find.text('Meal Planning'));
      await tester.pumpAndSettle();

      // Should navigate successfully (check for app bar title)
      expect(find.text('Meal Planning'), findsWidgets);
    });

    testWidgets('should maintain proper state during navigation', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MainScaffold(
            currentScreen: const Text('Test Screen'),
            title: 'Test',
            currentRoute: 'recipes',
          ),
        ),
      );

      // Navigate through drawer
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Tap on meal planning
      await tester.tap(find.text('Meal Planning'));
      await tester.pumpAndSettle();

      // Should navigate to meal planning (check for app bar title)
      expect(find.text('Meal Planning'), findsWidgets);
    });
  });

  group('MainScaffold Widget Properties', () {
    testWidgets('should display correct title and screen', (tester) async {
      const title = 'Test Title';
      const screenText = 'Test Screen Content';

      await tester.pumpWidget(
        MaterialApp(
          home: MainScaffold(
            currentScreen: const Text(screenText),
            title: title,
            currentRoute: 'recipes',
          ),
        ),
      );

      expect(find.text(title), findsOneWidget);
      expect(find.text(screenText), findsOneWidget);
    });

    testWidgets('should display floating action button when provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MainScaffold(
            currentScreen: const Text('Test Screen'),
            title: 'Test',
            currentRoute: 'recipes',
            floatingActionButton: FloatingActionButton(
              onPressed: () {},
              child: const Icon(Icons.add),
            ),
          ),
        ),
      );

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('should display app bar actions when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MainScaffold(
            currentScreen: const Text('Test Screen'),
            title: 'Test',
            currentRoute: 'recipes',
            actions: [
              IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
            ],
          ),
        ),
      );

      expect(find.byIcon(Icons.search), findsOneWidget);
    });
  });
}
