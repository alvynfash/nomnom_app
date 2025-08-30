import 'package:flutter/material.dart';
import '../models/meal_plan.dart';
import '../models/meal_slot.dart';
import '../models/recipe.dart';
import '../services/meal_plan_service.dart';
import '../services/recipe_service.dart';
import 'meal_slot_widget.dart';

/// A 4-week calendar widget for meal planning with week navigation and meal slot integration
class MealPlanCalendarWidget extends StatefulWidget {
  /// The meal plan to display
  final MealPlan mealPlan;

  /// The currently selected week (0-3)
  final int currentWeek;

  /// Available meal slots for the family
  final List<MealSlot> mealSlots;

  /// Callback when a meal slot is tapped
  final Function(DateTime date, String slotId) onSlotTap;

  /// Callback when the week is changed
  final Function(int weekNumber) onWeekChanged;

  /// Whether the meal plan can be edited
  final bool isEditable;

  /// Optional custom height for meal slots
  final double? slotHeight;

  /// Whether to show a compact view
  final bool isCompact;

  const MealPlanCalendarWidget({
    super.key,
    required this.mealPlan,
    required this.currentWeek,
    required this.mealSlots,
    required this.onSlotTap,
    required this.onWeekChanged,
    this.isEditable = true,
    this.slotHeight,
    this.isCompact = false,
  });

  @override
  State<MealPlanCalendarWidget> createState() => _MealPlanCalendarWidgetState();
}

class _MealPlanCalendarWidgetState extends State<MealPlanCalendarWidget> {
  final MealPlanService _mealPlanService = MealPlanService();
  final RecipeService _recipeService = RecipeService();

  // Cache for loaded recipes to avoid repeated API calls
  final Map<String, Recipe> _recipeCache = {};

  // Loading state for recipes
  final Set<String> _loadingRecipes = {};

  @override
  void initState() {
    super.initState();
    _loadRecipesForCurrentWeek();
  }

  @override
  void didUpdateWidget(MealPlanCalendarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Reload recipes if the week or meal plan changed
    if (oldWidget.currentWeek != widget.currentWeek ||
        oldWidget.mealPlan.id != widget.mealPlan.id) {
      _loadRecipesForCurrentWeek();
    }
  }

  /// Load recipes for the currently displayed week
  Future<void> _loadRecipesForCurrentWeek() async {
    final weekDates = widget.mealPlan.getWeekDates(widget.currentWeek);
    final recipeIds = <String>{};

    // Collect all recipe IDs for the current week
    for (final date in weekDates) {
      for (final slot in widget.mealSlots) {
        final recipeId = widget.mealPlan.getRecipeForSlot(date, slot.id);
        if (recipeId != null && !_recipeCache.containsKey(recipeId)) {
          recipeIds.add(recipeId);
        }
      }
    }

    // Load recipes that aren't already cached
    for (final recipeId in recipeIds) {
      if (!_loadingRecipes.contains(recipeId)) {
        _loadingRecipes.add(recipeId);
        _loadRecipe(recipeId);
      }
    }
  }

  /// Load a single recipe and cache it
  Future<void> _loadRecipe(String recipeId) async {
    try {
      final recipe = await _recipeService.getRecipeById(recipeId);
      if (recipe != null && mounted) {
        setState(() {
          _recipeCache[recipeId] = recipe;
          _loadingRecipes.remove(recipeId);
        });
      }
    } catch (e) {
      // Handle recipe loading error silently
      if (mounted) {
        setState(() {
          _loadingRecipes.remove(recipeId);
        });
      }
    }
  }

  /// Get the recipe for a specific date and slot
  Recipe? _getRecipeForSlot(DateTime date, String slotId) {
    final recipeId = widget.mealPlan.getRecipeForSlot(date, slotId);
    if (recipeId == null) return null;
    return _recipeCache[recipeId];
  }

