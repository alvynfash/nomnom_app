import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nomnom/models/meal_slot.dart';
import 'package:nomnom/widgets/meal_plan_form_dialog.dart';

void main() {
  group('MealPlanFormDialog', () {
    late List<MealSlot> testMealSlots;

    setUp(() {
      testMealSlots = MealSlot.getDefaultSlots();
    });

    testWidgets('should display meal slots selector', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => MealPlanFormDialog(
                      availableMealSlots: testMealSlots,
                      familyId: 'test_family',
                      userId: 'test_user',
                      onSave: (mealPlan) {},
                    ),
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      // Open the dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Verify dialog is shown
      expect(find.text('Create Meal Plan'), findsOneWidget);

      // Verify meal slots section is present
      expect(find.text('Meal Slots'), findsOneWidget);
      expect(
        find.text('Select which meal slots to include in your meal plan'),
        findsOneWidget,
      );

      // Verify all default meal slots are shown as chips
      expect(find.text('Breakfast'), findsOneWidget);
      expect(find.text('Lunch'), findsOneWidget);
      expect(find.text('Dinner'), findsOneWidget);
      expect(find.text('Snacks'), findsOneWidget);

      // Verify chips are selectable (should be FilterChip widgets)
      expect(find.byType(FilterChip), findsNWidgets(4));
    });

    testWidgets('should pre-select default meal slots for new meal plan', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => MealPlanFormDialog(
                      availableMealSlots: testMealSlots,
                      familyId: 'test_family',
                      userId: 'test_user',
                      onSave: (mealPlan) {},
                    ),
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      // Open the dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // All default slots should be pre-selected
      final filterChips = tester.widgetList<FilterChip>(
        find.byType(FilterChip),
      );
      for (final chip in filterChips) {
        expect(
          chip.selected,
          isTrue,
          reason: 'All default meal slots should be pre-selected',
        );
      }
    });

    testWidgets('should allow toggling meal slot selection', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => MealPlanFormDialog(
                      availableMealSlots: testMealSlots,
                      familyId: 'test_family',
                      userId: 'test_user',
                      onSave: (mealPlan) {},
                    ),
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      // Open the dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Find the breakfast chip and tap it to deselect
      final breakfastChip = find.ancestor(
        of: find.text('Breakfast'),
        matching: find.byType(FilterChip),
      );

      await tester.tap(breakfastChip);
      await tester.pumpAndSettle();

      // Verify breakfast is now deselected
      final breakfastChipWidget = tester.widget<FilterChip>(breakfastChip);
      expect(breakfastChipWidget.selected, isFalse);

      // Tap it again to reselect
      await tester.tap(breakfastChip);
      await tester.pumpAndSettle();

      // Verify breakfast is selected again
      final breakfastChipWidget2 = tester.widget<FilterChip>(breakfastChip);
      expect(breakfastChipWidget2.selected, isTrue);
    });

    testWidgets('should show error when no meal slots are selected', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => MealPlanFormDialog(
                      availableMealSlots: testMealSlots,
                      familyId: 'test_family',
                      userId: 'test_user',
                      onSave: (mealPlan) {},
                    ),
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      // Open the dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Deselect all meal slots
      for (final slot in testMealSlots) {
        final chipFinder = find.ancestor(
          of: find.text(slot.name),
          matching: find.byType(FilterChip),
        );
        await tester.tap(chipFinder);
        await tester.pumpAndSettle();
      }

      // Verify error message is shown
      expect(find.text('Please select at least one meal slot'), findsOneWidget);
    });
  });
}
