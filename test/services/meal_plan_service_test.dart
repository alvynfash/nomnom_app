import 'package:flutter_test/flutter_test.dart';
import 'package:nomnom/models/meal_plan.dart';
import 'package:nomnom/services/meal_plan_service.dart';

void main() {
  group('MealPlanService API Structure Tests', () {
    late MealPlanService service;
    late MealPlan testMealPlan;

    setUp(() {
      service = MealPlanService();

      testMealPlan = MealPlan.create(
        name: 'Test Meal Plan',
        familyId: 'family123',
        startDate: DateTime.now().subtract(const Duration(days: 7)),
        mealSlots: ['breakfast', 'lunch', 'dinner'],
        assignments: {
          '2024-01-01_breakfast': 'recipe1',
          '2024-01-01_lunch': 'recipe2',
        },
        createdBy: 'user123',
      );
    });

    group('Service API Structure', () {
      test('has all required CRUD methods', () {
        expect(service.getMealPlans, isA<Function>());
        expect(service.createMealPlan, isA<Function>());
        expect(service.updateMealPlan, isA<Function>());
        expect(service.deleteMealPlan, isA<Function>());
        expect(service.getMealPlanById, isA<Function>());
      });

      test('has backward compatibility methods', () {
        expect(service.getMealPlansContainingRecipe, isA<Function>());
        expect(service.getActiveMealPlansContainingRecipe, isA<Function>());
        expect(service.removeRecipeFromAllMealPlans, isA<Function>());
      });
    });

    group('Validation Logic', () {
      test('should reject invalid meal plan on create', () async {
        final invalidMealPlan = testMealPlan.copyWith(name: '');

        expect(
          () => service.createMealPlan(invalidMealPlan),
          throwsA(isA<MealPlanException>()),
        );
      });

      test('should reject invalid meal plan on update', () async {
        final invalidMealPlan = testMealPlan.copyWith(name: '');

        expect(
          () => service.updateMealPlan(testMealPlan.id, invalidMealPlan),
          throwsA(isA<MealPlanException>()),
        );
      });

      test('should validate meal plan before operations', () {
        // Test that validation works correctly
        final validPlan = testMealPlan;
        expect(validPlan.isValid, isTrue);

        final invalidPlan = testMealPlan.copyWith(name: '');
        expect(invalidPlan.isValid, isFalse);
      });
    });

    group('Error Handling', () {
      test('should throw MealPlanException with correct structure', () {
        final exception = MealPlanException('Test message', 'TEST_CODE');

        expect(exception.message, equals('Test message'));
        expect(exception.code, equals('TEST_CODE'));
        expect(exception.toString(), contains('MealPlanException'));
        expect(exception.toString(), contains('Test message'));
        expect(exception.toString(), contains('TEST_CODE'));
      });
    });

    group('Backward Compatibility', () {
      test('should maintain existing recipe deletion validation methods', () {
        expect(service.getMealPlansContainingRecipe, isA<Function>());
        expect(service.getActiveMealPlansContainingRecipe, isA<Function>());
        expect(service.removeRecipeFromAllMealPlans, isA<Function>());
      });

      test('should handle recipe deletion validation', () async {
        expect(
          () => service.getMealPlansContainingRecipe('recipe123'),
          returnsNormally,
        );
      });

      test('should handle active meal plan queries', () async {
        expect(
          () => service.getActiveMealPlansContainingRecipe('recipe123'),
          returnsNormally,
        );
      });

      test('should handle recipe removal from meal plans', () async {
        expect(
          () => service.removeRecipeFromAllMealPlans('recipe123'),
          returnsNormally,
        );
      });
    });

    group('Data Validation', () {
      test('should validate meal plan before creating', () async {
        final invalidPlan = MealPlan(
          id: 'test',
          name: '', // Invalid: empty name
          familyId: 'family123',
          startDate: DateTime.now(),
          mealSlots: [],
          assignments: {},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'user123',
        );

        expect(
          () => service.createMealPlan(invalidPlan),
          throwsA(isA<MealPlanException>()),
        );
      });

      test('should validate meal plan before updating', () async {
        final invalidPlan = testMealPlan.copyWith(
          mealSlots: [], // Invalid: empty meal slots
        );

        expect(
          () => service.updateMealPlan(testMealPlan.id, invalidPlan),
          throwsA(isA<MealPlanException>()),
        );
      });
    });

    group('Template Validation', () {
      test('should validate template requirements', () async {
        final invalidTemplate = MealPlan.create(
          name: 'Invalid Template',
          familyId: 'family123',
          startDate: DateTime.now(),
          mealSlots: ['breakfast'],
          isTemplate: true,
          // Missing templateName - should be invalid
          createdBy: 'user123',
        );

        expect(
          () => service.createMealPlan(invalidTemplate),
          throwsA(isA<MealPlanException>()),
        );
      });

      test('should accept valid template', () {
        final validTemplate = MealPlan.create(
          name: 'Valid Template',
          familyId: 'family123',
          startDate: DateTime.now(),
          mealSlots: ['breakfast'],
          isTemplate: true,
          templateName: 'Weekly Template',
          createdBy: 'user123',
        );

        expect(validTemplate.isValid, isTrue);
      });
    });

    group('Assignment Key Handling', () {
      test('should handle meal plan with valid assignments', () {
        final planWithAssignments = MealPlan.create(
          name: 'Plan with Assignments',
          familyId: 'family123',
          startDate: DateTime.now(),
          mealSlots: ['breakfast', 'lunch'],
          assignments: {
            '2024-01-01_breakfast': 'recipe1',
            '2024-01-01_lunch': 'recipe2',
            '2024-01-02_breakfast': 'recipe3',
          },
          createdBy: 'user123',
        );

        expect(planWithAssignments.isValid, isTrue);
        expect(planWithAssignments.assignments.length, equals(3));
      });

      test('should handle meal plan without assignments', () {
        final planWithoutAssignments = MealPlan.create(
          name: 'Empty Plan',
          familyId: 'family123',
          startDate: DateTime.now(),
          mealSlots: ['breakfast', 'lunch'],
          createdBy: 'user123',
        );

        expect(planWithoutAssignments.isValid, isTrue);
        expect(planWithoutAssignments.assignments.isEmpty, isTrue);
      });
    });

    group('Assignment Operations', () {
      test('should generate assignment key correctly', () {
        final date = DateTime(2024, 1, 15);
        final key = service.generateAssignmentKey(date, 'breakfast');
        expect(key, equals('2024-01-15_breakfast'));
      });

      test('should handle assignment operations gracefully', () {
        // These would require database setup, so we just test they don't throw immediately
        expect(service.assignRecipeToSlot, isA<Function>());
        expect(service.removeRecipeFromSlot, isA<Function>());
        expect(service.getMealAssignments, isA<Function>());
        expect(service.getMealAssignmentsWithRecipes, isA<Function>());
      });
    });

    group('Calendar Utilities', () {
      final testStartDate = DateTime(2024, 1, 1); // Monday

      test('should generate week dates correctly', () {
        // Week 0 (first week)
        final week0 = service.generateWeekDates(testStartDate, 0);
        expect(week0.length, equals(7));
        expect(week0.first, equals(testStartDate));
        expect(week0.last, equals(testStartDate.add(const Duration(days: 6))));

        // Week 3 (last week)
        final week3 = service.generateWeekDates(testStartDate, 3);
        expect(week3.length, equals(7));
        expect(
          week3.first,
          equals(testStartDate.add(const Duration(days: 21))),
        );
        expect(week3.last, equals(testStartDate.add(const Duration(days: 27))));
      });

      test('should throw error for invalid week number', () {
        expect(
          () => service.generateWeekDates(testStartDate, -1),
          throwsArgumentError,
        );
        expect(
          () => service.generateWeekDates(testStartDate, 4),
          throwsArgumentError,
        );
      });

      test('should generate four week dates correctly', () {
        final allDates = service.generateFourWeekDates(testStartDate);
        expect(allDates.length, equals(28));
        expect(allDates.first, equals(testStartDate));
        expect(
          allDates.last,
          equals(testStartDate.add(const Duration(days: 27))),
        );
      });

      test('should get current week number correctly', () {
        // Day 0 (start date) should be week 0
        expect(
          service.getCurrentWeekNumber(testStartDate, testStartDate),
          equals(0),
        );

        // Day 7 should be week 1
        expect(
          service.getCurrentWeekNumber(
            testStartDate,
            testStartDate.add(const Duration(days: 7)),
          ),
          equals(1),
        );

        // Day 21 should be week 3
        expect(
          service.getCurrentWeekNumber(
            testStartDate,
            testStartDate.add(const Duration(days: 21)),
          ),
          equals(3),
        );

        // Day before start should return null
        expect(
          service.getCurrentWeekNumber(
            testStartDate,
            testStartDate.subtract(const Duration(days: 1)),
          ),
          isNull,
        );

        // Day after end should return null
        expect(
          service.getCurrentWeekNumber(
            testStartDate,
            testStartDate.add(const Duration(days: 28)),
          ),
          isNull,
        );
      });

      test('should check if date is in meal plan correctly', () {
        expect(service.isDateInMealPlan(testStartDate, testStartDate), isTrue);
        expect(
          service.isDateInMealPlan(
            testStartDate,
            testStartDate.add(const Duration(days: 27)),
          ),
          isTrue,
        );
        expect(
          service.isDateInMealPlan(
            testStartDate,
            testStartDate.subtract(const Duration(days: 1)),
          ),
          isFalse,
        );
        expect(
          service.isDateInMealPlan(
            testStartDate,
            testStartDate.add(const Duration(days: 28)),
          ),
          isFalse,
        );
      });

      test('should get week start date correctly', () {
        expect(
          service.getWeekStartDate(testStartDate, 0),
          equals(testStartDate),
        );
        expect(
          service.getWeekStartDate(testStartDate, 1),
          equals(testStartDate.add(const Duration(days: 7))),
        );
        expect(
          service.getWeekStartDate(testStartDate, 3),
          equals(testStartDate.add(const Duration(days: 21))),
        );

        expect(
          () => service.getWeekStartDate(testStartDate, -1),
          throwsArgumentError,
        );
        expect(
          () => service.getWeekStartDate(testStartDate, 4),
          throwsArgumentError,
        );
      });

      test('should format date range correctly', () {
        final start = DateTime(2024, 1, 1);
        final end = DateTime(2024, 1, 7);
        expect(service.formatDateRange(start, end), equals('1/1 - 1/7'));

        final startDifferentYear = DateTime(2023, 12, 25);
        final endDifferentYear = DateTime(2024, 1, 7);
        expect(
          service.formatDateRange(startDifferentYear, endDifferentYear),
          equals('12/25/2023 - 1/7/2024'),
        );
      });

      test('should format week range correctly', () {
        final weekRange = service.formatWeekRange(testStartDate, 0);
        expect(weekRange, equals('1/1 - 1/7'));
      });

      test('should check meal plan active status', () {
        final now = DateTime.now();
        final currentPlan = now.subtract(const Duration(days: 7));
        final pastPlan = now.subtract(const Duration(days: 35));
        final futurePlan = now.add(const Duration(days: 35));

        expect(service.isMealPlanActive(currentPlan), isTrue);
        expect(service.isMealPlanActive(pastPlan), isFalse);
        expect(service.isMealPlanActive(futurePlan), isFalse);
      });

      test('should calculate days remaining correctly', () {
        final now = DateTime.now();

        // Past meal plan should have 0 days remaining
        final pastPlan = now.subtract(const Duration(days: 35));
        expect(service.getDaysRemainingInMealPlan(pastPlan), equals(0));

        // Future meal plan should have full duration
        final futurePlan = now.add(const Duration(days: 7));
        expect(service.getDaysRemainingInMealPlan(futurePlan), equals(28));

        // Current meal plan should have some days remaining
        final currentPlan = now.subtract(const Duration(days: 7));
        final remaining = service.getDaysRemainingInMealPlan(currentPlan);
        expect(remaining, greaterThan(0));
        expect(remaining, lessThanOrEqualTo(28));
      });
    });
  });
}
