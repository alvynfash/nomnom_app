import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../models/recipe.dart';

class PhotoServiceException implements Exception {
  final String message;
  final String code;

  PhotoServiceException(this.message, this.code);

  @override
  String toString() => 'PhotoServiceException: $message (code: $code)';
}

class PhotoService {
  static const String _photosDirectory = 'recipe_photos';
  static const int _maxPhotoSize = 5 * 1024 * 1024; // 5MB
  static const List<String> _allowedExtensions = ['jpg', 'jpeg', 'png'];

  /// Gets the directory where recipe photos are stored
  Future<Directory> get _photoDirectory async {
    final appDir = await getApplicationDocumentsDirectory();
    final photoDir = Directory(path.join(appDir.path, _photosDirectory));

    if (!await photoDir.exists()) {
      await photoDir.create(recursive: true);
    }

    return photoDir;
  }

  /// Saves a recipe photo and returns the file path
  Future<String> saveRecipePhoto(String recipeId, File imageFile) async {
    try {
      // Validate the image file
      await _validateImageFile(imageFile);

      // Get the photo directory
      final photoDir = await _photoDirectory;

      // Generate a unique filename
      final extension = path.extension(imageFile.path).toLowerCase();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = '${recipeId}_$timestamp$extension';
      final targetPath = path.join(photoDir.path, filename);

      // Copy the file to the photos directory
      final targetFile = await imageFile.copy(targetPath);

      return targetFile.path;
    } catch (e) {
      if (e is PhotoServiceException) {
        rethrow;
      }
      throw PhotoServiceException(
        'Failed to save photo: ${e.toString()}',
        'SAVE_ERROR',
      );
    }
  }

  /// Saves photo from bytes data
  Future<String> saveRecipePhotoFromBytes(
    String recipeId,
    Uint8List imageBytes,
    String originalFilename,
  ) async {
    try {
      // Validate file size
      if (imageBytes.length > _maxPhotoSize) {
        throw PhotoServiceException(
          'Photo size (${_formatFileSize(imageBytes.length)}) exceeds maximum allowed size (${_formatFileSize(_maxPhotoSize)})',
          'FILE_TOO_LARGE',
        );
      }

      // Validate file extension
      final extension = path.extension(originalFilename).toLowerCase();
      if (!_allowedExtensions.contains(extension.replaceFirst('.', ''))) {
        throw PhotoServiceException(
          'Invalid file format. Allowed formats: ${_allowedExtensions.join(', ')}',
          'INVALID_FORMAT',
        );
      }

      // Get the photo directory
      final photoDir = await _photoDirectory;

      // Generate a unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = '${recipeId}_$timestamp$extension';
      final targetPath = path.join(photoDir.path, filename);

      // Write the bytes to file
      final file = File(targetPath);
      await file.writeAsBytes(imageBytes);

      return file.path;
    } catch (e) {
      if (e is PhotoServiceException) {
        rethrow;
      }
      throw PhotoServiceException(
        'Failed to save photo from bytes: ${e.toString()}',
        'SAVE_BYTES_ERROR',
      );
    }
  }

  /// Deletes a recipe photo
  Future<void> deleteRecipePhoto(String photoPath) async {
    try {
      final file = File(photoPath);

      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw PhotoServiceException(
        'Failed to delete photo: ${e.toString()}',
        'DELETE_ERROR',
      );
    }
  }

  /// Gets all photos for a specific recipe
  Future<List<String>> getRecipePhotos(String recipeId) async {
    try {
      final photoDir = await _photoDirectory;

      if (!await photoDir.exists()) {
        return [];
      }

      final files = await photoDir.list().toList();
      final recipePhotos = <String>[];

      for (final file in files) {
        if (file is File) {
          final filename = path.basename(file.path);
          if (filename.startsWith('${recipeId}_')) {
            recipePhotos.add(file.path);
          }
        }
      }

      // Sort by timestamp (newest first)
      recipePhotos.sort((a, b) {
        final timestampA = _extractTimestampFromFilename(path.basename(a));
        final timestampB = _extractTimestampFromFilename(path.basename(b));
        return timestampB.compareTo(timestampA);
      });

      return recipePhotos;
    } catch (e) {
      throw PhotoServiceException(
        'Failed to get recipe photos: ${e.toString()}',
        'GET_PHOTOS_ERROR',
      );
    }
  }

  /// Deletes all photos for a specific recipe
  Future<void> deleteAllRecipePhotos(String recipeId) async {
    try {
      final recipePhotos = await getRecipePhotos(recipeId);

      for (final photoPath in recipePhotos) {
        await deleteRecipePhoto(photoPath);
      }
    } catch (e) {
      throw PhotoServiceException(
        'Failed to delete all recipe photos: ${e.toString()}',
        'DELETE_ALL_ERROR',
      );
    }
  }

  /// Gets the total size of all photos for a recipe
  Future<int> getRecipePhotosTotalSize(String recipeId) async {
    try {
      final recipePhotos = await getRecipePhotos(recipeId);
      int totalSize = 0;

      for (final photoPath in recipePhotos) {
        final file = File(photoPath);
        if (await file.exists()) {
          final stat = await file.stat();
          totalSize += stat.size;
        }
      }

      return totalSize;
    } catch (e) {
      throw PhotoServiceException(
        'Failed to calculate photos total size: ${e.toString()}',
        'SIZE_CALCULATION_ERROR',
      );
    }
  }

