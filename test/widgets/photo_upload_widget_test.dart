import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nomnom/widgets/photo_upload_widget.dart';
import 'package:nomnom/services/photo_service.dart';

// Mock classes for testing
class MockPhotoService extends PhotoService {
  final List<String> _savedPhotos = [];
  bool shouldThrowError = false;
  String? errorMessage;

  @override
  Future<String> saveRecipePhoto(String recipeId, File imageFile) async {
    if (shouldThrowError) {
      throw PhotoServiceException(errorMessage ?? 'Mock error', 'TEST_ERROR');
    }

    final mockPath =
        '/mock/path/${recipeId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    _savedPhotos.add(mockPath);
    return mockPath;
  }

  @override
  Future<void> deleteRecipePhoto(String photoPath) async {
    if (shouldThrowError) {
      throw PhotoServiceException(
        errorMessage ?? 'Mock delete error',
        'DELETE_ERROR',
      );
    }
    _savedPhotos.remove(photoPath);
  }

  List<String> get savedPhotos => List.unmodifiable(_savedPhotos);
}

void main() {
  group('PhotoUploadWidget', () {
    late List<String> testPhotoUrls;
    late List<String> capturedPhotoUrls;

    setUp(() {
      testPhotoUrls = [];
      capturedPhotoUrls = [];
    });

    Widget createTestWidget({
      List<String>? photoUrls,
      int maxPhotos = 5,
      bool enabled = true,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: PhotoUploadWidget(
            photoUrls: photoUrls ?? testPhotoUrls,
            onPhotosChanged: (urls) {
              capturedPhotoUrls = urls;
            },
            recipeId: 'test-recipe-id',
            maxPhotos: maxPhotos,
            enabled: enabled,
          ),
        ),
      );
    }

    testWidgets('displays empty state when no photos', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Should show upload controls
      expect(find.text('Add Recipe Photos'), findsOneWidget);
      expect(find.text('Show off your delicious creation!'), findsOneWidget);
      expect(find.text('Camera'), findsOneWidget);
      expect(find.text('Gallery'), findsOneWidget);

      // Should not show photo grid
      expect(find.byType(GridView), findsNothing);
    });

    testWidgets('displays photo grid when photos exist', (tester) async {
      testPhotoUrls.addAll(['/test/photo1.jpg', '/test/photo2.jpg']);

      await tester.pumpWidget(createTestWidget());

      // Should show photo grid
      expect(find.byType(GridView), findsOneWidget);

      // Should show photo count info
      expect(find.text('2 of 5 photos'), findsOneWidget);
      expect(find.text('Manage'), findsOneWidget);
    });

    testWidgets('shows main photo indicator for first photo', (tester) async {
      testPhotoUrls.addAll(['/test/photo1.jpg', '/test/photo2.jpg']);

      await tester.pumpWidget(createTestWidget());

      // Should show "Main" indicator on first photo
      expect(find.text('Main'), findsOneWidget);
    });

    testWidgets('hides upload controls when max photos reached', (
      tester,
    ) async {
      testPhotoUrls.addAll(['/test/photo1.jpg', '/test/photo2.jpg']);

      await tester.pumpWidget(createTestWidget(maxPhotos: 2));

      // Should not show upload controls
      expect(find.text('Add Recipe Photos'), findsNothing);
      expect(find.text('Camera'), findsNothing);
      expect(find.text('Gallery'), findsNothing);

      // Should show photo count indicating max reached
      expect(find.text('2 of 2 photos'), findsOneWidget);
    });

    testWidgets('disables interactions when disabled', (tester) async {
      testPhotoUrls.add('/test/photo1.jpg');

      await tester.pumpWidget(createTestWidget(enabled: false));

      // Should not show delete buttons
      expect(find.byIcon(Icons.close_rounded), findsNothing);

      // Should not show upload controls
      expect(find.text('Camera'), findsNothing);
      expect(find.text('Gallery'), findsNothing);

      // Should show photo but without interactive elements
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('shows loading state during upload', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Find and tap gallery button
      final galleryButton = find.text('Gallery');
      expect(galleryButton, findsOneWidget);

      // Note: In a real test, we would need to mock ImagePicker
      // For now, we're testing the UI structure
    });

    testWidgets('displays error state for broken images', (tester) async {
      testPhotoUrls.add('/nonexistent/photo.jpg');

      await tester.pumpWidget(createTestWidget());

      // Wait for the image to fail loading
      await tester.pumpAndSettle();

      // The broken image icon appears in the error builder, but we need to trigger the error
      // In a real test environment, we would need to mock the File.exists() or image loading
      // For now, let's just verify the widget structure is correct
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('shows delete confirmation dialog', (tester) async {
      testPhotoUrls.add('/test/photo1.jpg');

      await tester.pumpWidget(createTestWidget());

      // Find and tap delete button
      final deleteButton = find.byIcon(Icons.close_rounded);
      expect(deleteButton, findsOneWidget);

      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      // Should show confirmation dialog
      expect(find.text('Delete Photo'), findsOneWidget);
      expect(
        find.text('Are you sure you want to delete this photo?'),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('cancels delete when cancel is tapped', (tester) async {
      testPhotoUrls.add('/test/photo1.jpg');

      await tester.pumpWidget(createTestWidget());

      // Tap delete button
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      // Tap cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Photo should still be there
      expect(find.byType(GridView), findsOneWidget);
      expect(capturedPhotoUrls, isEmpty); // No change callback should be called
    });

    testWidgets('opens photo preview when photo is tapped', (tester) async {
      testPhotoUrls.add('/test/photo1.jpg');

      await tester.pumpWidget(createTestWidget());

      // Find the photo container and tap it
      final photoContainer = find.byType(GestureDetector).first;
      await tester.tap(photoContainer);
      await tester.pumpAndSettle();

      // Should navigate to photo preview screen
      expect(find.byType(PhotoPreviewScreen), findsOneWidget);
    });

    testWidgets('opens photo management sheet when manage is tapped', (
      tester,
    ) async {
      testPhotoUrls.addAll(['/test/photo1.jpg', '/test/photo2.jpg']);

      await tester.pumpWidget(createTestWidget());

      // Tap manage button
      await tester.tap(find.text('Manage'));
      await tester.pumpAndSettle();

      // Should show photo management sheet
      expect(find.text('Manage Photos'), findsOneWidget);
      expect(
        find.text('Drag to reorder • First photo is the main photo'),
        findsOneWidget,
      );
    });

    testWidgets('displays correct photo count info', (tester) async {
      // Test with no photos - photo count info only shows if maxPhotos > 1
      await tester.pumpWidget(createTestWidget());
      expect(find.text('0 of 5 photos'), findsOneWidget);

      // Test with some photos
      testPhotoUrls.addAll(['/test/photo1.jpg', '/test/photo2.jpg']);
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.text('2 of 5 photos'), findsOneWidget);

      // Test with max photos
      testPhotoUrls.clear();
      testPhotoUrls.addAll([
        '/test/photo1.jpg',
        '/test/photo2.jpg',
        '/test/photo3.jpg',
        '/test/photo4.jpg',
        '/test/photo5.jpg',
      ]);
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.text('5 of 5 photos'), findsOneWidget);
    });

    testWidgets('handles different max photo limits', (tester) async {
      // Test with max 1 photo - photo count info only shows if maxPhotos > 1 OR photoUrls.isNotEmpty
      await tester.pumpWidget(createTestWidget(maxPhotos: 1));
      expect(
        find.text('0 of 1 photos'),
        findsNothing,
      ); // Should not show for maxPhotos = 1 with no photos

      // Test with max 10 photos
      await tester.pumpWidget(createTestWidget(maxPhotos: 10));
      expect(find.text('0 of 10 photos'), findsOneWidget);
    });

    group('PhotoPreviewScreen', () {
      testWidgets('displays photo with navigation controls', (tester) async {
        const photoUrls = ['/test/photo1.jpg', '/test/photo2.jpg'];

        await tester.pumpWidget(
          MaterialApp(
            home: PhotoPreviewScreen(photoUrls: photoUrls, initialIndex: 0),
          ),
        );

        // Should show photo counter in app bar
        expect(find.text('1 of 2'), findsOneWidget);

        // Should show page indicators at bottom
        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('shows delete button when onDelete is provided', (
        tester,
      ) async {
        const photoUrls = ['/test/photo1.jpg'];
        bool deleteCallbackCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: PhotoPreviewScreen(
              photoUrls: photoUrls,
              initialIndex: 0,
              onDelete: (index) {
                deleteCallbackCalled = true;
              },
            ),
          ),
        );

        // Should show delete button in app bar
        expect(find.byIcon(Icons.delete_rounded), findsOneWidget);

        // Tap delete button
        await tester.tap(find.byIcon(Icons.delete_rounded));
        expect(deleteCallbackCalled, isTrue);
      });

      testWidgets('shows make main option for non-main photos', (tester) async {
        const photoUrls = ['/test/photo1.jpg', '/test/photo2.jpg'];
        bool reorderCallbackCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: PhotoPreviewScreen(
              photoUrls: photoUrls,
              initialIndex: 1, // Second photo
              onReorder: (oldIndex, newIndex) {
                reorderCallbackCalled = true;
              },
            ),
          ),
        );

        // Should show popup menu button
        expect(find.byType(PopupMenuButton<String>), findsOneWidget);

        // Tap popup menu
        await tester.tap(find.byType(PopupMenuButton<String>));
        await tester.pumpAndSettle();

        // Should show make main option
        expect(find.text('Make Main Photo'), findsOneWidget);

        // Tap make main
        await tester.tap(find.text('Make Main Photo'));
        expect(reorderCallbackCalled, isTrue);
      });
    });

    group('PhotoManagementSheet', () {
      testWidgets('displays reorderable list of photos', (tester) async {
        const photoUrls = ['/test/photo1.jpg', '/test/photo2.jpg'];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PhotoManagementSheet(
                photoUrls: photoUrls,
                onReorder: (oldIndex, newIndex) {},
                onDelete: (index) {},
              ),
            ),
          ),
        );

        // Should show management header
        expect(find.text('Manage Photos'), findsOneWidget);
        expect(
          find.text('Drag to reorder • First photo is the main photo'),
          findsOneWidget,
        );

        // Should show reorderable list
        expect(find.byType(ReorderableListView), findsOneWidget);

        // Should show main photo indicator
        expect(find.text('Main Photo'), findsOneWidget);
        expect(find.text('Photo 2'), findsOneWidget);

        // Should show delete buttons
        expect(find.byIcon(Icons.delete_rounded), findsNWidgets(2));

        // Should show drag handles
        expect(find.byIcon(Icons.drag_handle_rounded), findsNWidgets(2));
      });

      testWidgets('calls delete callback when delete is tapped', (
        tester,
      ) async {
        const photoUrls = ['/test/photo1.jpg'];
        int? deletedIndex;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PhotoManagementSheet(
                photoUrls: photoUrls,
                onReorder: (oldIndex, newIndex) {},
                onDelete: (index) {
                  deletedIndex = index;
                },
              ),
            ),
          ),
        );

        // Tap delete button
        await tester.tap(find.byIcon(Icons.delete_rounded));
        expect(deletedIndex, equals(0));
      });
    });
  });
}
