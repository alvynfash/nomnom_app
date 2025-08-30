import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recipe.dart';
import '../services/recipe_service.dart';
import '../widgets/search_bar_widget.dart';
import 'recipe_edit_screen.dart';
import 'recipe_detail_screen.dart';

class RecipeListScreen extends StatefulWidget {
  const RecipeListScreen({super.key});

  @override
  State<RecipeListScreen> createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends State<RecipeListScreen> {
  final RecipeService _recipeService = RecipeService();
  List<Recipe> _recipes = [];
  List<Recipe> _allRecipes = [];
  List<String> _availableTags = [];
  bool _isLoading = true;

  // Search and filter state
  String _searchQuery = '';
  List<String> _selectedTagFilters = [];

  // Preferences keys
  static const String _searchQueryKey = 'recipe_search_query';
  static const String _tagFiltersKey = 'recipe_tag_filters';

  @override
  void initState() {
    super.initState();
    _loadSavedFilters();
    _loadRecipes();
  }

  Future<void> _loadSavedFilters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _searchQuery = prefs.getString(_searchQueryKey) ?? '';
        _selectedTagFilters = prefs.getStringList(_tagFiltersKey) ?? [];
      });
    } catch (e) {
      // Handle error silently, use defaults
    }
  }

  Future<void> _saveFilters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_searchQueryKey, _searchQuery);
      await prefs.setStringList(_tagFiltersKey, _selectedTagFilters);
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _loadRecipes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load all recipes and available tags
      final allRecipes = await _recipeService.getRecipes();
      final availableTags = await _recipeService.getAllTags();

      setState(() {
        _allRecipes = allRecipes;
        _availableTags = availableTags;
        _isLoading = false;
      });

      // Apply current filters
      _applyFilters();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading recipes: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _applyFilters() {
    if (_searchQuery.isEmpty && _selectedTagFilters.isEmpty) {
      setState(() {
        _recipes = List.from(_allRecipes);
      });
      return;
    }

    setState(() {
      _recipes = _allRecipes.where((recipe) {
        // Apply text search
        bool matchesSearch = true;
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          matchesSearch =
              recipe.title.toLowerCase().contains(query) ||
              recipe.ingredients.any(
                (ingredient) => ingredient.name.toLowerCase().contains(query),
              ) ||
              recipe.tags.any((tag) => tag.toLowerCase().contains(query));
        }

        // Apply tag filters
        bool matchesTags = true;
        if (_selectedTagFilters.isNotEmpty) {
          matchesTags = _selectedTagFilters.every(
            (filter) => recipe.tags.any(
              (tag) => tag.toLowerCase() == filter.toLowerCase(),
            ),
          );
        }

        return matchesSearch && matchesTags;
      }).toList();
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _applyFilters();
    _saveFilters();
  }

  void _onTagFiltersChanged(List<String> tagFilters) {
    setState(() {
      _selectedTagFilters = tagFilters;
    });
    _applyFilters();
    _saveFilters();
  }

  void _navigateToCreateRecipe() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeEditScreen(onRecipeSaved: _loadRecipes),
      ),
    );
  }

  void _navigateToRecipeDetail(Recipe recipe) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeDetailScreen(
          recipe: recipe,
          onRecipeUpdated: _loadRecipes,
          onRecipeDeleted: _loadRecipes,
        ),
      ),
    );
  }

  void _navigateToEditRecipe(Recipe recipe) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            RecipeEditScreen(recipe: recipe, onRecipeSaved: _loadRecipes),
      ),
    );
  }

  Future<void> _deleteRecipe(Recipe recipe) async {
    await _recipeService.deleteRecipe(recipe.id);
    _loadRecipes();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'My Recipes',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search bar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    border: Border(
                      bottom: BorderSide(
                        color: colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                  child: SearchBarWidget(
                    key: ValueKey(
                      'search_bar_$_searchQuery${_selectedTagFilters.join(',')}',
                    ),
                    initialQuery: _searchQuery,
                    initialTagFilters: _selectedTagFilters,
                    availableTags: _availableTags,
                    onSearchChanged: _onSearchChanged,
                    onTagFiltersChanged: _onTagFiltersChanged,
                    hintText: 'Search recipes...',
                  ),
                ),

                // Recipe grid
                Expanded(
                  child: _recipes.isEmpty
                      ? _buildEmptyState(colorScheme)
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            // Calculate number of columns based on screen width
                            final screenWidth = constraints.maxWidth;
                            int crossAxisCount = 2;
                            if (screenWidth > 1200) {
                              crossAxisCount = 4;
                            } else if (screenWidth > 800) {
                              crossAxisCount = 3;
                            }

                            return GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                    childAspectRatio:
                                        0.75, // Adjust for card height
                                  ),
                              itemCount: _recipes.length,
                              itemBuilder: (context, index) {
                                final recipe = _recipes[index];
                                return _buildRecipeCard(recipe, colorScheme);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreateRecipe,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, size: 24),
        label: const Text(
          'New Recipe',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        extendedPadding: const EdgeInsets.symmetric(horizontal: 20),
      ),
    );
  }

  Widget _buildRecipeCard(Recipe recipe, ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: InkWell(
        onTap: () => _navigateToRecipeDetail(recipe),
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipe image
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  _buildCardImage(recipe, colorScheme),
                  // Favorite/bookmark button
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.bookmark_border_rounded,
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                          size: 20,
                        ),
                        onPressed: () {
                          // TODO: Implement bookmark functionality
                        },
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  // Menu button
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            _navigateToEditRecipe(recipe);
                          } else if (value == 'delete') {
                            _showDeleteConfirmation(recipe);
                          }
                        },
                        icon: Icon(
                          Icons.more_vert_rounded,
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                          size: 20,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        padding: EdgeInsets.zero,
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_rounded, size: 18),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_rounded, size: 18),
                                SizedBox(width: 8),
                                Text('Delete'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Sharing status indicator
                  if (recipe.isPublished || !recipe.isPrivate)
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: _buildSharingIndicator(recipe, colorScheme),
                    ),
                ],
              ),
            ),
            // Recipe details
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Recipe title
                    Text(
                      recipe.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: colorScheme.onSurface,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Recipe description (first instruction or ingredient summary)
                    Text(
                      _getRecipeDescription(recipe),
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    // Recipe metadata
                    Row(
                      children: [
                        _buildTimeChip(
                          Icons.timer_outlined,
                          '${recipe.prepTime + recipe.cookTime} min',
                          colorScheme,
                        ),
                        const SizedBox(width: 8),
                        _buildTimeChip(
                          Icons.people_outline_rounded,
                          '${recipe.servings}',
                          colorScheme,
                        ),
                        const Spacer(),
                        // Rating or difficulty indicator
                        _buildDifficultyIndicator(recipe, colorScheme),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardImage(Recipe recipe, ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        color: colorScheme.surfaceContainerHighest,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: recipe.photoUrls.isNotEmpty
            ? _buildCardRecipeImage(recipe.photoUrls.first, recipe, colorScheme)
            : _buildDefaultCardImage(recipe, colorScheme),
      ),
    );
  }

  Widget _buildCardRecipeImage(
    String photoUrl,
    Recipe recipe,
    ColorScheme colorScheme,
  ) {
    // Check if it's a network URL or local file path
    final isNetworkUrl =
        photoUrl.startsWith('http://') || photoUrl.startsWith('https://');

    if (isNetworkUrl) {
      return Image.network(
        photoUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultCardImage(recipe, colorScheme);
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: colorScheme.surfaceContainerHighest,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
      );
    } else {
      // Local file
      final file = File(photoUrl);
      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultCardImage(recipe, colorScheme);
        },
      );
    }
  }

  Widget _buildDefaultCardImage(Recipe recipe, ColorScheme colorScheme) {
    // Generate a color based on recipe title for variety
    final colors = [
      colorScheme.primaryContainer,
      colorScheme.secondaryContainer,
      colorScheme.tertiaryContainer,
      colorScheme.errorContainer,
    ];
    final colorIndex = recipe.title.hashCode.abs() % colors.length;
    final backgroundColor = colors[colorIndex];
    final foregroundColor = colorIndex == 0
        ? colorScheme.onPrimaryContainer
        : colorIndex == 1
        ? colorScheme.onSecondaryContainer
        : colorIndex == 2
        ? colorScheme.onTertiaryContainer
        : colorScheme.onErrorContainer;

    return Container(
      width: double.infinity,
      color: backgroundColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_rounded,
            size: 48,
            color: foregroundColor.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 8),
          Text(
            recipe.title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: foregroundColor.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _getRecipeDescription(Recipe recipe) {
    // Use the recipe's description if available
    if (recipe.description.isNotEmpty) {
      return recipe.description;
    }

    // Fallback to first instruction
    if (recipe.instructions.isNotEmpty) {
      return recipe.instructions.first;
    }

    // Fallback to ingredient summary
    if (recipe.ingredients.isNotEmpty) {
      final ingredientNames = recipe.ingredients
          .take(3)
          .map((ingredient) => ingredient.name)
          .join(', ');
      return 'Made with $ingredientNames${recipe.ingredients.length > 3 ? ' and more' : ''}';
    }

    return 'A delicious recipe';
  }

  Widget _buildTimeChip(IconData icon, String label, ColorScheme colorScheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDifficultyIndicator(Recipe recipe, ColorScheme colorScheme) {
    Color difficultyColor;
    IconData difficultyIcon;

    switch (recipe.difficulty) {
      case RecipeDifficulty.easy:
        difficultyColor = Colors.green;
        difficultyIcon = Icons.sentiment_satisfied_rounded;
        break;
      case RecipeDifficulty.medium:
        difficultyColor = Colors.orange;
        difficultyIcon = Icons.sentiment_neutral_rounded;
        break;
      case RecipeDifficulty.hard:
        difficultyColor = Colors.red;
        difficultyIcon = Icons.sentiment_very_dissatisfied_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: difficultyColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: difficultyColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(difficultyIcon, size: 12, color: difficultyColor),
          const SizedBox(width: 2),
          Text(
            recipe.difficulty.displayName,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: difficultyColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSharingIndicator(Recipe recipe, ColorScheme colorScheme) {
    if (recipe.isPublished) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.public_rounded, size: 12, color: Colors.white),
            const SizedBox(width: 4),
            const Text(
              'Public',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    } else if (!recipe.isPrivate) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.family_restroom_rounded,
              size: 12,
              color: Colors.white,
            ),
            const SizedBox(width: 4),
            const Text(
              'Family',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    final hasFilters =
        _searchQuery.isNotEmpty || _selectedTagFilters.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasFilters
                    ? Icons.search_off_rounded
                    : Icons.restaurant_menu_rounded,
                size: 64,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              hasFilters ? 'No recipes found' : 'Start Your Culinary Journey!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              hasFilters
                  ? 'Try adjusting your search terms or removing some filters to find more recipes.'
                  : 'Create your first recipe and start building your personal cookbook. Share your favorite dishes with family and friends!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            if (hasFilters) ...[
              FilledButton.tonal(
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                    _selectedTagFilters.clear();
                  });
                  _applyFilters();
                  _saveFilters();
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text('Clear All Filters'),
              ),
            ] else ...[
              FilledButton.icon(
                onPressed: _navigateToCreateRecipe,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create Your First Recipe'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmation(Recipe recipe) async {
    try {
      // Check for deletion conflicts first
      final validationResult = await _recipeService.getRecipeDeletionValidation(
        recipe.id,
      );

      if (!mounted) return;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) =>
            _buildDeleteConfirmationDialog(recipe, validationResult),
      );

      if (confirmed == true) {
        await _deleteRecipe(recipe);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking recipe deletion: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Widget _buildDeleteConfirmationDialog(
    Recipe recipe,
    dynamic validationResult,
  ) {
    final hasWarnings = validationResult.warnings.isNotEmpty;
    final hasActiveMealPlanConflicts =
        validationResult.hasActiveMealPlanConflicts;

    return AlertDialog(
      title: const Text('Delete Recipe'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Are you sure you want to delete "${recipe.title}"?'),
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
}
