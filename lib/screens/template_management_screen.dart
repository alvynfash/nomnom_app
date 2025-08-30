import 'package:flutter/material.dart';
import '../models/meal_plan.dart';
import '../models/recipe.dart';
import '../services/meal_plan_service.dart';
import '../services/recipe_service.dart';
import '../utils/fade_page_route.dart';
import 'meal_plan_screen.dart';

/// Screen for managing meal plan templates
class TemplateManagementScreen extends StatefulWidget {
  /// Optional family ID for filtering templates
  final String? familyId;

  const TemplateManagementScreen({super.key, this.familyId});

  @override
  State<TemplateManagementScreen> createState() =>
      _TemplateManagementScreenState();
}

class _TemplateManagementScreenState extends State<TemplateManagementScreen> {
  final MealPlanService _mealPlanService = MealPlanService();
  final RecipeService _recipeService = RecipeService();

  List<MealPlan> _templates = [];
  Map<String, Recipe> _recipeCache = {};
  bool _isLoading = true;
  String _searchQuery = '';
  String _sortBy = 'updated'; // updated, created, name

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  /// Load templates and cache recipes
  Future<void> _loadTemplates() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load templates
      final templates = await _mealPlanService.getTemplates(
        familyId: widget.familyId,
      );

      // Cache recipes used in templates
      final allRecipeIds = <String>{};
      for (final template in templates) {
        allRecipeIds.addAll(template.recipeIds);
      }

      final recipeCache = <String, Recipe>{};
      for (final recipeId in allRecipeIds) {
        try {
          final recipe = await _recipeService.getRecipeById(recipeId);
          if (recipe != null) {
            recipeCache[recipeId] = recipe;
          }
        } catch (e) {
          // Skip recipes that can't be loaded
          continue;
        }
      }

