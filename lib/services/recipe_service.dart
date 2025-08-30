import 'dart:developer' as developer;

import '../models/recipe.dart';
import '../models/deletion_validation_result.dart';
import 'storage_service.dart';
import 'photo_service.dart';
import 'meal_plan_service.dart';

/// Exception thrown by RecipeService operations
class RecipeServiceException implements Exception {
  final String message;
  final String code;

  RecipeServiceException(this.message, this.code);

  @override
  String toString() => 'RecipeServiceException: $message (code: $code)';
}

enum RecipeSortBy { title, createdAt, updatedAt, prepTime, cookTime, totalTime }

enum SortOrder { ascending, descending }

class RecipeSearchOptions {
  final String? query;
  final List<String>? tagFilters;
  final RecipeSortBy sortBy;
  final SortOrder sortOrder;
  final int? maxResults;
  final bool searchInTitle;
  final bool searchInIngredients;
  final bool searchInInstructions;
  final bool searchInTags;

  const RecipeSearchOptions({
    this.query,
    this.tagFilters,
    this.sortBy = RecipeSortBy.updatedAt,
    this.sortOrder = SortOrder.descending,
    this.maxResults,
    this.searchInTitle = true,
    this.searchInIngredients = true,
    this.searchInInstructions = false,
    this.searchInTags = true,
  });
}

class RecipeService {
  final StorageService _storageService = StorageService();
  final MealPlanService _mealPlanService = MealPlanService();

  Future<List<Recipe>> getRecipes({
    String? searchQuery,
    List<String>? tagFilters,
  }) async {
    return await searchRecipes(
      RecipeSearchOptions(query: searchQuery, tagFilters: tagFilters),
    );
  }

  /// Enhanced search method with comprehensive filtering and sorting options
  Future<List<Recipe>> searchRecipes(RecipeSearchOptions options) async {
    final recipes = await _storageService.loadRecipes();

    // Apply filters
    var filteredRecipes = recipes.where((recipe) {
      return _matchesSearchCriteria(recipe, options);
    }).toList();

    // Apply sorting
    _sortRecipes(filteredRecipes, options.sortBy, options.sortOrder);

    // Apply result limit
    if (options.maxResults != null && options.maxResults! > 0) {
      filteredRecipes = filteredRecipes.take(options.maxResults!).toList();
    }

    return filteredRecipes;
  }

  /// Simple search method for backward compatibility
  Future<List<Recipe>> searchRecipesByQuery(String query) async {
    return await searchRecipes(RecipeSearchOptions(query: query));
  }

  /// Search recipes by tags only
  Future<List<Recipe>> searchRecipesByTags(List<String> tags) async {
    return await searchRecipes(RecipeSearchOptions(tagFilters: tags));
  }

  /// Get recipes sorted by specific criteria
  Future<List<Recipe>> getRecipesSorted({
    RecipeSortBy sortBy = RecipeSortBy.updatedAt,
    SortOrder sortOrder = SortOrder.descending,
  }) async {
    return await searchRecipes(
      RecipeSearchOptions(sortBy: sortBy, sortOrder: sortOrder),
    );
  }

  bool _matchesSearchCriteria(Recipe recipe, RecipeSearchOptions options) {
    bool matchesSearch = true;
    bool matchesTags = true;

    // Text search
    if (options.query != null && options.query!.isNotEmpty) {
      final query = options.query!.toLowerCase().trim();
      matchesSearch = false;

      // Search in title
      if (options.searchInTitle && recipe.title.toLowerCase().contains(query)) {
        matchesSearch = true;
      }

      // Search in ingredients
      if (!matchesSearch && options.searchInIngredients) {
        matchesSearch = recipe.ingredients.any(
          (ingredient) => ingredient.name.toLowerCase().contains(query),
        );
      }

      // Search in instructions
      if (!matchesSearch && options.searchInInstructions) {
        matchesSearch = recipe.instructions.any(
          (instruction) => instruction.toLowerCase().contains(query),
        );
      }

      // Search in tags
      if (!matchesSearch && options.searchInTags) {
        matchesSearch = recipe.tags.any(
          (tag) => tag.toLowerCase().contains(query),
        );
      }
    }

    // Tag filtering
    if (options.tagFilters != null && options.tagFilters!.isNotEmpty) {
      matchesTags = options.tagFilters!.every(
        (filter) =>
            recipe.tags.any((tag) => tag.toLowerCase() == filter.toLowerCase()),
      );
    }

    return matchesSearch && matchesTags;
  }

