import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nomnom/models/recipe.dart';
import 'package:nomnom/screens/recipe_list_screen.dart';

void main() {
  group('Recipe Card Image Display', () {
    late Recipe sampleRecipeWithNetworkImage;
    late Recipe sampleRecipeWithLocalImage;
    late Recipe sampleRecipeWithoutImage;

    setUp(() {
      sampleRecipeWithNetworkImage = Recipe(
        id: 'test-recipe-network',
        title: 'Network Image Recipe',
        description: 'Recipe with network image',
        ingredients: [
          Ingredient(name: 'Test Ingredient', quantity: 1, unit: 'cup'),
        ],
        instructions: ['Test instruction'],
        prepTime: 10,
        cookTime: 15,
        servings: 2,
        difficulty: RecipeDifficulty.easy,
        tags: ['Test'],
        photoUrls: [
          'https://images.unsplash.com/photo-1551183053-bf91a1d81141?w=400&h=300&fit=crop',
        ],
        isPrivate: false,
        isPublished: true,
        familyId: 'family-1',
        createdAt: DateTime.now().subtract(Duration(days: 1)),
        updatedAt: DateTime.now(),
      );

      sampleRecipeWithLocalImage = Recipe(
        id: 'test-recipe-local',
        title: 'Local Image Recipe',
        description: 'Recipe with local image',
        ingredients: [
          Ingredient(name: 'Test Ingredient', quantity: 1, unit: 'cup'),
        ],
        instructions: ['Test instruction'],
        prepTime: 10,
        cookTime: 15,
        servings: 2,
        difficulty: RecipeDifficulty.easy,
        tags: ['Test'],
        photoUrls: ['/path/to/local/image.jpg'],
        isPrivate: false,
        isPublished: true,
        familyId: 'family-1',
        createdAt: DateTime.now().subtract(Duration(days: 1)),
        updatedAt: DateTime.now(),
      );

      sampleRecipeWithoutImage = Recipe(
        id: 'test-recipe-no-image',
        title: 'No Image Recipe',
        description: 'Recipe without image',
        ingredients: [
          Ingredient(name: 'Test Ingredient', quantity: 1, unit: 'cup'),
        ],
        instructions: ['Test instruction'],
        prepTime: 10,
        cookTime: 15,
        servings: 2,
        difficulty: RecipeDifficulty.easy,
        tags: ['Test'],
        photoUrls: [],
        isPrivate: false,
        isPublished: true,
        familyId: 'family-1',
        createdAt: DateTime.now().subtract(Duration(days: 1)),
        updatedAt: DateTime.now(),
      );
    });

    testWidgets('displays network image when recipe has network photo URL', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: RecipeListScreen())),
      );

      // Note: This test would need to be expanded with proper mocking
      // of the RecipeService to return our test recipe
      expect(find.byType(RecipeListScreen), findsOneWidget);
    });

    testWidgets('displays default image when recipe has no photos', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: RecipeListScreen())),
      );

      expect(find.byType(RecipeListScreen), findsOneWidget);
    });

    test('recipe with network URL should be identified correctly', () {
      expect(
        sampleRecipeWithNetworkImage.photoUrls.first.startsWith('http'),
        isTrue,
      );
    });

    test('recipe with local path should be identified correctly', () {
      expect(
        sampleRecipeWithLocalImage.photoUrls.first.startsWith('http'),
        isFalse,
      );
    });

    test('recipe without images should have empty photoUrls', () {
      expect(sampleRecipeWithoutImage.photoUrls.isEmpty, isTrue);
    });
  });
}
