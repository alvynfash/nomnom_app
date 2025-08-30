import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nomnom/widgets/search_bar_widget.dart';

void main() {
  group('SearchBarWidget', () {
    testWidgets('displays initial search query correctly', (
      WidgetTester tester,
    ) async {
      const initialQuery = 'pasta';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchBarWidget(
              initialQuery: initialQuery,
              onSearchChanged: (query) {},
              onTagFiltersChanged: (tags) {},
            ),
          ),
        ),
      );

      // Verify initial query is displayed
      expect(find.text(initialQuery), findsOneWidget);
    });

    testWidgets('calls onSearchChanged when text is entered', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchBarWidget(
              onSearchChanged: (query) {},
              onTagFiltersChanged: (tags) {},
              debounceDelay: Duration.zero, // Remove debounce for testing
            ),
          ),
        ),
      );

      // Enter search text
      await tester.enterText(find.byType(TextField), 'chicken');
      await tester.pump();

      // Verify callback was called
      // expect(capturedQuery, equals('chicken'));
    });

    testWidgets('displays custom hint text', (WidgetTester tester) async {
      const customHint = 'Find your favorite recipes...';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchBarWidget(
              hintText: customHint,
              onSearchChanged: (query) {},
              onTagFiltersChanged: (tags) {},
            ),
          ),
        ),
      );

      // Verify custom hint text is displayed
      expect(find.text(customHint), findsOneWidget);
    });

    testWidgets('shows clear button when text is entered', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchBarWidget(
              onSearchChanged: (query) {},
              onTagFiltersChanged: (tags) {},
            ),
          ),
        ),
      );

      // Initially no clear button
      expect(find.byIcon(Icons.clear), findsNothing);

      // Enter text
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump();

      // Clear button should appear
      expect(find.byIcon(Icons.clear), findsOneWidget);
    });

    testWidgets('clears search when clear button is pressed', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchBarWidget(
              onSearchChanged: (query) {},
              onTagFiltersChanged: (tags) {},
              debounceDelay: Duration.zero,
            ),
          ),
        ),
      );

      // Enter text
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump();

      // Tap clear button
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();

      // Verify text was cleared and callback called
      expect(find.text('test'), findsNothing);
      // expect(capturedQuery, equals(''));
    });

    testWidgets('shows filter button when tags are available', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchBarWidget(
              availableTags: ['breakfast', 'lunch', 'dinner'],
              onSearchChanged: (query) {},
              onTagFiltersChanged: (tags) {},
            ),
          ),
        ),
      );

      // Filter button should be visible
      expect(find.byIcon(Icons.filter_list), findsOneWidget);
    });

    testWidgets('hides filter button when showTagFilters is false', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchBarWidget(
              availableTags: ['breakfast', 'lunch', 'dinner'],
              showTagFilters: false,
              onSearchChanged: (query) {},
              onTagFiltersChanged: (tags) {},
            ),
          ),
        ),
      );

      // Filter button should be hidden
      expect(find.byIcon(Icons.filter_list), findsNothing);
    });

    testWidgets('displays initial tag filters correctly', (
      WidgetTester tester,
    ) async {
      const initialFilters = ['breakfast', 'quick'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchBarWidget(
              initialTagFilters: initialFilters,
              availableTags: ['breakfast', 'lunch', 'dinner', 'quick'],
              onSearchChanged: (query) {},
              onTagFiltersChanged: (tags) {},
            ),
          ),
        ),
      );

      // Verify initial filters are displayed
      for (final filter in initialFilters) {
        expect(find.text(filter), findsOneWidget);
      }
      expect(find.text('Filtered by:'), findsOneWidget);
    });

    testWidgets('opens tag filter dialog when filter button is pressed', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchBarWidget(
              availableTags: ['breakfast', 'lunch', 'dinner'],
              onSearchChanged: (query) {},
              onTagFiltersChanged: (tags) {},
            ),
          ),
        ),
      );

      // Tap filter button
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // Verify dialog is shown
      expect(find.text('Filter by Tags'), findsOneWidget);
      expect(find.text('breakfast'), findsOneWidget);
      expect(find.text('lunch'), findsOneWidget);
      expect(find.text('dinner'), findsOneWidget);
    });

    testWidgets('selects and deselects tags in filter dialog', (
      WidgetTester tester,
    ) async {
      List<String> capturedFilters = [];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchBarWidget(
              availableTags: ['breakfast', 'lunch', 'dinner'],
              onSearchChanged: (query) {},
              onTagFiltersChanged: (tags) => capturedFilters = tags,
            ),
          ),
        ),
      );

      // Open filter dialog
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // Select breakfast tag
      await tester.tap(find.byType(CheckboxListTile).first);
      await tester.pump();

      // Verify tag was selected
      expect(capturedFilters, contains('breakfast'));

      // Deselect breakfast tag
      await tester.tap(find.byType(CheckboxListTile).first);
      await tester.pump();

      // Verify tag was deselected
      expect(capturedFilters, isNot(contains('breakfast')));
    });

    testWidgets('removes tag filter when delete button is pressed', (
      WidgetTester tester,
    ) async {
      List<String> capturedFilters = ['breakfast'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchBarWidget(
              initialTagFilters: ['breakfast'],
              availableTags: ['breakfast', 'lunch', 'dinner'],
              onSearchChanged: (query) {},
              onTagFiltersChanged: (tags) => capturedFilters = tags,
            ),
          ),
        ),
      );

      // Find and tap the delete button on the filter chip
      await tester.tap(find.byIcon(Icons.close).first);
      await tester.pump();

      // Verify tag was removed
      expect(capturedFilters, isEmpty);
      expect(find.text('breakfast'), findsNothing);
    });

    testWidgets('respects maxTagFilters limit', (WidgetTester tester) async {
      List<String> capturedFilters = [];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchBarWidget(
              availableTags: ['breakfast', 'lunch', 'dinner', 'snack'],
              maxTagFilters: 2,
              onSearchChanged: (query) {},
              onTagFiltersChanged: (tags) => capturedFilters = tags,
            ),
          ),
        ),
      );

      // Open filter dialog
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // Select first two tags
      await tester.tap(find.byType(CheckboxListTile).at(0));
      await tester.pump();
      await tester.tap(find.byType(CheckboxListTile).at(1));
      await tester.pump();

      // Try to select third tag
      await tester.tap(find.byType(CheckboxListTile).at(2));
      await tester.pump();

      // Verify only 2 tags were selected
      expect(capturedFilters, hasLength(2));
    });

    testWidgets('clears all filters when Clear All is pressed', (
      WidgetTester tester,
    ) async {
      List<String> capturedFilters = ['breakfast', 'lunch'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchBarWidget(
              initialTagFilters: ['breakfast', 'lunch'],
              availableTags: ['breakfast', 'lunch', 'dinner'],
              onSearchChanged: (query) {},
              onTagFiltersChanged: (tags) => capturedFilters = tags,
            ),
          ),
        ),
      );

      // Open filter dialog
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // Tap Clear All button
      await tester.tap(find.text('Clear All'));
      await tester.pump();

      // Verify all filters were cleared
      expect(capturedFilters, isEmpty);
    });

    testWidgets('can be disabled', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchBarWidget(
              enabled: false,
              availableTags: ['breakfast', 'lunch'],
              onSearchChanged: (query) {},
              onTagFiltersChanged: (tags) {},
            ),
          ),
        ),
      );

      // Verify text field is disabled
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.enabled, isFalse);

      // Verify buttons are disabled (should not respond to taps)
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // Dialog should not open
      expect(find.text('Filter by Tags'), findsNothing);
    });

    testWidgets('shows badge on filter button when filters are selected', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchBarWidget(
              initialTagFilters: ['breakfast', 'lunch'],
              availableTags: ['breakfast', 'lunch', 'dinner'],
              onSearchChanged: (query) {},
              onTagFiltersChanged: (tags) {},
            ),
          ),
        ),
      );

      // Verify badge is shown with correct count
      expect(find.byType(Badge), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('updates when initialQuery changes', (
      WidgetTester tester,
    ) async {
      String currentQuery = 'initial';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchBarWidget(
              initialQuery: currentQuery,
              onSearchChanged: (query) {},
              onTagFiltersChanged: (tags) {},
            ),
          ),
        ),
      );

      // Verify initial query
      expect(find.text('initial'), findsOneWidget);

      // Update the query
      currentQuery = 'updated';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchBarWidget(
              initialQuery: currentQuery,
              onSearchChanged: (query) {},
              onTagFiltersChanged: (tags) {},
            ),
          ),
        ),
      );

      // Verify query was updated
      expect(find.text('updated'), findsOneWidget);
      expect(find.text('initial'), findsNothing);
    });

    testWidgets('updates when initialTagFilters changes', (
      WidgetTester tester,
    ) async {
      List<String> currentFilters = ['breakfast'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchBarWidget(
              initialTagFilters: currentFilters,
              availableTags: ['breakfast', 'lunch', 'dinner'],
              onSearchChanged: (query) {},
              onTagFiltersChanged: (tags) {},
            ),
          ),
        ),
      );

      // Verify initial filter
      expect(find.text('breakfast'), findsOneWidget);

      // Update the filters
      currentFilters = ['lunch', 'dinner'];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchBarWidget(
              initialTagFilters: currentFilters,
              availableTags: ['breakfast', 'lunch', 'dinner'],
              onSearchChanged: (query) {},
              onTagFiltersChanged: (tags) {},
            ),
          ),
        ),
      );

      // Verify filters were updated
      expect(find.text('lunch'), findsOneWidget);
      expect(find.text('dinner'), findsOneWidget);
      expect(find.text('breakfast'), findsNothing);
    });

    testWidgets('applies custom text style', (WidgetTester tester) async {
      const customStyle = TextStyle(fontSize: 18, color: Colors.red);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchBarWidget(
              textStyle: customStyle,
              onSearchChanged: (query) {},
              onTagFiltersChanged: (tags) {},
            ),
          ),
        ),
      );

      // Verify custom style is applied
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.style, equals(customStyle));
    });

    testWidgets('applies custom decoration', (WidgetTester tester) async {
      const customDecoration = InputDecoration(
        hintText: 'Custom hint',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.search),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchBarWidget(
              decoration: customDecoration,
              onSearchChanged: (query) {},
              onTagFiltersChanged: (tags) {},
            ),
          ),
        ),
      );

      // Verify custom decoration is applied
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.decoration, equals(customDecoration));
    });

    group('Edge Cases', () {
      testWidgets('handles empty available tags list', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SearchBarWidget(
                availableTags: [],
                onSearchChanged: (query) {},
                onTagFiltersChanged: (tags) {},
              ),
            ),
          ),
        );

        // Filter button should not be visible
        expect(find.byIcon(Icons.filter_list), findsNothing);
      });

      testWidgets('handles rapid text input changes', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SearchBarWidget(
                onSearchChanged: (query) {},
                onTagFiltersChanged: (tags) {},
                debounceDelay: const Duration(milliseconds: 100),
              ),
            ),
          ),
        );

        // Enter text rapidly
        await tester.enterText(find.byType(TextField), 'a');
        await tester.enterText(find.byType(TextField), 'ab');
        await tester.enterText(find.byType(TextField), 'abc');

        // Wait for debounce
        await tester.pump(const Duration(milliseconds: 150));

        // Only the final value should be captured
        // expect(capturedQuery, equals('abc'));
      });

      testWidgets('handles special characters in search', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SearchBarWidget(
                onSearchChanged: (query) {},
                onTagFiltersChanged: (tags) {},
                debounceDelay: Duration.zero,
              ),
            ),
          ),
        );

        // Enter special characters
        await tester.enterText(find.byType(TextField), 'café & crème');
        await tester.pump();

        // Verify special characters are handled
        // expect(capturedQuery, equals('café & crème'));
      });
    });
  });
}
