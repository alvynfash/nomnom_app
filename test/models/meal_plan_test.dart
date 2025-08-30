import 'package:flutter_test/flutter_test.dart';
import 'package:nomnom/models/meal_plan.dart';

void main() {
  group('MealPlan Model Tests', () {
    late MealPlan validMealPlan;
    late DateTime testStartDate;
    late List<String> validMealSlots;
    late Map<String, String?> validAssignments;

    setUp(() {
      testStartDate = DateTime.now().subtract(
        const Duration(days: 7),
      ); // A week ago
      validMealSlots = ['breakfast', 'lunch', 'dinner', 'snacks'];

      // Generate assignment keys based on the actual test date
      final day1 = testStartDate;
      final day2 = testStartDate.add(const Duration(days: 1));
      final day1Key =
          '${day1.year}-${day1.month.toString().padLeft(2, '0')}-${day1.day.toString().padLeft(2, '0')}';
      final day2Key =
          '${day2.year}-${day2.month.toString().padLeft(2, '0')}-${day2.day.toString().padLeft(2, '0')}';

      validAssignments = {
        '${day1Key}_breakfast': 'recipe1',
        '${day1Key}_lunch': 'recipe2',
        '${day2Key}_dinner': 'recipe3',
      };

      validMealPlan = MealPlan.create(
        name: 'Test Meal Plan',
        familyId: 'family123',
        startDate: testStartDate,
        mealSlots: validMealSlots,
        assignments: validAssignments,
        createdBy: 'user123',
      );
    });

    group('MealPlan Creation', () {
      test('should create a valid meal plan with all fields', () {
        expect(validMealPlan.name, equals('Test Meal Plan'));
        expect(validMealPlan.familyId, equals('family123'));
        expect(validMealPlan.startDate, equals(testStartDate));
        expect(validMealPlan.mealSlots, equals(validMealSlots));
        expect(validMealPlan.assignments, equals(validAssignments));
        expect(validMealPlan.isTemplate, isFalse);
        expect(validMealPlan.templateName, isNull);
        expect(validMealPlan.createdBy, equals('user123'));
        expect(validMealPlan.id, isNotEmpty);
        expect(validMealPlan.id, startsWith('mp_'));
      });

      test('should generate unique IDs for different meal plans', () {
        final mealPlan1 = MealPlan.create(
          name: 'Plan 1',
          familyId: 'family1',
          startDate: testStartDate,
          mealSlots: validMealSlots,
          createdBy: 'user1',
        );

        final mealPlan2 = MealPlan.create(
          name: 'Plan 2',
          familyId: 'family2',
          startDate: testStartDate,
          mealSlots: validMealSlots,
          createdBy: 'user2',
        );

        expect(mealPlan1.id, isNot(equals(mealPlan2.id)));
      });

      test('should create template meal plan correctly', () {
        final templatePlan = MealPlan.create(
          name: 'Template Plan',
          familyId: 'family123',
          startDate: testStartDate,
          mealSlots: validMealSlots,
          isTemplate: true,
          templateName: 'Weekly Template',
          templateDescription: 'A standard weekly meal plan',
          createdBy: 'user123',
        );

        expect(templatePlan.isTemplate, isTrue);
        expect(templatePlan.templateName, equals('Weekly Template'));
        expect(
          templatePlan.templateDescription,
          equals('A standard weekly meal plan'),
        );
      });
    });

    group('Date Calculations', () {
      test('should calculate end date correctly (4 weeks)', () {
        final expectedEndDate = testStartDate.add(const Duration(days: 27));
        expect(validMealPlan.endDate, equals(expectedEndDate));
      });

      test('should generate all dates for 4-week period', () {
        final allDates = validMealPlan.allDates;
        expect(allDates.length, equals(28));
        expect(allDates.first, equals(testStartDate));
        expect(
          allDates.last,
          equals(testStartDate.add(const Duration(days: 27))),
        );
      });

      test('should generate week dates correctly', () {
        // Week 0 (first week)
        final week0 = validMealPlan.getWeekDates(0);
        expect(week0.length, equals(7));
        expect(week0.first, equals(testStartDate));
        expect(week0.last, equals(testStartDate.add(const Duration(days: 6))));

        // Week 3 (last week)
        final week3 = validMealPlan.getWeekDates(3);
        expect(week3.length, equals(7));
        expect(
          week3.first,
          equals(testStartDate.add(const Duration(days: 21))),
        );
        expect(week3.last, equals(testStartDate.add(const Duration(days: 27))));
      });

      test('should throw error for invalid week number', () {
        expect(() => validMealPlan.getWeekDates(-1), throwsArgumentError);
        expect(() => validMealPlan.getWeekDates(4), throwsArgumentError);
      });

      test('should format date range correctly', () {
        final dateRange = validMealPlan.dateRange;
        final expectedStart = '${testStartDate.month}/${testStartDate.day}';
        final expectedEnd =
            '${validMealPlan.endDate.month}/${validMealPlan.endDate.day}';
        expect(dateRange, equals('$expectedStart - $expectedEnd'));
      });
    });

    group('Recipe Assignment', () {
      test('should generate assignment key correctly', () {
        final date = DateTime(2024, 1, 15);
        final key = MealPlan.generateAssignmentKey(date, 'breakfast');
        expect(key, equals('2024-01-15_breakfast'));
      });

      test('should get recipe for slot correctly', () {
        final recipeId = validMealPlan.getRecipeForSlot(
          testStartDate,
          'breakfast',
        );
        expect(recipeId, equals('recipe1'));

        final noRecipe = validMealPlan.getRecipeForSlot(
          testStartDate,
          'snacks',
        );
        expect(noRecipe, isNull);
      });

      test('should check if meal plan contains recipe', () {
        expect(validMealPlan.containsRecipe('recipe1'), isTrue);
        expect(validMealPlan.containsRecipe('recipe2'), isTrue);
        expect(validMealPlan.containsRecipe('recipe3'), isTrue);
        expect(validMealPlan.containsRecipe('nonexistent'), isFalse);
      });

      test('should get all unique recipe IDs', () {
        final recipeIds = validMealPlan.recipeIds;
        expect(recipeIds.length, equals(3));
        expect(recipeIds, containsAll(['recipe1', 'recipe2', 'recipe3']));
      });
    });

    group('Active Status', () {
      test('should identify currently active meal plan', () {
        final now = DateTime.now();
        final activePlan = MealPlan.create(
          name: 'Active Plan',
          familyId: 'family123',
          startDate: now.subtract(const Duration(days: 7)),
          mealSlots: validMealSlots,
          createdBy: 'user123',
        );

        expect(activePlan.isCurrentlyActive, isTrue);
      });

      test('should identify inactive meal plan (past)', () {
        final pastPlan = MealPlan.create(
          name: 'Past Plan',
          familyId: 'family123',
          startDate: DateTime.now().subtract(const Duration(days: 35)),
          mealSlots: validMealSlots,
          createdBy: 'user123',
        );

        expect(pastPlan.isCurrentlyActive, isFalse);
      });

      test('should identify inactive meal plan (future)', () {
        final futurePlan = MealPlan.create(
          name: 'Future Plan',
          familyId: 'family123',
          startDate: DateTime.now().add(const Duration(days: 35)),
          mealSlots: validMealSlots,
          createdBy: 'user123',
        );

        expect(futurePlan.isCurrentlyActive, isFalse);
      });
    });

    group('Serialization', () {
      test('should serialize to map correctly', () {
        final map = validMealPlan.toMap();

        expect(map['id'], equals(validMealPlan.id));
        expect(map['name'], equals('Test Meal Plan'));
        expect(map['familyId'], equals('family123'));
        expect(map['startDate'], equals(testStartDate.toIso8601String()));
        expect(map['mealSlots'], equals(validMealSlots));
        expect(map['assignments'], equals(validAssignments));
        expect(map['isTemplate'], isFalse);
        expect(map['createdBy'], equals('user123'));
      });

      test('should deserialize from map correctly', () {
        final map = validMealPlan.toMap();
        final deserializedPlan = MealPlan.fromMap(map);

        expect(deserializedPlan.id, equals(validMealPlan.id));
        expect(deserializedPlan.name, equals(validMealPlan.name));
        expect(deserializedPlan.familyId, equals(validMealPlan.familyId));
        expect(deserializedPlan.startDate, equals(validMealPlan.startDate));
        expect(deserializedPlan.mealSlots, equals(validMealPlan.mealSlots));
        expect(deserializedPlan.assignments, equals(validMealPlan.assignments));
        expect(deserializedPlan.isTemplate, equals(validMealPlan.isTemplate));
        expect(deserializedPlan.createdBy, equals(validMealPlan.createdBy));
      });

      test('should handle JSON serialization', () {
        final json = validMealPlan.toJson();
        final fromJson = MealPlan.fromJson(json);

        expect(fromJson.id, equals(validMealPlan.id));
        expect(fromJson.name, equals(validMealPlan.name));
      });
    });

    group('Validation', () {
      test('should validate valid meal plan', () {
        expect(validMealPlan.isValid, isTrue);
        expect(() => validMealPlan.validate(), returnsNormally);
      });

      test('should reject empty name', () {
        final invalidPlan = validMealPlan.copyWith(name: '');
        expect(invalidPlan.isValid, isFalse);
        expect(() => invalidPlan.validate(), throwsA(isA<MealPlanException>()));
      });

      test('should reject name too long', () {
        final longName = 'a' * 51;
        final invalidPlan = validMealPlan.copyWith(name: longName);
        expect(invalidPlan.isValid, isFalse);
        expect(() => invalidPlan.validate(), throwsA(isA<MealPlanException>()));
      });

      test('should reject start date too far in past', () {
        final tooOld = DateTime.now().subtract(const Duration(days: 400));
        final invalidPlan = validMealPlan.copyWith(startDate: tooOld);
        expect(invalidPlan.isValid, isFalse);
        expect(() => invalidPlan.validate(), throwsA(isA<MealPlanException>()));
      });

      test('should reject empty meal slots', () {
        final invalidPlan = validMealPlan.copyWith(mealSlots: []);
        expect(invalidPlan.isValid, isFalse);
        expect(() => invalidPlan.validate(), throwsA(isA<MealPlanException>()));
      });

      test('should reject too many meal slots', () {
        final tooManySlots = List.generate(9, (i) => 'slot$i');
        final invalidPlan = validMealPlan.copyWith(mealSlots: tooManySlots);
        expect(invalidPlan.isValid, isFalse);
        expect(() => invalidPlan.validate(), throwsA(isA<MealPlanException>()));
      });

      test('should reject template without name', () {
        final invalidTemplate = validMealPlan.copyWith(
          isTemplate: true,
          templateName: null,
        );
        expect(invalidTemplate.isValid, isFalse);
        expect(
          () => invalidTemplate.validate(),
          throwsA(isA<MealPlanException>()),
        );
      });

      test('should return validation errors map', () {
        final invalidPlan = validMealPlan.copyWith(name: '', mealSlots: []);

        final errors = invalidPlan.getValidationErrors();
        expect(errors, isNotEmpty);
        expect(errors.containsKey('name'), isTrue);
        expect(errors.containsKey('mealSlots'), isTrue);
      });
    });

    group('Copy Operations', () {
      test('should copy with updated values', () {
        final updatedPlan = validMealPlan.copyWith(
          name: 'Updated Plan',
          familyId: 'newFamily',
        );

        expect(updatedPlan.name, equals('Updated Plan'));
        expect(updatedPlan.familyId, equals('newFamily'));
        expect(
          updatedPlan.id,
          equals(validMealPlan.id),
        ); // Should keep original ID
        expect(updatedPlan.startDate, equals(validMealPlan.startDate));
      });

      test('should copy without changing original', () {
        final originalName = validMealPlan.name;
        final updatedPlan = validMealPlan.copyWith(name: 'New Name');

        expect(validMealPlan.name, equals(originalName));
        expect(updatedPlan.name, equals('New Name'));
      });
    });
  });
}
