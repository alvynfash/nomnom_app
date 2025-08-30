import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../services/recipe_service.dart';

/// A dialog for selecting recipes from the family's recipe collection
class RecipeSelectionDialog extends StatefulWidget {
  /// List of available recipes to choose from
  final List<Recipe> availableRecipes;

  /// Callback when a recipe is selected (null to clear selection)
  final Function(Recipe?) onRecipeSelected;

  /// Currently selected recipe ID (if any)
  final String? currentRecipeId;

  /// Whether to show a "Remove Recipe" option
  final bool showRemoveOption;

  /// Title for the dialog
  final String title;

  /// Subtitle for the dialog
  final String? subtitle;

  const RecipeSelectionDialog({
    super.key,
    required this.availableRecipes,
    required this.onRecipeSelected,
    this.currentRecipeId,
    this.showRemoveOption = true,
    this.title = 'Select Recipe',
    this.subtitle,
  });

  @override
  State<RecipeSelectionDialog> createState() => _RecipeSelectionDialogState();
}

class _RecipeSelectionDialogState extends State<RecipeSelectionDialog> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<Recipe> _filteredRecipes = [];
  String _searchQuery = '';
  String _selectedFilter = 'all';

  // Filter options
  final Map<String, String> _filterOptions = {
    'all': 'All Recipes',
    'quick': 'Quick (≤30 min)',
    'vegetarian': 'Vegetarian',
    'favorites': 'Favorites',
  };

  @override
  void initState() {
    super.initState();
    _filteredRecipes = List.from(widget.availableRecipes);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _applyFilters();
    });
  }

  void _applyFilters() {
    List<Recipe> filtered = List.from(widget.availableRecipes);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((recipe) {
        return recipe.title.toLowerCase().contains(query) ||
            recipe.description.toLowerCase().contains(query) ||
            recipe.tags.any((tag) => tag.toLowerCase().contains(query)) ||
            recipe.ingredients.any(
              (ingredient) => ingredient.name.toLowerCase().contains(query),
            );
      }).toList();
    }

    // Apply category filter
    switch (_selectedFilter) {
      case 'quick':
        filtered = filtered.where((recipe) => recipe.totalTime <= 30).toList();
        break;
      case 'vegetarian':
        filtered = filtered
            .where(
              (recipe) => recipe.tags.any(
                (tag) => tag.toLowerCase().contains('vegetarian'),
              ),
            )
            .toList();
        break;
      case 'favorites':
        // For now, treat recipes with tags containing 'favorite' as favorites
        filtered = filtered
            .where(
              (recipe) => recipe.tags.any(
                (tag) => tag.toLowerCase().contains('favorite'),
              ),
            )
            .toList();
        break;
      case 'all':
      default:
        // No additional filtering
        break;
    }

    // Sort by relevance (favorites first, then by name)
    filtered.sort((a, b) {
      final aIsFavorite = a.tags.any(
        (tag) => tag.toLowerCase().contains('favorite'),
      );
      final bIsFavorite = b.tags.any(
        (tag) => tag.toLowerCase().contains('favorite'),
      );

      if (aIsFavorite && !bIsFavorite) return -1;
      if (!aIsFavorite && bIsFavorite) return 1;
      return a.title.compareTo(b.title);
    });

    _filteredRecipes = filtered;
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
      _applyFilters();
    });
  }

  void _onRecipeSelected(Recipe? recipe) {
    Navigator.of(context).pop();
    widget.onRecipeSelected(recipe);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(context),

            const SizedBox(height: 16.0),

            // Search bar
            _buildSearchBar(context),

            const SizedBox(height: 12.0),

            // Filter chips
            _buildFilterChips(context),

            const SizedBox(height: 16.0),

            // Results count
            _buildResultsCount(context),

            const SizedBox(height: 8.0),

            // Recipe list
            Expanded(child: _buildRecipeList(context)),

            const SizedBox(height: 16.0),

            // Action buttons
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.title,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
              tooltip: 'Close',
            ),
          ],
        ),
        if (widget.subtitle != null) ...[
          const SizedBox(height: 4.0),
          Text(
            widget.subtitle!,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TextField(
      controller: _searchController,
      focusNode: _searchFocusNode,
      decoration: InputDecoration(
        hintText: 'Search recipes, ingredients, or tags...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                onPressed: () {
                  _searchController.clear();
                  _searchFocusNode.unfocus();
                },
                icon: const Icon(Icons.clear),
                tooltip: 'Clear search',
              )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
        filled: true,
        fillColor: colorScheme.surfaceContainerLow,
      ),
      textInputAction: TextInputAction.search,
      onSubmitted: (_) => _searchFocusNode.unfocus(),
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _filterOptions.entries.map((entry) {
          final isSelected = _selectedFilter == entry.key;

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              label: Text(entry.value),
              selected: isSelected,
              onSelected: (_) => _onFilterChanged(entry.key),
              backgroundColor: colorScheme.surfaceContainerLow,
              selectedColor: colorScheme.primaryContainer,
              checkmarkColor: colorScheme.onPrimaryContainer,
              labelStyle: TextStyle(
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurface,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildResultsCount(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    final count = _filteredRecipes.length;
    final total = widget.availableRecipes.length;

    return Text(
      count == total ? '$count recipes' : '$count of $total recipes',
      style: textTheme.bodySmall?.copyWith(
        color: colorScheme.onSurface.withValues(alpha: 0.7),
      ),
    );
  }

  Widget _buildRecipeList(BuildContext context) {
    if (_filteredRecipes.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.builder(
      itemCount: _filteredRecipes.length,
      itemBuilder: (context, index) {
        final recipe = _filteredRecipes[index];
        final isSelected = recipe.id == widget.currentRecipeId;

        return _buildRecipeCard(context, recipe, isSelected);
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64.0,
            color: colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16.0),
          Text(
            'No recipes found',
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try adjusting your search or filters'
                : 'No recipes match the selected filters',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeCard(
    BuildContext context,
    Recipe recipe,
    bool isSelected,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      elevation: isSelected ? 4.0 : 1.0,
      color: isSelected ? colorScheme.primaryContainer : colorScheme.surface,
      child: InkWell(
        onTap: () => _onRecipeSelected(recipe),
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Recipe image or placeholder
              _buildRecipeImage(context, recipe),

              const SizedBox(width: 12.0),

              // Recipe details
              Expanded(child: _buildRecipeDetails(context, recipe, isSelected)),

              // Selection indicator
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: colorScheme.primary,
                  size: 24.0,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecipeImage(BuildContext context, Recipe recipe) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: 60.0,
      height: 60.0,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8.0),
        image: recipe.photoUrls.isNotEmpty
            ? DecorationImage(
                image: NetworkImage(recipe.photoUrls.first),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: recipe.photoUrls.isEmpty
          ? Icon(
              Icons.restaurant,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
              size: 24.0,
            )
          : null,
    );
  }

  Widget _buildRecipeDetails(
    BuildContext context,
    Recipe recipe,
    bool isSelected,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final textColor = isSelected
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Recipe title with favorite indicator
        Row(
          children: [
            Expanded(
              child: Text(
                recipe.title,
                style: textTheme.titleSmall?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (recipe.tags.any(
              (tag) => tag.toLowerCase().contains('favorite'),
            ))
              Icon(
                Icons.favorite,
                size: 16.0,
                color: Colors.red.withValues(alpha: 0.7),
              ),
          ],
        ),

        const SizedBox(height: 4.0),

        // Recipe description
        if (recipe.description.isNotEmpty) ...[
          Text(
            recipe.description,
            style: textTheme.bodySmall?.copyWith(
              color: textColor.withValues(alpha: 0.8),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4.0),
        ],

        // Recipe metadata
        Row(
          children: [
            if (recipe.totalTime > 0) ...[
              Icon(
                Icons.access_time,
                size: 14.0,
                color: textColor.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 4.0),
              Text(
                recipe.formattedTime,
                style: textTheme.bodySmall?.copyWith(
                  color: textColor.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(width: 12.0),
            ],

            Icon(
              Icons.people,
              size: 14.0,
              color: textColor.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 4.0),
            Text(
              '${recipe.servings} servings',
              style: textTheme.bodySmall?.copyWith(
                color: textColor.withValues(alpha: 0.7),
              ),
            ),

            if (recipe.tags.isNotEmpty) ...[
              const SizedBox(width: 12.0),
              Expanded(
                child: Text(
                  recipe.tags.take(2).join(', '),
                  style: textTheme.bodySmall?.copyWith(
                    color: textColor.withValues(alpha: 0.6),
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        // Remove recipe button (if enabled)
        if (widget.showRemoveOption && widget.currentRecipeId != null)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _onRecipeSelected(null),
              icon: const Icon(Icons.remove_circle_outline),
              label: const Text('Remove Recipe'),
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.error,
                side: BorderSide(color: colorScheme.error),
              ),
            ),
          ),

        if (widget.showRemoveOption && widget.currentRecipeId != null)
          const SizedBox(width: 12.0),

        // Cancel button
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ),
      ],
    );
  }
}

/// Show the recipe selection dialog
Future<Recipe?> showRecipeSelectionDialog({
  required BuildContext context,
  required List<Recipe> availableRecipes,
  String? currentRecipeId,
  bool showRemoveOption = true,
  String title = 'Select Recipe',
  String? subtitle,
}) async {
  Recipe? selectedRecipe;

  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (context) => RecipeSelectionDialog(
      availableRecipes: availableRecipes,
      currentRecipeId: currentRecipeId,
      showRemoveOption: showRemoveOption,
      title: title,
      subtitle: subtitle,
      onRecipeSelected: (recipe) {
        selectedRecipe = recipe;
      },
    ),
  );

  return selectedRecipe;
}
