import 'meal_plan.dart';

/// Result of recipe deletion validation
class DeletionValidationResult {
  final bool canDelete;
  final List<DeletionWarning> warnings;
  final List<MealPlan> affectedMealPlans;

  DeletionValidationResult({
    required this.canDelete,
    this.warnings = const [],
    this.affectedMealPlans = const [],
  });

  /// Create a result that allows deletion with no warnings
  factory DeletionValidationResult.allowed() {
    return DeletionValidationResult(canDelete: true);
  }

  /// Create a result with warnings but still allows deletion
  factory DeletionValidationResult.withWarnings(
    List<DeletionWarning> warnings,
    List<MealPlan> affectedMealPlans,
  ) {
    return DeletionValidationResult(
      canDelete: true,
      warnings: warnings,
      affectedMealPlans: affectedMealPlans,
    );
  }

  /// Create a result that blocks deletion
  factory DeletionValidationResult.blocked(
    List<DeletionWarning> warnings,
    List<MealPlan> affectedMealPlans,
  ) {
    return DeletionValidationResult(
      canDelete: false,
      warnings: warnings,
      affectedMealPlans: affectedMealPlans,
    );
  }

  /// Check if there are any warnings
  bool get hasWarnings => warnings.isNotEmpty;

  /// Check if there are active meal plan conflicts
  bool get hasActiveMealPlanConflicts {
    return affectedMealPlans.any((plan) => plan.isCurrentlyActive);
  }

  /// Get a summary message for the user
  String get summaryMessage {
    if (!canDelete) {
      return 'Cannot delete recipe due to active meal plan usage';
    }

    if (hasWarnings) {
      final activeCount = affectedMealPlans
          .where((p) => p.isCurrentlyActive)
          .length;
      final totalCount = affectedMealPlans.length;

      if (activeCount > 0) {
        return 'Recipe is used in $activeCount active meal plan${activeCount == 1 ? '' : 's'}';
      } else if (totalCount > 0) {
        return 'Recipe is used in $totalCount meal plan${totalCount == 1 ? '' : 's'}';
      }
    }

    return 'Recipe can be safely deleted';
  }
}

/// Warning about recipe deletion
class DeletionWarning {
  final DeletionWarningType type;
  final String message;
  final String? mealPlanId;
  final String? mealPlanName;

  DeletionWarning({
    required this.type,
    required this.message,
    this.mealPlanId,
    this.mealPlanName,
  });

  /// Create a warning for active meal plan usage
  factory DeletionWarning.activeMealPlan(MealPlan mealPlan) {
    return DeletionWarning(
      type: DeletionWarningType.activeMealPlan,
      message:
          'Recipe is used in active meal plan "${mealPlan.name}" (${mealPlan.dateRange})',
      mealPlanId: mealPlan.id,
      mealPlanName: mealPlan.name,
    );
  }

  /// Create a warning for inactive meal plan usage
  factory DeletionWarning.inactiveMealPlan(MealPlan mealPlan) {
    return DeletionWarning(
      type: DeletionWarningType.inactiveMealPlan,
      message:
          'Recipe is used in meal plan "${mealPlan.name}" (${mealPlan.dateRange})',
      mealPlanId: mealPlan.id,
      mealPlanName: mealPlan.name,
    );
  }

  /// Create a generic warning
  factory DeletionWarning.generic(String message) {
    return DeletionWarning(type: DeletionWarningType.generic, message: message);
  }
}

/// Types of deletion warnings
enum DeletionWarningType { activeMealPlan, inactiveMealPlan, generic }

/// Extension to get user-friendly descriptions
extension DeletionWarningTypeExtension on DeletionWarningType {
  String get description {
    switch (this) {
      case DeletionWarningType.activeMealPlan:
        return 'Active Meal Plan Usage';
      case DeletionWarningType.inactiveMealPlan:
        return 'Meal Plan Usage';
      case DeletionWarningType.generic:
        return 'Warning';
    }
  }

  /// Get the severity level (higher = more severe)
  int get severity {
    switch (this) {
      case DeletionWarningType.activeMealPlan:
        return 3;
      case DeletionWarningType.inactiveMealPlan:
        return 2;
      case DeletionWarningType.generic:
        return 1;
    }
  }
}
