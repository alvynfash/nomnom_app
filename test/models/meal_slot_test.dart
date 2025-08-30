import 'package:flutter_test/flutter_test.dart';
import 'package:nomnom/models/meal_slot.dart';

void main() {
  group('MealSlot Model Tests', () {
    late MealSlot validMealSlot;

    setUp(() {
      validMealSlot = MealSlot(
        id: 'breakfast',
        name: 'Breakfast',
        order: 1,
        isDefault: true,
      );
    });

    group('MealSlot Creation', () {
      test('should create a valid meal slot with all fields', () {
        expect(validMealSlot.id, equals('breakfast'));
        expect(validMealSlot.name, equals('Breakfast'));
        expect(validMealSlot.order, equals(1));
        expect(validMealSlot.isDefault, isTrue);
      });

      test('should create meal slot with generated ID', () {
        final createdSlot = MealSlot.create(
          name: 'Snack',
          order: 5,
          isDefault: false,
        );

        expect(createdSlot.id, isNotEmpty);
        expect(createdSlot.id, startsWith('slot_'));
        expect(createdSlot.name, equals('Snack'));
        expect(createdSlot.order, equals(5));
        expect(createdSlot.isDefault, isFalse);
      });

      test('should generate unique IDs for different meal slots', () {
        final slot1 = MealSlot.create(name: 'Slot 1', order: 1);
        final slot2 = MealSlot.create(name: 'Slot 2', order: 2);

        expect(slot1.id, isNot(equals(slot2.id)));
      });

      test('should default isDefault to false when not specified', () {
        final slot = MealSlot(id: 'test', name: 'Test', order: 1);
        expect(slot.isDefault, isFalse);
      });
    });

    group('Default Slots', () {
      test('should provide correct default meal slots', () {
        final defaultSlots = MealSlot.getDefaultSlots();

        expect(defaultSlots.length, equals(4));

        expect(defaultSlots[0].id, equals('breakfast'));
        expect(defaultSlots[0].name, equals('Breakfast'));
        expect(defaultSlots[0].order, equals(1));
        expect(defaultSlots[0].isDefault, isTrue);

        expect(defaultSlots[1].id, equals('lunch'));
        expect(defaultSlots[1].name, equals('Lunch'));
        expect(defaultSlots[1].order, equals(2));
        expect(defaultSlots[1].isDefault, isTrue);

        expect(defaultSlots[2].id, equals('dinner'));
        expect(defaultSlots[2].name, equals('Dinner'));
        expect(defaultSlots[2].order, equals(3));
        expect(defaultSlots[2].isDefault, isTrue);

        expect(defaultSlots[3].id, equals('snacks'));
        expect(defaultSlots[3].name, equals('Snacks'));
        expect(defaultSlots[3].order, equals(4));
        expect(defaultSlots[3].isDefault, isTrue);
      });

      test('should return new instances each time', () {
        final slots1 = MealSlot.getDefaultSlots();
        final slots2 = MealSlot.getDefaultSlots();

        expect(identical(slots1, slots2), isFalse);
        expect(slots1.length, equals(slots2.length));
      });
    });

    group('Serialization', () {
      test('should serialize to map correctly', () {
        final map = validMealSlot.toMap();

        expect(map['id'], equals('breakfast'));
        expect(map['name'], equals('Breakfast'));
        expect(map['order'], equals(1));
        expect(map['isDefault'], isTrue);
      });

      test('should deserialize from map correctly', () {
        final map = validMealSlot.toMap();
        final deserializedSlot = MealSlot.fromMap(map);

        expect(deserializedSlot.id, equals(validMealSlot.id));
        expect(deserializedSlot.name, equals(validMealSlot.name));
        expect(deserializedSlot.order, equals(validMealSlot.order));
        expect(deserializedSlot.isDefault, equals(validMealSlot.isDefault));
      });

      test('should handle JSON serialization', () {
        final json = validMealSlot.toJson();
        final fromJson = MealSlot.fromJson(json);

        expect(fromJson.id, equals(validMealSlot.id));
        expect(fromJson.name, equals(validMealSlot.name));
        expect(fromJson.order, equals(validMealSlot.order));
        expect(fromJson.isDefault, equals(validMealSlot.isDefault));
      });

      test('should handle missing isDefault in deserialization', () {
        final map = {
          'id': 'test',
          'name': 'Test',
          'order': 1,
          // isDefault missing
        };

        final slot = MealSlot.fromMap(map);
        expect(slot.isDefault, isFalse);
      });
    });

    group('Validation', () {
      test('should validate valid meal slot', () {
        expect(validMealSlot.isValid, isTrue);
        expect(() => validMealSlot.validate(), returnsNormally);
      });

      test('should reject empty name', () {
        final invalidSlot = MealSlot(id: 'test', name: '', order: 1);
        expect(invalidSlot.isValid, isFalse);
        expect(() => invalidSlot.validate(), throwsA(isA<MealSlotException>()));
      });

      test('should reject whitespace-only name', () {
        final invalidSlot = MealSlot(id: 'test', name: '   ', order: 1);
        expect(invalidSlot.isValid, isFalse);
        expect(() => invalidSlot.validate(), throwsA(isA<MealSlotException>()));
      });

      test('should reject name too long', () {
        final longName = 'a' * 31;
        final invalidSlot = MealSlot(id: 'test', name: longName, order: 1);
        expect(invalidSlot.isValid, isFalse);
        expect(() => invalidSlot.validate(), throwsA(isA<MealSlotException>()));
      });

      test('should reject order less than 1', () {
        final invalidSlot = MealSlot(id: 'test', name: 'Test', order: 0);
        expect(invalidSlot.isValid, isFalse);
        expect(() => invalidSlot.validate(), throwsA(isA<MealSlotException>()));
      });

      test('should accept name at maximum length', () {
        final maxName = 'a' * 30;
        final validSlot = MealSlot(id: 'test', name: maxName, order: 1);
        expect(validSlot.isValid, isTrue);
      });
    });

    group('Copy Operations', () {
      test('should copy with updated values', () {
        final updatedSlot = validMealSlot.copyWith(
          name: 'Updated Breakfast',
          order: 2,
        );

        expect(updatedSlot.name, equals('Updated Breakfast'));
        expect(updatedSlot.order, equals(2));
        expect(
          updatedSlot.id,
          equals(validMealSlot.id),
        ); // Should keep original ID
        expect(updatedSlot.isDefault, equals(validMealSlot.isDefault));
      });

      test('should copy without changing original', () {
        final originalName = validMealSlot.name;
        final updatedSlot = validMealSlot.copyWith(name: 'New Name');

        expect(validMealSlot.name, equals(originalName));
        expect(updatedSlot.name, equals('New Name'));
      });

      test('should copy with null values keeping originals', () {
        final copiedSlot = validMealSlot.copyWith();

        expect(copiedSlot.id, equals(validMealSlot.id));
        expect(copiedSlot.name, equals(validMealSlot.name));
        expect(copiedSlot.order, equals(validMealSlot.order));
        expect(copiedSlot.isDefault, equals(validMealSlot.isDefault));
      });
    });

    group('Equality and Hash', () {
      test('should be equal when all properties match', () {
        final slot1 = MealSlot(
          id: 'test',
          name: 'Test',
          order: 1,
          isDefault: true,
        );
        final slot2 = MealSlot(
          id: 'test',
          name: 'Test',
          order: 1,
          isDefault: true,
        );

        expect(slot1, equals(slot2));
        expect(slot1.hashCode, equals(slot2.hashCode));
      });

      test('should not be equal when properties differ', () {
        final slot1 = MealSlot(id: 'test1', name: 'Test', order: 1);
        final slot2 = MealSlot(id: 'test2', name: 'Test', order: 1);

        expect(slot1, isNot(equals(slot2)));
      });

      test('should be identical to itself', () {
        expect(identical(validMealSlot, validMealSlot), isTrue);
        expect(validMealSlot, equals(validMealSlot));
      });
    });

    group('String Representation', () {
      test('should provide meaningful toString', () {
        final string = validMealSlot.toString();
        expect(string, contains('MealSlot'));
        expect(string, contains('breakfast'));
        expect(string, contains('Breakfast'));
        expect(string, contains('1'));
        expect(string, contains('true'));
      });
    });
  });
}
