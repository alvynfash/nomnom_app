import 'package:flutter/material.dart';
import '../models/meal_plan.dart';
import '../models/meal_slot.dart';
import '../models/recipe.dart';
import '../services/meal_plan_service.dart';
import '../services/meal_slot_service.dart';
import '../services/recipe_service.dart';
import '../widgets/meal_plan_calendar_widget.dart';
import '../widgets/recipe_selection_dialog.dart';

/// Main screen for meal planning with 4-week calendar integration
class MealPlanScreen extends StatefulWidget {
  /// Optional meal plan ID to load existing plan
  final String? mealPlanId;

  /// Optional family ID for filtering
  final String? familyId;

  const MealPlanScreen({super.key, this.mealPlanId, this.familyId});

  @override
  State<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  final MealPlanService _mealPlanService = MealPlanService();
  final MealSlotService _mealSlotService = MealSlotService();
  final RecipeService _recipeService = RecipeService();

  // State variables
  MealPlan? _currentMealPlan;
  List<MealSlot> _mealSlots = [];
  List<Recipe> _availableRecipes = [];
  int _currentWeek = 0;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _hasUnsavedChanges = false;

  // Controllers
  final TextEditingController _mealPlanNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  @override
  void dispose() {
    _mealPlanNameController.dispose();
    super.dispose();
  }

  /// Initialize the screen by loading data
  Future<void> _initializeScreen() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load meal slots
      _mealSlots = widget.familyId != null
          ? await _mealSlotService.getFamilyMealSlots(widget.familyId!)
          : await _mealSlotService.getDefaultMealSlots();

      // Load available recipes
      _availableRecipes = await _recipeService.getRecipes();

      // Load existing meal plan or create new one
      if (widget.mealPlanId != null) {
        await _loadExistingMealPlan();
      } else {
        await _createNewMealPlan();
      }

