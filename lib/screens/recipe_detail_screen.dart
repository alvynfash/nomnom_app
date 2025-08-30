import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../models/recipe.dart';
import '../services/recipe_service.dart';
import 'recipe_edit_screen.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;
  final VoidCallback? onRecipeUpdated;
  final VoidCallback? onRecipeDeleted;

  const RecipeDetailScreen({
    super.key,
    required this.recipe,
    this.onRecipeUpdated,
    this.onRecipeDeleted,
  });

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  final RecipeService _recipeService = RecipeService();
  late Recipe _recipe;
  final PageController _photoPageController = PageController();
  int _currentPhotoIndex = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _recipe = widget.recipe;
  }

  @override
  void dispose() {
    _photoPageController.dispose();
    super.dispose();
  }

  void _navigateToEdit() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeEditScreen(
          recipe: _recipe,
          onRecipeSaved: () {
            _refreshRecipe();
            widget.onRecipeUpdated?.call();
          },
        ),
      ),
    );

    if (result == true) {
      _refreshRecipe();
    }
  }

  Future<void> _refreshRecipe() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final updatedRecipe = await _recipeService.getRecipeById(_recipe.id);
      if (updatedRecipe != null) {
        setState(() {
          _recipe = updatedRecipe;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error refreshing recipe: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteRecipe() async {
    final confirmed = await _showDeleteConfirmation();
    if (!confirmed) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _recipeService.deleteRecipe(_recipe.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recipe deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );

        widget.onRecipeDeleted?.call();
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting recipe: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<bool> _showDeleteConfirmation() async {
    try {
      // Check for deletion conflicts first
      final validationResult = await _recipeService.getRecipeDeletionValidation(
        _recipe.id,
      );

      if (!mounted) return false;

      return await showDialog<bool>(
            context: context,
            builder: (context) =>
                _buildDeleteConfirmationDialog(validationResult),
          ) ??
          false;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking recipe deletion: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return false;
    }
  }

  Widget _buildDeleteConfirmationDialog(dynamic validationResult) {
    final hasWarnings = validationResult.warnings.isNotEmpty;
    final hasActiveMealPlanConflicts =
        validationResult.hasActiveMealPlanConflicts;

    return AlertDialog(
      title: const Text('Delete Recipe'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Are you sure you want to delete "${_recipe.title}"? This action cannot be undone.',
          ),
          if (hasWarnings) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: hasActiveMealPlanConflicts
                    ? Theme.of(context).colorScheme.errorContainer
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        hasActiveMealPlanConflicts
                            ? Icons.error
                            : Icons.warning,
                        size: 20,
                        color: hasActiveMealPlanConflicts
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        hasActiveMealPlanConflicts
                            ? 'Cannot Delete'
                            : 'Warning',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: hasActiveMealPlanConflicts
                              ? Theme.of(context).colorScheme.error
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...validationResult.warnings.map<Widget>(
                    (warning) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '• ${warning.message}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: hasActiveMealPlanConflicts
                              ? Theme.of(context).colorScheme.error
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        if (!hasActiveMealPlanConflicts)
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(hasWarnings ? 'Delete Anyway' : 'Delete'),
          ),
      ],
    );
  }

  Future<void> _shareRecipe() async {
    try {
      final recipeText = _formatRecipeForSharing();
      await Share.share(recipeText, subject: _recipe.title);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing recipe: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  String _formatRecipeForSharing() {
    final buffer = StringBuffer();

    buffer.writeln(_recipe.title);
    buffer.writeln('=' * _recipe.title.length);
    buffer.writeln();

    if (_recipe.prepTime > 0 || _recipe.cookTime > 0 || _recipe.servings > 0) {
      buffer.writeln('Recipe Info:');
      if (_recipe.prepTime > 0) {
        buffer.writeln('• Prep Time: ${_recipe.prepTime} minutes');
      }
      if (_recipe.cookTime > 0) {
        buffer.writeln('• Cook Time: ${_recipe.cookTime} minutes');
      }
      if (_recipe.servings > 0) {
        buffer.writeln('• Servings: ${_recipe.servings}');
      }
      buffer.writeln();
    }

    buffer.writeln('Ingredients:');
    for (final ingredient in _recipe.ingredients) {
      buffer.writeln('• ${ingredient.formatted}');
    }
    buffer.writeln();

    buffer.writeln('Instructions:');
    for (int i = 0; i < _recipe.instructions.length; i++) {
      buffer.writeln('${i + 1}. ${_recipe.instructions[i]}');
    }

    if (_recipe.tags.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Tags: ${_recipe.tags.join(', ')}');
    }

    buffer.writeln();
    buffer.writeln('Shared from NomNom Recipe App');

    return buffer.toString();
  }

  Future<void> _copyRecipeToClipboard() async {
    try {
      final recipeText = _formatRecipeForSharing();
      await Clipboard.setData(ClipboardData(text: recipeText));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text('Recipe copied to clipboard'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error copying recipe: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // App Bar with Photo Gallery
                SliverAppBar(
                  expandedHeight: _recipe.photoUrls.isNotEmpty ? 300 : 120,
                  floating: false,
                  pinned: true,
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      _recipe.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 1),
                            blurRadius: 3,
                            color: Colors.black26,
                          ),
                        ],
                      ),
                    ),
                    background: _recipe.photoUrls.isNotEmpty
                        ? _buildPhotoGallery(colorScheme)
                        : _buildDefaultBackground(colorScheme),
                  ),
                  actions: [
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            _navigateToEdit();
                            break;
                          case 'share':
                            _shareRecipe();
                            break;
                          case 'copy':
                            _copyRecipeToClipboard();
                            break;
                          case 'delete':
                            _deleteRecipe();
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_rounded),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'share',
                          child: Row(
                            children: [
                              Icon(Icons.share_rounded),
                              SizedBox(width: 8),
                              Text('Share'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'copy',
                          child: Row(
                            children: [
                              Icon(Icons.copy_rounded),
                              SizedBox(width: 8),
                              Text('Copy'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_rounded),
                              SizedBox(width: 8),
                              Text('Delete'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Recipe Content
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Recipe Info Cards
                        _buildRecipeInfoSection(colorScheme),

                        const SizedBox(height: 24),

                        // Tags Section
                        if (_recipe.tags.isNotEmpty) ...[
                          _buildTagsSection(colorScheme),
                          const SizedBox(height: 24),
                        ],

                        // Ingredients Section
                        _buildIngredientsSection(colorScheme),

                        const SizedBox(height: 24),

                        // Instructions Section
                        _buildInstructionsSection(colorScheme),

                        const SizedBox(height: 24),

                        // Recipe Metadata
                        _buildMetadataSection(colorScheme),

                        const SizedBox(height: 100), // Bottom padding for FAB
                      ],
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToEdit,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        icon: const Icon(Icons.edit_rounded),
        label: const Text('Edit Recipe'),
      ),
    );
  }

  Widget _buildPhotoGallery(ColorScheme colorScheme) {
    return Stack(
      children: [
        PageView.builder(
          controller: _photoPageController,
          onPageChanged: (index) {
            setState(() {
              _currentPhotoIndex = index;
            });
          },
          itemCount: _recipe.photoUrls.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () => _showFullScreenPhoto(index),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black26],
                  ),
                ),
                child: Image.network(
                  _recipe.photoUrls[index],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildDefaultBackground(colorScheme);
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                            : null,
                        color: colorScheme.onPrimary,
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),

        // Photo indicators
        if (_recipe.photoUrls.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _recipe.photoUrls.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index == _currentPhotoIndex
                        ? colorScheme.onPrimary
                        : colorScheme.onPrimary.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDefaultBackground(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary,
            colorScheme.primary.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.restaurant_rounded,
          size: 64,
          color: colorScheme.onPrimary.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  void _showFullScreenPhoto(int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _FullScreenPhotoGallery(
          photoUrls: _recipe.photoUrls,
          initialIndex: initialIndex,
          recipeTitle: _recipe.title,
        ),
      ),
    );
  }

  Widget _buildRecipeInfoSection(ColorScheme colorScheme) {
    final hasTimeInfo = _recipe.prepTime > 0 || _recipe.cookTime > 0;
    final hasServingInfo = _recipe.servings > 0;

    if (!hasTimeInfo && !hasServingInfo) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        if (_recipe.prepTime > 0) ...[
          Expanded(
            child: _buildInfoCard(
              icon: Icons.timer_outlined,
              title: 'Prep Time',
              value: '${_recipe.prepTime} min',
              colorScheme: colorScheme,
            ),
          ),
        ],
        if (_recipe.prepTime > 0 && _recipe.cookTime > 0)
          const SizedBox(width: 12),
        if (_recipe.cookTime > 0) ...[
          Expanded(
            child: _buildInfoCard(
              icon: Icons.local_fire_department_rounded,
              title: 'Cook Time',
              value: '${_recipe.cookTime} min',
              colorScheme: colorScheme,
            ),
          ),
        ],
        if (hasTimeInfo && hasServingInfo) const SizedBox(width: 12),
        if (_recipe.servings > 0) ...[
          Expanded(
            child: _buildInfoCard(
              icon: Icons.people_rounded,
              title: 'Servings',
              value: '${_recipe.servings}',
              colorScheme: colorScheme,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required ColorScheme colorScheme,
  }) {
    return Card(
      elevation: 0,
      color: colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: colorScheme.onPrimaryContainer, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsSection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tags',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _recipe.tags.map((tag) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                tag,
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onTertiaryContainer,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildIngredientsSection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ingredients',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          color: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: _recipe.ingredients.asMap().entries.map((entry) {
                final index = entry.key;
                final ingredient = entry.value;
                final isLast = index == _recipe.ingredients.length - 1;

                return Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            ingredient.formatted,
                            style: TextStyle(
                              fontSize: 16,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (!isLast) ...[
                      const SizedBox(height: 12),
                      Divider(
                        color: colorScheme.outline.withValues(alpha: 0.1),
                        height: 1,
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionsSection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Instructions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          color: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: _recipe.instructions.asMap().entries.map((entry) {
                final index = entry.key;
                final instruction = entry.value;
                final isLast = index == _recipe.instructions.length - 1;

                return Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            instruction,
                            style: TextStyle(
                              fontSize: 16,
                              color: colorScheme.onSurface,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (!isLast) ...[
                      const SizedBox(height: 16),
                      Divider(
                        color: colorScheme.outline.withValues(alpha: 0.1),
                        height: 1,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetadataSection(ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recipe Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            _buildMetadataRow(
              'Created',
              _formatDate(_recipe.createdAt),
              colorScheme,
            ),
            const SizedBox(height: 8),
            _buildMetadataRow(
              'Last Updated',
              _formatDate(_recipe.updatedAt),
              colorScheme,
            ),
            if (_recipe.photoUrls.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildMetadataRow(
                'Photos',
                '${_recipe.photoUrls.length}',
                colorScheme,
              ),
            ],
            const SizedBox(height: 8),
            _buildMetadataRow(
              'Sharing',
              _recipe.isPublished
                  ? 'Public'
                  : _recipe.isPrivate
                  ? 'Private'
                  : 'Family',
              colorScheme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataRow(
    String label,
    String value,
    ColorScheme colorScheme,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return months == 1 ? '1 month ago' : '$months months ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return years == 1 ? '1 year ago' : '$years years ago';
    }
  }
}

class _FullScreenPhotoGallery extends StatefulWidget {
  final List<String> photoUrls;
  final int initialIndex;
  final String recipeTitle;

  const _FullScreenPhotoGallery({
    required this.photoUrls,
    required this.initialIndex,
    required this.recipeTitle,
  });

  @override
  State<_FullScreenPhotoGallery> createState() =>
      _FullScreenPhotoGalleryState();
}

class _FullScreenPhotoGalleryState extends State<_FullScreenPhotoGallery> {
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
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(
          '${_currentIndex + 1} of ${widget.photoUrls.length}',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              try {
                await Share.shareXFiles([
                  XFile(widget.photoUrls[_currentIndex]),
                ], subject: widget.recipeTitle);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error sharing photo: ${e.toString()}'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.share_rounded),
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
              child: Image.network(
                widget.photoUrls[index],
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_rounded,
                          color: Colors.white,
                          size: 48,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Failed to load image',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                          : null,
                      color: Colors.white,
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