  /// Check if a recipe is currently loading
  bool _isRecipeLoading(DateTime date, String slotId) {
    final recipeId = widget.mealPlan.getRecipeForSlot(date, slotId);
    if (recipeId == null) return false;
    return _loadingRecipes.contains(recipeId);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Week navigation header
        _buildWeekNavigationHeader(context),

        const SizedBox(height: 16.0),

        // Calendar grid
        Expanded(child: _buildCalendarGrid(context)),
      ],
    );
  }

  Widget _buildWeekNavigationHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final weekDates = widget.mealPlan.getWeekDates(widget.currentWeek);
    final weekStart = weekDates.first;
    final weekEnd = weekDates.last;

    final weekRange = _mealPlanService.formatDateRange(weekStart, weekEnd);
    final isCurrentWeek = _isCurrentWeek(weekStart);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: isCurrentWeek
            ? colorScheme.secondaryContainer
            : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12.0),
        border: isCurrentWeek
            ? Border.all(color: colorScheme.secondary, width: 2.0)
            : null,
      ),
      child: Row(
        children: [
          // Previous week button
          IconButton(
            onPressed: widget.currentWeek > 0
                ? () => widget.onWeekChanged(widget.currentWeek - 1)
                : null,
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Previous week',
          ),

          // Week information
          Expanded(
            child: Column(
              children: [
                Text(
                  'Week ${widget.currentWeek + 1}',
                  style: textTheme.titleMedium?.copyWith(
                    color: isCurrentWeek
                        ? colorScheme.onSecondaryContainer
                        : colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  weekRange,
                  style: textTheme.bodySmall?.copyWith(
                    color: isCurrentWeek
                        ? colorScheme.onSecondaryContainer.withValues(
                            alpha: 0.8,
                          )
                        : colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                if (isCurrentWeek) ...[
                  const SizedBox(height: 2.0),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 2.0,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.secondary,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Text(
                      'Current Week',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSecondary,
                        fontSize: 10.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Next week button
          IconButton(
            onPressed: widget.currentWeek < 3
                ? () => widget.onWeekChanged(widget.currentWeek + 1)
                : null,
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Next week',
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(BuildContext context) {
    final weekDates = widget.mealPlan.getWeekDates(widget.currentWeek);

    return Column(
      children: [
        // Day headers
        _buildDayHeaders(context, weekDates),

        const SizedBox(height: 8.0),

        // Calendar content
        Expanded(
          child: Row(
            children: weekDates
                .map((date) => Expanded(child: _buildDayColumn(context, date)))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDayHeaders(BuildContext context, List<DateTime> weekDates) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Row(
      children: weekDates.map((date) {
        final isToday = _isToday(date);
        final dayName = _getDayName(date.weekday);
        final dayNumber = date.day;

        return Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            decoration: BoxDecoration(
              color: isToday
                  ? colorScheme.primaryContainer
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Column(
              children: [
                Text(
                  dayName,
                  style: textTheme.bodySmall?.copyWith(
                    color: isToday
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  dayNumber.toString(),
                  style: textTheme.titleMedium?.copyWith(
                    color: isToday
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDayColumn(BuildContext context, DateTime date) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2.0),
      child: Column(
        children: widget.mealSlots.map((slot) {
          final recipe = _getRecipeForSlot(date, slot.id);
          final isLoading = _isRecipeLoading(date, slot.id);

          if (isLoading) {
            return _buildLoadingSlot(context, slot);
          }

          return Expanded(
            child: MealSlotWidget(
              date: date,
              slot: slot,
              assignedRecipe: recipe,
              onTap: () => widget.onSlotTap(date, slot.id),
              isEditable: widget.isEditable,
              height: widget.slotHeight,
              isCompact: true, // Force compact mode in calendar view
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLoadingSlot(BuildContext context, MealSlot slot) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 2.0),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16.0,
                height: 16.0,
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colorScheme.primary.withValues(alpha: 0.7),
                  ),
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                slot.name,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                  fontSize: 10.0,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Check if the given week start date represents the current week
  bool _isCurrentWeek(DateTime weekStart) {
    final now = DateTime.now();
    final weekEnd = weekStart.add(const Duration(days: 6));

    return now.isAfter(weekStart.subtract(const Duration(days: 1))) &&
        now.isBefore(weekEnd.add(const Duration(days: 1)));
  }

  /// Check if the given date is today
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Get the abbreviated day name for a weekday (1 = Monday, 7 = Sunday)
  String _getDayName(int weekday) {
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return dayNames[weekday - 1];
  }
}
