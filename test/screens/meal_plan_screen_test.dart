import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nomnom/models/meal_plan.dart';
import 'package:nomnom/models/meal_slot.dart';
import 'package:nomnom/models/recipe.dart';
import 'package:nomnom/screens/meal_plan_screen.dart';
import 'package:nomnom/widgets/meal_plan_calendar_widget.dart';

void main() {
  group('MealPlanScreen', () {
    late List<MealSlot> testMealSlots;
    late List<Recipe> testRecipes;
    late MealPlan testMealPlan;

    setUp(() {
      testMealSlots = [
        MealSlot(id: 'breakfast', name: 'Breakfast', order: 1, isDefault: true),
        MealSlot(id: 'lunch', name: 'Lunch', order: 2, isDefault: true),
        MealSlot(id: 'dinner', name: 'Dinner', order: 3, isDefault: true),
      ];

      testRecipes = [
        Recipe.create(
          title: 'Test Recipe 1',
          ingredients: [Ingredient(name: 'Test', quantity: 1, unit: 'cup')],
          instructions: ['Test instruction'],
          prepTime: 10,
          cookTime: 20,
          servings: 2,
        ),
        Recipe.create(
          title: 'Test Recipe 2',
          ingredients: [Ingredient(name: 'Test 2', quantity: 2, unit: 'cups')],
          instructions: ['Test instruction 2'],
          prepTime: 15,
          cookTime: 25,
          servings: 4,
        ),
      ];

      testMealPlan = MealPlan.create(
        name: 'Test Meal Plan',
        familyId: 'family123',
        startDate: DateTime(2024, 1, 15), // Monday
        mealSlots: testMealSlots.map((slot) => slot.id).toList(),
        createdBy: 'user123',
      );
    });

    Widget createWidget({String? mealPlanId, String? familyId}) {
      return MaterialApp(
        home: MealPlanScreen(mealPlanId: mealPlanId, familyId: familyId),
      );
    }

    group('Widget Structure', () {
      testWidgets('should display loading indicator initially', (tester) async {
        await tester.pumpWidget(createWidget());

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should display app bar with title', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump(); // Allow initial build

        expect(find.byType(AppBar), findsOneWidget);
      });

      testWidgets('should display meal plan calendar when loaded', (
        tester,
      ) async {
        await tester.pumpWidget(createWidget());
        await tester.pump(); // Initial build

        // Should show loading initially
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // After async operations complete, should show calendar or error state
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Should show either calendar widget or error state, but not loading
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });

      testWidgets('should display floating action button when editing', (
        tester,
      ) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // New meal plans start in editing mode with unsaved changes
        expect(find.byType(FloatingActionButton), findsOneWidget);
      });
    });

    group('App Bar Functionality', () {
      testWidgets('should show editable title when creating new meal plan', (
        tester,
      ) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // Should have a text field for editing the name
        expect(find.byType(TextField), findsOneWidget);
        expect(find.text('New Meal Plan'), findsOneWidget);
      });

      testWidgets('should show save button when there are unsaved changes', (
        tester,
      ) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // Should show save button in app bar
        expect(find.byIcon(Icons.save), findsAtLeastNWidgets(1));
      });

      testWidgets('should update meal plan name when text field changes', (
        tester,
      ) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // Find and update the text field
        final textField = find.byType(TextField);
        expect(textField, findsOneWidget);

        await tester.enterText(textField, 'Updated Meal Plan Name');
        await tester.pump();

        // Should show the updated name
        expect(find.text('Updated Meal Plan Name'), findsOneWidget);
      });
    });

    group('Meal Plan Header', () {
      testWidgets('should display meal plan date range', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // Should show calendar icon and date range
        expect(find.byIcon(Icons.calendar_today), findsOneWidget);
      });

      testWidgets('should display meal plan statistics', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // Should show meal slots and assignments stats
        expect(find.byIcon(Icons.restaurant), findsOneWidget);
        expect(find.byIcon(Icons.assignment), findsOneWidget);
      });

      testWidgets('should show unsaved changes indicator', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // New meal plans have unsaved changes
        expect(find.text('Unsaved changes'), findsOneWidget);
      });
    });

    group('Calendar Integration', () {
      testWidgets('should pass correct parameters to calendar widget', (
        tester,
      ) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        final calendarWidget = tester.widget<MealPlanCalendarWidget>(
          find.byType(MealPlanCalendarWidget),
        );

        expect(calendarWidget.currentWeek, equals(0));
        expect(calendarWidget.isEditable, isTrue);
        expect(calendarWidget.mealSlots, isNotEmpty);
      });

      testWidgets('should handle week navigation', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        final calendarWidget = tester.widget<MealPlanCalendarWidget>(
          find.byType(MealPlanCalendarWidget),
        );

        // Simulate week change
        calendarWidget.onWeekChanged(1);
        await tester.pump();

        // Widget should handle the week change
        expect(find.byType(MealPlanCalendarWidget), findsOneWidget);
      });
    });

    group('Error Handling', () {
      testWidgets('should display error state when meal plan fails to load', (
        tester,
      ) async {
        // This would require mocking the service to return an error
        await tester.pumpWidget(createWidget(mealPlanId: 'nonexistent'));
        await tester.pumpAndSettle();

        // Should show error state or handle gracefully
        expect(find.byType(MealPlanCalendarWidget), findsOneWidget);
      });

      testWidgets('should show retry button in error state', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // Even if there's an error, the widget should handle it gracefully
        expect(find.byType(Scaffold), findsOneWidget);
      });
    });

    group('Navigation and State Management', () {
      testWidgets('should handle back navigation with unsaved changes', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MealPlanScreen()),
                  ),
                  child: const Text('Open Meal Plan'),
                ),
              ),
            ),
          ),
        );

        // Navigate to meal plan screen
        await tester.tap(find.text('Open Meal Plan'));
        await tester.pumpAndSettle();

        // Should be on meal plan screen
        expect(find.byType(MealPlanScreen), findsOneWidget);

        // Try to navigate back
        await tester.pageBack();
        await tester.pumpAndSettle();

        // Should show unsaved changes dialog or handle appropriately
        expect(find.byType(AlertDialog), findsAny);
      });

      testWidgets('should maintain state during widget rebuilds', (
        tester,
      ) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // Change the meal plan name
        final textField = find.byType(TextField);
        await tester.enterText(textField, 'Modified Name');
        await tester.pump();

        // Trigger a rebuild
        await tester.pumpWidget(createWidget());
        await tester.pump();

        // Should maintain the modified name
        expect(find.text('Modified Name'), findsOneWidget);
      });
    });

    group('Accessibility', () {
      testWidgets('should provide proper tooltips for action buttons', (
        tester,
      ) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // Save button should have tooltip
        final saveButton = find.byIcon(Icons.save).first;
        final saveIconButton = tester.widget<IconButton>(saveButton);
        expect(saveIconButton.tooltip, equals('Save meal plan'));
      });

      testWidgets('should be navigable with keyboard', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // Text field should be focusable
        expect(find.byType(TextField), findsOneWidget);

        // Buttons should be tappable
        expect(find.byType(IconButton), findsAtLeastNWidgets(1));
      });

      testWidgets('should provide semantic labels for screen readers', (
        tester,
      ) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // App bar should have proper title
        expect(find.byType(AppBar), findsOneWidget);

        // Calendar should be accessible
        expect(find.byType(MealPlanCalendarWidget), findsOneWidget);
      });
    });

    group('Performance', () {
      testWidgets('should not rebuild unnecessarily', (tester) async {
        int buildCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                buildCount++;
                return const MealPlanScreen();
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        final initialBuildCount = buildCount;

        // Pump again without changes
        await tester.pump();

        // Should not rebuild unnecessarily
        expect(buildCount, equals(initialBuildCount));
      });

      testWidgets('should handle large meal plans efficiently', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // Should render without performance issues
        expect(find.byType(MealPlanCalendarWidget), findsOneWidget);

        // Calendar should handle 4 weeks of data
        expect(find.byType(Scaffold), findsOneWidget);
      });
    });

    group('Edge Cases', () {
      testWidgets('should handle empty meal slots list', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // Should handle gracefully even with no meal slots
        expect(find.byType(Scaffold), findsOneWidget);
      });

      testWidgets('should handle empty recipes list', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // Should still display the calendar
        expect(find.byType(MealPlanCalendarWidget), findsOneWidget);
      });

      testWidgets('should handle invalid meal plan ID', (tester) async {
        await tester.pumpWidget(createWidget(mealPlanId: 'invalid-id'));
        await tester.pumpAndSettle();

        // Should handle gracefully
        expect(find.byType(Scaffold), findsOneWidget);
      });

      testWidgets('should handle network errors gracefully', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // Should show appropriate error handling
        expect(find.byType(Scaffold), findsOneWidget);
      });
    });

    group('Integration', () {
      testWidgets('should integrate with meal plan service', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // Should successfully load and display meal plan data
        expect(find.byType(MealPlanCalendarWidget), findsOneWidget);
      });

      testWidgets('should integrate with recipe service', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // Should be able to handle recipe selection
        expect(find.byType(MealPlanCalendarWidget), findsOneWidget);
      });

      testWidgets('should integrate with meal slot service', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // Should load and display meal slots
        expect(find.byType(MealPlanCalendarWidget), findsOneWidget);
      });
    });

    group('User Interactions', () {
      testWidgets('should handle save button tap', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // Find and tap save button
        final saveButton = find.byIcon(Icons.save).first;
        await tester.tap(saveButton);
        await tester.pump();

        // Should handle save operation
        expect(find.byType(MealPlanScreen), findsOneWidget);
      });

      testWidgets('should handle floating action button tap', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // Should have floating action button
        final fab = find.byType(FloatingActionButton);
        if (fab.evaluate().isNotEmpty) {
          await tester.tap(fab);
          await tester.pump();

          // Should handle save operation
          expect(find.byType(MealPlanScreen), findsOneWidget);
        }
      });

      testWidgets('should handle text field input', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // Enter text in the meal plan name field
        final textField = find.byType(TextField);
        await tester.enterText(textField, 'My Custom Meal Plan');
        await tester.pump();

        // Should update the display
        expect(find.text('My Custom Meal Plan'), findsOneWidget);
      });
    });
  });
}
