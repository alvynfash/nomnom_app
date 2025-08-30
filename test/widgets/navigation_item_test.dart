import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nomnom/widgets/navigation_item.dart';

void main() {
  group('NavigationItem', () {
    testWidgets('should display icon and title', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NavigationItem(
              icon: Icons.home,
              title: 'Home',
              isSelected: false,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      // Check that icon and title are displayed
      expect(find.byIcon(Icons.home), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(tapped, isFalse);
    });

    testWidgets('should handle tap correctly', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NavigationItem(
              icon: Icons.home,
              title: 'Home',
              isSelected: false,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      // Tap the navigation item
      await tester.tap(find.byType(ListTile));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('should show selected state correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NavigationItem(
              icon: Icons.home,
              title: 'Home',
              isSelected: true,
              onTap: () {},
            ),
          ),
        ),
      );

      // Find the ListTile and check if it's selected
      final listTile = tester.widget<ListTile>(find.byType(ListTile));
      expect(listTile.selected, isTrue);
    });

    testWidgets('should show unselected state correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NavigationItem(
              icon: Icons.home,
              title: 'Home',
              isSelected: false,
              onTap: () {},
            ),
          ),
        ),
      );

      // Find the ListTile and check if it's not selected
      final listTile = tester.widget<ListTile>(find.byType(ListTile));
      expect(listTile.selected, isFalse);
    });

    testWidgets('should have correct styling properties', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NavigationItem(
              icon: Icons.home,
              title: 'Home',
              isSelected: false,
              onTap: () {},
            ),
          ),
        ),
      );

      // Check ListTile properties
      final listTile = tester.widget<ListTile>(find.byType(ListTile));
      expect(
        listTile.contentPadding,
        equals(const EdgeInsets.symmetric(horizontal: 16, vertical: 4)),
      );
      expect(listTile.minLeadingWidth, equals(24));
      expect(listTile.horizontalTitleGap, equals(24));

      // Check that shape is RoundedRectangleBorder
      expect(listTile.shape, isA<RoundedRectangleBorder>());
    });

    testWidgets('should have correct container margin', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NavigationItem(
              icon: Icons.home,
              title: 'Home',
              isSelected: false,
              onTap: () {},
            ),
          ),
        ),
      );

      // Check container margin
      final container = tester.widget<Container>(find.byType(Container));
      expect(
        container.margin,
        equals(const EdgeInsets.symmetric(horizontal: 12, vertical: 4)),
      );
    });
  });
}
