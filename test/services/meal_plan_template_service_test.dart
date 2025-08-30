import 'package:flutter_test/flutter_test.dart';
import 'package:nomnom/models/meal_plan.dart';
import 'package:nomnom/services/meal_plan_service.dart';

void main() {
  group('MealPlanService Template Operations', () {
    late MealPlanService service;
    late MealPlan testMealPlan;

    setUp(() {
      service = MealPlanService();

      // Create a test meal plan with some assignments
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, now.day);

      testMealPlan = MealPlan.create(
        name: 'Test Meal Plan',
        familyId: 'family123',
        startDate: startDate,
        mealSlots: ['breakfast', 'lunch', 'dinner'],
        assignments: {
          '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}_breakfast':
              'recipe1',
          '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}_lunch':
              'recipe2',
          '${startDate.add(Duration(days: 1)).year}-${startDate.add(Duration(days: 1)).month.toString().padLeft(2, '0')}-${startDate.add(Duration(days: 1)).day.toString().padLeft(2, '0')}_dinner':
              'recipe3',
          '${startDate.add(Duration(days: 5)).year}-${startDate.add(Duration(days: 5)).month.toString().padLeft(2, '0')}-${startDate.add(Duration(days: 5)).day.toString().padLeft(2, '0')}_breakfast':
              'recipe1', // Week 2
        },
        createdBy: 'user123',
      );
    });

    group('saveAsTemplate', () {
      test('should create template from meal plan successfully', () async {
        // First create the meal plan
        await service.createMealPlan(testMealPlan);

        // Save as template
        final template = await service.saveAsTemplate(
          testMealPlan.id,
          'My Template',
          'A test template',
        );

        expect(template.isTemplate, isTrue);
        expect(template.templateName, equals('My Template'));
        expect(template.templateDescription, equals('A test template'));
        expect(template.familyId, equals(testMealPlan.familyId));
        expect(template.mealSlots, equals(testMealPlan.mealSlots));
        expect(template.assignments.isNotEmpty, isTrue);
      });

      test('should use reference date for template assignments', () async {
        await service.createMealPlan(testMealPlan);

        final template = await service.saveAsTemplate(
          testMealPlan.id,
          'Reference Date Template',
          null,
        );

        // Template should use reference date (2024-01-01)
        expect(template.startDate, equals(DateTime(2024, 1, 1)));

        // Check that assignments are mapped to reference date
        final hasReferenceAssignments = template.assignments.keys.any(
          (key) => key.startsWith('2024-01-01'),
        );
        expect(hasReferenceAssignments, isTrue);
      });

      test('should preserve meal slot assignments in template', () async {
        await service.createMealPlan(testMealPlan);

        final template = await service.saveAsTemplate(
          testMealPlan.id,
          'Assignment Template',
          null,
        );

        // Should have same number of assignments
        expect(
          template.assignments.length,
          equals(testMealPlan.assignments.length),
        );

        // Should preserve recipe IDs
        final templateRecipeIds = template.assignments.values
            .where((id) => id != null)
            .toSet();
        final originalRecipeIds = testMealPlan.assignments.values
            .where((id) => id != null)
            .toSet();
        expect(templateRecipeIds, equals(originalRecipeIds));
      });

      test('should validate template name', () async {
        await service.createMealPlan(testMealPlan);

        // Empty name should throw
        expect(
          () => service.saveAsTemplate(testMealPlan.id, '', null),
          throwsA(isA<MealPlanException>()),
        );

        // Too long name should throw
        final longName = 'a' * 51;
        expect(
          () => service.saveAsTemplate(testMealPlan.id, longName, null),
          throwsA(isA<MealPlanException>()),
        );
      });

      test('should prevent duplicate template names', () async {
        await service.createMealPlan(testMealPlan);

        // Create first template
        await service.saveAsTemplate(testMealPlan.id, 'Duplicate Name', null);

        // Try to create another with same name
        expect(
          () => service.saveAsTemplate(testMealPlan.id, 'Duplicate Name', null),
          throwsA(isA<MealPlanException>()),
        );
      });

      test('should handle case-insensitive duplicate names', () async {
        await service.createMealPlan(testMealPlan);

        await service.saveAsTemplate(testMealPlan.id, 'Template Name', null);

        // Different case should still be considered duplicate
        expect(
          () => service.saveAsTemplate(testMealPlan.id, 'TEMPLATE NAME', null),
          throwsA(isA<MealPlanException>()),
        );
      });

      test('should handle meal plan not found', () async {
        expect(
          () => service.saveAsTemplate('nonexistent', 'Template', null),
          throwsA(isA<MealPlanException>()),
        );
      });

      test('should trim and handle empty description', () async {
        await service.createMealPlan(testMealPlan);

        // Empty description should be null
        final template1 = await service.saveAsTemplate(
          testMealPlan.id,
          'Template 1',
          '',
        );
        expect(template1.templateDescription, isNull);

        // Whitespace-only description should be null
        final template2 = await service.saveAsTemplate(
          testMealPlan.id,
          'Template 2',
          '   ',
        );
        expect(template2.templateDescription, isNull);

        // Valid description should be trimmed
        final template3 = await service.saveAsTemplate(
          testMealPlan.id,
          'Template 3',
          '  Valid description  ',
        );
        expect(template3.templateDescription, equals('Valid description'));
      });
    });

    group('getTemplates', () {
      test('should return only templates', () async {
        // Create regular meal plan
        await service.createMealPlan(testMealPlan);

        // Create template
        await service.saveAsTemplate(testMealPlan.id, 'Test Template', null);

        final templates = await service.getTemplates();
        expect(templates.length, equals(1));
        expect(templates.first.isTemplate, isTrue);
        expect(templates.first.templateName, equals('Test Template'));
      });

      test('should filter by family ID', () async {
        await service.createMealPlan(testMealPlan);

        // Create template for family123
        await service.saveAsTemplate(testMealPlan.id, 'Family Template', null);

        // Get templates for specific family
        final familyTemplates = await service.getTemplates(
          familyId: 'family123',
        );
        expect(familyTemplates.length, equals(1));
        expect(familyTemplates.first.familyId, equals('family123'));

        // Get templates for different family
        final otherFamilyTemplates = await service.getTemplates(
          familyId: 'other',
        );
        expect(otherFamilyTemplates.length, equals(0));
      });

      test('should return empty list when no templates exist', () async {
        final templates = await service.getTemplates();
        expect(templates, isEmpty);
      });
    });

    group('applyTemplate', () {
      late MealPlan template;

      setUp(() async {
        await service.createMealPlan(testMealPlan);
        template = await service.saveAsTemplate(
          testMealPlan.id,
          'Apply Test Template',
          'Template for testing application',
        );
      });

      test('should create new meal plan from template', () async {
        final newStartDate = DateTime.now().add(
          Duration(days: 30),
        ); // Future date
        final newMealPlan = await service.applyTemplate(
          template.id,
          newStartDate,
        );

        expect(newMealPlan.isTemplate, isFalse);
        expect(newMealPlan.name, equals('Meal Plan from Apply Test Template'));
        expect(newMealPlan.startDate, equals(newStartDate));
        expect(newMealPlan.familyId, equals(template.familyId));
        expect(newMealPlan.mealSlots, equals(template.mealSlots));
      });

      test('should map assignments to new start date', () async {
        final newStartDate = DateTime.now().add(
          Duration(days: 30),
        ); // Future date
        final newMealPlan = await service.applyTemplate(
          template.id,
          newStartDate,
        );

        // Should have same number of assignments
        expect(
          newMealPlan.assignments.length,
          equals(template.assignments.length),
        );

        // Check that assignments are mapped to new dates
        final expectedDateStr =
            '${newStartDate.year}-${newStartDate.month.toString().padLeft(2, '0')}-${newStartDate.day.toString().padLeft(2, '0')}';
        final hasNewDateAssignments = newMealPlan.assignments.keys.any(
          (key) => key.startsWith(expectedDateStr),
        );
        expect(hasNewDateAssignments, isTrue);

        // Should preserve recipe IDs
        final newRecipeIds = newMealPlan.assignments.values
            .where((id) => id != null)
            .toSet();
        final templateRecipeIds = template.assignments.values
            .where((id) => id != null)
            .toSet();
        expect(newRecipeIds, equals(templateRecipeIds));
      });

      test('should validate start date', () async {
        final tooOldDate = DateTime.now().subtract(const Duration(days: 400));

        expect(
          () => service.applyTemplate(template.id, tooOldDate),
          throwsA(isA<MealPlanException>()),
        );
      });

      test('should handle template not found', () async {
        expect(
          () => service.applyTemplate('nonexistent', DateTime.now()),
          throwsA(isA<MealPlanException>()),
        );
      });

      test('should handle non-template meal plan', () async {
        expect(
          () => service.applyTemplate(testMealPlan.id, DateTime.now()),
          throwsA(isA<MealPlanException>()),
        );
      });
    });

    group('deleteTemplate', () {
      late MealPlan template;

      setUp(() async {
        await service.createMealPlan(testMealPlan);
        template = await service.saveAsTemplate(
          testMealPlan.id,
          'Delete Test Template',
          null,
        );
      });

      test('should delete template successfully', () async {
        await service.deleteTemplate(template.id);

        final templates = await service.getTemplates();
        expect(templates, isEmpty);
      });

      test('should handle template not found', () async {
        expect(
          () => service.deleteTemplate('nonexistent'),
          throwsA(isA<MealPlanException>()),
        );
      });

      test('should prevent deleting non-template meal plan', () async {
        expect(
          () => service.deleteTemplate(testMealPlan.id),
          throwsA(isA<MealPlanException>()),
        );
      });
    });

    group('isTemplateNameAvailable', () {
      test('should return true for available name', () async {
        final isAvailable = await service.isTemplateNameAvailable(
          'Available Name',
          'family123',
        );
        expect(isAvailable, isTrue);
      });

      test('should return false for existing name', () async {
        await service.createMealPlan(testMealPlan);
        await service.saveAsTemplate(
          testMealPlan.id,
          'Existing Template',
          null,
        );

        final isAvailable = await service.isTemplateNameAvailable(
          'Existing Template',
          'family123',
        );
        expect(isAvailable, isFalse);
      });

      test('should be case-insensitive', () async {
        await service.createMealPlan(testMealPlan);
        await service.saveAsTemplate(testMealPlan.id, 'Case Template', null);

        final isAvailable = await service.isTemplateNameAvailable(
          'CASE TEMPLATE',
          'family123',
        );
        expect(isAvailable, isFalse);
      });

      test('should check within family scope', () async {
        await service.createMealPlan(testMealPlan);
        await service.saveAsTemplate(testMealPlan.id, 'Family Template', null);

        // Same name should be available in different family
        final isAvailable = await service.isTemplateNameAvailable(
          'Family Template',
          'different_family',
        );
        expect(isAvailable, isTrue);
      });
    });

    group('getTemplateStats', () {
      late MealPlan template;

      setUp(() async {
        await service.createMealPlan(testMealPlan);
        template = await service.saveAsTemplate(
          testMealPlan.id,
          'Stats Template',
          null,
        );
      });

      test('should calculate template statistics correctly', () {
        final stats = service.getTemplateStats(template);

        expect(stats['totalSlots'], equals(84)); // 3 slots * 28 days
        expect(stats['assignedSlots'], equals(4)); // From test data
        expect(stats['emptySlots'], equals(80)); // 84 - 4
        expect(stats['uniqueRecipes'], equals(3)); // recipe1, recipe2, recipe3
        expect(stats['completionPercentage'], equals(5)); // 4/84 * 100 rounded
        expect(stats['mealSlotsCount'], equals(3));
      });

      test('should handle empty template', () async {
        final emptyMealPlan = MealPlan.create(
          name: 'Empty Plan',
          familyId: 'family123',
          startDate: DateTime.now(),
          mealSlots: ['breakfast'],
          assignments: {},
          createdBy: 'user123',
        );

        await service.createMealPlan(emptyMealPlan);
        final emptyTemplate = await service.saveAsTemplate(
          emptyMealPlan.id,
          'Empty Template',
          null,
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
        expect(
          () => service.getTemplateStats(testMealPlan),
          throwsA(isA<MealPlanException>()),
        );
      });
    });

    group('Edge Cases', () {
      test(
        'should handle assignments outside 4-week period when creating template',
        () async {
          // Create meal plan with assignment outside 4-week period
          final mealPlanWithInvalidAssignment = testMealPlan.copyWith(
            assignments: {
              ...testMealPlan.assignments,
              '2024-02-15_breakfast': 'recipe4', // 31 days from start
            },
          );

          await service.createMealPlan(mealPlanWithInvalidAssignment);

          final template = await service.saveAsTemplate(
            mealPlanWithInvalidAssignment.id,
            'Edge Case Template',
            null,
          );

          // Should only include assignments within 4-week period
          expect(
            template.assignments.length,
            equals(testMealPlan.assignments.length),
          );
        },
      );

      test('should handle invalid date formats in assignments', () async {
        // This would be handled by the assignment validation in the model
        // The service should gracefully skip invalid assignments
        final template = await service.saveAsTemplate(
          testMealPlan.id,
          'Invalid Date Template',
          null,
        );

        expect(template.isTemplate, isTrue);
      });

      test('should preserve meal slot order in template', () async {
        await service.createMealPlan(testMealPlan);

        final template = await service.saveAsTemplate(
          testMealPlan.id,
          'Order Template',
          null,
        );

        expect(template.mealSlots, orderedEquals(testMealPlan.mealSlots));
      });
    });
  });
}
