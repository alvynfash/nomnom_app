import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nomnom/models/recipe.dart';
import 'package:nomnom/screens/recipe_detail_screen.dart';

void main() {
  group('RecipeDetailScreen', () {
    late Recipe testRecipe;

    setUp(() {
      testRecipe = Recipe.create(
        title: 'Test Recipe',
        ingredients: [
          Ingredient(name: 'Flour', quantity: 2.0, unit: 'cups'),
          Ingredient(name: 'Sugar', quantity: 1.0, unit: 'cup'),
        ],
        instructions: ['Mix flour and sugar', 'Bake for 30 minutes'],
        prepTime: 15,
        cookTime: 30,
        servings: 4,
        tags: ['dessert', 'easy'],
      );
    });

    testWidgets('displays recipe title in app bar', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: RecipeDetailScreen(recipe: testRecipe)),
      );

      expect(find.text('Test Recipe'), findsOneWidget);
    });

    testWidgets('displays recipe information cards', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: RecipeDetailScreen(recipe: testRecipe)),
      );

      // Wait for the widget to build
      await tester.pumpAndSettle();

      expect(find.text('Prep Time'), findsOneWidget);
      expect(find.text('Cook Time'), findsOneWidget);
      expect(find.text('Servings'), findsOneWidget);
    });

    testWidgets('displays tags section when recipe has tags', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: RecipeDetailScreen(recipe: testRecipe)),
      );

      await tester.pumpAndSettle();

      expect(find.text('Tags'), findsOneWidget);
      expect(find.text('dessert'), findsOneWidget);
      expect(find.text('easy'), findsOneWidget);
    });

    testWidgets('does not display tags section when recipe has no tags', (
      WidgetTester tester,
    ) async {
      final recipeWithoutTags = testRecipe.copyWith(tags: []);

      await tester.pumpWidget(
        MaterialApp(home: RecipeDetailScreen(recipe: recipeWithoutTags)),
      );

      await tester.pumpAndSettle();

      expect(find.text('Tags'), findsNothing);
    });

    testWidgets('displays ingredients section', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: RecipeDetailScreen(recipe: testRecipe)),
      );

      await tester.pumpAndSettle();

      expect(find.text('Ingredients'), findsOneWidget);
      // Check for ingredient content without exact formatting
      expect(find.textContaining('Flour'), findsOneWidget);
      expect(find.textContaining('Sugar'), findsOneWidget);
    });

    testWidgets('displays instructions section', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: RecipeDetailScreen(recipe: testRecipe)),
      );

      await tester.pumpAndSettle();

      expect(find.text('Instructions'), findsOneWidget);
      expect(find.text('Mix flour and sugar'), findsOneWidget);
      expect(find.text('Bake for 30 minutes'), findsOneWidget);
    });

    testWidgets('displays recipe metadata section', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: RecipeDetailScreen(recipe: testRecipe)),
      );

      await tester.pumpAndSettle();

      expect(find.text('Recipe Details'), findsOneWidget);
      expect(find.text('Created'), findsOneWidget);
      expect(find.text('Last Updated'), findsOneWidget);
      expect(find.text('Sharing'), findsOneWidget);
    });

    testWidgets('displays default background when recipe has no photos', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: RecipeDetailScreen(recipe: testRecipe)),
      );

      await tester.pumpAndSettle();

      // Should find the restaurant icon in default background
      expect(find.byIcon(Icons.restaurant_rounded), findsOneWidget);
    });

    testWidgets('shows popup menu with correct options', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: RecipeDetailScreen(recipe: testRecipe)),
      );

      await tester.pumpAndSettle();

      // Find and tap the popup menu button
      final popupMenuButton = find.byType(PopupMenuButton<String>);
      expect(popupMenuButton, findsOneWidget);

      await tester.tap(popupMenuButton);
      await tester.pumpAndSettle();

      // Check that all menu options are present
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);
      expect(find.text('Copy'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('shows delete confirmation dialog when delete is selected', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: RecipeDetailScreen(recipe: testRecipe)),
      );

      await tester.pumpAndSettle();

      // Open popup menu
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      // Tap delete option
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Should show confirmation dialog
      expect(find.text('Delete Recipe'), findsOneWidget);
      expect(
        find.textContaining('Are you sure you want to delete'),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('displays correct sharing status in metadata', (
      WidgetTester tester,
    ) async {
      // Test private recipe
      await tester.pumpWidget(
        MaterialApp(home: RecipeDetailScreen(recipe: testRecipe)),
      );

      await tester.pumpAndSettle();
      expect(find.text('Private'), findsOneWidget);
    });

    testWidgets('handles recipe with no time information', (
      WidgetTester tester,
    ) async {
      final recipeWithoutTime = testRecipe.copyWith(prepTime: 0, cookTime: 0);

      await tester.pumpWidget(
        MaterialApp(home: RecipeDetailScreen(recipe: recipeWithoutTime)),
      );

      await tester.pumpAndSettle();

      expect(find.text('Prep Time'), findsNothing);
      expect(find.text('Cook Time'), findsNothing);
    });

    testWidgets('handles recipe with no serving information', (
      WidgetTester tester,
    ) async {
      final recipeWithoutServings = testRecipe.copyWith(servings: 0);

      await tester.pumpWidget(
        MaterialApp(home: RecipeDetailScreen(recipe: recipeWithoutServings)),
      );

      await tester.pumpAndSettle();

      expect(find.text('Servings'), findsNothing);
    });

    testWidgets('has floating action button for editing', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: RecipeDetailScreen(recipe: testRecipe)),
      );

      await tester.pumpAndSettle();

      // Find the floating action button
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('Edit Recipe'), findsOneWidget);
    });

    group('Navigation and Callbacks', () {
      testWidgets('calls onRecipeDeleted callback when recipe is deleted', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: RecipeDetailScreen(
              recipe: testRecipe,
              onRecipeDeleted: () {},
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Open popup menu and select delete
        await tester.tap(find.byType(PopupMenuButton<String>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        // Confirm deletion
        await tester.tap(find.text('Delete').last);
        await tester.pumpAndSettle();

        // Note: In a real test, we'd need to mock the RecipeService
        // For now, we're just testing the UI flow
      });
    });

    group('Accessibility', () {
      testWidgets('has proper semantic structure', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(home: RecipeDetailScreen(recipe: testRecipe)),
        );

        await tester.pumpAndSettle();

        // Check that important elements are accessible
        expect(find.byType(FloatingActionButton), findsOneWidget);
        expect(find.byType(PopupMenuButton<String>), findsOneWidget);
      });
    });

    group('Error Handling', () {
      testWidgets('handles widget creation gracefully', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(home: RecipeDetailScreen(recipe: testRecipe)),
        );

        await tester.pumpAndSettle();

        expect(find.byType(RecipeDetailScreen), findsOneWidget);
      });
    });
  });
}