  void _sortRecipes(
    List<Recipe> recipes,
    RecipeSortBy sortBy,
    SortOrder sortOrder,
  ) {
    recipes.sort((a, b) {
      int comparison = 0;

      switch (sortBy) {
        case RecipeSortBy.title:
          comparison = a.title.toLowerCase().compareTo(b.title.toLowerCase());
          break;
        case RecipeSortBy.createdAt:
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
        case RecipeSortBy.updatedAt:
          comparison = a.updatedAt.compareTo(b.updatedAt);
          break;
        case RecipeSortBy.prepTime:
          comparison = a.prepTime.compareTo(b.prepTime);
          break;
        case RecipeSortBy.cookTime:
          comparison = a.cookTime.compareTo(b.cookTime);
          break;
        case RecipeSortBy.totalTime:
          final totalTimeA = a.prepTime + a.cookTime;
          final totalTimeB = b.prepTime + b.cookTime;
          comparison = totalTimeA.compareTo(totalTimeB);
          break;
      }

      return sortOrder == SortOrder.ascending ? comparison : -comparison;
    });
  }

  /// Creates a new recipe with enhanced error handling and validation
  Future<Recipe> createRecipe(Recipe recipe) async {
    try {
      // Validate recipe data before saving
      _validateRecipeData(recipe);

      // Ensure unique ID
      if (await _storageService.getRecipeById(recipe.id) != null) {
        throw RecipeServiceException(
          'Recipe with ID ${recipe.id} already exists',
          'DUPLICATE_ID',
        );
      }

      await _storageService.saveRecipe(recipe);
      return recipe;
    } catch (e) {
      if (e is RecipeServiceException) {
        rethrow;
      }
      throw RecipeServiceException(
        'Failed to create recipe: ${e.toString()}',
        'CREATE_ERROR',
      );
    }
  }

  /// Updates an existing recipe with enhanced error handling
  Future<Recipe> updateRecipe(String id, Recipe updatedRecipe) async {
    try {
      // Validate recipe data before updating
      _validateRecipeData(updatedRecipe);

      final existingRecipe = await _storageService.getRecipeById(id);
      if (existingRecipe == null) {
        throw RecipeServiceException(
          'Recipe with ID $id not found',
          'RECIPE_NOT_FOUND',
        );
      }

      // Ensure the updated recipe has the correct ID
      if (updatedRecipe.id != id) {
        throw RecipeServiceException(
          'Recipe ID mismatch: expected $id, got ${updatedRecipe.id}',
          'ID_MISMATCH',
        );
      }

      await _storageService.saveRecipe(updatedRecipe);
      return updatedRecipe;
    } catch (e) {
      if (e is RecipeServiceException) {
        rethrow;
      }
      throw RecipeServiceException(
        'Failed to update recipe: ${e.toString()}',
        'UPDATE_ERROR',
      );
    }
  }

