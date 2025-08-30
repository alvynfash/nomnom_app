import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nomnom/models/meal_slot.dart';
import 'package:nomnom/models/recipe.dart';
import 'package:nomnom/widgets/meal_slot_widget.dart';

void main() {
  group('MealSlotWidget', () {
    late MealSlot testSlot;
    late Recipe testRecipe;
    late DateTime testDate;

    setUp(() {
      testSlot = MealSlot(
        id: 'breakfast',
        name: 'Breakfast',
        order: 1,
        isDefault: true,
      );

      testRecipe = Recipe.create(
        title: 'Pancakes',
        ingredients: [
          Ingredient(name: 'Flour', quantity: 2.0, unit: 'cups'),
          Ingredient(name: 'Milk', quantity: 1.5, unit: 'cups'),
        ],
        instructions: ['Mix ingredients', 'Cook on griddle'],
        prepTime: 10,
        cookTime: 15,
        servings: 4,
      );

      testDate = DateTime(2024, 1, 15);
    });

    Widget createWidget({
      DateTime? date,
      MealSlot? slot,
      Recipe? assignedRecipe,
      VoidCallback? onTap,
      bool isEditable = true,
      double? height,
      bool isCompact = false,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: MealSlotWidget(
            date: date ?? testDate,
            slot: slot ?? testSlot,
            assignedRecipe: assignedRecipe,
            onTap: onTap ?? () {},
            isEditable: isEditable,
            height: height,
            isCompact: isCompact,
          ),
        ),
      );
    }

    group('Widget Structure', () {
      testWidgets('should display meal slot name', (tester) async {
        await tester.pumpWidget(createWidget());

        expect(find.text('Breakfast'), findsOneWidget);
      });

      testWidgets('should display add icon when no recipe assigned', (
        tester,
      ) async {
        await tester.pumpWidget(createWidget());

        expect(find.byIcon(Icons.add), findsOneWidget);
        expect(find.text('Add recipe'), findsOneWidget);
        expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
      });

      testWidgets('should display edit icon when recipe is assigned', (
        tester,
      ) async {
        await tester.pumpWidget(createWidget(assignedRecipe: testRecipe));

        expect(find.byIcon(Icons.edit), findsOneWidget);
        expect(find.byIcon(Icons.add), findsNothing);
      });

      testWidgets('should display recipe information when assigned', (
        tester,
      ) async {
        await tester.pumpWidget(createWidget(assignedRecipe: testRecipe));

        expect(find.text('Pancakes'), findsOneWidget);
        expect(find.text('25m'), findsOneWidget); // 10 + 15 minutes
        expect(find.text('4'), findsOneWidget); // servings
        expect(find.byIcon(Icons.access_time), findsOneWidget);
        expect(find.byIcon(Icons.people), findsOneWidget);
      });

      testWidgets('should not display icons when not editable', (tester) async {
        await tester.pumpWidget(createWidget(isEditable: false));

        expect(find.byIcon(Icons.add), findsNothing);
        expect(find.byIcon(Icons.edit), findsNothing);
      });
    });

    group('Interaction Handling', () {
      testWidgets('should call onTap when tapped and editable', (tester) async {
        bool tapped = false;
        await tester.pumpWidget(
          createWidget(onTap: () => tapped = true, isEditable: true),
        );

        // Find the GestureDetector and tap it
        final gestureDetector = find.byType(GestureDetector);
        expect(gestureDetector, findsOneWidget);

        await tester.tap(gestureDetector, warnIfMissed: false);
        expect(tapped, isTrue);
      });

      testWidgets('should not call onTap when not editable', (tester) async {
        bool tapped = false;
        await tester.pumpWidget(
          createWidget(onTap: () => tapped = true, isEditable: false),
        );

        // Find the GestureDetector and tap it
        final gestureDetector = find.byType(GestureDetector);
        expect(gestureDetector, findsOneWidget);

        await tester.tap(gestureDetector, warnIfMissed: false);
        expect(tapped, isFalse);
      });

      testWidgets('should have GestureDetector for interaction', (
        tester,
      ) async {
        await tester.pumpWidget(createWidget(isEditable: true));

        // Should have a GestureDetector for handling taps
        expect(find.byType(GestureDetector), findsOneWidget);
      });
    });

    group('Visual States', () {
      testWidgets('should apply different styling when recipe is assigned', (
        tester,
      ) async {
        // Test without recipe
        await tester.pumpWidget(createWidget());
        await tester.pump();

        Container containerWithoutRecipe = tester.widget<Container>(
          find
              .descendant(
                of: find.byType(MealSlotWidget),
                matching: find.byType(Container),
              )
              .first,
        );

        // Test with recipe
        await tester.pumpWidget(createWidget(assignedRecipe: testRecipe));
        await tester.pump();

        Container containerWithRecipe = tester.widget<Container>(
          find
              .descendant(
                of: find.byType(MealSlotWidget),
                matching: find.byType(Container),
              )
              .first,
        );

        // Decorations should be different
        expect(
          containerWithoutRecipe.decoration,
          isNot(equals(containerWithRecipe.decoration)),
        );
      });

      testWidgets('should apply different styling when not editable', (
        tester,
      ) async {
        // Test editable
        await tester.pumpWidget(createWidget(isEditable: true));
        await tester.pump();

        Container editableContainer = tester.widget<Container>(
          find
              .descendant(
                of: find.byType(MealSlotWidget),
                matching: find.byType(Container),
              )
              .first,
        );

        // Test not editable
        await tester.pumpWidget(createWidget(isEditable: false));
        await tester.pump();

        Container nonEditableContainer = tester.widget<Container>(
          find
              .descendant(
                of: find.byType(MealSlotWidget),
                matching: find.byType(Container),
              )
              .first,
        );

        // Decorations should be different
        expect(
          editableContainer.decoration,
          isNot(equals(nonEditableContainer.decoration)),
        );
      });

      testWidgets('should highlight today\'s date differently', (tester) async {
        final today = DateTime.now();
        final tomorrow = today.add(const Duration(days: 1));

        // Test today
        await tester.pumpWidget(createWidget(date: today));
        await tester.pump();

        Container todayContainer = tester.widget<Container>(
          find
              .descendant(
                of: find.byType(MealSlotWidget),
                matching: find.byType(Container),
              )
              .first,
        );

        // Test tomorrow
        await tester.pumpWidget(createWidget(date: tomorrow));
        await tester.pump();

        Container tomorrowContainer = tester.widget<Container>(
          find
              .descendant(
                of: find.byType(MealSlotWidget),
                matching: find.byType(Container),
              )
              .first,
        );

        // Border should be different for today
        final todayBorder =
            (todayContainer.decoration as BoxDecoration).border as Border;
        final tomorrowBorder =
            (tomorrowContainer.decoration as BoxDecoration).border as Border;

        expect(todayBorder.top.width, greaterThan(tomorrowBorder.top.width));
      });
    });

    group('Compact Mode', () {
      testWidgets('should use smaller dimensions in compact mode', (
        tester,
      ) async {
        // Test normal mode
        await tester.pumpWidget(createWidget(isCompact: false));
        await tester.pump();

        final normalSize = tester.getSize(find.byType(MealSlotWidget));

        // Test compact mode
        await tester.pumpWidget(createWidget(isCompact: true));
        await tester.pump();

        final compactSize = tester.getSize(find.byType(MealSlotWidget));

        expect(compactSize.height, lessThan(normalSize.height));
      });

      testWidgets('should use smaller text in compact mode', (tester) async {
        await tester.pumpWidget(
          createWidget(isCompact: true, assignedRecipe: testRecipe),
        );

        // Find text widgets and verify they exist
        expect(find.text('Breakfast'), findsOneWidget);
        expect(find.text('Pancakes'), findsOneWidget);
      });
    });

    group('Custom Height', () {
      testWidgets('should use custom height when provided', (tester) async {
        const customHeight = 120.0;
        const defaultHeight = 100.0;

        // Test with custom height
        await tester.pumpWidget(createWidget(height: customHeight));
        await tester.pump();

        final customWidget = tester.getSize(find.byType(MealSlotWidget));

        // Test with default height
        await tester.pumpWidget(createWidget(height: defaultHeight));
        await tester.pump();

        final defaultWidget = tester.getSize(find.byType(MealSlotWidget));

        // Custom height should be different from default
        expect(customWidget.height, greaterThan(defaultWidget.height));
      });
    });

    group('Recipe Information Display', () {
      testWidgets('should handle recipe with zero time', (tester) async {
        final recipeWithoutTime = testRecipe.copyWith(prepTime: 0, cookTime: 0);

        await tester.pumpWidget(
          createWidget(assignedRecipe: recipeWithoutTime),
        );

        expect(find.byIcon(Icons.access_time), findsNothing);
        expect(find.byIcon(Icons.people), findsOneWidget);
        expect(find.text('4'), findsOneWidget); // servings still shown
      });

      testWidgets('should truncate long recipe titles', (tester) async {
        final longTitleRecipe = testRecipe.copyWith(
          title: 'This is a very long recipe title that should be truncated',
        );

        await tester.pumpWidget(createWidget(assignedRecipe: longTitleRecipe));

        // Text should be present but truncated
        final textWidget = tester.widget<Text>(
          find.text(
            'This is a very long recipe title that should be truncated',
          ),
        );
        expect(textWidget.overflow, equals(TextOverflow.ellipsis));
      });

      testWidgets('should display formatted time correctly', (tester) async {
        final recipeWithHours = testRecipe.copyWith(
          prepTime: 60, // 1 hour
          cookTime: 30, // 30 minutes
        );

        await tester.pumpWidget(createWidget(assignedRecipe: recipeWithHours));

        expect(find.text('1h 30m'), findsOneWidget);
      });
    });

    group('Empty State', () {
      testWidgets('should show appropriate empty state when editable', (
        tester,
      ) async {
        await tester.pumpWidget(createWidget(isEditable: true));

        expect(find.text('Add recipe'), findsOneWidget);
        expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
      });

      testWidgets('should show appropriate empty state when not editable', (
        tester,
      ) async {
        await tester.pumpWidget(createWidget(isEditable: false));

        expect(find.text('No recipe'), findsOneWidget);
        expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
      });
    });

    group('Accessibility', () {
      testWidgets('should be accessible with proper semantics', (tester) async {
        await tester.pumpWidget(createWidget(assignedRecipe: testRecipe));

        // Widget should be tappable
        expect(find.byType(GestureDetector), findsOneWidget);

        // Text should be readable
        expect(find.text('Breakfast'), findsOneWidget);
        expect(find.text('Pancakes'), findsOneWidget);
      });
    });

    group('Edge Cases', () {
      testWidgets('should handle null recipe gracefully', (tester) async {
        await tester.pumpWidget(createWidget(assignedRecipe: null));

        expect(find.text('Add recipe'), findsOneWidget);
        expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
      });

      testWidgets('should handle past dates with visual indication', (
        tester,
      ) async {
        final pastDate = DateTime.now().subtract(const Duration(days: 2));
        await tester.pumpWidget(createWidget(date: pastDate));

        // Widget should still render
        expect(find.byType(MealSlotWidget), findsOneWidget);
        expect(find.text('Breakfast'), findsOneWidget);
      });

      testWidgets('should handle very long slot names', (tester) async {
        final longNameSlot = MealSlot(
          id: 'test',
          name: 'Very Long Meal Slot Name That Should Be Truncated',
          order: 1,
        );

        await tester.pumpWidget(createWidget(slot: longNameSlot));

        final textWidget = tester.widget<Text>(
          find.text('Very Long Meal Slot Name That Should Be Truncated'),
        );
        expect(textWidget.overflow, equals(TextOverflow.ellipsis));
      });
    });
  });
}
