import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nomnom/models/meal_slot.dart';
import 'package:nomnom/screens/meal_plan_list_screen.dart';
import 'package:nomnom/services/meal_slot_service.dart';

void main() {
  group('Meal Plan Creation Integration Tests', () {
    testWidgets('should show meal slots selector in create meal plan dialog', (
      WidgetTester tester,
    ) async {
      // Build the meal plan list screen
      await tester.pumpWidget(const MaterialApp(home: MealPlanListScreen()));
      await tester.pumpAndSettle();

      // Wait for data to load
      await tester.pump(const Duration(seconds: 1));

      // Tap the floating action button to create a new meal plan
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Verify the dialog is shown
      expect(find.text('Create Meal Plan'), findsOneWidget);

      // Verify meal slots section is present
      expect(find.text('Meal Slots'), findsOneWidget);
      expect(
        find.text('Select which meal slots to include in your meal plan'),
        findsOneWidget,
      );

      // Verify default meal slots are shown
      expect(find.text('Breakfast'), findsOneWidget);
      expect(find.text('Lunch'), findsOneWidget);
      expect(find.text('Dinner'), findsOneWidget);
      expect(find.text('Snacks'), findsOneWidget);

      // Verify meal slots are selectable (FilterChip widgets)
      expect(find.byType(FilterChip), findsNWidgets(4));
    });

    testWidgets('should load default meal slots correctly', (
      WidgetTester tester,
    ) async {
      final mealSlotService = MealSlotService();

      // Test that default meal slots are loaded correctly
      final defaultSlots = await mealSlotService.getDefaultMealSlots();

      expect(defaultSlots.length, equals(4));
      expect(defaultSlots.any((slot) => slot.name == 'Breakfast'), isTrue);
      expect(defaultSlots.any((slot) => slot.name == 'Lunch'), isTrue);
      expect(defaultSlots.any((slot) => slot.name == 'Dinner'), isTrue);
      expect(defaultSlots.any((slot) => slot.name == 'Snacks'), isTrue);

      // All default slots should have isDefault = true
      for (final slot in defaultSlots) {
        expect(slot.isDefault, isTrue);
      }
    });

    testWidgets('should load family meal slots with default fallback', (
      WidgetTester tester,
    ) async {
      final mealSlotService = MealSlotService();

      // Test that family meal slots fall back to default when no custom slots exist
      final familySlots = await mealSlotService.getFamilyMealSlots(
        'default_family',
      );

      expect(familySlots.length, equals(4));
      expect(familySlots.any((slot) => slot.name == 'Breakfast'), isTrue);
      expect(familySlots.any((slot) => slot.name == 'Lunch'), isTrue);
      expect(familySlots.any((slot) => slot.name == 'Dinner'), isTrue);
      expect(familySlots.any((slot) => slot.name == 'Snacks'), isTrue);
    });

    testWidgets('should validate meal slot model correctly', (
      WidgetTester tester,
    ) async {
      // Test MealSlot validation
      final validSlot = MealSlot(
        id: 'test_id',
        name: 'Test Slot',
        order: 1,
        isDefault: true,
      );

      expect(validSlot.isValid, isTrue);
      expect(() => validSlot.validate(), returnsNormally);

      // Test invalid slot (empty name)
      final invalidSlot = MealSlot(
        id: 'test_id',
        name: '',
        order: 1,
        isDefault: false,
      );

      expect(invalidSlot.isValid, isFalse);
      expect(() => invalidSlot.validate(), throwsA(isA<MealSlotException>()));
    });
  });
}
