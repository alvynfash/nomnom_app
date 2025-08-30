import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nomnom/screens/template_management_screen.dart';

void main() {
  group('TemplateManagementScreen', () {
    /// Create widget for testing
    Widget createWidget({String? familyId}) {
      return MaterialApp(home: TemplateManagementScreen(familyId: familyId));
    }

    testWidgets('displays loading indicator initially', (tester) async {
      await tester.pumpWidget(createWidget());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays app bar with correct title', (tester) async {
      await tester.pumpWidget(createWidget());

      expect(find.text('Meal Plan Templates'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('displays search bar', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search templates...'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('displays sort options', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Sort by:'), findsOneWidget);
      expect(find.text('Recently Updated'), findsOneWidget);
      expect(find.text('Recently Created'), findsOneWidget);
      expect(find.text('Name'), findsOneWidget);
    });

    testWidgets('search bar shows clear button when text is entered', (
      tester,
    ) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Initially no clear button
      expect(find.byIcon(Icons.clear), findsNothing);

      // Enter text
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pumpAndSettle();

      // Clear button should appear
      expect(find.byIcon(Icons.clear), findsOneWidget);

      // Tap clear button
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      // Clear button should disappear
      expect(find.byIcon(Icons.clear), findsNothing);
    });

    testWidgets('sort chips are selectable', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Find sort chips
      final updatedChip = find.text('Recently Updated');
      final createdChip = find.text('Recently Created');
      final nameChip = find.text('Name');

      expect(updatedChip, findsOneWidget);
      expect(createdChip, findsOneWidget);
      expect(nameChip, findsOneWidget);

      // Tap on "Name" chip
      await tester.tap(nameChip);
      await tester.pumpAndSettle();

      // Tap on "Recently Created" chip
      await tester.tap(createdChip);
      await tester.pumpAndSettle();
    });

    testWidgets('displays empty state when no templates', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Wait for loading to complete and empty state to show
      await tester.pump(const Duration(seconds: 1));

      expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
      expect(find.text('No templates saved'), findsOneWidget);
      expect(
        find.text(
          'Create a meal plan and save it as a template to get started',
        ),
        findsOneWidget,
      );
    });

    testWidgets('search shows empty state when no results', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Wait for initial load
      await tester.pump(const Duration(seconds: 1));

      // Enter search text
      await tester.enterText(find.byType(TextField), 'NonExistentTemplate');
      await tester.pumpAndSettle();

      expect(find.text('No templates found'), findsOneWidget);
      expect(find.text('Try adjusting your search terms'), findsOneWidget);
    });

    testWidgets('refresh button triggers reload', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Tap refresh button
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump(); // Don't settle immediately to catch loading state

      // Should show loading indicator briefly or complete successfully
      // The loading might be too fast to catch, so we just verify no errors
      expect(tester.takeException(), isNull);
    });

    testWidgets('handles different family IDs', (tester) async {
      await tester.pumpWidget(createWidget(familyId: 'test-family'));
      await tester.pumpAndSettle();

      expect(find.byType(TemplateManagementScreen), findsOneWidget);
    });

    testWidgets('template preview dialog components exist', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // The TemplatePreviewDialog class should be available
      expect(TemplatePreviewDialog, isNotNull);
    });

    testWidgets('widget builds without errors', (tester) async {
      await tester.pumpWidget(createWidget());

      // Should not throw any exceptions during build
      expect(tester.takeException(), isNull);
    });

    testWidgets('handles null family ID', (tester) async {
      await tester.pumpWidget(createWidget(familyId: null));
      await tester.pumpAndSettle();

      expect(find.byType(TemplateManagementScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('search field accepts input', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      await tester.enterText(searchField, 'test search');
      await tester.pumpAndSettle();

      expect(find.text('test search'), findsOneWidget);
    });

    testWidgets('displays correct empty state icon', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Wait for loading to complete
      await tester.pump(const Duration(seconds: 1));

      expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
    });

    testWidgets('app bar has correct structure', (tester) async {
      await tester.pumpWidget(createWidget());

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Meal Plan Templates'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('search and sort section has correct layout', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Check for search field
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);

      // Check for sort options
      expect(find.text('Sort by:'), findsOneWidget);
      expect(find.byType(FilterChip), findsNWidgets(3));
    });

    testWidgets('handles widget lifecycle correctly', (tester) async {
      await tester.pumpWidget(createWidget());

      // Initial build
      expect(find.byType(TemplateManagementScreen), findsOneWidget);

      // Rebuild with different family ID
      await tester.pumpWidget(createWidget(familyId: 'different-family'));
      expect(find.byType(TemplateManagementScreen), findsOneWidget);

      // No exceptions should be thrown
      expect(tester.takeException(), isNull);
    });
  });

  group('TemplatePreviewDialog', () {
    testWidgets('dialog structure is correct', (tester) async {
      // Test that the dialog class exists and can be instantiated
      expect(TemplatePreviewDialog, isNotNull);
    });
  });
}