  /// Deletes a recipe with enhanced error handling and validation
  Future<void> deleteRecipe(String id) async {
    try {
      // Check if recipe exists
      final existingRecipe = await _storageService.getRecipeById(id);
      if (existingRecipe == null) {
        throw RecipeServiceException(
          'Recipe with ID $id not found',
          'RECIPE_NOT_FOUND',
        );
      }

      // Validate deletion (check for meal plan usage, etc.)
      await validateRecipeForDeletion(id);

      // Remove recipe from all meal plans
      try {
        await _mealPlanService.removeRecipeFromAllMealPlans(id);
      } catch (e) {
        developer.log(
          'Warning: Failed to remove recipe from meal plans: $e',
          name: 'RecipeService',
          level: 900, // Warning level
        );
      }

      // Delete associated photos first
      try {
        final photoService = PhotoService();
        await photoService.deleteAllRecipePhotos(id);
      } catch (e) {
        // Log photo deletion error but don't fail the recipe deletion
        developer.log(
          'Warning: Failed to delete photos for recipe $id: $e',
          name: 'RecipeService',
          level: 900, // Warning level
        );
      }

      await _storageService.deleteRecipe(id);
    } catch (e) {
      if (e is RecipeServiceException) {
        rethrow;
      }
      throw RecipeServiceException(
        'Failed to delete recipe: ${e.toString()}',
        'DELETE_ERROR',
      );
    }
  }

  /// Gets a recipe by ID with error handling
  Future<Recipe?> getRecipeById(String id) async {
    try {
      if (id.trim().isEmpty) {
        throw RecipeServiceException('Recipe ID cannot be empty', 'INVALID_ID');
      }

      return await _storageService.getRecipeById(id);
    } catch (e) {
      if (e is RecipeServiceException) {
        rethrow;
      }
      throw RecipeServiceException(
        'Failed to get recipe: ${e.toString()}',
        'GET_ERROR',
      );
    }
  }

  /// Validates recipe data for consistency and completeness
  void _validateRecipeData(Recipe recipe) {
    if (recipe.id.trim().isEmpty) {
      throw RecipeServiceException('Recipe ID cannot be empty', 'INVALID_ID');
    }

    if (recipe.title.trim().isEmpty) {
      throw RecipeServiceException(
        'Recipe title cannot be empty',
        'INVALID_TITLE',
      );
    }

    if (recipe.ingredients.isEmpty) {
      throw RecipeServiceException(
        'Recipe must have at least one ingredient',
        'NO_INGREDIENTS',
      );
    }

    if (recipe.instructions.isEmpty) {
      throw RecipeServiceException(
        'Recipe must have at least one instruction',
        'NO_INSTRUCTIONS',
      );
    }

    if (recipe.prepTime < 0 || recipe.cookTime < 0) {
      throw RecipeServiceException(
        'Prep time and cook time must be non-negative',
        'INVALID_TIME',
      );
    }

    if (recipe.servings <= 0) {
      throw RecipeServiceException(
        'Servings must be greater than zero',
        'INVALID_SERVINGS',
      );
    }

    // Validate ingredients
    for (final ingredient in recipe.ingredients) {
      if (ingredient.name.trim().isEmpty) {
        throw RecipeServiceException(
          'Ingredient name cannot be empty',
          'INVALID_INGREDIENT',
        );
      }
      if (ingredient.quantity <= 0) {
        throw RecipeServiceException(
          'Ingredient quantity must be greater than zero',
          'INVALID_QUANTITY',
        );
      }
      if (ingredient.unit.trim().isEmpty) {
        throw RecipeServiceException(
          'Ingredient unit cannot be empty',
          'INVALID_UNIT',
        );
      }
    }

    // Validate instructions
    for (final instruction in recipe.instructions) {
      if (instruction.trim().isEmpty) {
        throw RecipeServiceException(
          'Instruction cannot be empty',
          'INVALID_INSTRUCTION',
        );
      }
    }
  }

  /// Get all unique tags from all recipes
  Future<List<String>> getAllTags() async {
    return await _storageService.getAllTags();
  }

  /// Get tags with usage count
  Future<Map<String, int>> getTagsWithCount() async {
    final recipes = await _storageService.loadRecipes();
    final tagCounts = <String, int>{};

    for (final recipe in recipes) {
      for (final tag in recipe.tags) {
        final normalizedTag = tag.trim().toLowerCase();
        if (normalizedTag.isNotEmpty) {
          tagCounts[normalizedTag] = (tagCounts[normalizedTag] ?? 0) + 1;
        }
      }
    }

    return tagCounts;
  }

