import 'package:nomnom/models/meal_plan.dart';

/// Helper class for creating test MealPlan instances
class MealPlanTestHelper {
  /// Creates a test meal plan with the given parameters
  static MealPlan createTestMealPlan({
    String? id,
    required String name,
    required String familyId,
    required DateTime startDate,
    List<String>? mealSlots,
    Map<String, String?>? assignments,
    String? createdBy,
    bool isTemplate = false,
    String? templateName,
  }) {
    final plan = MealPlan.create(
      name: name,
      familyId: familyId,
      startDate: startDate,
      mealSlots: mealSlots ?? ['breakfast', 'lunch', 'dinner'],
      assignments: assignments ?? {},
      createdBy: createdBy ?? 'test-user',
      isTemplate: isTemplate,
      templateName: templateName,
    );

    // If a specific ID is needed, create a copy with that ID
    if (id != null) {
      return plan.copyWith(id: id);
    }

    return plan;
  }

  /// Creates an active meal plan (current date within the 4-week period)
  static MealPlan createActiveMealPlan({
    String? id,
    String name = 'Active Plan',
    String familyId = 'test-family',
    List<String>? recipeIds,
  }) {
    final now = DateTime.now();
    final startDate = now.subtract(
      const Duration(days: 7),
    ); // Started a week ago

    final assignments = <String, String?>{};
    if (recipeIds != null) {
      for (int i = 0; i < recipeIds.length && i < 3; i++) {
        final date = startDate.add(Duration(days: i));
        final dateStr = date.toIso8601String().split('T')[0];
        final slots = ['breakfast', 'lunch', 'dinner'];
        assignments['${dateStr}_${slots[i % slots.length]}'] = recipeIds[i];
      }
    }

    return createTestMealPlan(
      id: id,
      name: name,
      familyId: familyId,
      startDate: startDate,
      assignments: assignments,
    );
  }

  /// Creates an inactive meal plan (past date range)
  static MealPlan createInactiveMealPlan({
    String? id,
    String name = 'Inactive Plan',
    String familyId = 'test-family',
    List<String>? recipeIds,
  }) {
    final now = DateTime.now();
    final startDate = now.subtract(
      const Duration(days: 35),
    ); // Started 35 days ago (past)

    final assignments = <String, String?>{};
    if (recipeIds != null) {
      for (int i = 0; i < recipeIds.length && i < 3; i++) {
        final date = startDate.add(Duration(days: i));
        final dateStr = date.toIso8601String().split('T')[0];
        final slots = ['breakfast', 'lunch', 'dinner'];
        assignments['${dateStr}_${slots[i % slots.length]}'] = recipeIds[i];
      }
    }

    return createTestMealPlan(
      id: id,
      name: name,
      familyId: familyId,
      startDate: startDate,
      assignments: assignments,
    );
  }

  /// Creates a future meal plan (future date range)
  static MealPlan createFutureMealPlan({
    String? id,
    String name = 'Future Plan',
    String familyId = 'test-family',
    List<String>? recipeIds,
  }) {
    final now = DateTime.now();
    final startDate = now.add(const Duration(days: 7)); // Starts in a week

    final assignments = <String, String?>{};
    if (recipeIds != null) {
      for (int i = 0; i < recipeIds.length && i < 3; i++) {
        final date = startDate.add(Duration(days: i));
        final dateStr = date.toIso8601String().split('T')[0];
        final slots = ['breakfast', 'lunch', 'dinner'];
        assignments['${dateStr}_${slots[i % slots.length]}'] = recipeIds[i];
      }
    }

    return createTestMealPlan(
      id: id,
      name: name,
      familyId: familyId,
      startDate: startDate,
      assignments: assignments,
    );
  }

  /// Creates a meal plan with specific recipe assignments
  static MealPlan createMealPlanWithRecipes({
    String? id,
    String name = 'Plan with Recipes',
    String familyId = 'test-family',
    required List<String> recipeIds,
    DateTime? startDate,
  }) {
    final actualStartDate =
        startDate ?? DateTime.now().subtract(const Duration(days: 7));

    final assignments = <String, String?>{};
    for (int i = 0; i < recipeIds.length; i++) {
      final date = actualStartDate.add(Duration(days: i ~/ 3));
      final dateStr = date.toIso8601String().split('T')[0];
      final slots = ['breakfast', 'lunch', 'dinner'];
      assignments['${dateStr}_${slots[i % slots.length]}'] = recipeIds[i];
    }

    return createTestMealPlan(
      id: id,
      name: name,
      familyId: familyId,
      startDate: actualStartDate,
      assignments: assignments,
    );
  }
}
