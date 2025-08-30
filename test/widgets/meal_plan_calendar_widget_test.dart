import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nomnom/models/meal_plan.dart';
import 'package:nomnom/models/meal_slot.dart';
import 'package:nomnom/widgets/meal_plan_calendar_widget.dart';
import 'package:nomnom/widgets/meal_slot_widget.dart';

void main() {
  group('MealPlanCalendarWidget', () {
    late MealPlan testMealPlan;
    late List<MealSlot> testMealSlots;
    late DateTime testStartDate;

    setUp(() {
      testStartDate = DateTime(2024, 1, 15); // Monday

      testMealSlots = [
        MealSlot(id: 'breakfast', name: 'Breakfast', order: 1, isDefault: true),
        MealSlot(id: 'lunch', name: 'Lunch', order: 2, isDefault: true),
        MealSlot(id: 'dinner', name: 'Dinner', order: 3, isDefault: true),
      ];

      testMealPlan = MealPlan.create(
        name: 'Test Meal Plan',
        familyId: 'family123',
        startDate: testStartDate,
        mealSlots: testMealSlots.map((slot) => slot.id).toList(),
        createdBy: 'user123',
      );
    });

    Widget createWidget({
      MealPlan? mealPlan,
      int currentWeek = 0,
      List<MealSlot>? mealSlots,
      Function(DateTime, String)? onSlotTap,
      Function(int)? onWeekChanged,
      bool isEditable = true,
      double? slotHeight,
      bool isCompact = false,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: MealPlanCalendarWidget(
            mealPlan: mealPlan ?? testMealPlan,
            currentWeek: currentWeek,
            mealSlots: mealSlots ?? testMealSlots,
            onSlotTap: onSlotTap ?? (date, slotId) {},
            onWeekChanged: onWeekChanged ?? (week) {},
            isEditable: isEditable,
            slotHeight: slotHeight,
            isCompact: isCompact,
          ),
        ),
      );
    }

    group('Widget Structure', () {
      testWidgets('should display week navigation header', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        expect(find.text('Week 1'), findsOneWidget);
        expect(find.byIcon(Icons.chevron_left), findsOneWidget);
        expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      });

      testWidgets('should display day headers for the week', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        // Should show all 7 days of the week
        expect(find.text('Mon'), findsOneWidget);
        expect(find.text('Tue'), findsOneWidget);
        expect(find.text('Wed'), findsOneWidget);
        expect(find.text('Thu'), findsOneWidget);
        expect(find.text('Fri'), findsOneWidget);
        expect(find.text('Sat'), findsOneWidget);
        expect(find.text('Sun'), findsOneWidget);
      });

      testWidgets('should display day numbers in headers', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        // Should show day numbers (15-21 for the test week)
        expect(find.text('15'), findsOneWidget);
        expect(find.text('16'), findsOneWidget);
        expect(find.text('17'), findsOneWidget);
        expect(find.text('18'), findsOneWidget);
        expect(find.text('19'), findsOneWidget);
        expect(find.text('20'), findsOneWidget);
        expect(find.text('21'), findsOneWidget);
      });

      testWidgets('should display meal slots for each day', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        // Should have 7 days × 3 meal slots = 21 meal slot widgets
        expect(find.byType(MealSlotWidget), findsNWidgets(21));
      });

      testWidgets('should display date range in week header', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        expect(find.text('1/15 - 1/21'), findsOneWidget);
      });
    });

    group('Week Navigation', () {
      testWidgets('should call onWeekChanged when next week is tapped', (
        tester,
      ) async {
        int? changedWeek;
        await tester.pumpWidget(
          createWidget(onWeekChanged: (week) => changedWeek = week),
        );
        await tester.pump();

        await tester.tap(find.byIcon(Icons.chevron_right));
        expect(changedWeek, equals(1));
      });

      testWidgets('should call onWeekChanged when previous week is tapped', (
        tester,
      ) async {
        int? changedWeek;
        await tester.pumpWidget(
          createWidget(
            currentWeek: 1,
            onWeekChanged: (week) => changedWeek = week,
          ),
        );
        await tester.pump();

        await tester.tap(find.byIcon(Icons.chevron_left));
        expect(changedWeek, equals(0));
      });

      testWidgets('should disable previous button on first week', (
        tester,
      ) async {
        await tester.pumpWidget(createWidget(currentWeek: 0));
        await tester.pump();

        final previousButton = tester.widget<IconButton>(
          find.byIcon(Icons.chevron_left).first,
        );
        expect(previousButton.onPressed, isNull);
      });

      testWidgets('should disable next button on last week', (tester) async {
        await tester.pumpWidget(createWidget(currentWeek: 3));
        await tester.pump();

        final nextButton = tester.widget<IconButton>(
          find.byIcon(Icons.chevron_right).first,
        );
        expect(nextButton.onPressed, isNull);
      });

      testWidgets('should update week display when currentWeek changes', (
        tester,
      ) async {
        await tester.pumpWidget(createWidget(currentWeek: 0));
        await tester.pump();
        expect(find.text('Week 1'), findsOneWidget);

        await tester.pumpWidget(createWidget(currentWeek: 1));
        await tester.pump();
        expect(find.text('Week 2'), findsOneWidget);

        await tester.pumpWidget(createWidget(currentWeek: 2));
        await tester.pump();
        expect(find.text('Week 3'), findsOneWidget);

        await tester.pumpWidget(createWidget(currentWeek: 3));
        await tester.pump();
        expect(find.text('Week 4'), findsOneWidget);
      });

      testWidgets('should update date range when week changes', (tester) async {
        await tester.pumpWidget(createWidget(currentWeek: 0));
        await tester.pump();
        expect(find.text('1/15 - 1/21'), findsOneWidget);

        await tester.pumpWidget(createWidget(currentWeek: 1));
        await tester.pump();
        expect(find.text('1/22 - 1/28'), findsOneWidget);
      });
    });

    group('Current Week Highlighting', () {
      testWidgets('should highlight current week when it matches', (
        tester,
      ) async {
        // Create a meal plan that starts this week
        final now = DateTime.now();
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final currentWeekMealPlan = MealPlan.create(
          name: 'Current Week Plan',
          familyId: 'family123',
          startDate: startOfWeek,
          mealSlots: testMealSlots.map((slot) => slot.id).toList(),
          createdBy: 'user123',
        );

        await tester.pumpWidget(
          createWidget(mealPlan: currentWeekMealPlan, currentWeek: 0),
        );
        await tester.pump();

        expect(find.text('Current Week'), findsOneWidget);
      });

      testWidgets('should not highlight non-current weeks', (tester) async {
        await tester.pumpWidget(createWidget(currentWeek: 0));
        await tester.pump();

        expect(find.text('Current Week'), findsNothing);
      });
    });

    group('Today Highlighting', () {
      testWidgets('should highlight today\'s date in day headers', (
        tester,
      ) async {
        // Create a meal plan that includes today
        final today = DateTime.now();
        final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
        final todayMealPlan = MealPlan.create(
          name: 'Today Plan',
          familyId: 'family123',
          startDate: startOfWeek,
          mealSlots: testMealSlots.map((slot) => slot.id).toList(),
          createdBy: 'user123',
        );

        await tester.pumpWidget(
          createWidget(mealPlan: todayMealPlan, currentWeek: 0),
        );
        await tester.pump();

        // Today's date should be highlighted
        expect(find.text(today.day.toString()), findsOneWidget);
      });
    });

    group('Meal Slot Integration', () {
      testWidgets('should call onSlotTap when meal slot is tapped', (
        tester,
      ) async {
        DateTime? tappedDate;
        String? tappedSlotId;

        await tester.pumpWidget(
          createWidget(
            onSlotTap: (date, slotId) {
              tappedDate = date;
              tappedSlotId = slotId;
            },
          ),
        );
        await tester.pump();

        // Tap the first meal slot widget
        await tester.tap(find.byType(MealSlotWidget).first);

        expect(tappedDate, isNotNull);
        expect(tappedSlotId, equals('breakfast'));
        expect(tappedDate!.day, equals(15)); // First day of test week
      });

      testWidgets('should pass correct parameters to meal slot widgets', (
        tester,
      ) async {
        await tester.pumpWidget(
          createWidget(isEditable: false, slotHeight: 120.0, isCompact: true),
        );
        await tester.pump();

        final mealSlotWidget = tester.widget<MealSlotWidget>(
          find.byType(MealSlotWidget).first,
        );

        expect(mealSlotWidget.isEditable, isFalse);
        expect(mealSlotWidget.height, equals(120.0));
        expect(mealSlotWidget.isCompact, isTrue);
      });

      testWidgets('should display correct meal slot names', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        expect(find.text('Breakfast'), findsNWidgets(7)); // 7 days
        expect(find.text('Lunch'), findsNWidgets(7)); // 7 days
        expect(find.text('Dinner'), findsNWidgets(7)); // 7 days
      });
    });

    group('Recipe Assignment Display', () {
      testWidgets('should display assigned recipes in meal slots', (
        tester,
      ) async {
        // Create a meal plan with some recipe assignments
        final mealPlanWithRecipes = testMealPlan.copyWith(
          assignments: {
            '2024-01-15_breakfast': 'recipe1',
            '2024-01-16_lunch': 'recipe2',
          },
        );

        await tester.pumpWidget(createWidget(mealPlan: mealPlanWithRecipes));
        await tester.pump();

        // Should have meal slot widgets (recipes will be loaded asynchronously)
        expect(find.byType(MealSlotWidget), findsNWidgets(21));
      });

      testWidgets('should handle empty meal slots', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        // All slots should be empty initially
        expect(find.byType(MealSlotWidget), findsNWidgets(21));
      });
    });

    group('Loading States', () {
      testWidgets('should show loading indicators for recipes being loaded', (
        tester,
      ) async {
        // Create a meal plan with recipe assignments
        final mealPlanWithRecipes = testMealPlan.copyWith(
          assignments: {'2024-01-15_breakfast': 'recipe1'},
        );

        await tester.pumpWidget(createWidget(mealPlan: mealPlanWithRecipes));

        // Should show loading state initially
        expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
      });
    });

    group('Responsive Design', () {
      testWidgets('should adapt to compact mode', (tester) async {
        await tester.pumpWidget(createWidget(isCompact: true));
        await tester.pump();

        // Should still display all components in compact mode
        expect(find.text('Week 1'), findsOneWidget);
        expect(find.byType(MealSlotWidget), findsNWidgets(21));
      });

      testWidgets('should use custom slot height when provided', (
        tester,
      ) async {
        await tester.pumpWidget(createWidget(slotHeight: 150.0));
        await tester.pump();

        final mealSlotWidget = tester.widget<MealSlotWidget>(
          find.byType(MealSlotWidget).first,
        );
        expect(mealSlotWidget.height, equals(150.0));
      });
    });

    group('Edge Cases', () {
      testWidgets('should handle meal plan with no meal slots', (tester) async {
        await tester.pumpWidget(createWidget(mealSlots: []));
        await tester.pump();

        // Should still show week navigation and day headers
        expect(find.text('Week 1'), findsOneWidget);
        expect(find.text('Mon'), findsOneWidget);

        // But no meal slot widgets
        expect(find.byType(MealSlotWidget), findsNothing);
      });

      testWidgets('should handle different week numbers correctly', (
        tester,
      ) async {
        for (int week = 0; week < 4; week++) {
          await tester.pumpWidget(createWidget(currentWeek: week));
          await tester.pump();

          expect(find.text('Week ${week + 1}'), findsOneWidget);

          // Check that dates are calculated correctly for each week
          final expectedStartDay = 15 + (week * 7);
          expect(find.text(expectedStartDay.toString()), findsOneWidget);
        }
      });

      testWidgets('should handle meal plan updates correctly', (tester) async {
        await tester.pumpWidget(createWidget(mealPlan: testMealPlan));
        await tester.pump();

        expect(
          find.text('Test Meal Plan'),
          findsNothing,
        ); // Plan name not shown in widget

        // Update with different meal plan
        final newMealPlan = MealPlan.create(
          name: 'Updated Meal Plan',
          familyId: 'family123',
          startDate: testStartDate.add(const Duration(days: 7)),
          mealSlots: testMealSlots.map((slot) => slot.id).toList(),
          createdBy: 'user123',
        );

        await tester.pumpWidget(createWidget(mealPlan: newMealPlan));
        await tester.pump();

        // Dates should be updated
        expect(find.text('22'), findsOneWidget); // New start date
      });
    });

    group('Accessibility', () {
      testWidgets('should provide proper tooltips for navigation buttons', (
        tester,
      ) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        final previousButton = tester.widget<IconButton>(
          find.byIcon(Icons.chevron_left).first,
        );
        final nextButton = tester.widget<IconButton>(
          find.byIcon(Icons.chevron_right).first,
        );

        expect(previousButton.tooltip, equals('Previous week'));
        expect(nextButton.tooltip, equals('Next week'));
      });

      testWidgets('should be navigable with keyboard', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        // Navigation buttons should be focusable
        expect(find.byType(IconButton), findsNWidgets(2));
      });
    });

    group('Performance', () {
      testWidgets('should not rebuild unnecessarily', (tester) async {
        int buildCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  buildCount++;
                  return MealPlanCalendarWidget(
                    mealPlan: testMealPlan,
                    currentWeek: 0,
                    mealSlots: testMealSlots,
                    onSlotTap: (date, slotId) {},
                    onWeekChanged: (week) {},
                  );
                },
              ),
            ),
          ),
        );
        await tester.pump();

        final initialBuildCount = buildCount;

        // Pump again without changes - should not rebuild
        await tester.pump();
        expect(buildCount, equals(initialBuildCount));
      });
    });

    group('Date Calculations', () {
      testWidgets('should calculate week dates correctly', (tester) async {
        // Test different start dates and weeks
        final testCases = [
          {'startDate': DateTime(2024, 1, 1), 'week': 0, 'expectedStart': 1},
          {'startDate': DateTime(2024, 1, 1), 'week': 1, 'expectedStart': 8},
          {'startDate': DateTime(2024, 1, 15), 'week': 2, 'expectedStart': 29},
        ];

        for (final testCase in testCases) {
          final startDate = testCase['startDate'] as DateTime;
          final week = testCase['week'] as int;
          final expectedStart = testCase['expectedStart'] as int;

          final mealPlan = MealPlan.create(
            name: 'Test Plan',
            familyId: 'family123',
            startDate: startDate,
            mealSlots: testMealSlots.map((slot) => slot.id).toList(),
            createdBy: 'user123',
          );

          await tester.pumpWidget(
            createWidget(mealPlan: mealPlan, currentWeek: week),
          );
          await tester.pump();

          expect(find.text(expectedStart.toString()), findsOneWidget);
        }
      });
    });
  });
}