  /// Get most popular tags (sorted by usage count)
  Future<List<String>> getPopularTags({int limit = 10}) async {
    final tagCounts = await getTagsWithCount();
    final sortedTags = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedTags.take(limit).map((entry) => entry.key).toList();
  }

  /// Get tag suggestions based on partial input
  Future<List<String>> getTagSuggestions(
    String partialTag, {
    int limit = 5,
  }) async {
    if (partialTag.trim().isEmpty) return [];

    final allTags = await getAllTags();
    final query = partialTag.toLowerCase().trim();

    final suggestions = allTags
        .where((tag) => tag.toLowerCase().contains(query))
        .toList();

    // Sort by relevance (exact matches first, then starts with, then contains)
    suggestions.sort((a, b) {
      final aLower = a.toLowerCase();
      final bLower = b.toLowerCase();

      // Exact match
      if (aLower == query) return -1;
      if (bLower == query) return 1;

      // Starts with
      if (aLower.startsWith(query) && !bLower.startsWith(query)) return -1;
      if (bLower.startsWith(query) && !aLower.startsWith(query)) return 1;

      // Alphabetical for same relevance
      return aLower.compareTo(bLower);
    });

    return suggestions.take(limit).toList();
  }

  /// Validates if a recipe can be safely deleted
  Future<void> validateRecipeForDeletion(String id) async {
    try {
      final recipe = await getRecipeById(id);
      if (recipe == null) {
        throw RecipeServiceException(
          'Recipe with ID $id not found',
          'RECIPE_NOT_FOUND',
        );
      }

      // Get detailed validation result
      final validationResult = await getRecipeDeletionValidation(id);

      // If there are active meal plan conflicts, throw an exception
      if (validationResult.hasActiveMealPlanConflicts) {
        final activePlans = validationResult.affectedMealPlans
            .where((plan) => plan.isCurrentlyActive)
            .toList();

        final planNames = activePlans.map((plan) => plan.name).join(', ');
        throw RecipeServiceException(
          'Cannot delete recipe: it is currently used in active meal plan(s): $planNames',
          'ACTIVE_MEAL_PLAN_CONFLICT',
        );
      }
    } catch (e) {
      if (e is RecipeServiceException) {
        rethrow;
      }
      throw RecipeServiceException(
        'Failed to validate recipe for deletion: ${e.toString()}',
        'VALIDATION_ERROR',
      );
    }
  }

  /// Gets detailed validation information for recipe deletion
  Future<DeletionValidationResult> getRecipeDeletionValidation(
    String id,
  ) async {
    try {
      final recipe = await getRecipeById(id);
      if (recipe == null) {
        throw RecipeServiceException(
          'Recipe with ID $id not found',
          'RECIPE_NOT_FOUND',
        );
      }

      // Check meal plan usage
      final affectedMealPlans = await _mealPlanService
          .getMealPlansContainingRecipe(id);

      if (affectedMealPlans.isEmpty) {
        return DeletionValidationResult.allowed();
      }

      // Create warnings for each affected meal plan
      final warnings = <DeletionWarning>[];

      for (final mealPlan in affectedMealPlans) {
        if (mealPlan.isCurrentlyActive) {
          warnings.add(DeletionWarning.activeMealPlan(mealPlan));
        } else {
          warnings.add(DeletionWarning.inactiveMealPlan(mealPlan));
        }
      }

      // Sort warnings by severity (most severe first)
      warnings.sort((a, b) => b.type.severity.compareTo(a.type.severity));

      // Determine if deletion should be blocked
      // For now, we'll allow deletion but warn about active meal plans
      // In a stricter implementation, you might block deletion of recipes in active meal plans
      return DeletionValidationResult.withWarnings(warnings, affectedMealPlans);
    } catch (e) {
      if (e is RecipeServiceException) {
        rethrow;
      }
      throw RecipeServiceException(
        'Failed to get deletion validation for recipe $id: ${e.toString()}',
        'VALIDATION_ERROR',
      );
    }
  }

