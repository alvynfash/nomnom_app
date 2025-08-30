import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:nomnom/services/photo_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('PhotoService Tests', () {
    late PhotoService photoService;
    late String testRecipeId;

    setUp(() {
      photoService = PhotoService();
      testRecipeId = 'test_recipe_123';
    });

    group('Photo Bytes Saving', () {
      test('should save valid JPEG bytes successfully', () async {
        // Create valid JPEG bytes
        final jpegBytes = Uint8List.fromList([
          0xFF, 0xD8, 0xFF, 0xE0, // JPEG header
          ...List.filled(100, 0x00), // Dummy data
        ]);

        final savedPath = await photoService.saveRecipePhotoFromBytes(
          testRecipeId,
          jpegBytes,
          'test.jpg',
        );

        expect(savedPath, isNotEmpty);
        expect(File(savedPath).existsSync(), isTrue);

        // Clean up
        await photoService.deleteRecipePhoto(savedPath);
      });

      test('should save valid PNG bytes successfully', () async {
        // Create valid PNG bytes
        final pngBytes = Uint8List.fromList([
          0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG header
          ...List.filled(100, 0x00), // Dummy data
        ]);

        final savedPath = await photoService.saveRecipePhotoFromBytes(
          testRecipeId,
          pngBytes,
          'test.png',
        );

        expect(savedPath, isNotEmpty);
        expect(File(savedPath).existsSync(), isTrue);

        // Clean up
        await photoService.deleteRecipePhoto(savedPath);
      });

      test('should reject bytes that are too large', () async {
        // Create bytes larger than 5MB
        final largeBytes = Uint8List(6 * 1024 * 1024); // 6MB

        expect(
          () => photoService.saveRecipePhotoFromBytes(
            testRecipeId,
            largeBytes,
            'large.jpg',
          ),
          throwsA(isA<PhotoServiceException>()),
        );
      });

      test('should reject invalid file extension', () async {
        final validBytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]);

        expect(
          () => photoService.saveRecipePhotoFromBytes(
            testRecipeId,
            validBytes,
            'test.gif',
          ),
          throwsA(isA<PhotoServiceException>()),
        );
      });

      test('should reject invalid image content', () async {
        final invalidBytes = Uint8List.fromList([0x00, 0x01, 0x02, 0x03]);

        expect(
          () => photoService.saveRecipePhotoFromBytes(
            testRecipeId,
            invalidBytes,
            'test.jpg',
          ),
          throwsA(isA<PhotoServiceException>()),
        );
      });
    });

    group('Photo Management', () {
      late String testPhotoPath;

      setUp(() async {
        // Create a test photo
        final jpegBytes = Uint8List.fromList([
          0xFF,
          0xD8,
          0xFF,
          0xE0,
          ...List.filled(100, 0x00),
        ]);

        testPhotoPath = await photoService.saveRecipePhotoFromBytes(
          testRecipeId,
          jpegBytes,
          'test.jpg',
        );
      });

      tearDown(() async {
        // Clean up test photo
        try {
          await photoService.deleteRecipePhoto(testPhotoPath);
        } catch (e) {
          // Ignore cleanup errors
        }
      });

      test('should get recipe photos correctly', () async {
        final photos = await photoService.getRecipePhotos(testRecipeId);
        expect(photos, contains(testPhotoPath));
      });

      test('should delete photo successfully', () async {
        expect(await photoService.photoExists(testPhotoPath), isTrue);

        await photoService.deleteRecipePhoto(testPhotoPath);

        expect(await photoService.photoExists(testPhotoPath), isFalse);
      });

      test('should get photo info correctly', () async {
        final info = await photoService.getPhotoInfo(testPhotoPath);

        expect(info, isNotNull);
        expect(info!['path'], equals(testPhotoPath));
        expect(info['recipeId'], equals(testRecipeId));
        expect(info['size'], isA<int>());
        expect(info['sizeFormatted'], isA<String>());
        expect(info['modified'], isA<DateTime>());
      });

      test('should return null for non-existent photo info', () async {
        final info = await photoService.getPhotoInfo('/non/existent/path.jpg');
        expect(info, isNull);
      });

      test('should calculate recipe photos total size', () async {
        final totalSize = await photoService.getRecipePhotosTotalSize(
          testRecipeId,
        );
        expect(totalSize, greaterThan(0));
      });

      test('should get empty list for non-existent recipe', () async {
        final photos = await photoService.getRecipePhotos(
          'non_existent_recipe',
        );
        expect(photos, isEmpty);
      });
    });

    group('Bulk Operations', () {
      late List<String> testPhotoPaths;
      late List<String> testRecipeIds;

      setUp(() async {
        testPhotoPaths = [];
        testRecipeIds = [];

        // Create multiple test photos
        for (int i = 0; i < 3; i++) {
          final recipeId = '${testRecipeId}_$i';
          testRecipeIds.add(recipeId);

          final jpegBytes = Uint8List.fromList([
            0xFF,
            0xD8,
            0xFF,
            0xE0,
            ...List.filled(100, 0x00),
          ]);

          final photoPath = await photoService.saveRecipePhotoFromBytes(
            recipeId,
            jpegBytes,
            'test$i.jpg',
          );
          testPhotoPaths.add(photoPath);
        }
      });

      tearDown(() async {
        // Clean up test photos
        for (final photoPath in testPhotoPaths) {
          try {
            await photoService.deleteRecipePhoto(photoPath);
          } catch (e) {
            // Ignore cleanup errors
          }
        }
      });

      test('should delete all recipe photos', () async {
        await photoService.deleteAllRecipePhotos(testRecipeIds[0]);

        final photos = await photoService.getRecipePhotos(testRecipeIds[0]);
        expect(photos, isEmpty);
      });

      test('should calculate total photos size', () async {
        final totalSize = await photoService.getAllPhotosTotalSize();
        expect(totalSize, greaterThan(0));
      });

      test('should cleanup orphaned photos', () async {
        // Create an orphaned photo
        final orphanedBytes = Uint8List.fromList([
          0xFF,
          0xD8,
          0xFF,
          0xE0,
          ...List.filled(50, 0x00),
        ]);

        final orphanedPath = await photoService.saveRecipePhotoFromBytes(
          'orphaned_recipe',
          orphanedBytes,
          'orphaned.jpg',
        );

        // Cleanup orphaned photos (only keep existing recipe IDs)
        final deletedPhotos = await photoService.cleanupOrphanedPhotos(
          testRecipeIds,
        );

        expect(deletedPhotos, contains(orphanedPath));
        expect(await photoService.photoExists(orphanedPath), isFalse);
      });
    });

    group('Error Handling', () {
      test('should handle non-existent photo deletion gracefully', () async {
        // Should not throw an exception
        await photoService.deleteRecipePhoto('/non/existent/path.jpg');
      });

      test('should handle directory operations', () async {
        // This test verifies the service can get the directory path
        final dirPath = await photoService.getPhotoDirectoryPath();
        expect(dirPath, isNotEmpty);
        expect(dirPath, contains('recipe_photos'));
      });

      test('should check photo existence correctly', () async {
        expect(
          await photoService.photoExists('/non/existent/path.jpg'),
          isFalse,
        );
      });
    });

    group('File Operations', () {
      test('should create temporary test file and validate it', () async {
        // Create a temporary file for testing file-based operations
        final tempDir = await Directory.systemTemp.createTemp('photo_test');
        final testFile = File('${tempDir.path}/test.jpg');

        // Write valid JPEG bytes
        final jpegBytes = Uint8List.fromList([
          0xFF,
          0xD8,
          0xFF,
          0xE0,
          ...List.filled(100, 0x00),
        ]);
        await testFile.writeAsBytes(jpegBytes);

        // Test saving from file
        final savedPath = await photoService.saveRecipePhoto(
          testRecipeId,
          testFile,
        );
        expect(savedPath, isNotEmpty);
        expect(File(savedPath).existsSync(), isTrue);

        // Clean up
        await photoService.deleteRecipePhoto(savedPath);
        await tempDir.delete(recursive: true);
      });

      test('should reject non-existent file', () async {
        final nonExistentFile = File('/non/existent/file.jpg');

        expect(
          () => photoService.saveRecipePhoto(testRecipeId, nonExistentFile),
          throwsA(isA<PhotoServiceException>()),
        );
      });

      test('should reject file that is too large', () async {
        // Create a temporary large file
        final tempDir = await Directory.systemTemp.createTemp('photo_test');
        final largeFile = File('${tempDir.path}/large.jpg');

        // Write large file (6MB)
        final largeBytes = Uint8List(6 * 1024 * 1024);
        // Add JPEG header
        largeBytes[0] = 0xFF;
        largeBytes[1] = 0xD8;
        largeBytes[2] = 0xFF;
        largeBytes[3] = 0xE0;

        await largeFile.writeAsBytes(largeBytes);

        expect(
          () => photoService.saveRecipePhoto(testRecipeId, largeFile),
          throwsA(isA<PhotoServiceException>()),
        );

        // Clean up
        await tempDir.delete(recursive: true);
      });
    });
  });
}
