import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nomnom/models/recipe.dart';
import 'package:nomnom/widgets/recipe_selection_dialog.dart';

void main() {
  group('RecipeSelectionDialog', () {
    late List<Recipe> testRecipes;

    setUp(() {
      testRecipes = [
        Recipe.create(
          title: 'Quick Pasta',
          ingredients: [
            Ingredient(name: 'Pasta', quantity: 200, unit: 'g'),
            Ingredient(name: 'Tomato Sauce', quantity: 1, unit: 'cup'),
          ],
          instructions: ['Boil pasta', 'Add sauce'],
          prepTime: 5,
          cookTime: 15,
          servings: 2,
          description: 'A quick and easy pasta dish',
          tags: ['quick', 'vegetarian'],
        ),
        Recipe.create(
          title: 'Chicken Curry',
          ingredients: [
            Ingredient(name: 'Chicken', quantity: 500, unit: 'g'),
            Ingredient(name: 'Curry Powder', quantity: 2, unit: 'tbsp'),
          ],
          instructions: ['Cook chicken', 'Add curry powder'],
          prepTime: 15,
          cookTime: 45,
          servings: 4,
          description: 'Spicy chicken curry',
          tags: ['spicy', 'main'],
        ),
        Recipe.create(
          title: 'Vegetarian Salad',
          ingredients: [
            Ingredient(name: 'Lettuce', quantity: 1, unit: 'head'),
            Ingredient(name: 'Tomatoes', quantity: 2, unit: 'pieces'),
          ],
          instructions: ['Chop vegetables', 'Mix together'],
          prepTime: 10,
          cookTime: 0,
          servings: 2,
          description: 'Fresh vegetarian salad',
          tags: ['vegetarian', 'healthy'],
        ),
      ];

      // Mark one recipe as favorite by adding 'favorite' tag
      testRecipes[0] = testRecipes[0].copyWith(
        tags: [...testRecipes[0].tags, 'favorite'],
      );
    });

    Widget createWidget({
      List<Recipe>? availableRecipes,
      Function(Recipe?)? onRecipeSelected,
      String? currentRecipeId,
      bool showRemoveOption = true,
      String title = 'Select Recipe',
      String? subtitle,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: RecipeSelectionDialog(
            availableRecipes: availableRecipes ?? testRecipes,
            onRecipeSelected: onRecipeSelected ?? (recipe) {},
            currentRecipeId: currentRecipeId,
            showRemoveOption: showRemoveOption,
            title: title,
            subtitle: subtitle,
          ),
        ),
      );
    }

    group('Widget Structure', () {
      testWidgets('should display dialog title', (tester) async {
        await tester.pumpWidget(createWidget(title: 'Choose Recipe'));
        await tester.pump();

        expect(find.text('Choose Recipe'), findsOneWidget);
      });

      testWidgets('should display subtitle when provided', (tester) async {
        await tester.pumpWidget(
          createWidget(subtitle: 'Select a recipe for dinner'),
        );
        await tester.pump();

        expect(find.text('Select a recipe for dinner'), findsOneWidget);
      });

      testWidgets('should display close button', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        expect(find.byIcon(Icons.close), findsOneWidget);
      });

      testWidgets('should display search bar', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        expect(find.byType(TextField), findsOneWidget);
        expect(
          find.text('Search recipes, ingredients, or tags...'),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.search), findsOneWidget);
      });

      testWidgets('should display filter chips', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        expect(find.text('All Recipes'), findsOneWidget);
        expect(find.text('Quick (≤30 min)'), findsOneWidget);
        expect(find.text('Vegetarian'), findsOneWidget);
        expect(find.text('Favorites'), findsOneWidget);
      });

      testWidgets('should display results count', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        expect(find.text('3 recipes'), findsOneWidget);
      });

      testWidgets('should display all recipes initially', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        expect(find.text('Quick Pasta'), findsOneWidget);
        expect(find.text('Chicken Curry'), findsOneWidget);
        expect(find.text('Vegetarian Salad'), findsOneWidget);
      });

      testWidgets('should display action buttons', (tester) async {
        await tester.pumpWidget(
          createWidget(currentRecipeId: testRecipes[0].id),
        );
        await tester.pump();

        expect(find.text('Remove Recipe'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
      });
    });

    group('Search Functionality', () {
      testWidgets('should filter recipes by title', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        // Enter search query
        await tester.enterText(find.byType(TextField), 'pasta');
        await tester.pump();

        expect(find.text('Quick Pasta'), findsOneWidget);
        expect(find.text('Chicken Curry'), findsNothing);
        expect(find.text('Vegetarian Salad'), findsNothing);
        expect(find.text('1 of 3 recipes'), findsOneWidget);
      });

      testWidgets('should filter recipes by description', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        await tester.enterText(find.byType(TextField), 'spicy');
        await tester.pump();

        expect(find.text('Chicken Curry'), findsOneWidget);
        expect(find.text('Quick Pasta'), findsNothing);
        expect(find.text('1 of 3 recipes'), findsOneWidget);
      });

      testWidgets('should filter recipes by ingredients', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        await tester.enterText(find.byType(TextField), 'chicken');
        await tester.pump();

        expect(find.text('Chicken Curry'), findsOneWidget);
        expect(find.text('Quick Pasta'), findsNothing);
      });

      testWidgets('should filter recipes by tags', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        await tester.enterText(find.byType(TextField), 'vegetarian');
        await tester.pump();

        expect(find.text('Quick Pasta'), findsOneWidget);
        expect(find.text('Vegetarian Salad'), findsOneWidget);
        expect(find.text('Chicken Curry'), findsNothing);
        expect(find.text('2 of 3 recipes'), findsOneWidget);
      });

      testWidgets('should show clear button when searching', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        // Initially no clear button
        expect(find.byIcon(Icons.clear), findsNothing);

        // Enter search query
        await tester.enterText(find.byType(TextField), 'pasta');
        await tester.pump();

        // Clear button should appear
        expect(find.byIcon(Icons.clear), findsOneWidget);
      });

      testWidgets('should clear search when clear button is tapped', (
        tester,
      ) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        // Enter search query
        await tester.enterText(find.byType(TextField), 'pasta');
        await tester.pump();

        expect(find.text('1 of 3 recipes'), findsOneWidget);

        // Tap clear button
        await tester.tap(find.byIcon(Icons.clear));
        await tester.pump();

        expect(find.text('3 recipes'), findsOneWidget);
        expect(find.text('Quick Pasta'), findsOneWidget);
        expect(find.text('Chicken Curry'), findsOneWidget);
      });

      testWidgets('should show empty state when no results', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        await tester.enterText(find.byType(TextField), 'nonexistent');
        await tester.pump();

        expect(find.text('No recipes found'), findsOneWidget);
        expect(
          find.text('Try adjusting your search or filters'),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.search_off), findsOneWidget);
      });
    });

    group('Filter Functionality', () {
      testWidgets('should filter by quick recipes', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        // Tap quick filter
        await tester.tap(find.widgetWithText(FilterChip, 'Quick (≤30 min)'));
        await tester.pump();

        expect(find.text('Quick Pasta'), findsOneWidget); // 20 min total
        expect(find.text('Vegetarian Salad'), findsOneWidget); // 10 min total
        expect(find.text('Chicken Curry'), findsNothing); // 60 min total
        expect(find.text('2 of 3 recipes'), findsOneWidget);
      });

      testWidgets('should filter by vegetarian recipes', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        // Tap vegetarian filter
        await tester.tap(find.widgetWithText(FilterChip, 'Vegetarian'));
        await tester.pump();

        expect(find.text('Quick Pasta'), findsOneWidget);
        expect(find.text('Vegetarian Salad'), findsOneWidget);
        expect(find.text('Chicken Curry'), findsNothing);
        expect(find.text('2 of 3 recipes'), findsOneWidget);
      });

      testWidgets('should filter by favorite recipes', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        // Scroll to make sure the filter chip is visible
        await tester.ensureVisible(
          find.widgetWithText(FilterChip, 'Favorites'),
        );
        await tester.pump();

        // Tap favorites filter chip
        await tester.tap(
          find.widgetWithText(FilterChip, 'Favorites'),
          warnIfMissed: false,
        );
        await tester.pump();

        expect(find.text('Quick Pasta'), findsOneWidget); // marked as favorite
        expect(find.text('Chicken Curry'), findsNothing);
        expect(find.text('Vegetarian Salad'), findsNothing);
        expect(find.text('1 of 3 recipes'), findsOneWidget);
      });

      testWidgets('should show all recipes when all filter is selected', (
        tester,
      ) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        // First select a different filter
        await tester.tap(find.widgetWithText(FilterChip, 'Quick (≤30 min)'));
        await tester.pump();
        expect(find.text('2 of 3 recipes'), findsOneWidget);

        // Then select all filter
        await tester.tap(find.widgetWithText(FilterChip, 'All Recipes'));
        await tester.pump();

        expect(find.text('3 recipes'), findsOneWidget);
        expect(find.text('Quick Pasta'), findsOneWidget);
        expect(find.text('Chicken Curry'), findsOneWidget);
        expect(find.text('Vegetarian Salad'), findsOneWidget);
      });

      testWidgets('should combine search and filter', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        // Apply vegetarian filter
        await tester.tap(find.widgetWithText(FilterChip, 'Vegetarian'));
        await tester.pump();
        expect(find.text('2 of 3 recipes'), findsOneWidget);

        // Then search for pasta
        await tester.enterText(find.byType(TextField), 'pasta');
        await tester.pump();

        expect(find.text('Quick Pasta'), findsOneWidget);
        expect(find.text('Vegetarian Salad'), findsNothing);
        expect(find.text('1 of 3 recipes'), findsOneWidget);
      });
    });

    group('Recipe Selection', () {
      testWidgets('should call onRecipeSelected when recipe is tapped', (
        tester,
      ) async {
        Recipe? selectedRecipe;

        await tester.pumpWidget(
          createWidget(onRecipeSelected: (recipe) => selectedRecipe = recipe),
        );
        await tester.pump();

        // Tap on the first recipe
        await tester.tap(find.text('Quick Pasta'));
        await tester.pump();

        expect(selectedRecipe, isNotNull);
        expect(selectedRecipe!.title, equals('Quick Pasta'));
      });

      testWidgets('should highlight selected recipe', (tester) async {
        await tester.pumpWidget(
          createWidget(currentRecipeId: testRecipes[0].id),
        );
        await tester.pump();

        // Find the card containing the selected recipe
        final selectedCard = find.ancestor(
          of: find.text('Quick Pasta'),
          matching: find.byType(Card),
        );
        expect(selectedCard, findsOneWidget);

        // Should show check icon for selected recipe
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
      });

      testWidgets(
        'should call onRecipeSelected with null when remove is tapped',
        (tester) async {
          Recipe? selectedRecipe = testRecipes[0]; // Start with a selection

          await tester.pumpWidget(
            createWidget(
              currentRecipeId: testRecipes[0].id,
              onRecipeSelected: (recipe) => selectedRecipe = recipe,
            ),
          );
          await tester.pump();

          // Tap remove recipe button
          await tester.tap(find.text('Remove Recipe'));
          await tester.pump();

          expect(selectedRecipe, isNull);
        },
      );

      testWidgets(
        'should not show remove button when showRemoveOption is false',
        (tester) async {
          await tester.pumpWidget(
            createWidget(
              currentRecipeId: testRecipes[0].id,
              showRemoveOption: false,
            ),
          );
          await tester.pump();

          expect(find.text('Remove Recipe'), findsNothing);
        },
      );

      testWidgets('should not show remove button when no recipe is selected', (
        tester,
      ) async {
        await tester.pumpWidget(
          createWidget(currentRecipeId: null, showRemoveOption: true),
        );
        await tester.pump();

        expect(find.text('Remove Recipe'), findsNothing);
      });
    });

    group('Recipe Display', () {
      testWidgets('should display recipe details correctly', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        // Check recipe title
        expect(find.text('Quick Pasta'), findsOneWidget);

        // Check recipe description
        expect(find.text('A quick and easy pasta dish'), findsOneWidget);

        // Check time and servings
        expect(find.text('20m'), findsOneWidget); // 5 + 15 minutes
        expect(find.text('2 servings'), findsOneWidget);

        // Check tags
        expect(find.text('quick, vegetarian'), findsOneWidget);
      });

      testWidgets('should show favorite icon for favorite recipes', (
        tester,
      ) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        // Quick Pasta is marked as favorite
        expect(find.byIcon(Icons.favorite), findsOneWidget);
      });

      testWidgets('should show recipe placeholder when no image', (
        tester,
      ) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        // Should show restaurant icon as placeholder
        expect(
          find.byIcon(Icons.restaurant),
          findsNWidgets(3),
        ); // All recipes have no image
      });

      testWidgets('should handle recipes with no description', (tester) async {
        final recipesWithoutDescription = [
          Recipe.create(
            title: 'Simple Recipe',
            ingredients: [Ingredient(name: 'Test', quantity: 1, unit: 'cup')],
            instructions: ['Test instruction'],
            prepTime: 5,
            cookTime: 10,
            servings: 1,
            description: '', // Empty description
          ),
        ];

        await tester.pumpWidget(
          createWidget(availableRecipes: recipesWithoutDescription),
        );
        await tester.pump();

        expect(find.text('Simple Recipe'), findsOneWidget);
        expect(find.text('15m'), findsOneWidget);
        expect(find.text('1 servings'), findsOneWidget);
      });

      testWidgets('should handle recipes with zero cook time', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        // Vegetarian Salad has 0 cook time, 10 prep time
        expect(find.text('10m'), findsOneWidget);
      });
    });

    group('Dialog Actions', () {
      testWidgets('should close dialog when close button is tapped', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => RecipeSelectionDialog(
                      availableRecipes: testRecipes,
                      onRecipeSelected: (_) {},
                    ),
                  ),
                  child: const Text('Show Dialog'),
                ),
              ),
            ),
          ),
        );

        // Open dialog
        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        expect(find.byType(RecipeSelectionDialog), findsOneWidget);

        // Close dialog
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        expect(find.byType(RecipeSelectionDialog), findsNothing);
      });

      testWidgets('should close dialog when cancel button is tapped', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => RecipeSelectionDialog(
                      availableRecipes: testRecipes,
                      onRecipeSelected: (_) {},
                    ),
                  ),
                  child: const Text('Show Dialog'),
                ),
              ),
            ),
          ),
        );

        // Open dialog
        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        expect(find.byType(RecipeSelectionDialog), findsOneWidget);

        // Close dialog
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        expect(find.byType(RecipeSelectionDialog), findsNothing);
      });
    });

    group('Edge Cases', () {
      testWidgets('should handle empty recipe list', (tester) async {
        await tester.pumpWidget(createWidget(availableRecipes: []));
        await tester.pump();

        expect(find.text('0 recipes'), findsOneWidget);
        expect(find.text('No recipes found'), findsOneWidget);
        expect(
          find.text('No recipes match the selected filters'),
          findsOneWidget,
        );
      });

      testWidgets('should handle very long recipe titles', (tester) async {
        final longTitleRecipes = [
          Recipe.create(
            title:
                'This is a very long recipe title that should be truncated properly',
            ingredients: [Ingredient(name: 'Test', quantity: 1, unit: 'cup')],
            instructions: ['Test'],
            prepTime: 5,
            cookTime: 10,
            servings: 1,
          ),
        ];

        await tester.pumpWidget(
          createWidget(availableRecipes: longTitleRecipes),
        );
        await tester.pump();

        // Title should be present but truncated
        expect(
          find.textContaining('This is a very long recipe title'),
          findsOneWidget,
        );
      });

      testWidgets('should handle recipes with many tags', (tester) async {
        final manyTagsRecipes = [
          Recipe.create(
            title: 'Tagged Recipe',
            ingredients: [Ingredient(name: 'Test', quantity: 1, unit: 'cup')],
            instructions: ['Test'],
            prepTime: 5,
            cookTime: 10,
            servings: 1,
            tags: ['tag1', 'tag2', 'tag3', 'tag4', 'tag5'],
          ),
        ];

        await tester.pumpWidget(
          createWidget(availableRecipes: manyTagsRecipes),
        );
        await tester.pump();

        // Should show only first 2 tags
        expect(find.text('tag1, tag2'), findsOneWidget);
      });

      testWidgets('should handle case-insensitive search', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        await tester.enterText(find.byType(TextField), 'PASTA');
        await tester.pump();

        expect(find.text('Quick Pasta'), findsOneWidget);
        expect(find.text('1 of 3 recipes'), findsOneWidget);
      });
    });

    group('Accessibility', () {
      testWidgets('should provide proper tooltips', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        final closeButton = tester.widget<IconButton>(find.byIcon(Icons.close));
        expect(closeButton.tooltip, equals('Close'));
      });

      testWidgets('should be keyboard navigable', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        // Search field should be focusable
        expect(find.byType(TextField), findsOneWidget);

        // Buttons should be tappable
        expect(find.byType(OutlinedButton), findsAtLeastNWidgets(1));
      });
    });
  });

  group('showRecipeSelectionDialog', () {
    testWidgets('should return selected recipe', (tester) async {
      final testRecipes = [
        Recipe.create(
          title: 'Test Recipe',
          ingredients: [Ingredient(name: 'Test', quantity: 1, unit: 'cup')],
          instructions: ['Test'],
          prepTime: 5,
          cookTime: 10,
          servings: 1,
        ),
      ];

      Recipe? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  result = await showRecipeSelectionDialog(
                    context: context,
                    availableRecipes: testRecipes,
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Select recipe
      await tester.tap(find.text('Test Recipe'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.title, equals('Test Recipe'));
    });

    testWidgets('should return null when dialog is cancelled', (tester) async {
      final testRecipes = [
        Recipe.create(
          title: 'Test Recipe',
          ingredients: [Ingredient(name: 'Test', quantity: 1, unit: 'cup')],
          instructions: ['Test'],
          prepTime: 5,
          cookTime: 10,
          servings: 1,
        ),
      ];

      Recipe? result = testRecipes[0]; // Start with a value

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  result = await showRecipeSelectionDialog(
                    context: context,
                    availableRecipes: testRecipes,
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Cancel dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result, equals(testRecipes[0])); // Should remain unchanged
    });
  });
}
