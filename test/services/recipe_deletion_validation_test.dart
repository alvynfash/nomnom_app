import 'package:flutter_test/flutter_test.dart';
import 'package:nomnom/models/deletion_validation_result.dart';
import '../helpers/meal_plan_test_helper.dart';

void main() {
  group('Recipe Deletion Validation', () {
    group('DeletionValidationResult', () {
      test('creates result with warnings correctly', () {
        final mealPlan = MealPlanTestHelper.createActiveMealPlan(
          id: 'plan1',
          name: 'Test Plan',
          familyId: 'family1',
          recipeIds: ['recipe1'],
        );

        final warnings = [DeletionWarning.activeMealPlan(mealPlan)];
        final result = DeletionValidationResult.withWarnings(warnings, [
          mealPlan,
        ]);

        expect(result.canDelete, isTrue);
        expect(result.hasWarnings, isTrue);
        expect(result.warnings, equals(warnings));
        expect(result.affectedMealPlans, contains(mealPlan));
        expect(result.hasActiveMealPlanConflicts, isTrue);
      });

      test('creates blocked result correctly', () {
        final mealPlan = MealPlanTestHelper.createActiveMealPlan(
          id: 'plan1',
          name: 'Test Plan',
          familyId: 'family1',
          recipeIds: ['recipe1'],
        );

        final warnings = [DeletionWarning.activeMealPlan(mealPlan)];
        final result = DeletionValidationResult.blocked(warnings, [mealPlan]);

        expect(result.canDelete, isFalse);
        expect(result.hasWarnings, isTrue);
        expect(result.warnings, equals(warnings));
        expect(result.affectedMealPlans, contains(mealPlan));
        expect(result.hasActiveMealPlanConflicts, isTrue);
      });

      test('creates allowed result correctly', () {
        final result = DeletionValidationResult.allowed();

        expect(result.canDelete, isTrue);
        expect(result.hasWarnings, isFalse);
        expect(result.warnings, isEmpty);
        expect(result.affectedMealPlans, isEmpty);
        expect(result.hasActiveMealPlanConflicts, isFalse);
      });
    });

    group('DeletionWarning', () {
      test('creates active meal plan warning correctly', () {
        final mealPlan = MealPlanTestHelper.createActiveMealPlan(
          id: 'plan1',
          name: 'Weekly Plan',
          familyId: 'family1',
          recipeIds: ['recipe1'],
        );

        final warning = DeletionWarning.activeMealPlan(mealPlan);

        expect(warning.type, equals(DeletionWarningType.activeMealPlan));
        expect(warning.message, contains('Weekly Plan'));
        expect(warning.message, contains('active meal plan'));
        expect(warning.mealPlanId, equals(mealPlan.id));
        expect(warning.mealPlanName, equals(mealPlan.name));
      });

      test('creates inactive meal plan warning correctly', () {
        final mealPlan = MealPlanTestHelper.createInactiveMealPlan(
          id: 'plan2',
          name: 'Old Plan',
          familyId: 'family1',
          recipeIds: ['recipe1'],
        );

        final warning = DeletionWarning.inactiveMealPlan(mealPlan);

        expect(warning.type, equals(DeletionWarningType.inactiveMealPlan));
        expect(warning.message, contains('Old Plan'));
        expect(warning.message, contains('meal plan'));
        expect(warning.mealPlanId, equals(mealPlan.id));
        expect(warning.mealPlanName, equals(mealPlan.name));
      });

      test('creates generic warning correctly', () {
        const message = 'This is a generic warning';
        final warning = DeletionWarning.generic(message);

        expect(warning.type, equals(DeletionWarningType.generic));
        expect(warning.message, equals(message));
        expect(warning.mealPlanId, isNull);
        expect(warning.mealPlanName, isNull);
      });

      test('warning types have correct severity values', () {
        expect(
          DeletionWarningType.activeMealPlan.severity,
          greaterThan(DeletionWarningType.inactiveMealPlan.severity),
        );
        expect(
          DeletionWarningType.inactiveMealPlan.severity,
          greaterThan(DeletionWarningType.generic.severity),
        );
      });

      test('warning types have correct descriptions', () {
        expect(
          DeletionWarningType.activeMealPlan.description,
          equals('Active Meal Plan Usage'),
        );
        expect(
          DeletionWarningType.inactiveMealPlan.description,
          equals('Meal Plan Usage'),
        );
        expect(DeletionWarningType.generic.description, equals('Warning'));
      });
    });

    group('MealPlan Model', () {
      test('containsRecipe works correctly', () {
        final mealPlan = MealPlanTestHelper.createMealPlanWithRecipes(
          id: 'plan1',
          name: 'Test Plan',
          familyId: 'family1',
          recipeIds: ['recipe1', 'recipe2', 'recipe3'],
        );

        expect(mealPlan.containsRecipe('recipe1'), isTrue);
        expect(mealPlan.containsRecipe('recipe2'), isTrue);
        expect(mealPlan.containsRecipe('recipe3'), isTrue);
        expect(mealPlan.containsRecipe('recipe4'), isFalse);
        expect(mealPlan.containsRecipe(''), isFalse);
      });

      test('isCurrentlyActive works correctly', () {
        // Active plan (current date within range)
        final activePlan = MealPlanTestHelper.createActiveMealPlan(
          id: 'active',
          name: 'Active Plan',
          familyId: 'family1',
          recipeIds: ['recipe1'],
        );

        // Inactive plan (past date range)
        final inactivePlan = MealPlanTestHelper.createInactiveMealPlan(
          id: 'inactive',
          name: 'Inactive Plan',
          familyId: 'family1',
          recipeIds: ['recipe1'],
        );

        // Future plan (date range in the future)
        final futurePlan = MealPlanTestHelper.createFutureMealPlan(
          id: 'future',
          name: 'Future Plan',
          familyId: 'family1',
          recipeIds: ['recipe1'],
        );

        expect(activePlan.isCurrentlyActive, isTrue);
        expect(inactivePlan.isCurrentlyActive, isFalse);
        expect(futurePlan.isCurrentlyActive, isFalse);
      });

      test('dateRange formats correctly', () {
        final mealPlan = MealPlanTestHelper.createTestMealPlan(
          id: 'plan1',
          name: 'Test Plan',
          familyId: 'family1',
          startDate: DateTime(2024, 3, 15),
        );

        // 4-week meal plan starting March 15, 2024 ends April 11, 2024
        expect(mealPlan.dateRange, equals('3/15 - 4/11'));
      });
    });

    group('Summary Messages', () {
      test('generates correct summary for single active meal plan', () {
        final activePlan = MealPlanTestHelper.createActiveMealPlan(
          name: 'Current Week',
          familyId: 'family1',
          recipeIds: ['recipe1'],
        );

        final warnings = [DeletionWarning.activeMealPlan(activePlan)];
        final result = DeletionValidationResult.withWarnings(warnings, [
          activePlan,
        ]);

        expect(result.summaryMessage, contains('1 active meal plan'));
      });

      test('generates correct summary for multiple meal plans', () {
        final activePlan = MealPlanTestHelper.createActiveMealPlan(
          name: 'Active Plan',
          familyId: 'family1',
          recipeIds: ['recipe1'],
        );

        final inactivePlan = MealPlanTestHelper.createInactiveMealPlan(
          name: 'Inactive Plan',
          familyId: 'family1',
          recipeIds: ['recipe1'],
        );

        final warnings = [
          DeletionWarning.activeMealPlan(activePlan),
          DeletionWarning.inactiveMealPlan(inactivePlan),
        ];

        final result = DeletionValidationResult.withWarnings(warnings, [
          activePlan,
          inactivePlan,
        ]);

        expect(result.summaryMessage, contains('1 active meal plan'));
      });

      test('generates correct summary for inactive meal plans only', () {
        final inactivePlan = MealPlanTestHelper.createInactiveMealPlan(
          name: 'Old Plan',
          familyId: 'family1',
          recipeIds: ['recipe1'],
        );

        final warnings = [DeletionWarning.inactiveMealPlan(inactivePlan)];
        final result = DeletionValidationResult.withWarnings(warnings, [
          inactivePlan,
        ]);

        expect(result.summaryMessage, contains('1 meal plan'));
        expect(result.summaryMessage, isNot(contains('active')));
      });

      test('generates correct summary for allowed deletion', () {
        final result = DeletionValidationResult.allowed();
        expect(result.summaryMessage, equals('Recipe can be safely deleted'));
      });
    });

    group('Integration Scenarios', () {
      test('warning sorting by severity works correctly', () {
        final activePlan = MealPlanTestHelper.createActiveMealPlan(
          id: 'active',
          name: 'Active Plan',
          familyId: 'family1',
          recipeIds: ['recipe1'],
        );

        final inactivePlan = MealPlanTestHelper.createInactiveMealPlan(
          id: 'inactive',
          name: 'Inactive Plan',
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

      test('complex deletion scenario with mixed conflicts', () {
        // Active meal plan conflict
        final activePlan = MealPlanTestHelper.createActiveMealPlan(
          id: 'active',
          name: 'Active Plan',
          familyId: 'family1',
          recipeIds: ['recipe1'],
        );

        final activeWarnings = [DeletionWarning.activeMealPlan(activePlan)];
        final activeConflict = DeletionValidationResult.withWarnings(
          activeWarnings,
          [activePlan],
        );

        // Inactive meal plan usage
        final inactivePlan = MealPlanTestHelper.createInactiveMealPlan(
          id: 'inactive',
          name: 'Inactive Plan',
          familyId: 'family1',
          recipeIds: ['recipe1'],
        );

        final inactiveWarnings = [
          DeletionWarning.inactiveMealPlan(inactivePlan),
        ];
        final inactiveUsage = DeletionValidationResult.withWarnings(
          inactiveWarnings,
          [inactivePlan],
        );

        // Verify different handling
        expect(activeConflict.hasActiveMealPlanConflicts, isTrue);
        expect(inactiveUsage.hasActiveMealPlanConflicts, isFalse);

        expect(activeConflict.canDelete, isTrue);
        expect(inactiveUsage.canDelete, isTrue);

        expect(activeConflict.summaryMessage, contains('1 active meal plan'));
        expect(inactiveUsage.summaryMessage, contains('1 meal plan'));
        expect(inactiveUsage.summaryMessage, isNot(contains('active')));
      });
    });
  });
}
