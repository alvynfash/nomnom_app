import 'package:flutter_test/flutter_test.dart';
import 'package:nomnom/models/deletion_validation_result.dart';
import 'package:nomnom/services/meal_plan_service.dart';
import '../helpers/meal_plan_test_helper.dart';

void main() {
  group('Recipe Deletion Integration Tests', () {
    late MealPlanService mealPlanService;

    setUp(() async {
      mealPlanService = MealPlanService();
      await mealPlanService.clearAllMealPlans();
    });

    tearDown(() async {
      await mealPlanService.clearAllMealPlans();
    });

    test('meal plan service can manage recipe references', () async {
      // Create test meal plans
      final activePlan = MealPlanTestHelper.createActiveMealPlan(
        name: 'This Week',
        familyId: 'family1',
        recipeIds: ['recipe1', 'recipe2'],
      );

      final inactivePlan = MealPlanTestHelper.createInactiveMealPlan(
        name: 'Last Week',
        familyId: 'family1',
        recipeIds: ['recipe1', 'recipe3'],
      );

      // Add meal plans
      await mealPlanService.addTestMealPlan(activePlan);
      await mealPlanService.addTestMealPlan(inactivePlan);

      // Test finding meal plans containing a recipe
      final plansWithRecipe1 = await mealPlanService
          .getMealPlansContainingRecipe('recipe1');
      expect(plansWithRecipe1, hasLength(2));

      final plansWithRecipe2 = await mealPlanService
          .getMealPlansContainingRecipe('recipe2');
      expect(plansWithRecipe2, hasLength(1));

      final plansWithRecipe4 = await mealPlanService
          .getMealPlansContainingRecipe('recipe4');
      expect(plansWithRecipe4, isEmpty);

      // Test finding active meal plans
      final activePlansWithRecipe1 = await mealPlanService
          .getActiveMealPlansContainingRecipe('recipe1');
      expect(activePlansWithRecipe1, hasLength(1));

      // Test removing recipe from meal plans
      await mealPlanService.removeRecipeFromAllMealPlans('recipe1');

      // Verify recipe was removed
      final plansAfterRemoval = await mealPlanService
          .getMealPlansContainingRecipe('recipe1');
      expect(plansAfterRemoval, isEmpty);

      // Verify other recipes are still there
      final plansWithRecipe2AfterRemoval = await mealPlanService
          .getMealPlansContainingRecipe('recipe2');
      expect(plansWithRecipe2AfterRemoval, hasLength(1));
    });

    test('deletion validation result provides correct information', () {
      // Test with active meal plan
      final activePlan = MealPlanTestHelper.createActiveMealPlan(
        id: 'active',
        name: 'Current Week',
        familyId: 'family1',
        recipeIds: ['recipe1'],
      );

      final activeWarning = DeletionWarning.activeMealPlan(activePlan);
      final resultWithActiveConflict = DeletionValidationResult.withWarnings(
        [activeWarning],
        [activePlan],
      );

      expect(resultWithActiveConflict.canDelete, isTrue);
      expect(resultWithActiveConflict.hasWarnings, isTrue);
      expect(resultWithActiveConflict.hasActiveMealPlanConflicts, isTrue);
      expect(
        resultWithActiveConflict.summaryMessage,
        contains('1 active meal plan'),
      );

      // Test with inactive meal plan
      final inactivePlan = MealPlanTestHelper.createInactiveMealPlan(
        id: 'inactive',
        name: 'Last Week',
        familyId: 'family1',
        recipeIds: ['recipe1'],
      );

      final inactiveWarning = DeletionWarning.inactiveMealPlan(inactivePlan);
      final resultWithInactiveUsage = DeletionValidationResult.withWarnings(
        [inactiveWarning],
        [inactivePlan],
      );

      expect(resultWithInactiveUsage.canDelete, isTrue);
      expect(resultWithInactiveUsage.hasWarnings, isTrue);
      expect(resultWithInactiveUsage.hasActiveMealPlanConflicts, isFalse);
      expect(resultWithInactiveUsage.summaryMessage, contains('1 meal plan'));
      expect(resultWithInactiveUsage.summaryMessage, isNot(contains('active')));

      // Test with no conflicts
      final noConflicts = DeletionValidationResult.allowed();
      expect(noConflicts.canDelete, isTrue);
      expect(noConflicts.hasWarnings, isFalse);
      expect(noConflicts.hasActiveMealPlanConflicts, isFalse);
      expect(
        noConflicts.summaryMessage,
        equals('Recipe can be safely deleted'),
      );
    });

    test('warning types have correct severity ordering', () {
      final inactivePlan = MealPlanTestHelper.createInactiveMealPlan(
        id: 'inactive',
        name: 'Inactive Plan',
        familyId: 'family1',
        recipeIds: ['recipe1'],
      );

      final activePlan = MealPlanTestHelper.createActiveMealPlan(
        id: 'active',
        name: 'Active Plan',
        familyId: 'family1',
        recipeIds: ['recipe1'],
      );

      final warnings = [
        DeletionWarning.generic('Generic warning'),
        DeletionWarning.inactiveMealPlan(inactivePlan),
        DeletionWarning.activeMealPlan(activePlan),
      ];

      // Sort by severity (highest first)
      warnings.sort((a, b) => b.type.severity.compareTo(a.type.severity));

      expect(warnings[0].type, equals(DeletionWarningType.activeMealPlan));
      expect(warnings[1].type, equals(DeletionWarningType.inactiveMealPlan));
      expect(warnings[2].type, equals(DeletionWarningType.generic));
    });

    test('meal plan date range formatting works correctly', () {
      final plan = MealPlanTestHelper.createTestMealPlan(
        id: 'test',
        name: 'Test Plan',
        familyId: 'family1',
        startDate: DateTime(2024, 3, 15),
      );

      // The date range for a 4-week meal plan starting March 15, 2024
      expect(plan.dateRange, equals('3/15 - 4/11'));
    });

    test('meal plan activity detection works correctly', () {
      // Currently active plan
      final activePlan = MealPlanTestHelper.createActiveMealPlan(
        id: 'active',
        name: 'Active Plan',
        familyId: 'family1',
        recipeIds: ['recipe1'],
      );

      // Past plan
      final pastPlan = MealPlanTestHelper.createInactiveMealPlan(
        id: 'past',
        name: 'Past Plan',
        familyId: 'family1',
        recipeIds: ['recipe1'],
      );

      // Future plan
      final futurePlan = MealPlanTestHelper.createFutureMealPlan(
        id: 'future',
        name: 'Future Plan',
        familyId: 'family1',
        recipeIds: ['recipe1'],
      );

      expect(activePlan.isCurrentlyActive, isTrue);
      expect(pastPlan.isCurrentlyActive, isFalse);
      expect(futurePlan.isCurrentlyActive, isFalse);
    });
  });
}
