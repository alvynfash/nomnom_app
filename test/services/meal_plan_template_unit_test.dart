import 'package:flutter_test/flutter_test.dart';
import 'package:nomnom/models/meal_plan.dart';
import 'package:nomnom/services/meal_plan_service.dart';

void main() {
  group('MealPlanService Template Logic Tests', () {
    late MealPlanService service;

    setUp(() {
      service = MealPlanService();
    });

    group('Template Statistics', () {
      test('should calculate template statistics correctly', () {
        final template = MealPlan.create(
          name: 'Test Template',
          familyId: 'family123',
          startDate: DateTime(2024, 1, 1), // Reference date
          mealSlots: ['breakfast', 'lunch', 'dinner'],
          assignments: {
            '2024-01-01_breakfast': 'recipe1',
            '2024-01-01_lunch': 'recipe2',
            '2024-01-02_dinner': 'recipe3',
            '2024-01-05_breakfast': 'recipe1', // Duplicate recipe
          },
          isTemplate: true,
          templateName: 'Test Template',
          createdBy: 'user123',
        );

        final stats = service.getTemplateStats(template);

        expect(stats['totalSlots'], equals(84)); // 3 slots * 28 days
        expect(stats['assignedSlots'], equals(4)); // 4 assignments
        expect(stats['emptySlots'], equals(80)); // 84 - 4
        expect(stats['uniqueRecipes'], equals(3)); // recipe1, recipe2, recipe3
        expect(stats['completionPercentage'], equals(5)); // 4/84 * 100 rounded
        expect(stats['mealSlotsCount'], equals(3));
      });

      test('should handle empty template', () {
        final emptyTemplate = MealPlan.create(
          name: 'Empty Template',
          familyId: 'family123',
          startDate: DateTime(2024, 1, 1),
          mealSlots: ['breakfast'],
          assignments: {},
          isTemplate: true,
          templateName: 'Empty Template',
          createdBy: 'user123',
        );

        final stats = service.getTemplateStats(emptyTemplate);

        expect(stats['totalSlots'], equals(28)); // 1 slot * 28 days
        expect(stats['assignedSlots'], equals(0));
        expect(stats['emptySlots'], equals(28));
        expect(stats['uniqueRecipes'], equals(0));
        expect(stats['completionPercentage'], equals(0));
        expect(stats['mealSlotsCount'], equals(1));
      });

      test('should throw for non-template meal plan', () {
        final regularMealPlan = MealPlan.create(
          name: 'Regular Plan',
          familyId: 'family123',
          startDate: DateTime.now(),
          mealSlots: ['breakfast'],
          assignments: {},
          isTemplate: false, // Not a template
          createdBy: 'user123',
        );

        expect(
          () => service.getTemplateStats(regularMealPlan),
          throwsA(isA<MealPlanException>()),
        );
      });
    });

    group('Calendar Utilities', () {
      test('should generate week dates correctly', () {
        final startDate = DateTime(2024, 1, 1); // Monday

        // Week 0 (first week)
        final week0 = service.generateWeekDates(startDate, 0);
        expect(week0.length, equals(7));
        expect(week0.first, equals(startDate));
        expect(week0.last, equals(DateTime(2024, 1, 7)));

        // Week 1 (second week)
        final week1 = service.generateWeekDates(startDate, 1);
        expect(week1.length, equals(7));
        expect(week1.first, equals(DateTime(2024, 1, 8)));
        expect(week1.last, equals(DateTime(2024, 1, 14)));

        // Week 3 (last week)
        final week3 = service.generateWeekDates(startDate, 3);
        expect(week3.length, equals(7));
        expect(week3.first, equals(DateTime(2024, 1, 22)));
        expect(week3.last, equals(DateTime(2024, 1, 28)));
      });

      test('should generate four week dates correctly', () {
        final startDate = DateTime(2024, 1, 1);
        final allDates = service.generateFourWeekDates(startDate);

        expect(allDates.length, equals(28));
        expect(allDates.first, equals(startDate));
        expect(allDates.last, equals(DateTime(2024, 1, 28)));
      });

      test('should validate week numbers', () {
        final startDate = DateTime(2024, 1, 1);

        expect(
          () => service.generateWeekDates(startDate, -1),
          throwsA(isA<ArgumentError>()),
        );

        expect(
          () => service.generateWeekDates(startDate, 4),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should get current week number correctly', () {
        final startDate = DateTime(2024, 1, 1); // Monday

        // First day should be week 0
        expect(service.getCurrentWeekNumber(startDate, startDate), equals(0));

        // Day 7 should be week 0 (last day of first week)
        expect(
          service.getCurrentWeekNumber(startDate, DateTime(2024, 1, 7)),
          equals(0),
        );

        // Day 8 should be week 1 (first day of second week)
        expect(
          service.getCurrentWeekNumber(startDate, DateTime(2024, 1, 8)),
          equals(1),
        );

        // Day 28 should be week 3 (last day of meal plan)
        expect(
          service.getCurrentWeekNumber(startDate, DateTime(2024, 1, 28)),
          equals(3),
        );

        // Day before start should return null
        expect(
          service.getCurrentWeekNumber(startDate, DateTime(2023, 12, 31)),
          isNull,
        );

        // Day after end should return null
        expect(
          service.getCurrentWeekNumber(startDate, DateTime(2024, 1, 29)),
          isNull,
        );
      });

      test('should check if date is in meal plan', () {
        final startDate = DateTime(2024, 1, 1);

        // First day should be in plan
        expect(service.isDateInMealPlan(startDate, startDate), isTrue);

        // Last day should be in plan
        expect(
          service.isDateInMealPlan(startDate, DateTime(2024, 1, 28)),
          isTrue,
        );

        // Day before should not be in plan
        expect(
          service.isDateInMealPlan(startDate, DateTime(2023, 12, 31)),
          isFalse,
        );

        // Day after should not be in plan
        expect(
          service.isDateInMealPlan(startDate, DateTime(2024, 1, 29)),
          isFalse,
        );
      });

      test('should get week start date correctly', () {
        final mealPlanStart = DateTime(2024, 1, 1);

        expect(
          service.getWeekStartDate(mealPlanStart, 0),
          equals(DateTime(2024, 1, 1)),
        );

        expect(
          service.getWeekStartDate(mealPlanStart, 1),
          equals(DateTime(2024, 1, 8)),
        );

        expect(
          service.getWeekStartDate(mealPlanStart, 3),
          equals(DateTime(2024, 1, 22)),
        );

        expect(
          () => service.getWeekStartDate(mealPlanStart, 4),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should format date ranges correctly', () {
        final start = DateTime(2024, 1, 1);
        final end = DateTime(2024, 1, 7);

        expect(service.formatDateRange(start, end), equals('1/1 - 1/7'));

        // Different years
        final startDiffYear = DateTime(2023, 12, 25);
        final endDiffYear = DateTime(2024, 1, 1);
        expect(
          service.formatDateRange(startDiffYear, endDiffYear),
          equals('12/25/2023 - 1/1/2024'),
        );
      });

      test('should format week ranges correctly', () {
        final startDate = DateTime(2024, 1, 1);

        expect(service.formatWeekRange(startDate, 0), equals('1/1 - 1/7'));
        expect(service.formatWeekRange(startDate, 1), equals('1/8 - 1/14'));
        expect(service.formatWeekRange(startDate, 3), equals('1/22 - 1/28'));
      });

      test('should check if meal plan is active', () {
        final now = DateTime.now();

        // Current meal plan should be active
        final currentPlan = now.subtract(Duration(days: 7));
        expect(service.isMealPlanActive(currentPlan), isTrue);

        // Future meal plan should not be active
        final futurePlan = now.add(Duration(days: 30));
        expect(service.isMealPlanActive(futurePlan), isFalse);

        // Past meal plan should not be active
        final pastPlan = now.subtract(Duration(days: 60));
        expect(service.isMealPlanActive(pastPlan), isFalse);
      });

      test('should calculate days remaining correctly', () {
        final now = DateTime.now();

        // Meal plan starting today should have 28 days remaining (but might be 27 due to time of day)
        final remaining = service.getDaysRemainingInMealPlan(now);
        expect(remaining, inInclusiveRange(27, 28));

        // Meal plan that started 7 days ago should have around 21 days remaining
        final weekOld = now.subtract(Duration(days: 7));
        final weekOldRemaining = service.getDaysRemainingInMealPlan(weekOld);
        expect(weekOldRemaining, inInclusiveRange(20, 21));

        // Meal plan that ended should have 0 days remaining
        final ended = now.subtract(Duration(days: 30));
        expect(service.getDaysRemainingInMealPlan(ended), equals(0));

        // Future meal plan should have full duration
        final future = now.add(Duration(days: 10));
        expect(service.getDaysRemainingInMealPlan(future), equals(28));
      });
    });

    group('Assignment Key Generation', () {
      test('should generate assignment keys correctly', () {
        final date = DateTime(2024, 1, 15);
        final slotId = 'breakfast';

        final key = service.generateAssignmentKey(date, slotId);
        expect(key, equals('2024-01-15_breakfast'));
      });

      test('should handle single digit months and days', () {
        final date = DateTime(2024, 3, 5);
        final slotId = 'lunch';

        final key = service.generateAssignmentKey(date, slotId);
        expect(key, equals('2024-03-05_lunch'));
      });
    });
  });
}
