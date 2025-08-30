import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/photo_service.dart';
import '../utils/fade_page_route.dart';

class PhotoUploadWidget extends StatefulWidget {
  final List<String> photoUrls;
  final Function(List<String>) onPhotosChanged;
  final String recipeId;
  final int maxPhotos;
  final bool enabled;

  const PhotoUploadWidget({
    super.key,
    required this.photoUrls,
    required this.onPhotosChanged,
    required this.recipeId,
    this.maxPhotos = 5,
    this.enabled = true,
  });

  @override
  State<PhotoUploadWidget> createState() => _PhotoUploadWidgetState();
}

class _PhotoUploadWidgetState extends State<PhotoUploadWidget> {
  final PhotoService _photoService = PhotoService();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Photo Grid
        if (widget.photoUrls.isNotEmpty) ...[
          _buildPhotoGrid(colorScheme),
          const SizedBox(height: 16),
        ],

        // Upload Controls
        if (widget.enabled && widget.photoUrls.length < widget.maxPhotos) ...[
          _buildUploadControls(colorScheme),
        ],

        // Photo Count Info
        if (widget.photoUrls.isNotEmpty || widget.maxPhotos > 1) ...[
          const SizedBox(height: 8),
          _buildPhotoCountInfo(colorScheme),
        ],
      ],
    );
  }

  Widget _buildPhotoGrid(ColorScheme colorScheme) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: widget.photoUrls.length,
      itemBuilder: (context, index) {
        return _buildPhotoItem(widget.photoUrls[index], index, colorScheme);
      },
    );
  }

  Widget _buildPhotoItem(String photoUrl, int index, ColorScheme colorScheme) {
    return Stack(
      children: [
        // Photo Container
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: GestureDetector(
              onTap: () => _showPhotoPreview(photoUrl, index),
              child: Image.file(
                File(photoUrl),
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.broken_image_rounded,
                      color: colorScheme.onSurfaceVariant,
                      size: 32,
                    ),
                  );
                },
              ),
            ),
          ),
        ),

        // Delete Button
        if (widget.enabled)
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _deletePhoto(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: colorScheme.error,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.close_rounded,
                  color: colorScheme.onError,
                  size: 16,
                ),
              ),
            ),
          ),

        // Primary Photo Indicator
        if (index == 0 && widget.photoUrls.length > 1)
          Positioned(
            bottom: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                'Main',
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildUploadControls(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.add_photo_alternate_rounded,
            size: 32,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 8),
          Text(
            'Add Recipe Photos',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Show off your delicious creation!',
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isUploading
                      ? null
                      : () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_rounded),
                  label: const Text('Camera'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _isUploading
                      ? null
                      : () => _pickImage(ImageSource.gallery),
                  icon: _isUploading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.photo_library_rounded),
                  label: Text(_isUploading ? 'Uploading...' : 'Gallery'),
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoCountInfo(ColorScheme colorScheme) {
    return Row(
      children: [
        Icon(
          Icons.info_outline_rounded,
          size: 16,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(
          '${widget.photoUrls.length} of ${widget.maxPhotos} photos',
          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
        ),
        if (widget.photoUrls.isNotEmpty) ...[
          const Spacer(),
          TextButton.icon(
            onPressed: widget.enabled ? _showPhotoManagement : null,
            icon: const Icon(Icons.edit_rounded, size: 16),
            label: const Text('Manage'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_isUploading) return;

    try {
      setState(() {
        _isUploading = true;
      });

      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        await _processSelectedImage(File(image.path));
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to pick image: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _processSelectedImage(File imageFile) async {
    try {
      // Save the photo using PhotoService
      final savedPath = await _photoService.saveRecipePhoto(
        widget.recipeId,
        imageFile,
      );

      // Update the photo URLs list
      final updatedUrls = List<String>.from(widget.photoUrls)..add(savedPath);
      widget.onPhotosChanged(updatedUrls);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 8),
                Text('Photo added successfully!'),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Failed to save photo';
        if (e is PhotoServiceException) {
          errorMessage = e.message;
        }
        _showErrorSnackBar(errorMessage);
      }
    }
  }

  Future<void> _deletePhoto(int index) async {
    final confirmed = await _showDeleteConfirmation();
    if (!confirmed) return;

    try {
      final photoUrl = widget.photoUrls[index];

      // Delete the photo file
      await _photoService.deleteRecipePhoto(photoUrl);

      // Update the photo URLs list
      final updatedUrls = List<String>.from(widget.photoUrls)..removeAt(index);
      widget.onPhotosChanged(updatedUrls);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.delete_rounded, color: Colors.white),
                SizedBox(width: 8),
                Text('Photo deleted'),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to delete photo: ${e.toString()}');
      }
    }
  }

  Future<bool> _showDeleteConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Photo'),
        content: const Text('Are you sure you want to delete this photo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showPhotoPreview(String photoUrl, int index) {
    FadeNavigation.push(
      context,
      PhotoPreviewScreen(
        photoUrls: widget.photoUrls,
        initialIndex: index,
        onDelete: widget.enabled
            ? (deleteIndex) async {
                Navigator.of(context).pop();
                await _deletePhoto(deleteIndex);
              }
            : null,
        onReorder: widget.enabled
            ? (oldIndex, newIndex) {
                final updatedUrls = List<String>.from(widget.photoUrls);
                final item = updatedUrls.removeAt(oldIndex);
                updatedUrls.insert(
                  newIndex > oldIndex ? newIndex - 1 : newIndex,
                  item,
                );
                widget.onPhotosChanged(updatedUrls);
                Navigator.of(context).pop();
              }
            : null,
      ),
    );
  }

  void _showPhotoManagement() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => PhotoManagementSheet(
        photoUrls: widget.photoUrls,
        onReorder: (oldIndex, newIndex) {
          final updatedUrls = List<String>.from(widget.photoUrls);
          final item = updatedUrls.removeAt(oldIndex);
          updatedUrls.insert(
            newIndex > oldIndex ? newIndex - 1 : newIndex,
            item,
          );
          widget.onPhotosChanged(updatedUrls);
        },
        onDelete: (index) async {
          Navigator.of(context).pop();
          await _deletePhoto(index);
        },
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class PhotoPreviewScreen extends StatefulWidget {
  final List<String> photoUrls;
  final int initialIndex;
  final Function(int)? onDelete;
  final Function(int, int)? onReorder;

  const PhotoPreviewScreen({
    super.key,
    required this.photoUrls,
    required this.initialIndex,
    this.onDelete,
    this.onReorder,
  });

  @override
  State<PhotoPreviewScreen> createState() => _PhotoPreviewScreenState();
}

class _PhotoPreviewScreenState extends State<PhotoPreviewScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_currentIndex + 1} of ${widget.photoUrls.length}'),
        actions: [
          if (widget.onDelete != null)
            IconButton(
              onPressed: () => widget.onDelete!(_currentIndex),
              icon: const Icon(Icons.delete_rounded),
            ),
          if (widget.onReorder != null && widget.photoUrls.length > 1)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'make_main' && _currentIndex != 0) {
                  widget.onReorder!(_currentIndex, 0);
                }
              },
              itemBuilder: (context) => [
                if (_currentIndex != 0)
                  const PopupMenuItem(
                    value: 'make_main',
                    child: Row(
                      children: [
                        Icon(Icons.star_rounded),
                        SizedBox(width: 8),
                        Text('Make Main Photo'),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemCount: widget.photoUrls.length,
        itemBuilder: (context, index) {
          return InteractiveViewer(
            child: Center(
              child: Image.file(
                File(widget.photoUrls[index]),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.broken_image_rounded,
                      color: colorScheme.onSurfaceVariant,
                      size: 64,
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: widget.photoUrls.length > 1
          ? Container(
              color: Colors.black,
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.photoUrls.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == _currentIndex
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

class PhotoManagementSheet extends StatefulWidget {
  final List<String> photoUrls;
  final Function(int, int) onReorder;
  final Function(int) onDelete;

  const PhotoManagementSheet({
    super.key,
    required this.photoUrls,
    required this.onReorder,
    required this.onDelete,
  });

  @override
  State<PhotoManagementSheet> createState() => _PhotoManagementSheetState();
}

class _PhotoManagementSheetState extends State<PhotoManagementSheet> {
  late List<String> _photoUrls;

  @override
  void initState() {
    super.initState();
    _photoUrls = List.from(widget.photoUrls);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Manage Photos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Drag to reorder • First photo is the main photo',
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: ReorderableListView.builder(
              shrinkWrap: true,
              itemCount: _photoUrls.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  final item = _photoUrls.removeAt(oldIndex);
                  _photoUrls.insert(
                    newIndex > oldIndex ? newIndex - 1 : newIndex,
                    item,
                  );
                });
                widget.onReorder(oldIndex, newIndex);
              },
              itemBuilder: (context, index) {
                return ListTile(
                  key: ValueKey(_photoUrls[index]),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(_photoUrls[index]),
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: Text(
                    index == 0 ? 'Main Photo' : 'Photo ${index + 1}',
                    style: TextStyle(
                      fontWeight: index == 0
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  subtitle: index == 0
                      ? const Text('Shown first in recipe')
                      : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.drag_handle_rounded),
                      IconButton(
                        onPressed: () => widget.onDelete(index),
                        icon: Icon(
                          Icons.delete_rounded,
                          color: colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