  /// Batch creates multiple recipes with transaction support
  Future<List<Recipe>> createRecipes(List<Recipe> recipes) async {
    try {
      final createdRecipes = <Recipe>[];

      for (final recipe in recipes) {
        final createdRecipe = await createRecipe(recipe);
        createdRecipes.add(createdRecipe);
      }

      return createdRecipes;
    } catch (e) {
      throw RecipeServiceException(
        'Failed to create recipes in batch: ${e.toString()}',
        'BATCH_CREATE_ERROR',
      );
    }
  }

  /// Batch updates multiple recipes
  Future<List<Recipe>> updateRecipes(Map<String, Recipe> recipeUpdates) async {
    try {
      final updatedRecipes = <Recipe>[];

      for (final entry in recipeUpdates.entries) {
        final updatedRecipe = await updateRecipe(entry.key, entry.value);
        updatedRecipes.add(updatedRecipe);
      }

      return updatedRecipes;
    } catch (e) {
      throw RecipeServiceException(
        'Failed to update recipes in batch: ${e.toString()}',
        'BATCH_UPDATE_ERROR',
      );
    }
  }

  /// Batch deletes multiple recipes
  Future<void> deleteRecipes(List<String> recipeIds) async {
    try {
      for (final id in recipeIds) {
        await deleteRecipe(id);
      }
    } catch (e) {
      throw RecipeServiceException(
        'Failed to delete recipes in batch: ${e.toString()}',
        'BATCH_DELETE_ERROR',
      );
    }
  }

  /// Migrates recipe data to ensure compatibility with current schema
  Future<void> migrateRecipeData() async {
    try {
      final recipes = await _storageService.loadRecipes();
      bool migrationNeeded = false;

      for (final recipe in recipes) {
        // Check if migration is needed for this recipe
        if (_needsMigration(recipe)) {
          migrationNeeded = true;
          final migratedRecipe = _migrateRecipe(recipe);
          await _storageService.saveRecipe(migratedRecipe);
        }
      }

      if (migrationNeeded) {
        developer.log(
          'Recipe data migration completed successfully',
          name: 'RecipeService',
          level: 800, // Info level
        );
      }
    } catch (e) {
      throw RecipeServiceException(
        'Failed to migrate recipe data: ${e.toString()}',
        'MIGRATION_ERROR',
      );
    }
  }

  /// Checks if a recipe needs migration
  bool _needsMigration(Recipe recipe) {
    // Check for missing or invalid data that needs migration

    // Check if familyId is missing (older recipes might not have this)
    if (recipe.familyId.isEmpty) {
      return true;
    }

    // Check if photoUrls field is missing (older recipes might not have this)
    // This is handled by the Recipe model, but we can add additional checks

    // Check for invalid timestamps
    if (recipe.createdAt.year < 2020 || recipe.updatedAt.year < 2020) {
      return true;
    }

    return false;
  }

  /// Migrates a recipe to the current schema
  Recipe _migrateRecipe(Recipe recipe) {
    return Recipe(
      id: recipe.id,
      title: recipe.title,
      ingredients: recipe.ingredients,
      instructions: recipe.instructions,
      prepTime: recipe.prepTime,
      cookTime: recipe.cookTime,
      servings: recipe.servings,
      tags: recipe.tags,
      photoUrls: recipe.photoUrls,
      isPrivate: recipe.isPrivate,
      isPublished: recipe.isPublished,
      familyId: recipe.familyId.isEmpty ? 'default' : recipe.familyId,
      createdAt: recipe.createdAt.year < 2020
          ? DateTime.now()
          : recipe.createdAt,
      updatedAt: DateTime.now(), // Always update the timestamp during migration
    );
  }

