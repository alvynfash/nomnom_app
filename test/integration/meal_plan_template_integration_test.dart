import 'package:flutter_test/flutter_test.dart';
import 'package:nomnom/models/meal_plan.dart';
import 'package:nomnom/services/meal_plan_service.dart';

void main() {
  group('Meal Plan Template Integration Tests', () {
    late MealPlanService service;

    setUp(() {
      service = MealPlanService();
    });

    test('should complete full template workflow', () async {
      // This test verifies the template creation logic without database operations

      // 1. Create a meal plan with assignments
      final originalPlan = MealPlan.create(
        name: 'Weekly Family Plan',
        familyId: 'family123',
        startDate: DateTime.now(),
        mealSlots: ['breakfast', 'lunch', 'dinner'],
        assignments: {
          // Add some sample assignments
          MealPlan.generateAssignmentKey(DateTime.now(), 'breakfast'):
              'recipe1',
          MealPlan.generateAssignmentKey(
            DateTime.now().add(Duration(days: 1)),
            'lunch',
          ): 'recipe2',
          MealPlan.generateAssignmentKey(
            DateTime.now().add(Duration(days: 2)),
            'dinner',
          ): 'recipe3',
        },
        createdBy: 'user123',
      );

      // Verify the original plan is valid
      expect(originalPlan.isValid, isTrue);
      expect(originalPlan.isTemplate, isFalse);
      expect(originalPlan.assignments.length, equals(3));

      // 2. Test template name validation
      expect(
        () => service.getTemplateStats(originalPlan),
        throwsA(isA<MealPlanException>()),
      );

      // 3. Create a template manually (simulating the saveAsTemplate logic)
      final template = originalPlan.copyWith(
        id: 'template_123',
        name: 'Family Weekly Template',
        startDate: DateTime(
          DateTime.now().year,
          1,
          1,
        ), // Reference date - current year
        isTemplate: true,
        templateName: 'Family Weekly Template',
        templateDescription: 'Our standard weekly meal plan',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Verify template properties
      expect(template.isTemplate, isTrue);
      expect(template.templateName, equals('Family Weekly Template'));
      expect(
        template.templateDescription,
        equals('Our standard weekly meal plan'),
      );

      // Validate template
      final validationErrors = template.getValidationErrors();
      expect(validationErrors, isEmpty, reason: 'Template should be valid');
      expect(template.isValid, isTrue);

      // 4. Test template statistics
      final stats = service.getTemplateStats(template);
      expect(stats['totalSlots'], equals(84)); // 3 slots * 28 days
      expect(stats['assignedSlots'], equals(3));
      expect(stats['emptySlots'], equals(81));
      expect(stats['uniqueRecipes'], equals(3));
      expect(stats['mealSlotsCount'], equals(3));

      // 5. Test calendar utilities with template
      final weekDates = service.generateWeekDates(template.startDate, 0);
      expect(weekDates.length, equals(7));
      expect(weekDates.first, equals(template.startDate));

      final allDates = service.generateFourWeekDates(template.startDate);
      expect(allDates.length, equals(28));

      // 6. Test assignment key generation
      final testDate = DateTime(DateTime.now().year, 1, 15);
      final key = service.generateAssignmentKey(testDate, 'breakfast');
      final expectedKey = '${DateTime.now().year}-01-15_breakfast';
      expect(key, equals(expectedKey));

      // 7. Verify template can be used for date calculations
      final currentWeek = service.getCurrentWeekNumber(
        template.startDate,
        template.startDate.add(Duration(days: 10)),
      );
      expect(currentWeek, equals(1)); // Second week

      // 8. Test date range formatting
      final weekRange = service.formatWeekRange(template.startDate, 0);
      final expectedRange = template.startDate.day == 1
          ? '1/1 - 1/7'
          : '${template.startDate.month}/${template.startDate.day} - ${template.startDate.add(Duration(days: 6)).month}/${template.startDate.add(Duration(days: 6)).day}';
      expect(weekRange, equals(expectedRange));
    });

    test('should handle template validation edge cases', () {
      // Test empty template name
      final invalidTemplate = MealPlan.create(
        name: 'Invalid Template',
        familyId: 'family123',
        startDate: DateTime(DateTime.now().year, 1, 1),
        mealSlots: ['breakfast'],
        assignments: {},
        isTemplate: true,
        templateName: '', // Empty name should be invalid
        createdBy: 'user123',
      );

      expect(invalidTemplate.isValid, isFalse);
      final errors = invalidTemplate.getValidationErrors();
      expect(errors.containsKey('template'), isTrue);
    });

    test('should handle meal slot validation', () {
      // Test too many meal slots
      final tooManySlots = List.generate(10, (i) => 'slot$i');

      final invalidPlan = MealPlan.create(
        name: 'Too Many Slots',
        familyId: 'family123',
        startDate: DateTime.now(),
        mealSlots: tooManySlots,
        assignments: {},
        createdBy: 'user123',
      );

      expect(invalidPlan.isValid, isFalse);
      final errors = invalidPlan.getValidationErrors();
      expect(errors.containsKey('mealSlots'), isTrue);
    });

    test('should handle assignment key validation', () {
      // Test invalid assignment key format
      final invalidAssignments = {
        'invalid_key_format': 'recipe1',
        'also-invalid': 'recipe2',
      };

      final invalidPlan = MealPlan.create(
        name: 'Invalid Assignments',
        familyId: 'family123',
        startDate: DateTime.now(),
        mealSlots: ['breakfast'],
        assignments: invalidAssignments,
        createdBy: 'user123',
      );

      expect(invalidPlan.isValid, isFalse);
      final errors = invalidPlan.getValidationErrors();
      expect(errors.containsKey('assignments'), isTrue);
    });

    test('should calculate completion percentage correctly', () {
      // Create template with partial assignments
      final currentYear = DateTime.now().year;
      final partialTemplate = MealPlan.create(
        name: 'Partial Template',
        familyId: 'family123',
        startDate: DateTime(currentYear, 1, 1),
        mealSlots: ['breakfast', 'lunch'], // 2 slots
        assignments: {
          '$currentYear-01-01_breakfast': 'recipe1',
          '$currentYear-01-01_lunch': 'recipe2',
          '$currentYear-01-02_breakfast': 'recipe1',
          // 3 out of 56 total slots (2 slots * 28 days)
        },
        isTemplate: true,
        templateName: 'Partial Template',
        createdBy: 'user123',
      );

      final stats = service.getTemplateStats(partialTemplate);
      expect(stats['totalSlots'], equals(56)); // 2 slots * 28 days
      expect(stats['assignedSlots'], equals(3));
      expect(
        stats['completionPercentage'],
        equals(5),
      ); // 3/56 * 100 = 5.36 rounded to 5
    });

    test('should handle recipe counting correctly', () {
      // Create template with duplicate recipes
      final currentYear = DateTime.now().year;
      final templateWithDuplicates = MealPlan.create(
        name: 'Duplicate Recipe Template',
        familyId: 'family123',
        startDate: DateTime(currentYear, 1, 1),
        mealSlots: ['breakfast', 'lunch', 'dinner'],
        assignments: {
          '$currentYear-01-01_breakfast': 'recipe1',
          '$currentYear-01-01_lunch': 'recipe2',
          '$currentYear-01-01_dinner': 'recipe1', // Duplicate
          '$currentYear-01-02_breakfast': 'recipe1', // Another duplicate
          '$currentYear-01-02_lunch': 'recipe3',
        },
        isTemplate: true,
        templateName: 'Duplicate Recipe Template',
        createdBy: 'user123',
      );

      final stats = service.getTemplateStats(templateWithDuplicates);
      expect(stats['uniqueRecipes'], equals(3)); // recipe1, recipe2, recipe3
      expect(stats['assignedSlots'], equals(5)); // Total assignments
    });
  });
}
