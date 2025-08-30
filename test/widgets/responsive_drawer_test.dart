import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nomnom/widgets/main_scaffold.dart';

void main() {
  group('Responsive Drawer Tests', () {
    testWidgets('should have correct drawer width on mobile', (
      WidgetTester tester,
    ) async {
      // Set mobile screen size
      tester.view.physicalSize = const Size(375, 667); // iPhone SE size
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(
        MaterialApp(
          home: MainScaffold(
            currentScreen: const Text('Test Screen'),
            title: 'Test Title',
            currentRoute: 'recipes',
          ),
        ),
      );

      // Open drawer
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Check drawer width
      final drawer = tester.widget<Drawer>(find.byType(Drawer));
      expect(drawer.width, equals(280));
    });

    testWidgets('should have correct drawer width on tablet', (
      WidgetTester tester,
    ) async {
      // Set tablet screen size
      tester.view.physicalSize = const Size(768, 1024); // iPad size
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(
        MaterialApp(
          home: MainScaffold(
            currentScreen: const Text('Test Screen'),
            title: 'Test Title',
            currentRoute: 'recipes',
          ),
        ),
      );

      // Open drawer
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Check drawer width (should still be 280 for consistency)
      final drawer = tester.widget<Drawer>(find.byType(Drawer));
      expect(drawer.width, equals(280));
    });

    testWidgets('should animate drawer open and close smoothly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MainScaffold(
            currentScreen: const Text('Test Screen'),
            title: 'Test Title',
            currentRoute: 'recipes',
          ),
        ),
      );

      // Initially drawer should not be visible
      expect(find.text('NomNom'), findsNothing);

      // Start opening drawer
      await tester.tap(find.byIcon(Icons.menu));

      // During animation, we should see the drawer appearing
      await tester.pump(const Duration(milliseconds: 100));

      // Complete the animation
      await tester.pumpAndSettle();

      // Drawer should now be fully visible
      expect(find.text('NomNom'), findsOneWidget);

      // Close drawer by tapping outside
      await tester.tapAt(const Offset(400, 300));

      // During closing animation
      await tester.pump(const Duration(milliseconds: 100));

      // Complete the closing animation
      await tester.pumpAndSettle();

      // Drawer should be closed
      expect(find.text('NomNom'), findsNothing);
    });

    testWidgets('should handle screen orientation changes', (
      WidgetTester tester,
    ) async {
      // Start in portrait
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(
        MaterialApp(
          home: MainScaffold(
            currentScreen: const Text('Test Screen'),
            title: 'Test Title',
            currentRoute: 'recipes',
          ),
        ),
      );

      // Open drawer in portrait
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      expect(find.text('NomNom'), findsOneWidget);

      // Rotate to landscape
      tester.view.physicalSize = const Size(667, 375);
      await tester.pumpAndSettle();

      // Drawer should still be functional
      expect(find.text('NomNom'), findsOneWidget);

      // Close drawer
      await tester.tapAt(const Offset(500, 200));
      await tester.pumpAndSettle();

      // Should be able to open again in landscape
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      expect(find.text('NomNom'), findsOneWidget);
    });

    testWidgets(
      'should maintain drawer functionality across different screen sizes',
      (WidgetTester tester) async {
        final screenSizes = [
          const Size(320, 568), // iPhone 5
          const Size(375, 667), // iPhone SE
          const Size(414, 896), // iPhone 11
          const Size(768, 1024), // iPad
          const Size(1024, 768), // iPad landscape
        ];

        for (final size in screenSizes) {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 2.0;

          await tester.pumpWidget(
            MaterialApp(
              home: MainScaffold(
                currentScreen: const Text('Test Screen'),
                title: 'Test Title',
                currentRoute: 'recipes',
              ),
            ),
          );

          // Test drawer functionality
          await tester.tap(find.byIcon(Icons.menu));
          await tester.pumpAndSettle();

          expect(find.text('NomNom'), findsOneWidget);
          expect(find.text('Recipes'), findsAtLeastNWidgets(1));

          // Close drawer
          await tester.tapAt(Offset(size.width * 0.8, size.height * 0.5));
          await tester.pumpAndSettle();

          expect(find.text('NomNom'), findsNothing);
        }
      },
    );

    testWidgets('should have proper backdrop behavior', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MainScaffold(
            currentScreen: const Text('Test Screen'),
            title: 'Test Title',
            currentRoute: 'recipes',
          ),
        ),
      );

      // Open drawer
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Should have a modal barrier (backdrop) that can be tapped to close
      expect(find.byType(ModalBarrier), findsOneWidget);

      // Tap the backdrop to close
      final modalBarrier = find.byType(ModalBarrier);
      await tester.tap(modalBarrier);
      await tester.pumpAndSettle();

      // Drawer should be closed
      expect(find.text('NomNom'), findsNothing);
    });
  });
}