  /// Gets database statistics for monitoring and debugging
  Future<Map<String, dynamic>> getDatabaseStats() async {
    try {
      final recipes = await _storageService.loadRecipes();
      final tags = await getAllTags();

      // Calculate photo statistics
      final photoService = PhotoService();
      final totalPhotoSize = await photoService.getAllPhotosTotalSize();

      return {
        'totalRecipes': recipes.length,
        'totalTags': tags.length,
        'totalPhotoSize': totalPhotoSize,
        'totalPhotoSizeFormatted': _formatFileSize(totalPhotoSize),
        'averageIngredientsPerRecipe': recipes.isEmpty
            ? 0.0
            : recipes.map((r) => r.ingredients.length).reduce((a, b) => a + b) /
                  recipes.length,
        'averageTagsPerRecipe': recipes.isEmpty
            ? 0.0
            : recipes.map((r) => r.tags.length).reduce((a, b) => a + b) /
                  recipes.length,
        'recipesWithPhotos': recipes
            .where((r) => r.photoUrls.isNotEmpty)
            .length,
        'oldestRecipe': recipes.isEmpty
            ? null
            : recipes
                  .map((r) => r.createdAt)
                  .reduce((a, b) => a.isBefore(b) ? a : b),
        'newestRecipe': recipes.isEmpty
            ? null
            : recipes
                  .map((r) => r.createdAt)
                  .reduce((a, b) => a.isAfter(b) ? a : b),
      };
    } catch (e) {
      throw RecipeServiceException(
        'Failed to get database statistics: ${e.toString()}',
        'STATS_ERROR',
      );
    }
  }

  /// Performs database cleanup operations
  Future<Map<String, dynamic>> cleanupDatabase() async {
    try {
      final recipes = await _storageService.loadRecipes();
      final recipeIds = recipes.map((r) => r.id).toList();

      // Cleanup orphaned photos
      final photoService = PhotoService();
      final deletedPhotos = await photoService.cleanupOrphanedPhotos(recipeIds);

      return {
        'deletedPhotos': deletedPhotos.length,
        'deletedPhotosList': deletedPhotos,
      };
    } catch (e) {
      throw RecipeServiceException(
        'Failed to cleanup database: ${e.toString()}',
        'CLEANUP_ERROR',
      );
    }
  }

  /// Formats file size in human-readable format
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Exports all recipes to a JSON-serializable format
  Future<List<Map<String, dynamic>>> exportRecipes() async {
    try {
      final recipes = await _storageService.loadRecipes();
      return recipes.map((recipe) => recipe.toJson()).toList();
    } catch (e) {
      throw RecipeServiceException(
        'Failed to export recipes: ${e.toString()}',
        'EXPORT_ERROR',
      );
    }
  }

  /// Imports recipes from a JSON format with validation
  Future<List<Recipe>> importRecipes(
    List<Map<String, dynamic>> recipesJson,
  ) async {
    try {
      final importedRecipes = <Recipe>[];

      for (final recipeJson in recipesJson) {
        try {
          final recipe = Recipe.fromJson(recipeJson);
          _validateRecipeData(recipe);

          // Check if recipe already exists
          final existingRecipe = await _storageService.getRecipeById(recipe.id);
          if (existingRecipe != null) {
            // Skip or update existing recipe based on timestamps
            if (recipe.updatedAt.isAfter(existingRecipe.updatedAt)) {
              await _storageService.saveRecipe(recipe);
              importedRecipes.add(recipe);
            }
          } else {
            await _storageService.saveRecipe(recipe);
            importedRecipes.add(recipe);
          }
        } catch (e) {
          // Log individual recipe import errors but continue with others
          developer.log(
            'Warning: Failed to import recipe: $e',
            name: 'RecipeService',
            level: 900, // Warning level
          );
        }
      }

      return importedRecipes;
    } catch (e) {
      throw RecipeServiceException(
        'Failed to import recipes: ${e.toString()}',
        'IMPORT_ERROR',
      );
    }
  }
}
