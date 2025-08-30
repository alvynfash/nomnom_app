import 'package:flutter_test/flutter_test.dart';
import 'package:nomnom/services/recipe_service.dart';

void main() {
  group('RecipeService API Tests', () {
    group('RecipeSearchOptions', () {
      test('creates default search options correctly', () {
        const options = RecipeSearchOptions();

        expect(options.query, isNull);
        expect(options.tagFilters, isNull);
        expect(options.sortBy, equals(RecipeSortBy.updatedAt));
        expect(options.sortOrder, equals(SortOrder.descending));
        expect(options.maxResults, isNull);
        expect(options.searchInTitle, isTrue);
        expect(options.searchInIngredients, isTrue);
        expect(options.searchInInstructions, isFalse);
        expect(options.searchInTags, isTrue);
      });

      test('creates custom search options correctly', () {
        const options = RecipeSearchOptions(
          query: 'test',
          tagFilters: ['tag1', 'tag2'],
          sortBy: RecipeSortBy.title,
          sortOrder: SortOrder.ascending,
          maxResults: 10,
          searchInTitle: false,
          searchInIngredients: false,
          searchInInstructions: true,
          searchInTags: false,
        );

        expect(options.query, equals('test'));
        expect(options.tagFilters, equals(['tag1', 'tag2']));
        expect(options.sortBy, equals(RecipeSortBy.title));
        expect(options.sortOrder, equals(SortOrder.ascending));
        expect(options.maxResults, equals(10));
        expect(options.searchInTitle, isFalse);
        expect(options.searchInIngredients, isFalse);
        expect(options.searchInInstructions, isTrue);
        expect(options.searchInTags, isFalse);
      });
    });

    group('Enum Values', () {
      test('RecipeSortBy enum has all expected values', () {
        expect(RecipeSortBy.values, contains(RecipeSortBy.title));
        expect(RecipeSortBy.values, contains(RecipeSortBy.createdAt));
        expect(RecipeSortBy.values, contains(RecipeSortBy.updatedAt));
        expect(RecipeSortBy.values, contains(RecipeSortBy.prepTime));
        expect(RecipeSortBy.values, contains(RecipeSortBy.cookTime));
        expect(RecipeSortBy.values, contains(RecipeSortBy.totalTime));
        expect(RecipeSortBy.values.length, equals(6));
      });

      test('SortOrder enum has all expected values', () {
        expect(SortOrder.values, contains(SortOrder.ascending));
        expect(SortOrder.values, contains(SortOrder.descending));
        expect(SortOrder.values.length, equals(2));
      });
    });

    group('Service Instantiation', () {
      test('RecipeService can be instantiated', () {
        final service = RecipeService();
        expect(service, isA<RecipeService>());
      });

      test('RecipeService has required methods', () {
        final service = RecipeService();

        // Check that methods exist and are callable
        expect(service.searchRecipes, isA<Function>());
        expect(service.searchRecipesByQuery, isA<Function>());
        expect(service.searchRecipesByTags, isA<Function>());
        expect(service.getRecipesSorted, isA<Function>());
        expect(service.getAllTags, isA<Function>());
        expect(service.getTagsWithCount, isA<Function>());
        expect(service.getPopularTags, isA<Function>());
        expect(service.getTagSuggestions, isA<Function>());
      });
    });

    group('Input Validation Logic', () {
      test('getTagSuggestions handles empty string input', () async {
        final service = RecipeService();

        // This should not throw an exception and should return empty list
        final result = await service.getTagSuggestions('');
        expect(result, isA<List<String>>());
        expect(result, isEmpty);
      });

      test('getTagSuggestions handles whitespace input', () async {
        final service = RecipeService();

        // This should not throw an exception and should return empty list
        final result = await service.getTagSuggestions('   ');
        expect(result, isA<List<String>>());
        expect(result, isEmpty);
      });

      test('getTagSuggestions handles mixed whitespace input', () async {
        final service = RecipeService();

        // This should not throw an exception and should return empty list
        final result = await service.getTagSuggestions('  \t\n  ');
        expect(result, isA<List<String>>());
        expect(result, isEmpty);
      });
    });
  });
}
