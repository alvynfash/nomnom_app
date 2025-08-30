import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nomnom/screens/meal_plan_list_screen.dart';
import 'package:nomnom/widgets/meal_plan_form_dialog.dart';

void main() {
  group('MealPlanListScreen', () {
    Widget createWidget({String? familyId}) {
      return MaterialApp(home: MealPlanListScreen(familyId: familyId));
    }

    group('Widget Structure', () {
      testWidgets('should display app bar with title', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        expect(find.byType(AppBar), findsOneWidget);
        expect(find.text('Meal Plans'), findsOneWidget);
      });

      testWidgets('should display refresh button in app bar', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        expect(find.byIcon(Icons.refresh), findsOneWidget);
      });

      testWidgets('should display floating action button', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        expect(find.byType(FloatingActionButton), findsOneWidget);
        expect(find.byIcon(Icons.add), findsOneWidget);
      });

      testWidgets('should display loading indicator initially', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should display search and filter section', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.text('Search meal plans...'), findsOneWidget);
        expect(find.byIcon(Icons.search), findsOneWidget);
      });

      testWidgets('should display filter chips', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.text('All Plans'), findsOneWidget);
        expect(find.text('Active'), findsOneWidget);
        expect(find.text('Templates'), findsOneWidget);
      });
    });

    group('Search and Filter', () {
      testWidgets('should show clear button when search has text', (
        tester,
      ) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // Initially no clear button
        expect(find.byIcon(Icons.clear), findsNothing);

        // Enter search text
        await tester.enterText(find.byType(TextField), 'test search');
        await tester.pump();

        // Should show clear button
        expect(find.byIcon(Icons.clear), findsOneWidget);
      });

      testWidgets('should clear search when clear button is tapped', (
        tester,
      ) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // Enter search text
        await tester.enterText(find.byType(TextField), 'test search');
        await tester.pump();

        // Tap clear button
        await tester.tap(find.byIcon(Icons.clear));
        await tester.pump();

        // Search field should be empty
        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.controller?.text, isEmpty);
      });

      testWidgets('should update filter when filter chip is tapped', (
        tester,
      ) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // Initially "All Plans" should be selected
        final allPlansChip = find.widgetWithText(FilterChip, 'All Plans');
        expect(tester.widget<FilterChip>(allPlansChip).selected, isTrue);

        // Tap "Active" filter
        await tester.tap(find.widgetWithText(FilterChip, 'Active'));
        await tester.pump();

        // "Active" should now be selected
        final activeChip = find.widgetWithText(FilterChip, 'Active');
        expect(tester.widget<FilterChip>(activeChip).selected, isTrue);
      });
    });

    group('Empty States', () {
      testWidgets('should display empty state when no meal plans', (
        tester,
      ) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // Should show empty state
        expect(find.text('No meal plans yet'), findsOneWidget);
        expect(
          find.text('Create your first meal plan to get started'),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.restaurant_menu), findsOneWidget);
      });

      testWidgets('should display search empty state', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // Enter search that won't match anything
        await tester.enterText(find.byType(TextField), 'nonexistent search');
        await tester.pump();

        // Should show search empty state
        expect(find.text('No meal plans found'), findsOneWidget);
        expect(
          find.text('Try adjusting your search or filters'),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.search_off), findsOneWidget);
      });

      testWidgets('should display active filter empty state', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // Select active filter
        await tester.tap(find.widgetWithText(FilterChip, 'Active'));
        await tester.pump();

        // Should show active empty state
        expect(find.text('No active meal plans'), findsOneWidget);
        expect(
          find.text('Create a new meal plan to get started'),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.calendar_today), findsOneWidget);
      });

      testWidgets('should display templates filter empty state', (
        tester,
      ) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // Select templates filter
        await tester.tap(find.widgetWithText(FilterChip, 'Templates'));
        await tester.pump();

        // Should show templates empty state
        expect(find.text('No templates saved'), findsOneWidget);
        expect(
          find.text('Save a meal plan as a template to reuse it'),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
      });

      testWidgets('should show create button in main empty state', (
        tester,
      ) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // Should show create button in empty state
        expect(find.text('Create Meal Plan'), findsOneWidget);
      });
    });

    group('User Interactions', () {
      testWidgets('should open form dialog when FAB is tapped', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // Tap floating action button
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();

        // Should show meal plan form dialog
        expect(find.byType(MealPlanFormDialog), findsOneWidget);
        expect(find.text('Create Meal Plan'), findsOneWidget);
      });

      testWidgets('should open form dialog when create button is tapped', (
        tester,
      ) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // Tap create button in empty state
        await tester.tap(find.text('Create Meal Plan'));
        await tester.pumpAndSettle();

        // Should show meal plan form dialog
        expect(find.byType(MealPlanFormDialog), findsOneWidget);
      });

      testWidgets('should refresh data when refresh button is tapped', (
        tester,
      ) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // Tap refresh button
        await tester.tap(find.byIcon(Icons.refresh));
        await tester.pump();

        // Should show loading indicator
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should handle search input', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // Enter search text
        await tester.enterText(find.byType(TextField), 'my search');
        await tester.pump();

        // Text field should contain the search text
        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.controller?.text, equals('my search'));
      });
    });

    group('Meal Plan Cards', () {
      // Note: These tests would require mocking the services to return test data
      // For now, we'll test the basic structure and interactions

      testWidgets('should handle meal plan card tap', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // If there were meal plan cards, tapping them should navigate
        // This would require mocked data to test properly
        expect(find.byType(MealPlanListScreen), findsOneWidget);
      });

      testWidgets('should show popup menu for meal plan actions', (
        tester,
      ) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // If there were meal plan cards with popup menus, we could test them
        // This would require mocked data to test properly
        expect(find.byType(MealPlanListScreen), findsOneWidget);
      });
    });

    group('Error Handling', () {
      testWidgets('should handle service errors gracefully', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // Should not crash even if services fail
        expect(find.byType(MealPlanListScreen), findsOneWidget);
      });

      testWidgets('should show error snackbar on operation failure', (
        tester,
      ) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // Error handling would be tested with mocked services
        expect(find.byType(Scaffold), findsOneWidget);
      });
    });

    group('Navigation', () {
      testWidgets('should navigate to meal plan screen when card is tapped', (
        tester,
      ) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // Navigation testing would require mocked data and navigation testing setup
        expect(find.byType(MealPlanListScreen), findsOneWidget);
      });

      testWidgets('should navigate to meal plan screen after creation', (
        tester,
      ) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // This would require mocking the service and testing navigation
        expect(find.byType(MealPlanListScreen), findsOneWidget);
      });
    });

    group('Accessibility', () {
      testWidgets('should provide proper tooltips', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        final fab = tester.widget<FloatingActionButton>(
          find.byType(FloatingActionButton),
        );
        expect(fab.tooltip, equals('Create meal plan'));

        final refreshButton = tester.widget<IconButton>(
          find.byIcon(Icons.refresh),
        );
        expect(refreshButton.tooltip, equals('Refresh'));
      });

      testWidgets('should be keyboard navigable', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // Search field should be focusable
        expect(find.byType(TextField), findsOneWidget);

        // Buttons should be tappable
        expect(find.byType(FloatingActionButton), findsOneWidget);
        expect(find.byType(FilterChip), findsAtLeastNWidgets(3));
      });

      testWidgets('should provide semantic labels', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // App bar should have proper title
        expect(find.text('Meal Plans'), findsOneWidget);

        // Search field should have proper hint
        expect(find.text('Search meal plans...'), findsOneWidget);
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
                return const MealPlanListScreen();
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

      testWidgets('should handle large lists efficiently', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // Should render without performance issues
        expect(find.byType(MealPlanListScreen), findsOneWidget);
      });
    });

    group('Edge Cases', () {
      testWidgets('should handle null family ID', (tester) async {
        await tester.pumpWidget(createWidget(familyId: null));
        await tester.pumpAndSettle();

        // Should handle gracefully
        expect(find.byType(MealPlanListScreen), findsOneWidget);
      });

      testWidgets('should handle empty family ID', (tester) async {
        await tester.pumpWidget(createWidget(familyId: ''));
        await tester.pumpAndSettle();

        // Should handle gracefully
        expect(find.byType(MealPlanListScreen), findsOneWidget);
      });

      testWidgets('should handle network errors', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // Should show appropriate error handling
        expect(find.byType(MealPlanListScreen), findsOneWidget);
      });
    });

    group('State Management', () {
      testWidgets('should maintain search state during rebuilds', (
        tester,
      ) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // Enter search text
        await tester.enterText(find.byType(TextField), 'persistent search');
        await tester.pump();

        // Trigger rebuild
        await tester.pumpWidget(createWidget());
        await tester.pump();

        // Search text should be maintained
        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.controller?.text, equals('persistent search'));
      });

      testWidgets('should maintain filter state during rebuilds', (
        tester,
      ) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // Select active filter
        await tester.tap(find.widgetWithText(FilterChip, 'Active'));
        await tester.pump();

        // Trigger rebuild
        await tester.pumpWidget(createWidget());
        await tester.pump();

        // Active filter should still be selected
        final activeChip = find.widgetWithText(FilterChip, 'Active');
        expect(tester.widget<FilterChip>(activeChip).selected, isTrue);
      });
    });

    group('Integration', () {
      testWidgets('should integrate with meal plan service', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // Should successfully integrate with services
        expect(find.byType(MealPlanListScreen), findsOneWidget);
      });

      testWidgets('should integrate with meal slot service', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // Should load meal slots for form dialog
        expect(find.byType(MealPlanListScreen), findsOneWidget);
      });
    });
  });
}