      // Determine current week based on today's date
      _currentWeek = _getCurrentWeekNumber();
    } catch (e) {
      _showErrorSnackBar('Failed to load meal planning data: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Load an existing meal plan
  Future<void> _loadExistingMealPlan() async {
    final mealPlan = await _mealPlanService.getMealPlanById(widget.mealPlanId!);
    if (mealPlan != null) {
      setState(() {
        _currentMealPlan = mealPlan;
        _mealPlanNameController.text = mealPlan.name;
        _isEditing = false;
      });
    } else {
      throw Exception('Meal plan not found');
    }
  }

  /// Create a new meal plan
  Future<void> _createNewMealPlan() async {
    final startDate = _getStartOfCurrentWeek();
    final newMealPlan = MealPlan.create(
      name: 'New Meal Plan',
      familyId: widget.familyId ?? '',
      startDate: startDate,
      mealSlots: _mealSlots.map((slot) => slot.id).toList(),
      createdBy: 'current_user', // TODO: Get from auth service
    );

    setState(() {
      _currentMealPlan = newMealPlan;
      _mealPlanNameController.text = newMealPlan.name;
      _isEditing = true;
      _hasUnsavedChanges = true;
    });
  }

  /// Get the start of the current week (Monday)
  DateTime _getStartOfCurrentWeek() {
    final now = DateTime.now();
    final daysFromMonday = now.weekday - 1;
    return DateTime(now.year, now.month, now.day - daysFromMonday);
  }

  /// Determine which week contains today's date
  int _getCurrentWeekNumber() {
    if (_currentMealPlan == null) return 0;

    final now = DateTime.now();
    final weekNumber = _mealPlanService.getCurrentWeekNumber(
      _currentMealPlan!.startDate,
      now,
    );

    return weekNumber ?? 0;
  }

  /// Handle meal slot tap for recipe selection
  Future<void> _onSlotTap(DateTime date, String slotId) async {
    if (_currentMealPlan == null || !_isEditable()) return;

    final currentRecipeId = _currentMealPlan!.getRecipeForSlot(date, slotId);

    final selectedRecipe = await showRecipeSelectionDialog(
      context: context,
      availableRecipes: _availableRecipes,
      currentRecipeId: currentRecipeId,
      title: 'Select Recipe',
      subtitle: _formatSlotSelectionSubtitle(date, slotId),
    );

    if (selectedRecipe != null) {
      await _assignRecipeToSlot(date, slotId, selectedRecipe.id);
    } else if (currentRecipeId != null) {
      // User selected to remove the recipe
      await _removeRecipeFromSlot(date, slotId);
    }
  }

  /// Format subtitle for recipe selection dialog
  String _formatSlotSelectionSubtitle(DateTime date, String slotId) {
    final slotName = _mealSlots
        .firstWhere(
          (slot) => slot.id == slotId,
          orElse: () => MealSlot(id: slotId, name: slotId, order: 0),
        )
        .name;
    final dateStr = '${date.month}/${date.day}';
    return '$slotName on $dateStr';
  }

  /// Assign a recipe to a meal slot
  Future<void> _assignRecipeToSlot(
    DateTime date,
    String slotId,
    String recipeId,
  ) async {
    if (_currentMealPlan == null) return;

    try {
      final assignmentKey = MealPlan.generateAssignmentKey(date, slotId);
      final updatedAssignments = Map<String, String?>.from(
        _currentMealPlan!.assignments,
      );
      updatedAssignments[assignmentKey] = recipeId;

      final updatedMealPlan = _currentMealPlan!.copyWith(
        assignments: updatedAssignments,
        updatedAt: DateTime.now(),
      );

      setState(() {
        _currentMealPlan = updatedMealPlan;
        _hasUnsavedChanges = true;
      });

      // Auto-save if editing existing meal plan
      if (!_isEditing) {
        await _saveMealPlan();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to assign recipe: ${e.toString()}');
    }
  }

  /// Remove a recipe from a meal slot
  Future<void> _removeRecipeFromSlot(DateTime date, String slotId) async {
    if (_currentMealPlan == null) return;

    try {
      final assignmentKey = MealPlan.generateAssignmentKey(date, slotId);
      final updatedAssignments = Map<String, String?>.from(
        _currentMealPlan!.assignments,
      );
      updatedAssignments.remove(assignmentKey);

      final updatedMealPlan = _currentMealPlan!.copyWith(
        assignments: updatedAssignments,
        updatedAt: DateTime.now(),
      );

      setState(() {
        _currentMealPlan = updatedMealPlan;
        _hasUnsavedChanges = true;
      });

      // Auto-save if editing existing meal plan
      if (!_isEditing) {
        await _saveMealPlan();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to remove recipe: ${e.toString()}');
    }
  }

  /// Handle week navigation
  void _onWeekChanged(int weekNumber) {
    setState(() {
      _currentWeek = weekNumber;
    });
  }

  /// Check if the meal plan is editable
  bool _isEditable() {
    // TODO: Add permission checking based on family roles
    return true;
  }

  /// Save the current meal plan
  Future<void> _saveMealPlan() async {
    if (_currentMealPlan == null) return;

    try {
      setState(() {
        _isLoading = true;
      });

      final updatedName = _mealPlanNameController.text.trim();
      if (updatedName.isEmpty) {
        _showErrorSnackBar('Meal plan name cannot be empty');
        return;
      }

      final mealPlanToSave = _currentMealPlan!.copyWith(
        name: updatedName,
        updatedAt: DateTime.now(),
      );

      MealPlan savedMealPlan;
      if (_isEditing) {
        // Create new meal plan
        savedMealPlan = await _mealPlanService.createMealPlan(mealPlanToSave);
      } else {
        // Update existing meal plan
        savedMealPlan = await _mealPlanService.updateMealPlan(
          _currentMealPlan!.id,
          mealPlanToSave,
        );
      }

      setState(() {
        _currentMealPlan = savedMealPlan;
        _isEditing = false;
        _hasUnsavedChanges = false;
      });

      _showSuccessSnackBar('Meal plan saved successfully');
    } catch (e) {
      _showErrorSnackBar('Failed to save meal plan: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Delete the current meal plan
  Future<void> _deleteMealPlan() async {
    if (_currentMealPlan == null || _isEditing) return;

    final confirmed = await _showDeleteConfirmationDialog();
    if (!confirmed) return;

    try {
      setState(() {
        _isLoading = true;
      });

      await _mealPlanService.deleteMealPlan(_currentMealPlan!.id);

      if (mounted) {
        Navigator.of(context).pop(); // Return to previous screen
      }
    } catch (e) {
      _showErrorSnackBar('Failed to delete meal plan: ${e.toString()}');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Show delete confirmation dialog
  Future<bool> _showDeleteConfirmationDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Meal Plan'),
            content: Text(
              'Are you sure you want to delete "${_currentMealPlan?.name}"? This action cannot be undone.',
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

  /// Handle back navigation with unsaved changes check
  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Unsaved Changes'),
            content: const Text(
              'You have unsaved changes. Do you want to save before leaving?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Discard'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop(false);
                  await _saveMealPlan();
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('Save'),
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
    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final shouldPop = await _onWillPop();
          if (shouldPop && mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        appBar: _buildAppBar(),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _currentMealPlan == null
            ? _buildErrorState()
            : _buildMealPlanContent(),
        floatingActionButton: _buildFloatingActionButton(),
      ),
    );
  }

  /// Build the app bar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: _isEditing
          ? TextField(
              controller: _mealPlanNameController,
              decoration: const InputDecoration(
                hintText: 'Meal Plan Name',
                border: InputBorder.none,
              ),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
              onChanged: (_) {
                setState(() {
                  _hasUnsavedChanges = true;
                });
              },
            )
          : Text(_currentMealPlan?.name ?? 'Meal Plan'),
      actions: _buildAppBarActions(),
    );
  }

  /// Build app bar actions
  List<Widget> _buildAppBarActions() {
    final actions = <Widget>[];

    if (_currentMealPlan != null && !_isEditing) {
      // Edit button for existing meal plans
      actions.add(
        IconButton(
          onPressed: () {
            setState(() {
              _isEditing = true;
              _hasUnsavedChanges = true;
            });
          },
          icon: const Icon(Icons.edit),
          tooltip: 'Edit meal plan',
        ),
      );

      // Delete button for existing meal plans
      actions.add(
        IconButton(
          onPressed: _deleteMealPlan,
          icon: const Icon(Icons.delete),
          tooltip: 'Delete meal plan',
        ),
      );
    }

    // Save button when editing
    if (_hasUnsavedChanges) {
      actions.add(
        IconButton(
          onPressed: _saveMealPlan,
          icon: const Icon(Icons.save),
          tooltip: 'Save meal plan',
        ),
      );
    }

    return actions;
  }

  /// Build floating action button
  Widget? _buildFloatingActionButton() {
    if (!_hasUnsavedChanges || _isLoading) return null;

    return FloatingActionButton(
      onPressed: _saveMealPlan,
      tooltip: 'Save meal plan',
      child: const Icon(Icons.save),
    );
  }

  /// Build error state
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64.0,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16.0),
          Text(
            'Failed to load meal plan',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8.0),
          Text(
            'Please try again or create a new meal plan',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24.0),
          ElevatedButton(
            onPressed: _initializeScreen,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  /// Build the main meal plan content
  Widget _buildMealPlanContent() {
    return Column(
      children: [
        // Meal plan info header
        _buildMealPlanHeader(),

        // Calendar widget
        Expanded(
          child: MealPlanCalendarWidget(
            mealPlan: _currentMealPlan!,
            currentWeek: _currentWeek,
            mealSlots: _mealSlots,
            onSlotTap: _onSlotTap,
            onWeekChanged: _onWeekChanged,
            isEditable: _isEditable(),
          ),
        ),
      ],
    );
  }

  /// Build meal plan header with info
  Widget _buildMealPlanHeader() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date range
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 16.0,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 8.0),
              Text(
                _currentMealPlan!.dateRange,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const Spacer(),
              if (_hasUnsavedChanges)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    'Unsaved changes',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 8.0),

          // Meal plan stats
          Row(
            children: [
              _buildStatChip(
                icon: Icons.restaurant,
                label: '${_mealSlots.length} meal slots',
                colorScheme: colorScheme,
                textTheme: textTheme,
              ),
              const SizedBox(width: 12.0),
              _buildStatChip(
                icon: Icons.assignment,
                label: '${_currentMealPlan!.assignments.length} assignments',
                colorScheme: colorScheme,
                textTheme: textTheme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build a stat chip
  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
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
}
