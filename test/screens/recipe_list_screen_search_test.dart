import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nomnom/screens/recipe_list_screen.dart';
import 'package:nomnom/widgets/search_bar_widget.dart';

void main() {
  group('RecipeListScreen Search and Filter Integration', () {
    testWidgets('displays search bar widget', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: RecipeListScreen()));

      // Wait for loading to complete
      await tester.pumpAndSettle();

      // Verify search bar is displayed
      expect(find.byType(SearchBarWidget), findsOneWidget);
      expect(find.text('Search recipes...'), findsOneWidget);
    });

    testWidgets('shows empty state when no recipes exist', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: RecipeListScreen()));

      // Wait for loading to complete
      await tester.pumpAndSettle();

      // Verify empty state is shown
      expect(find.text('No recipes yet!'), findsOneWidget);
      expect(
        find.text('Tap the + button to create your first recipe.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.restaurant_menu_rounded), findsOneWidget);
    });

    testWidgets(
      'shows clear filters button in empty state when filters are active',
      (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(home: RecipeListScreen()));

        // Wait for loading to complete
        await tester.pumpAndSettle();

        // Enter search text to activate filters
        await tester.enterText(find.byType(TextField), 'nonexistent');
        await tester.pump();

        // Wait for search debounce
        await tester.pump(const Duration(milliseconds: 400));

        // Verify filtered empty state is shown
        expect(find.text('No recipes found'), findsOneWidget);
        expect(
          find.text('Try adjusting your search or filters.'),
          findsOneWidget,
        );
        expect(find.text('Clear Filters'), findsOneWidget);
        expect(find.byIcon(Icons.search_off_rounded), findsOneWidget);
      },
    );

    testWidgets('shows clear filters functionality', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: RecipeListScreen()));

      // Wait for loading to complete
      await tester.pumpAndSettle();

      // Enter search text
      await tester.enterText(find.byType(TextField), 'test search');
      await tester.pump();

      // Wait for search debounce
      await tester.pump(const Duration(milliseconds: 400));

      // Verify filtered empty state is shown
      expect(find.text('No recipes found'), findsOneWidget);
      expect(find.text('Clear Filters'), findsOneWidget);

      // Verify the button can be found and is tappable
      final clearButton = find.text('Clear Filters');
      expect(clearButton, findsOneWidget);

      // Verify button is enabled
      final buttonWidget = tester.widget<FilledButton>(
        find.ancestor(of: clearButton, matching: find.byType(FilledButton)),
      );
      expect(buttonWidget.onPressed, isNotNull);
    });

    testWidgets('displays floating action button for creating new recipe', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: RecipeListScreen()));

      // Wait for loading to complete
      await tester.pumpAndSettle();

      // Verify FAB is displayed
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('New Recipe'), findsOneWidget);
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    });

    testWidgets('has proper app bar title', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: RecipeListScreen()));

      // Wait for loading to complete
      await tester.pumpAndSettle();

      // Verify app bar title
      expect(find.text('My Recipes'), findsOneWidget);
    });

    testWidgets('search bar has correct initial state', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: RecipeListScreen()));

      // Wait for loading to complete
      await tester.pumpAndSettle();

      // Verify search bar initial state
      final searchBarWidget = tester.widget<SearchBarWidget>(
        find.byType(SearchBarWidget),
      );
      expect(searchBarWidget.initialQuery, isEmpty);
      expect(searchBarWidget.initialTagFilters, isEmpty);
      expect(searchBarWidget.hintText, equals('Search recipes...'));
    });

    testWidgets('search bar container has proper styling', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: RecipeListScreen()));

      // Wait for loading to complete
      await tester.pumpAndSettle();

      // Find the search bar container
      final containerFinder = find
          .ancestor(
            of: find.byType(SearchBarWidget),
            matching: find.byType(Container),
          )
          .first;

      final container = tester.widget<Container>(containerFinder);
      expect(container.padding, equals(const EdgeInsets.all(16)));

      // Verify decoration exists
      expect(container.decoration, isA<BoxDecoration>());
    });

    group('Layout Structure', () {
      testWidgets('has correct widget hierarchy', (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(home: RecipeListScreen()));

        // Wait for loading to complete
        await tester.pumpAndSettle();

        // Verify main structure
        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.byType(AppBar), findsOneWidget);
        expect(find.byType(Column), findsWidgets);
        expect(find.byType(SearchBarWidget), findsOneWidget);
        expect(find.byType(Expanded), findsWidgets);
      });

      testWidgets('search bar is positioned above recipe list', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(const MaterialApp(home: RecipeListScreen()));

        // Wait for loading to complete
        await tester.pumpAndSettle();

        // Find the main column
        final columnFinder = find
            .descendant(
              of: find.byType(Scaffold),
              matching: find.byType(Column),
            )
            .first;

        final column = tester.widget<Column>(columnFinder);

        // Verify the column has children (search bar container and expanded list)
        expect(column.children.length, equals(2));

        // First child should be the search bar container
        expect(column.children[0], isA<Container>());

        // Second child should be the expanded recipe list
        expect(column.children[1], isA<Expanded>());
      });
    });

    group('Error Handling', () {
      testWidgets('handles loading state correctly', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(const MaterialApp(home: RecipeListScreen()));

        // Initially should show loading indicator
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Wait for loading to complete
        await tester.pumpAndSettle();

        // Loading indicator should be gone
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });
    });

    group('Accessibility', () {
      testWidgets('has proper semantic labels', (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(home: RecipeListScreen()));

        // Wait for loading to complete
        await tester.pumpAndSettle();

        // Verify app bar has proper semantics
        expect(find.text('My Recipes'), findsOneWidget);

        // Verify FAB has proper semantics
        expect(find.text('New Recipe'), findsOneWidget);
      });
    });
  });
}
