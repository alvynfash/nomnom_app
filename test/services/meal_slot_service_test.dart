import 'package:flutter_test/flutter_test.dart';
import 'package:nomnom/models/meal_slot.dart';
import 'package:nomnom/services/meal_slot_service.dart';

void main() {
  group('MealSlotService API Structure Tests', () {
    late MealSlotService service;

    setUp(() {
      service = MealSlotService();
    });

    group('Service API Structure', () {
      test('has all required methods', () {
        expect(service.getDefaultMealSlots, isA<Function>());
        expect(service.getFamilyMealSlots, isA<Function>());
        expect(service.updateFamilyMealSlots, isA<Function>());
        expect(service.addMealSlot, isA<Function>());
        expect(service.removeMealSlot, isA<Function>());
        expect(service.updateMealSlot, isA<Function>());
        expect(service.resetToDefaultSlots, isA<Function>());
        expect(service.getMealSlotById, isA<Function>());
        expect(service.getNextAvailableOrder, isA<Function>());
        expect(service.reorderMealSlots, isA<Function>());
      });
    });

    group('Default Meal Slots', () {
      test('should return default meal slots', () async {
        final defaultSlots = await service.getDefaultMealSlots();

        expect(defaultSlots.length, equals(4));
        expect(defaultSlots[0].name, equals('Breakfast'));
        expect(defaultSlots[1].name, equals('Lunch'));
        expect(defaultSlots[2].name, equals('Dinner'));
        expect(defaultSlots[3].name, equals('Snacks'));

        // Check that all are marked as default
        for (final slot in defaultSlots) {
          expect(slot.isDefault, isTrue);
        }

        // Check ordering
        expect(defaultSlots[0].order, equals(1));
        expect(defaultSlots[1].order, equals(2));
        expect(defaultSlots[2].order, equals(3));
        expect(defaultSlots[3].order, equals(4));
      });

      test('should return consistent default slots', () async {
        final slots1 = await service.getDefaultMealSlots();
        final slots2 = await service.getDefaultMealSlots();

        expect(slots1.length, equals(slots2.length));
        for (int i = 0; i < slots1.length; i++) {
          expect(slots1[i].name, equals(slots2[i].name));
          expect(slots1[i].order, equals(slots2[i].order));
          expect(slots1[i].isDefault, equals(slots2[i].isDefault));
        }
      });
    });

    group('Validation Logic', () {
      test('should validate meal slots before updating', () async {
        final invalidSlots = [
          MealSlot(id: 'test1', name: '', order: 1), // Invalid: empty name
          MealSlot(id: 'test2', name: 'Valid', order: 2),
        ];

        expect(
          () => service.updateFamilyMealSlots('family123', invalidSlots),
          throwsA(isA<MealSlotException>()),
        );
      });

      test('should reject duplicate slot names', () async {
        final duplicateNameSlots = [
          MealSlot(id: 'test1', name: 'Breakfast', order: 1),
          MealSlot(
            id: 'test2',
            name: 'breakfast',
            order: 2,
          ), // Case-insensitive duplicate
        ];

        expect(
          () => service.updateFamilyMealSlots('family123', duplicateNameSlots),
          throwsA(isA<MealSlotException>()),
        );
      });

      test('should reject duplicate slot orders', () async {
        final duplicateOrderSlots = [
          MealSlot(id: 'test1', name: 'Breakfast', order: 1),
          MealSlot(id: 'test2', name: 'Lunch', order: 1), // Duplicate order
        ];

        expect(
          () => service.updateFamilyMealSlots('family123', duplicateOrderSlots),
          throwsA(isA<MealSlotException>()),
        );
      });

      test('should accept valid meal slots', () {
        final validSlots = [
          MealSlot(id: 'test1', name: 'Breakfast', order: 1),
          MealSlot(id: 'test2', name: 'Lunch', order: 2),
          MealSlot(id: 'test3', name: 'Dinner', order: 3),
        ];

        // All slots should be individually valid
        for (final slot in validSlots) {
          expect(slot.isValid, isTrue);
        }

        // No duplicate names
        final names = validSlots.map((s) => s.name.toLowerCase()).toSet();
        expect(names.length, equals(validSlots.length));

        // No duplicate orders
        final orders = validSlots.map((s) => s.order).toSet();
        expect(orders.length, equals(validSlots.length));
      });
    });

    group('Error Handling', () {
      test('should throw MealSlotException with correct structure', () {
        final exception = MealSlotException('Test message', 'TEST_CODE');

        expect(exception.message, equals('Test message'));
        expect(exception.code, equals('TEST_CODE'));
        expect(exception.toString(), contains('MealSlotException'));
        expect(exception.toString(), contains('Test message'));
        expect(exception.toString(), contains('TEST_CODE'));
      });

      test('should handle validation errors properly', () {
        // Test various validation scenarios
        final emptyNameSlot = MealSlot(id: 'test', name: '', order: 1);
        expect(emptyNameSlot.isValid, isFalse);

        final invalidOrderSlot = MealSlot(id: 'test', name: 'Test', order: 0);
        expect(invalidOrderSlot.isValid, isFalse);

        final longNameSlot = MealSlot(id: 'test', name: 'a' * 31, order: 1);
        expect(longNameSlot.isValid, isFalse);
      });
    });

    group('Slot Validation Rules', () {
      test('should validate individual slot properties', () {
        // Valid slot
        final validSlot = MealSlot(id: 'test', name: 'Breakfast', order: 1);
        expect(validSlot.isValid, isTrue);

        // Invalid slot - empty name
        final invalidNameSlot = MealSlot(id: 'test', name: '', order: 1);
        expect(invalidNameSlot.isValid, isFalse);

        // Invalid slot - order less than 1
        final invalidOrderSlot = MealSlot(
          id: 'test',
          name: 'Breakfast',
          order: 0,
        );
        expect(invalidOrderSlot.isValid, isFalse);

        // Invalid slot - name too long
        final longName = 'a' * 31;
        final invalidLongNameSlot = MealSlot(
          id: 'test',
          name: longName,
          order: 1,
        );
        expect(invalidLongNameSlot.isValid, isFalse);

        // Valid slot at boundary conditions
        final maxNameSlot = MealSlot(id: 'test', name: 'a' * 30, order: 1);
        expect(maxNameSlot.isValid, isTrue);

        final minOrderSlot = MealSlot(id: 'test', name: 'Test', order: 1);
        expect(minOrderSlot.isValid, isTrue);
      });
    });

    group('Business Logic Validation', () {
      test('should handle duplicate detection correctly', () {
        final slots = [
          MealSlot(id: 'test1', name: 'Breakfast', order: 1),
          MealSlot(id: 'test2', name: 'Lunch', order: 2),
          MealSlot(id: 'test3', name: 'Dinner', order: 3),
        ];

        // Test case-insensitive duplicate detection
        final duplicateNameSlots = [
          ...slots,
          MealSlot(
            id: 'test4',
            name: 'BREAKFAST',
            order: 4,
          ), // Case-insensitive duplicate
        ];

        expect(
          () => service.updateFamilyMealSlots('family123', duplicateNameSlots),
          throwsA(isA<MealSlotException>()),
        );

        // Test duplicate order detection
        final duplicateOrderSlots = [
          ...slots,
          MealSlot(id: 'test4', name: 'Snack', order: 1), // Duplicate order
        ];

        expect(
          () => service.updateFamilyMealSlots('family123', duplicateOrderSlots),
          throwsA(isA<MealSlotException>()),
        );
      });

      test('should validate slot collections', () {
        // Test that we can create valid slot collections without database calls

        // Single valid slot should work
        final singleSlot = [MealSlot(id: 'test', name: 'Breakfast', order: 1)];
        expect(singleSlot.first.isValid, isTrue);

        // Multiple valid slots should work
        final multipleSlots = [
          MealSlot(id: 'test1', name: 'Breakfast', order: 1),
          MealSlot(id: 'test2', name: 'Lunch', order: 2),
          MealSlot(id: 'test3', name: 'Dinner', order: 3),
          MealSlot(id: 'test4', name: 'Snacks', order: 4),
        ];

        for (final slot in multipleSlots) {
          expect(slot.isValid, isTrue);
        }
      });
    });

    group('Default Slot Properties', () {
      test('should have correct default slot properties', () async {
        final defaultSlots = await service.getDefaultMealSlots();

        // Test specific properties of each default slot
        final breakfast = defaultSlots.firstWhere((s) => s.name == 'Breakfast');
        expect(breakfast.id, equals('breakfast'));
        expect(breakfast.order, equals(1));
        expect(breakfast.isDefault, isTrue);

        final lunch = defaultSlots.firstWhere((s) => s.name == 'Lunch');
        expect(lunch.id, equals('lunch'));
        expect(lunch.order, equals(2));
        expect(lunch.isDefault, isTrue);

        final dinner = defaultSlots.firstWhere((s) => s.name == 'Dinner');
        expect(dinner.id, equals('dinner'));
        expect(dinner.order, equals(3));
        expect(dinner.isDefault, isTrue);

        final snacks = defaultSlots.firstWhere((s) => s.name == 'Snacks');
        expect(snacks.id, equals('snacks'));
        expect(snacks.order, equals(4));
        expect(snacks.isDefault, isTrue);
      });

      test('should maintain slot ordering', () async {
        final defaultSlots = await service.getDefaultMealSlots();

        // Check that slots are ordered correctly
        for (int i = 0; i < defaultSlots.length - 1; i++) {
          expect(defaultSlots[i].order, lessThan(defaultSlots[i + 1].order));
        }
      });
    });

    group('Service Method Signatures', () {
      test('should have correct method signatures', () {
        // Test that methods have the expected parameter types
        expect(
          service.getDefaultMealSlots,
          isA<Future<List<MealSlot>> Function()>(),
        );
        expect(
          service.getFamilyMealSlots,
          isA<Future<List<MealSlot>> Function(String)>(),
        );
        expect(
          service.updateFamilyMealSlots,
          isA<Future<void> Function(String, List<MealSlot>)>(),
        );
        expect(
          service.addMealSlot,
          isA<Future<void> Function(String, MealSlot)>(),
        );
        expect(
          service.removeMealSlot,
          isA<Future<void> Function(String, String)>(),
        );
        expect(
          service.updateMealSlot,
          isA<Future<void> Function(String, String, MealSlot)>(),
        );
        expect(
          service.resetToDefaultSlots,
          isA<Future<void> Function(String)>(),
        );
        expect(
          service.getMealSlotById,
          isA<Future<MealSlot?> Function(String, String)>(),
        );
        expect(
          service.getNextAvailableOrder,
          isA<Future<int> Function(String)>(),
        );
        expect(
          service.reorderMealSlots,
          isA<Future<void> Function(String, List<String>)>(),
        );
      });
    });
  });
}