      setState(() {
        _templates = templates;
        _recipeCache = recipeCache;
      });
    } catch (e) {
      _showErrorSnackBar('Failed to load templates: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Get filtered and sorted templates
  List<MealPlan> get _filteredTemplates {
    var filtered = _templates.where((template) {
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return template.templateName?.toLowerCase().contains(query) == true ||
            template.templateDescription?.toLowerCase().contains(query) == true;
      }
      return true;
    }).toList();

    // Sort templates
    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'name':
          return (a.templateName ?? '').compareTo(b.templateName ?? '');
        case 'created':
          return b.createdAt.compareTo(a.createdAt);
        case 'updated':
        default:
          return b.updatedAt.compareTo(a.updatedAt);
      }
    });

    return filtered;
  }

  /// Apply template to create a new meal plan
  Future<void> _applyTemplate(MealPlan template) async {
    final startDate = await _showDatePicker();
    if (startDate == null) return;

    try {
      final newMealPlan = await _mealPlanService.applyTemplate(
        template.id,
        startDate,
      );

      _showSuccessSnackBar('Template applied successfully');

      // Navigate to the new meal plan with fade transition
      if (mounted) {
        FadeNavigation.push(
          context,
          MealPlanScreen(mealPlanId: newMealPlan.id, familyId: widget.familyId),
        );
      }
    } catch (e) {
      _showErrorSnackBar('Failed to apply template: ${e.toString()}');
    }
  }

  /// Show date picker for template application
  Future<DateTime?> _showDatePicker() async {
    final now = DateTime.now();
    final firstDate = now.subtract(const Duration(days: 30));
    final lastDate = now.add(const Duration(days: 365));

    return await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Select start date for meal plan',
    );
  }

  /// Delete template with confirmation
  Future<void> _deleteTemplate(MealPlan template) async {
    final confirmed = await _showDeleteConfirmationDialog(template);
    if (!confirmed) return;

    try {
      await _mealPlanService.deleteTemplate(template.id);

      setState(() {
        _templates.removeWhere((t) => t.id == template.id);
      });

      _showSuccessSnackBar('Template deleted successfully');
    } catch (e) {
      _showErrorSnackBar('Failed to delete template: ${e.toString()}');
    }
  }

  /// Show delete confirmation dialog
  Future<bool> _showDeleteConfirmationDialog(MealPlan template) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Template'),
            content: Text(
              'Are you sure you want to delete "${template.templateName}"? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// Show error snackbar
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  /// Show success snackbar
  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  /// Build app bar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Meal Plan Templates'),
      actions: [
        IconButton(
          onPressed: _loadTemplates,
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh',
        ),
      ],
    );
  }

  /// Build main body
  Widget _buildBody() {
    return Column(
      children: [
        // Search and sort section
        _buildSearchAndSort(),

        // Templates list
        Expanded(
          child: _filteredTemplates.isEmpty
              ? _buildEmptyState()
              : _buildTemplatesList(),
        ),
      ],
    );
  }

  /// Build search and sort section
  Widget _buildSearchAndSort() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
        ),
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Search templates...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                      icon: const Icon(Icons.clear),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              filled: true,
              fillColor: colorScheme.surface,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),

          const SizedBox(height: 12.0),

          // Sort options
          Row(
            children: [
              const Text('Sort by:'),
              const SizedBox(width: 8.0),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildSortChip('updated', 'Recently Updated'),
                      const SizedBox(width: 8.0),
                      _buildSortChip('created', 'Recently Created'),
                      const SizedBox(width: 8.0),
                      _buildSortChip('name', 'Name'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build sort chip
  Widget _buildSortChip(String value, String label) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = _sortBy == value;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _sortBy = value;
        });
      },
      backgroundColor: colorScheme.surfaceContainerLow,
      selectedColor: colorScheme.primaryContainer,
      checkmarkColor: colorScheme.onPrimaryContainer,
      labelStyle: TextStyle(
        color: isSelected
            ? colorScheme.onPrimaryContainer
            : colorScheme.onSurface,
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    String message;
    String subtitle;

    if (_searchQuery.isNotEmpty) {
      message = 'No templates found';
      subtitle = 'Try adjusting your search terms';
    } else {
      message = 'No templates saved';
      subtitle = 'Create a meal plan and save it as a template to get started';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border,
            size: 64.0,
            color: colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16.0),
          Text(
            message,
            style: textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            subtitle,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build templates list
  Widget _buildTemplatesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _filteredTemplates.length,
      itemBuilder: (context, index) {
        final template = _filteredTemplates[index];
        return _buildTemplateCard(template);
      },
    );
  }

  /// Build template card
  Widget _buildTemplateCard(MealPlan template) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final stats = _mealPlanService.getTemplateStats(template);
    final assignedRecipes = template.recipeIds
        .map((id) => _recipeCache[id])
        .where((recipe) => recipe != null)
        .cast<Recipe>()
        .toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () => _showTemplatePreview(template),
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Expanded(
                    child: Text(
                      template.templateName ?? 'Unnamed Template',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  // Template badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.secondary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Text(
                      'Template',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.secondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  // More actions button
                  PopupMenuButton<String>(
                    onSelected: (action) {
                      switch (action) {
                        case 'apply':
                          _applyTemplate(template);
                          break;
                        case 'delete':
                          _deleteTemplate(template);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'apply',
                        child: ListTile(
                          leading: Icon(Icons.play_arrow),
                          title: Text('Apply Template'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete),
                          title: Text('Delete'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              if (template.templateDescription?.isNotEmpty == true) ...[
                const SizedBox(height: 8.0),
                Text(
                  template.templateDescription!,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 12.0),

              // Stats row
              Row(
                children: [
                  _buildStatChip(
                    Icons.restaurant,
                    '${stats['mealSlotsCount']} slots',
                    colorScheme,
                    textTheme,
                  ),
                  const SizedBox(width: 8.0),
                  _buildStatChip(
                    Icons.assignment,
                    '${stats['assignedSlots']} assigned',
                    colorScheme,
                    textTheme,
                  ),
                  const SizedBox(width: 8.0),
                  _buildStatChip(
                    Icons.local_dining,
                    '${stats['uniqueRecipes']} recipes',
                    colorScheme,
                    textTheme,
                  ),
                ],
              ),

              const SizedBox(height: 12.0),

              // Progress bar
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: stats['completionPercentage'] / 100.0,
                      backgroundColor: colorScheme.outline.withValues(
                        alpha: 0.2,
                      ),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    '${stats['completionPercentage']}%',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              if (assignedRecipes.isNotEmpty) ...[
                const SizedBox(height: 12.0),
                Text(
                  'Featured Recipes:',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4.0),
                Wrap(
                  spacing: 4.0,
                  runSpacing: 4.0,
                  children: assignedRecipes
                      .take(3)
                      .map(
                        (recipe) => Chip(
                          label: Text(recipe.title, style: textTheme.bodySmall),
                          backgroundColor: colorScheme.surfaceContainerLow,
                          side: BorderSide.none,
                        ),
                      )
                      .toList(),
                ),
                if (assignedRecipes.length > 3)
                  Text(
                    '+${assignedRecipes.length - 3} more recipes',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],

              const SizedBox(height: 8.0),

              // Apply button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _applyTemplate(template),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Apply Template'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build stat chip
  Widget _buildStatChip(
    IconData icon,
    String label,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14.0,
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 4.0),
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  /// Show template preview dialog
  void _showTemplatePreview(MealPlan template) {
    showDialog(
      context: context,
      builder: (context) => TemplatePreviewDialog(
        template: template,
        recipeCache: _recipeCache,
        onApply: () {
          Navigator.of(context).pop();
          _applyTemplate(template);
        },
      ),
    );
  }
}

/// Dialog for previewing template details
class TemplatePreviewDialog extends StatelessWidget {
  final MealPlan template;
  final Map<String, Recipe> recipeCache;
  final VoidCallback onApply;

  const TemplatePreviewDialog({
    super.key,
    required this.template,
    required this.recipeCache,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final stats = MealPlanService().getTemplateStats(template);
    final assignedRecipes = template.recipeIds
        .map((id) => recipeCache[id])
        .where((recipe) => recipe != null)
        .cast<Recipe>()
        .toList();

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12.0),
                  topRight: Radius.circular(12.0),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      template.templateName ?? 'Unnamed Template',
                      style: textTheme.titleLarge?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (template.templateDescription?.isNotEmpty == true) ...[
                      Text(
                        'Description',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        template.templateDescription!,
                        style: textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16.0),
                    ],

                    // Stats
                    Text(
                      'Template Statistics',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    _buildStatsGrid(stats, colorScheme, textTheme),

                    const SizedBox(height: 16.0),

                    // Recipes
                    if (assignedRecipes.isNotEmpty) ...[
                      Text(
                        'Recipes (${assignedRecipes.length})',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      ...assignedRecipes.map(
                        (recipe) => ListTile(
                          leading: const Icon(Icons.restaurant),
                          title: Text(recipe.title),
                          subtitle: Text(
                            '${recipe.prepTime + recipe.cookTime} min • ${recipe.servings} servings',
                          ),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onApply,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Apply Template'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build stats grid
  Widget _buildStatsGrid(
    Map<String, dynamic> stats,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Total Slots',
                  '${stats['totalSlots']}',
                  textTheme,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Assigned',
                  '${stats['assignedSlots']}',
                  textTheme,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Unique Recipes',
                  '${stats['uniqueRecipes']}',
                  textTheme,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Completion',
                  '${stats['completionPercentage']}%',
                  textTheme,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build stat item
  Widget _buildStatItem(String label, String value, TextTheme textTheme) {
    return Column(
      children: [
        Text(
          value,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        Text(label, style: textTheme.bodySmall),
      ],
    );
  }
}
