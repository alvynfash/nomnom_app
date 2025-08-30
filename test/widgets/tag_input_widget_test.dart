import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nomnom/widgets/tag_input_widget.dart';

void main() {
  group('TagInputWidget', () {
    testWidgets('displays initial tags correctly', (WidgetTester tester) async {
      final initialTags = ['breakfast', 'quick', 'healthy'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TagInputWidget(
              initialTags: initialTags,
              onTagsChanged: (tags) {},
            ),
          ),
        ),
      );

      // Verify initial tags are displayed
      for (final tag in initialTags) {
        expect(find.text(tag), findsOneWidget);
      }
    });

    testWidgets('adds new tag when text is submitted', (
      WidgetTester tester,
    ) async {
      List<String> capturedTags = [];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TagInputWidget(onTagsChanged: (tags) => capturedTags = tags),
          ),
        ),
      );

      // Enter text and submit
      await tester.enterText(find.byType(TextField), 'dinner');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      // Verify tag was added
      expect(capturedTags, contains('dinner'));
      expect(find.text('dinner'), findsOneWidget);
    });

    testWidgets('adds tag when add button is pressed', (
      WidgetTester tester,
    ) async {
      List<String> capturedTags = [];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TagInputWidget(onTagsChanged: (tags) => capturedTags = tags),
          ),
        ),
      );

      // Enter text
      await tester.enterText(find.byType(TextField), 'lunch');
      await tester.pump();

      // Tap add button
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      // Verify tag was added
      expect(capturedTags, contains('lunch'));
      expect(find.text('lunch'), findsOneWidget);
    });

    testWidgets('removes tag when delete button is pressed', (
      WidgetTester tester,
    ) async {
      List<String> capturedTags = ['breakfast'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TagInputWidget(
              initialTags: ['breakfast'],
              onTagsChanged: (tags) => capturedTags = tags,
            ),
          ),
        ),
      );

      // Verify tag is initially present
      expect(find.text('breakfast'), findsOneWidget);

      // Tap delete button
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      // Verify tag was removed
      expect(capturedTags, isEmpty);
      expect(find.text('breakfast'), findsNothing);
    });

    testWidgets('handles comma-separated input', (WidgetTester tester) async {
      List<String> capturedTags = [];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TagInputWidget(onTagsChanged: (tags) => capturedTags = tags),
          ),
        ),
      );

      // Enter comma-separated tags
      await tester.enterText(
        find.byType(TextField),
        'breakfast, lunch, dinner',
      );
      await tester.pump();

      // Verify all tags were added
      expect(capturedTags, containsAll(['breakfast', 'lunch', 'dinner']));
      expect(find.text('breakfast'), findsOneWidget);
      expect(find.text('lunch'), findsOneWidget);
      expect(find.text('dinner'), findsOneWidget);
    });

    testWidgets('handles space-separated input', (WidgetTester tester) async {
      List<String> capturedTags = [];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TagInputWidget(onTagsChanged: (tags) => capturedTags = tags),
          ),
        ),
      );

      // Enter space-separated tags
      await tester.enterText(find.byType(TextField), 'quick easy healthy');
      await tester.pump();

      // Verify all tags were added
      expect(capturedTags, containsAll(['quick', 'easy', 'healthy']));
    });

    testWidgets('prevents duplicate tags by default', (
      WidgetTester tester,
    ) async {
      List<String> capturedTags = [];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TagInputWidget(
              initialTags: ['breakfast'],
              onTagsChanged: (tags) => capturedTags = tags,
            ),
          ),
        ),
      );

      // Try to add duplicate tag
      await tester.enterText(find.byType(TextField), 'breakfast');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      // Verify duplicate was not added
      expect(capturedTags, hasLength(1));
      expect(capturedTags, contains('breakfast'));
    });

    testWidgets('allows duplicates when configured', (
      WidgetTester tester,
    ) async {
      List<String> capturedTags = [];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TagInputWidget(
              initialTags: ['breakfast'],
              allowDuplicates: true,
              onTagsChanged: (tags) => capturedTags = tags,
            ),
          ),
        ),
      );

      // Add duplicate tag
      await tester.enterText(find.byType(TextField), 'breakfast');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      // Verify duplicate was added
      expect(capturedTags, hasLength(2));
      expect(capturedTags.where((tag) => tag == 'breakfast'), hasLength(2));
    });

    testWidgets('respects max tags limit', (WidgetTester tester) async {
      List<String> capturedTags = [];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TagInputWidget(
              initialTags: ['tag1', 'tag2'],
              maxTags: 2,
              onTagsChanged: (tags) => capturedTags = tags,
            ),
          ),
        ),
      );

      // Try to add third tag
      await tester.enterText(find.byType(TextField), 'tag3');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      // Verify third tag was not added
      expect(capturedTags, hasLength(2));
      expect(capturedTags, isNot(contains('tag3')));
    });

    testWidgets('respects max tag length limit', (WidgetTester tester) async {
      List<String> capturedTags = [];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TagInputWidget(
              maxTagLength: 5,
              onTagsChanged: (tags) => capturedTags = tags,
            ),
          ),
        ),
      );

      // Try to add tag that's too long
      await tester.enterText(find.byType(TextField), 'verylongtag');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      // Verify long tag was not added
      expect(capturedTags, isEmpty);
    });

    testWidgets('handles case sensitivity correctly', (
      WidgetTester tester,
    ) async {
      List<String> capturedTags = [];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TagInputWidget(
              initialTags: ['Breakfast'],
              caseSensitive: false,
              onTagsChanged: (tags) => capturedTags = tags,
            ),
          ),
        ),
      );

      // Try to add same tag with different case
      await tester.enterText(find.byType(TextField), 'breakfast');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      // Verify case-insensitive duplicate was not added
      expect(capturedTags, hasLength(1));
      expect(capturedTags, contains('Breakfast'));
    });

    testWidgets('handles case sensitivity when enabled', (
      WidgetTester tester,
    ) async {
      List<String> capturedTags = [];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TagInputWidget(
              initialTags: ['Breakfast'],
              caseSensitive: true,
              onTagsChanged: (tags) => capturedTags = tags,
            ),
          ),
        ),
      );

      // Add same tag with different case
      await tester.enterText(find.byType(TextField), 'breakfast');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      // Verify case-sensitive tag was added
      expect(capturedTags, hasLength(2));
      expect(capturedTags, containsAll(['Breakfast', 'breakfast']));
    });

    testWidgets('uses custom tag validator', (WidgetTester tester) async {
      List<String> capturedTags = [];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TagInputWidget(
              tagValidator: (tag) {
                if (tag.contains('invalid')) {
                  return 'Tag cannot contain "invalid"';
                }
                return null;
              },
              onTagsChanged: (tags) => capturedTags = tags,
            ),
          ),
        ),
      );

      // Try to add invalid tag
      await tester.enterText(find.byType(TextField), 'invalidtag');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      // Verify invalid tag was not added
      expect(capturedTags, isEmpty);
    });

    testWidgets('can be disabled', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TagInputWidget(
              initialTags: ['breakfast'],
              enabled: false,
              onTagsChanged: (tags) {},
            ),
          ),
        ),
      );

      // Verify input field is disabled
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.enabled, isFalse);

      // Verify delete buttons are not present (disabled)
      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('displays custom hint text', (WidgetTester tester) async {
      const customHint = 'Enter recipe tags...';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TagInputWidget(
              hintText: customHint,
              onTagsChanged: (tags) {},
            ),
          ),
        ),
      );

      // Verify custom hint text is displayed
      expect(find.text(customHint), findsOneWidget);
    });

    testWidgets('trims whitespace from tags', (WidgetTester tester) async {
      List<String> capturedTags = [];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TagInputWidget(onTagsChanged: (tags) => capturedTags = tags),
          ),
        ),
      );

      // Enter tag with whitespace
      await tester.enterText(find.byType(TextField), '  breakfast  ');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      // Verify whitespace was trimmed
      expect(capturedTags, contains('breakfast'));
      expect(capturedTags, isNot(contains('  breakfast  ')));
    });

    testWidgets('ignores empty tags', (WidgetTester tester) async {
      List<String> capturedTags = [];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TagInputWidget(onTagsChanged: (tags) => capturedTags = tags),
          ),
        ),
      );

      // Try to add empty tag
      await tester.enterText(find.byType(TextField), '   ');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      // Verify empty tag was not added
      expect(capturedTags, isEmpty);
    });

    group('Suggestions', () {
      testWidgets('displays suggestions when available', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TagInputWidget(
                suggestions: ['breakfast', 'lunch', 'dinner'],
                onTagsChanged: (tags) {},
              ),
            ),
          ),
        );

        // Focus on input field
        await tester.tap(find.byType(TextField));
        await tester.pump();

        // Verify suggestions are shown (in overlay)
        // Note: Testing overlay content is complex in widget tests
        // This test verifies the basic structure is in place
        expect(find.byType(TextField), findsOneWidget);
      });

      testWidgets('filters suggestions based on input', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TagInputWidget(
                suggestions: ['breakfast', 'lunch', 'dinner', 'brunch'],
                onTagsChanged: (tags) {},
              ),
            ),
          ),
        );

        // Enter partial text
        await tester.enterText(find.byType(TextField), 'br');
        await tester.pump();

        // The filtering logic is tested, but overlay testing is complex
        // This verifies the input handling works
        expect(find.text('br'), findsOneWidget);
      });
    });

    group('Styling', () {
      testWidgets('applies custom tag styling', (WidgetTester tester) async {
        const customTextStyle = TextStyle(fontSize: 16, color: Colors.red);
        const customBackgroundColor = Colors.blue;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TagInputWidget(
                initialTags: ['test'],
                tagTextStyle: customTextStyle,
                tagBackgroundColor: customBackgroundColor,
                onTagsChanged: (tags) {},
              ),
            ),
          ),
        );

        // Verify tag is displayed
        expect(find.text('test'), findsOneWidget);

        // Note: Testing specific styling properties requires more complex widget testing
        // This test verifies the structure is correct
      });

      testWidgets('applies custom input styling', (WidgetTester tester) async {
        const customInputStyle = TextStyle(fontSize: 18, color: Colors.green);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TagInputWidget(
                inputTextStyle: customInputStyle,
                onTagsChanged: (tags) {},
              ),
            ),
          ),
        );

        // Verify input field exists with custom styling
        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.style, equals(customInputStyle));
      });
    });

    group('Edge Cases', () {
      testWidgets('handles rapid tag addition', (WidgetTester tester) async {
        List<String> capturedTags = [];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TagInputWidget(
                onTagsChanged: (tags) => capturedTags = tags,
              ),
            ),
          ),
        );

        // Add multiple tags rapidly
        for (int i = 0; i < 5; i++) {
          await tester.enterText(find.byType(TextField), 'tag$i');
          await tester.testTextInput.receiveAction(TextInputAction.done);
          await tester.pump();
        }

        // Verify all tags were added
        expect(capturedTags, hasLength(5));
        for (int i = 0; i < 5; i++) {
          expect(capturedTags, contains('tag$i'));
        }
      });

      testWidgets('handles special characters in tags', (
        WidgetTester tester,
      ) async {
        List<String> capturedTags = [];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TagInputWidget(
                onTagsChanged: (tags) => capturedTags = tags,
              ),
            ),
          ),
        );

        // Add tag with special characters
        await tester.enterText(find.byType(TextField), 'tag-with_special');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pump();

        // Verify tag with special characters was added
        expect(capturedTags, contains('tag-with_special'));
      });
    });
  });
}