  /// Gets the total size of all photos in the app
  Future<int> getAllPhotosTotalSize() async {
    try {
      final photoDir = await _photoDirectory;

      if (!await photoDir.exists()) {
        return 0;
      }

      final files = await photoDir.list().toList();
      int totalSize = 0;

      for (final file in files) {
        if (file is File) {
          final stat = await file.stat();
          totalSize += stat.size;
        }
      }

      return totalSize;
    } catch (e) {
      throw PhotoServiceException(
        'Failed to calculate total photos size: ${e.toString()}',
        'TOTAL_SIZE_ERROR',
      );
    }
  }

  /// Cleans up orphaned photos (photos without corresponding recipes)
  Future<List<String>> cleanupOrphanedPhotos(
    List<String> existingRecipeIds,
  ) async {
    try {
      final photoDir = await _photoDirectory;

      if (!await photoDir.exists()) {
        return [];
      }

      final files = await photoDir.list().toList();
      final deletedPhotos = <String>[];

      for (final file in files) {
        if (file is File) {
          final filename = path.basename(file.path);
          final recipeId = _extractRecipeIdFromFilename(filename);

          if (recipeId != null && !existingRecipeIds.contains(recipeId)) {
            await file.delete();
            deletedPhotos.add(file.path);
          }
        }
      }

      return deletedPhotos;
    } catch (e) {
      throw PhotoServiceException(
        'Failed to cleanup orphaned photos: ${e.toString()}',
        'CLEANUP_ERROR',
      );
    }
  }

  /// Validates an image file
  Future<void> _validateImageFile(File imageFile) async {
    // Check if file exists
    if (!await imageFile.exists()) {
      throw PhotoServiceException(
        'Image file does not exist',
        'FILE_NOT_FOUND',
      );
    }

    // Check file size
    final stat = await imageFile.stat();
    if (stat.size > _maxPhotoSize) {
      throw PhotoServiceException(
        'Photo size (${_formatFileSize(stat.size)}) exceeds maximum allowed size (${_formatFileSize(_maxPhotoSize)})',
        'FILE_TOO_LARGE',
      );
    }

    // Check file extension
    if (!Recipe.isValidPhotoExtension(imageFile.path)) {
      throw PhotoServiceException(
        'Invalid file format. Allowed formats: ${_allowedExtensions.join(', ')}',
        'INVALID_FORMAT',
      );
    }

    // Basic file content validation (check if it's actually an image)
    try {
      final bytes = await imageFile.readAsBytes();
      if (!_isValidImageBytes(bytes)) {
        throw PhotoServiceException(
          'File does not appear to be a valid image',
          'INVALID_IMAGE_CONTENT',
        );
      }
    } catch (e) {
      throw PhotoServiceException(
        'Failed to read image file: ${e.toString()}',
        'READ_ERROR',
      );
    }
  }

  /// Basic validation of image bytes by checking file headers
  bool _isValidImageBytes(Uint8List bytes) {
    if (bytes.length < 4) return false;

    // Check for common image file signatures
    // JPEG: FF D8 FF
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return true;
    }

    // PNG: 89 50 4E 47
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return true;
    }

    return false;
  }

  /// Extracts timestamp from filename
  int _extractTimestampFromFilename(String filename) {
    try {
      final parts = filename.split('_');
      if (parts.length >= 2) {
        final timestampPart = parts[1].split('.')[0];
        return int.parse(timestampPart);
      }
    } catch (e) {
      // Ignore parsing errors
    }
    return 0;
  }

  /// Extracts recipe ID from filename
  String? _extractRecipeIdFromFilename(String filename) {
    try {
      final parts = filename.split('_');
      if (parts.length >= 2) {
        return parts[0];
      }
    } catch (e) {
      // Ignore parsing errors
    }
    return null;
  }

  /// Formats file size in human-readable format
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Gets photo directory path for debugging/info purposes
  Future<String> getPhotoDirectoryPath() async {
    final photoDir = await _photoDirectory;
    return photoDir.path;
  }

  /// Checks if a photo file exists
  Future<bool> photoExists(String photoPath) async {
    try {
      final file = File(photoPath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Gets photo file info
  Future<Map<String, dynamic>?> getPhotoInfo(String photoPath) async {
    try {
      final file = File(photoPath);

      if (!await file.exists()) {
        return null;
      }

      final stat = await file.stat();
      final filename = path.basename(photoPath);

      return {
        'path': photoPath,
        'filename': filename,
        'size': stat.size,
        'sizeFormatted': _formatFileSize(stat.size),
        'modified': stat.modified,
        'recipeId': _extractRecipeIdFromFilename(filename),
        'timestamp': _extractTimestampFromFilename(filename),
      };
    } catch (e) {
      throw PhotoServiceException(
        'Failed to get photo info: ${e.toString()}',
        'INFO_ERROR',
      );
    }
  }
}
