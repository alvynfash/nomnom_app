import 'package:flutter_test/flutter_test.dart';
import 'package:nomnom/models/meal_assignment.dart';
import 'package:nomnom/models/recipe.dart';

void main() {
  group('MealAssignment Model Tests', () {
    late MealAssignment validAssignment;
    late DateTime testDate;
    late Recipe testRecipe;

    setUp(() {
      testDate = DateTime(2024, 1, 15);
      testRecipe = Recipe.create(
        title: 'Test Recipe',
        ingredients: [
          Ingredient(name: 'Test Ingredient', quantity: 1.0, unit: 'cup'),
        ],
        instructions: ['Test instruction'],
      );

      validAssignment = MealAssignment(
        mealPlanId: 'plan123',
        date: testDate,
        slotId: 'breakfast',
        recipeId: 'recipe123',
        recipe: testRecipe,
      );
    });

    group('MealAssignment Creation', () {
      test('should create a valid meal assignment with all fields', () {
        expect(validAssignment.mealPlanId, equals('plan123'));
        expect(validAssignment.date, equals(testDate));
        expect(validAssignment.slotId, equals('breakfast'));
        expect(validAssignment.recipeId, equals('recipe123'));
        expect(validAssignment.recipe, equals(testRecipe));
      });

      test('should create assignment without recipe', () {
        final emptyAssignment = MealAssignment(
          mealPlanId: 'plan123',
          date: testDate,
          slotId: 'breakfast',
        );

        expect(emptyAssignment.mealPlanId, equals('plan123'));
        expect(emptyAssignment.date, equals(testDate));
        expect(emptyAssignment.slotId, equals('breakfast'));
        expect(emptyAssignment.recipeId, isNull);
        expect(emptyAssignment.recipe, isNull);
      });

      test('should create assignment with recipe ID but no recipe data', () {
        final assignment = MealAssignment(
          mealPlanId: 'plan123',
          date: testDate,
          slotId: 'breakfast',
          recipeId: 'recipe123',
        );

        expect(assignment.recipeId, equals('recipe123'));
        expect(assignment.recipe, isNull);
        expect(assignment.hasRecipe, isTrue);
        expect(assignment.hasRecipeData, isFalse);
      });
    });

    group('Assignment Key Generation', () {
      test('should generate correct assignment key', () {
        final key = validAssignment.assignmentKey;
        expect(key, equals('2024-01-15_breakfast'));
      });

      test('should generate key with proper date formatting', () {
        final assignment = MealAssignment(
          mealPlanId: 'plan123',
          date: DateTime(2024, 3, 5), // Single digit month and day
          slotId: 'lunch',
        );

        expect(assignment.assignmentKey, equals('2024-03-05_lunch'));
      });

      test('should generate different keys for different dates/slots', () {
        final assignment1 = MealAssignment(
          mealPlanId: 'plan123',
          date: testDate,
          slotId: 'breakfast',
        );

        final assignment2 = MealAssignment(
          mealPlanId: 'plan123',
          date: testDate,
          slotId: 'lunch',
        );

        expect(
          assignment1.assignmentKey,
          isNot(equals(assignment2.assignmentKey)),
        );
      });
    });

    group('Recipe Status Checks', () {
      test('should correctly identify when recipe is assigned', () {
        expect(validAssignment.hasRecipe, isTrue);
        expect(validAssignment.hasRecipeData, isTrue);
      });

      test('should correctly identify when no recipe is assigned', () {
        final emptyAssignment = MealAssignment(
          mealPlanId: 'plan123',
          date: testDate,
          slotId: 'breakfast',
        );

        expect(emptyAssignment.hasRecipe, isFalse);
        expect(emptyAssignment.hasRecipeData, isFalse);
      });

      test('should correctly identify when recipe ID exists but no data', () {
        final assignment = MealAssignment(
          mealPlanId: 'plan123',
          date: testDate,
          slotId: 'breakfast',
          recipeId: 'recipe123',
        );

        expect(assignment.hasRecipe, isTrue);
        expect(assignment.hasRecipeData, isFalse);
      });
    });

    group('Serialization', () {
      test('should serialize to map correctly with recipe data', () {
        final map = validAssignment.toMap();

        expect(map['mealPlanId'], equals('plan123'));
        expect(map['date'], equals(testDate.toIso8601String()));
        expect(map['slotId'], equals('breakfast'));
        expect(map['recipeId'], equals('recipe123'));
        expect(map['recipe'], isNotNull);
        expect(map['recipe']['title'], equals('Test Recipe'));
      });

      test('should serialize to map correctly without recipe data', () {
        final assignment = MealAssignment(
          mealPlanId: 'plan123',
          date: testDate,
          slotId: 'breakfast',
          recipeId: 'recipe123',
        );

        final map = assignment.toMap();
        expect(map['recipe'], isNull);
      });

      test('should deserialize from map correctly', () {
        final map = validAssignment.toMap();
        final deserializedAssignment = MealAssignment.fromMap(map);

        expect(
          deserializedAssignment.mealPlanId,
          equals(validAssignment.mealPlanId),
        );
        expect(deserializedAssignment.date, equals(validAssignment.date));
        expect(deserializedAssignment.slotId, equals(validAssignment.slotId));
        expect(
          deserializedAssignment.recipeId,
          equals(validAssignment.recipeId),
        );
        expect(deserializedAssignment.recipe?.title, equals(testRecipe.title));
      });

      test('should handle JSON serialization', () {
        final json = validAssignment.toJson();
        final fromJson = MealAssignment.fromJson(json);

        expect(fromJson.mealPlanId, equals(validAssignment.mealPlanId));
        expect(fromJson.date, equals(validAssignment.date));
        expect(fromJson.slotId, equals(validAssignment.slotId));
        expect(fromJson.recipeId, equals(validAssignment.recipeId));
      });
    });

    group('Database Serialization', () {
      test('should serialize to database map correctly', () {
        final dbMap = validAssignment.toDatabaseMap();

        expect(dbMap['mealPlanId'], equals('plan123'));
        expect(dbMap['assignmentDate'], equals(testDate.toIso8601String()));
        expect(dbMap['slotId'], equals('breakfast'));
        expect(dbMap['recipeId'], equals('recipe123'));
        expect(
          dbMap.containsKey('recipe'),
          isFalse,
        ); // Should not include recipe data
      });

      test('should deserialize from database map correctly', () {
        final dbMap = {
          'mealPlanId': 'plan123',
          'assignmentDate': testDate.toIso8601String(),
          'slotId': 'breakfast',
          'recipeId': 'recipe123',
        };

        final assignment = MealAssignment.fromDatabaseMap(dbMap);

        expect(assignment.mealPlanId, equals('plan123'));
        expect(assignment.date, equals(testDate));
        expect(assignment.slotId, equals('breakfast'));
        expect(assignment.recipeId, equals('recipe123'));
        expect(
          assignment.recipe,
          isNull,
        ); // Should not have recipe data from DB
      });
    });

    group('Copy Operations', () {
      test('should copy with updated values', () {
        final newDate = DateTime(2024, 2, 1);
        final updatedAssignment = validAssignment.copyWith(
          date: newDate,
          slotId: 'lunch',
        );

        expect(updatedAssignment.date, equals(newDate));
        expect(updatedAssignment.slotId, equals('lunch'));
        expect(
          updatedAssignment.mealPlanId,
          equals(validAssignment.mealPlanId),
        );
        expect(updatedAssignment.recipeId, equals(validAssignment.recipeId));
      });

      test('should copy without changing original', () {
        final originalDate = validAssignment.date;
        final updatedAssignment = validAssignment.copyWith(
          date: DateTime(2024, 2, 1),
        );

        expect(validAssignment.date, equals(originalDate));
        expect(updatedAssignment.date, isNot(equals(originalDate)));
      });

      test('should add recipe data with withRecipe', () {
        final assignmentWithoutData = MealAssignment(
          mealPlanId: 'plan123',
          date: testDate,
          slotId: 'breakfast',
          recipeId: 'recipe123',
        );

        final withRecipe = assignmentWithoutData.withRecipe(testRecipe);

        expect(withRecipe.recipe, equals(testRecipe));
        expect(withRecipe.hasRecipeData, isTrue);
        expect(assignmentWithoutData.recipe, isNull); // Original unchanged
      });

      test('should remove recipe with withoutRecipe', () {
        final withoutRecipe = validAssignment.withoutRecipe();

        expect(withoutRecipe.recipeId, isNull);
        expect(withoutRecipe.recipe, isNull);
        expect(withoutRecipe.hasRecipe, isFalse);
        expect(withoutRecipe.mealPlanId, equals(validAssignment.mealPlanId));
        expect(withoutRecipe.date, equals(validAssignment.date));
        expect(withoutRecipe.slotId, equals(validAssignment.slotId));
      });
    });

    group('Validation', () {
      test('should validate valid meal assignment', () {
        expect(validAssignment.isValid, isTrue);
        expect(() => validAssignment.validate(), returnsNormally);
      });

      test('should reject empty meal plan ID', () {
        final invalidAssignment = MealAssignment(
          mealPlanId: '',
          date: testDate,
          slotId: 'breakfast',
        );

        expect(invalidAssignment.isValid, isFalse);
        expect(
          () => invalidAssignment.validate(),
          throwsA(isA<MealAssignmentException>()),
        );
      });

      test('should reject whitespace-only meal plan ID', () {
        final invalidAssignment = MealAssignment(
          mealPlanId: '   ',
          date: testDate,
          slotId: 'breakfast',
        );

        expect(invalidAssignment.isValid, isFalse);
        expect(
          () => invalidAssignment.validate(),
          throwsA(isA<MealAssignmentException>()),
        );
      });

      test('should reject empty slot ID', () {
        final invalidAssignment = MealAssignment(
          mealPlanId: 'plan123',
          date: testDate,
          slotId: '',
        );

        expect(invalidAssignment.isValid, isFalse);
        expect(
          () => invalidAssignment.validate(),
          throwsA(isA<MealAssignmentException>()),
        );
      });

      test('should reject empty recipe ID when provided', () {
        final invalidAssignment = MealAssignment(
          mealPlanId: 'plan123',
          date: testDate,
          slotId: 'breakfast',
          recipeId: '',
        );

        expect(invalidAssignment.isValid, isFalse);
        expect(
          () => invalidAssignment.validate(),
          throwsA(isA<MealAssignmentException>()),
        );
      });

      test('should accept null recipe ID', () {
        final validAssignment = MealAssignment(
          mealPlanId: 'plan123',
          date: testDate,
          slotId: 'breakfast',
          recipeId: null,
        );

        expect(validAssignment.isValid, isTrue);
        expect(() => validAssignment.validate(), returnsNormally);
      });
    });

    group('Equality and Hash', () {
      test('should be equal when core properties match', () {
        final assignment1 = MealAssignment(
          mealPlanId: 'plan123',
          date: testDate,
          slotId: 'breakfast',
          recipeId: 'recipe123',
        );

        final assignment2 = MealAssignment(
          mealPlanId: 'plan123',
          date: testDate,
          slotId: 'breakfast',
          recipeId: 'recipe123',
        );

        expect(assignment1, equals(assignment2));
        expect(assignment1.hashCode, equals(assignment2.hashCode));
      });

      test('should not be equal when properties differ', () {
        final assignment1 = MealAssignment(
          mealPlanId: 'plan123',
          date: testDate,
          slotId: 'breakfast',
          recipeId: 'recipe123',
        );

        final assignment2 = MealAssignment(
          mealPlanId: 'plan123',
          date: testDate,
          slotId: 'lunch', // Different slot
          recipeId: 'recipe123',
        );

        expect(assignment1, isNot(equals(assignment2)));
      });

      test('should be identical to itself', () {
        expect(identical(validAssignment, validAssignment), isTrue);
        expect(validAssignment, equals(validAssignment));
      });
    });

    group('String Representation', () {
      test('should provide meaningful toString', () {
        final string = validAssignment.toString();
        expect(string, contains('MealAssignment'));
        expect(string, contains('plan123'));
        expect(string, contains('breakfast'));
        expect(string, contains('recipe123'));
      });
    });
  });
}
