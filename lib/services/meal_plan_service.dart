import '../models/meal_plan.dart';
import '../models/meal_assignment.dart';
import 'storage_service.dart';

class MealPlanService {
  final StorageService _storageService = StorageService();

  // In-memory storage for backward compatibility (will be removed later)
  static final List<MealPlan> _mealPlans = [];

  /// Get all meal plans that contain a specific recipe
  Future<List<MealPlan>> getMealPlansContainingRecipe(String recipeId) async {
    try {
      return _mealPlans.where((plan) => plan.containsRecipe(recipeId)).toList();
    } catch (e) {
      throw MealPlanException(
        'Failed to get meal plans for recipe $recipeId: ${e.toString()}',
        'GET_MEAL_PLANS_ERROR',
      );
    }
  }

  /// Get active meal plans that contain a specific recipe
  Future<List<MealPlan>> getActiveMealPlansContainingRecipe(
    String recipeId,
  ) async {
    try {
      final allPlans = await getMealPlansContainingRecipe(recipeId);
      return allPlans.where((plan) => plan.isCurrentlyActive).toList();
    } catch (e) {
      throw MealPlanException(
        'Failed to get active meal plans for recipe $recipeId: ${e.toString()}',
        'GET_ACTIVE_MEAL_PLANS_ERROR',
      );
    }
  }

  /// Remove a recipe from all meal plans
  Future<void> removeRecipeFromAllMealPlans(String recipeId) async {
    try {
      final affectedPlans = await getMealPlansContainingRecipe(recipeId);

      for (final plan in affectedPlans) {
        // In a real implementation, this would update the database
        // For now, we'll just update the in-memory list
        final index = _mealPlans.indexWhere((p) => p.id == plan.id);
        if (index != -1) {
          // Create updated assignments without the removed recipe
          final updatedAssignments = <String, String?>{};
          for (final entry in plan.assignments.entries) {
            if (entry.value != recipeId) {
              updatedAssignments[entry.key] = entry.value;
            }
          }

          _mealPlans[index] = plan.copyWith(
            assignments: updatedAssignments,
            updatedAt: DateTime.now(),
          );
        }
      }
    } catch (e) {
      throw MealPlanException(
        'Failed to remove recipe $recipeId from meal plans: ${e.toString()}',
        'REMOVE_RECIPE_ERROR',
      );
    }
  }

  /// Add a test meal plan (for testing deletion validation)
  Future<void> addTestMealPlan(MealPlan mealPlan) async {
    _mealPlans.add(mealPlan);
  }

  /// Clear all meal plans (for testing)
  Future<void> clearAllMealPlans() async {
    _mealPlans.clear();
  }

  /// Get all meal plans (for testing)
  Future<List<MealPlan>> getAllMealPlans() async {
    return List.from(_mealPlans);
  }

  // CRUD operations

  /// Get all meal plans, optionally filtered by family ID
  Future<List<MealPlan>> getMealPlans({String? familyId}) async {
    try {
      final mealPlanMaps = await _storageService.loadMealPlans(
        familyId: familyId,
      );
      return mealPlanMaps.map((map) => MealPlan.fromMap(map)).toList();
    } catch (e) {
      throw MealPlanException(
        'Failed to get meal plans: ${e.toString()}',
        'GET_MEAL_PLANS_ERROR',
      );
    }
  }

  /// Create a new meal plan
  Future<MealPlan> createMealPlan(MealPlan mealPlan) async {
    try {
      // Validate the meal plan
      mealPlan.validate();

      // Convert assignments to the format expected by storage
      final assignments = <Map<String, dynamic>>[];
      for (final entry in mealPlan.assignments.entries) {
        if (entry.value != null) {
          final parts = entry.key.split('_');
          if (parts.length == 2) {
            assignments.add({
              'mealPlanId': mealPlan.id,
              'assignmentDate': parts[0],
              'slotId': parts[1],
              'recipeId': entry.value,
            });
          }
        }
      }

      // Save to storage
      await _storageService.saveMealPlan(mealPlan.toMap(), assignments);

      return mealPlan;
    } catch (e) {
      if (e is MealPlanException) {
        rethrow;
      }
      throw MealPlanException(
        'Failed to create meal plan: ${e.toString()}',
        'CREATE_MEAL_PLAN_ERROR',
      );
    }
  }

  /// Update an existing meal plan
  Future<MealPlan> updateMealPlan(String id, MealPlan updatedMealPlan) async {
    try {
      // Validate the updated meal plan
      updatedMealPlan.validate();

      // Ensure the ID matches
      final mealPlanToUpdate = updatedMealPlan.copyWith(
        id: id,
        updatedAt: DateTime.now(),
      );

      // Convert assignments to the format expected by storage
      final assignments = <Map<String, dynamic>>[];
      for (final entry in mealPlanToUpdate.assignments.entries) {
        if (entry.value != null) {
          final parts = entry.key.split('_');
          if (parts.length == 2) {
            assignments.add({
              'mealPlanId': id,
              'assignmentDate': parts[0],
              'slotId': parts[1],
              'recipeId': entry.value,
            });
          }
        }
      }

      // Save to storage
      await _storageService.saveMealPlan(mealPlanToUpdate.toMap(), assignments);

      return mealPlanToUpdate;
    } catch (e) {
      if (e is MealPlanException) {
        rethrow;
      }
      throw MealPlanException(
        'Failed to update meal plan: ${e.toString()}',
        'UPDATE_MEAL_PLAN_ERROR',
      );
    }
  }

  /// Delete a meal plan
  Future<void> deleteMealPlan(String id) async {
    try {
      await _storageService.deleteMealPlan(id);
    } catch (e) {
      throw MealPlanException(
        'Failed to delete meal plan: ${e.toString()}',
        'DELETE_MEAL_PLAN_ERROR',
      );
    }
  }

  /// Get a meal plan by ID
  Future<MealPlan?> getMealPlanById(String id) async {
    try {
      final mealPlanMap = await _storageService.getMealPlanById(id);
      if (mealPlanMap == null) return null;

      return MealPlan.fromMap(mealPlanMap);
    } catch (e) {
      throw MealPlanException(
        'Failed to get meal plan by ID: ${e.toString()}',
        'GET_MEAL_PLAN_BY_ID_ERROR',
      );
    }
  }

  // Assignment operations

  /// Assign a recipe to a specific meal slot
  Future<void> assignRecipeToSlot(
    String planId,
    DateTime date,
    String slotId,
    String recipeId,
  ) async {
    try {
      // Get the existing meal plan
      final mealPlan = await getMealPlanById(planId);
      if (mealPlan == null) {
        throw MealPlanException('Meal plan not found', 'MEAL_PLAN_NOT_FOUND');
      }

      // Create updated assignments
      final updatedAssignments = Map<String, String?>.from(
        mealPlan.assignments,
      );
      final assignmentKey = MealPlan.generateAssignmentKey(date, slotId);
      updatedAssignments[assignmentKey] = recipeId;

      // Update the meal plan
      final updatedPlan = mealPlan.copyWith(
        assignments: updatedAssignments,
        updatedAt: DateTime.now(),
      );

      await updateMealPlan(planId, updatedPlan);
    } catch (e) {
      if (e is MealPlanException) {
        rethrow;
      }
      throw MealPlanException(
        'Failed to assign recipe to slot: ${e.toString()}',
        'ASSIGN_RECIPE_ERROR',
      );
    }
  }

  /// Remove a recipe from a specific meal slot
  Future<void> removeRecipeFromSlot(
    String planId,
    DateTime date,
    String slotId,
  ) async {
    try {
      // Get the existing meal plan
      final mealPlan = await getMealPlanById(planId);
      if (mealPlan == null) {
        throw MealPlanException('Meal plan not found', 'MEAL_PLAN_NOT_FOUND');
      }

      // Create updated assignments
      final updatedAssignments = Map<String, String?>.from(
        mealPlan.assignments,
      );
      final assignmentKey = MealPlan.generateAssignmentKey(date, slotId);
      updatedAssignments.remove(assignmentKey);

      // Update the meal plan
      final updatedPlan = mealPlan.copyWith(
        assignments: updatedAssignments,
        updatedAt: DateTime.now(),
      );

      await updateMealPlan(planId, updatedPlan);
    } catch (e) {
      if (e is MealPlanException) {
        rethrow;
      }
      throw MealPlanException(
        'Failed to remove recipe from slot: ${e.toString()}',
        'REMOVE_RECIPE_ERROR',
      );
    }
  }

  /// Get meal assignments for a meal plan with recipe data populated
  Future<List<MealAssignment>> getMealAssignments(String planId) async {
    try {
      // Get the meal plan
      final mealPlan = await getMealPlanById(planId);
      if (mealPlan == null) {
        return [];
      }

      final assignments = <MealAssignment>[];

      // Convert assignments map to MealAssignment objects
      for (final entry in mealPlan.assignments.entries) {
        final parts = entry.key.split('_');
        if (parts.length == 2 && entry.value != null) {
          try {
            final date = DateTime.parse(parts[0]);
            final assignment = MealAssignment(
              mealPlanId: planId,
              date: date,
              slotId: parts[1],
              recipeId: entry.value,
            );
            assignments.add(assignment);
          } catch (e) {
            // Skip invalid date formats
            continue;
          }
        }
      }

      return assignments;
    } catch (e) {
      throw MealPlanException(
        'Failed to get meal assignments: ${e.toString()}',
        'GET_ASSIGNMENTS_ERROR',
      );
    }
  }

  /// Get meal assignments with recipe data populated
  Future<List<MealAssignment>> getMealAssignmentsWithRecipes(
    String planId,
  ) async {
    try {
      final assignments = await getMealAssignments(planId);

      // TODO: This would require RecipeService integration
      // For now, return assignments without recipe data
      // In a full implementation, we would:
      // 1. Get unique recipe IDs from assignments
      // 2. Fetch recipes using RecipeService
      // 3. Populate recipe data in assignments

      return assignments;
    } catch (e) {
      throw MealPlanException(
        'Failed to get meal assignments with recipes: ${e.toString()}',
        'GET_ASSIGNMENTS_WITH_RECIPES_ERROR',
      );
    }
  }

  /// Generate assignment key for a specific date and meal slot
  String generateAssignmentKey(DateTime date, String slotId) {
    return MealPlan.generateAssignmentKey(date, slotId);
  }

  // Calendar utilities

  /// Generate dates for a specific week (0-3) of a meal plan
  List<DateTime> generateWeekDates(DateTime startDate, int weekNumber) {
    if (weekNumber < 0 || weekNumber > 3) {
      throw ArgumentError('Week number must be between 0 and 3');
    }

    final weekStart = startDate.add(Duration(days: weekNumber * 7));
    final dates = <DateTime>[];
    for (int i = 0; i < 7; i++) {
      dates.add(weekStart.add(Duration(days: i)));
    }
    return dates;
  }

  /// Generate all dates for a 4-week meal plan
  List<DateTime> generateFourWeekDates(DateTime startDate) {
    final dates = <DateTime>[];
    for (int i = 0; i < 28; i++) {
      dates.add(startDate.add(Duration(days: i)));
    }
    return dates;
  }

  /// Get the current week number (0-3) for a given date within a meal plan
  int? getCurrentWeekNumber(DateTime startDate, DateTime currentDate) {
    final daysDifference = currentDate.difference(startDate).inDays;

    if (daysDifference < 0 || daysDifference >= 28) {
      return null; // Date is outside the 4-week period
    }

    return daysDifference ~/ 7;
  }

  /// Check if a date falls within a meal plan's 4-week period
  bool isDateInMealPlan(DateTime startDate, DateTime date) {
    final daysDifference = date.difference(startDate).inDays;
    return daysDifference >= 0 && daysDifference < 28;
  }

  /// Get the start date of a specific week within a meal plan
  DateTime getWeekStartDate(DateTime mealPlanStartDate, int weekNumber) {
    if (weekNumber < 0 || weekNumber > 3) {
      throw ArgumentError('Week number must be between 0 and 3');
    }

    return mealPlanStartDate.add(Duration(days: weekNumber * 7));
  }

  /// Format a date range for display
  String formatDateRange(DateTime startDate, DateTime endDate) {
    final start = '${startDate.month}/${startDate.day}';
    final end = '${endDate.month}/${endDate.day}';

    if (startDate.year != endDate.year) {
      return '${startDate.month}/${startDate.day}/${startDate.year} - ${endDate.month}/${endDate.day}/${endDate.year}';
    }

    return '$start - $end';
  }

  /// Get a formatted string for a specific week within a meal plan
  String formatWeekRange(DateTime startDate, int weekNumber) {
    final weekDates = generateWeekDates(startDate, weekNumber);
    return formatDateRange(weekDates.first, weekDates.last);
  }

  /// Check if a meal plan is currently active (current date falls within the 4-week period)
  bool isMealPlanActive(DateTime startDate) {
    final now = DateTime.now();
    return isDateInMealPlan(startDate, now);
  }

  /// Get the number of days remaining in a meal plan
  int getDaysRemainingInMealPlan(DateTime startDate) {
    final now = DateTime.now();
    final endDate = startDate.add(const Duration(days: 27)); // 4 weeks - 1 day

    if (now.isAfter(endDate)) {
      return 0; // Meal plan has ended
    }

    if (now.isBefore(startDate)) {
      return endDate.difference(startDate).inDays +
          1; // Full meal plan duration
    }

    return endDate.difference(now).inDays + 1;
  }

  // Template operations

  /// Save a meal plan as a reusable template
  Future<MealPlan> saveAsTemplate(
    String planId,
    String templateName,
    String? description,
  ) async {
    try {
      // Get the existing meal plan
      final mealPlan = await getMealPlanById(planId);
      if (mealPlan == null) {
        throw MealPlanException('Meal plan not found', 'MEAL_PLAN_NOT_FOUND');
      }

      // Validate template name
      if (templateName.trim().isEmpty) {
        throw MealPlanException(
          'Template name cannot be empty',
          'INVALID_TEMPLATE_NAME',
        );
      }

      if (templateName.length > 50) {
        throw MealPlanException(
          'Template name cannot exceed 50 characters',
          'INVALID_TEMPLATE_NAME',
        );
      }

      // Check for duplicate template names within the family
      final existingTemplates = await getTemplates(familyId: mealPlan.familyId);
      final duplicateName = existingTemplates.any(
        (template) =>
            template.templateName?.toLowerCase() == templateName.toLowerCase(),
      );

      if (duplicateName) {
        throw MealPlanException(
          'A template with this name already exists',
          'DUPLICATE_TEMPLATE_NAME',
        );
      }

      // Create template from meal plan
      // Templates don't have specific start dates - they use a reference date
      final currentYear = DateTime.now().year;
      final referenceDate = DateTime(
        currentYear,
        1,
        1,
      ); // Monday reference date for current year

      // Convert assignments to use relative dates (days 0-27 from reference)
      final templateAssignments = <String, String?>{};
      for (final entry in mealPlan.assignments.entries) {
        if (entry.value != null) {
          final parts = entry.key.split('_');
          if (parts.length == 2) {
            try {
              final originalDate = DateTime.parse(parts[0]);
              final dayOffset = originalDate
                  .difference(mealPlan.startDate)
                  .inDays;

              // Only include assignments within the 4-week period
              if (dayOffset >= 0 && dayOffset < 28) {
                final templateDate = referenceDate.add(
                  Duration(days: dayOffset),
                );
                final templateKey = generateAssignmentKey(
                  templateDate,
                  parts[1],
                );
                templateAssignments[templateKey] = entry.value;
              }
            } catch (e) {
              // Skip invalid date formats
              continue;
            }
          }
        }
      }

      // Create the template
      final template = MealPlan.create(
        name: templateName,
        familyId: mealPlan.familyId,
        startDate: referenceDate,
        mealSlots: List.from(mealPlan.mealSlots),
        assignments: templateAssignments,
        isTemplate: true,
        templateName: templateName,
        templateDescription: description?.trim().isEmpty == true
            ? null
            : description?.trim(),
        createdBy: mealPlan.createdBy,
      );

      // Validate the template
      template.validate();

      // Save the template
      await createMealPlan(template);

      return template;
    } catch (e) {
      if (e is MealPlanException) {
        rethrow;
      }
      throw MealPlanException(
        'Failed to save meal plan as template: ${e.toString()}',
        'SAVE_TEMPLATE_ERROR',
      );
    }
  }

  /// Get all templates, optionally filtered by family ID
  Future<List<MealPlan>> getTemplates({String? familyId}) async {
    try {
      final allMealPlans = await getMealPlans(familyId: familyId);
      return allMealPlans.where((plan) => plan.isTemplate).toList();
    } catch (e) {
      throw MealPlanException(
        'Failed to get templates: ${e.toString()}',
        'GET_TEMPLATES_ERROR',
      );
    }
  }

  /// Apply a template to create a new meal plan for a specific start date
  Future<MealPlan> applyTemplate(String templateId, DateTime startDate) async {
    try {
      // Get the template
      final template = await getMealPlanById(templateId);
      if (template == null) {
        throw MealPlanException('Template not found', 'TEMPLATE_NOT_FOUND');
      }

      if (!template.isTemplate) {
        throw MealPlanException(
          'The specified meal plan is not a template',
          'NOT_A_TEMPLATE',
        );
      }

      // Validate start date
      final oneYearAgo = DateTime.now().subtract(const Duration(days: 365));
      if (startDate.isBefore(oneYearAgo)) {
        throw MealPlanException(
          'Start date cannot be more than 1 year in the past',
          'INVALID_START_DATE',
        );
      }

      // Convert template assignments to the new start date
      final newAssignments = <String, String?>{};
      for (final entry in template.assignments.entries) {
        if (entry.value != null) {
          final parts = entry.key.split('_');
          if (parts.length == 2) {
            try {
              final templateDate = DateTime.parse(parts[0]);
              final dayOffset = templateDate
                  .difference(template.startDate)
                  .inDays;

              // Map to new date
              final newDate = startDate.add(Duration(days: dayOffset));
              final newKey = generateAssignmentKey(newDate, parts[1]);
              newAssignments[newKey] = entry.value;
            } catch (e) {
              // Skip invalid date formats
              continue;
            }
          }
        }
      }

      // Create new meal plan from template
      final newMealPlan = MealPlan.create(
        name: 'Meal Plan from ${template.templateName}',
        familyId: template.familyId,
        startDate: startDate,
        mealSlots: List.from(template.mealSlots),
        assignments: newAssignments,
        isTemplate: false,
        createdBy: template.createdBy,
      );

      // Validate and save the new meal plan
      newMealPlan.validate();
      await createMealPlan(newMealPlan);

      return newMealPlan;
    } catch (e) {
      if (e is MealPlanException) {
        rethrow;
      }
      throw MealPlanException(
        'Failed to apply template: ${e.toString()}',
        'APPLY_TEMPLATE_ERROR',
      );
    }
  }

  /// Delete a template
  Future<void> deleteTemplate(String templateId) async {
    try {
      // Verify it's actually a template before deleting
      final template = await getMealPlanById(templateId);
      if (template == null) {
        throw MealPlanException('Template not found', 'TEMPLATE_NOT_FOUND');
      }

      if (!template.isTemplate) {
        throw MealPlanException(
          'The specified meal plan is not a template',
          'NOT_A_TEMPLATE',
        );
      }

      await deleteMealPlan(templateId);
    } catch (e) {
      if (e is MealPlanException) {
        rethrow;
      }
      throw MealPlanException(
        'Failed to delete template: ${e.toString()}',
        'DELETE_TEMPLATE_ERROR',
      );
    }
  }

  /// Check if a template name is available within a family
  Future<bool> isTemplateNameAvailable(
    String templateName,
    String familyId,
  ) async {
    try {
      final existingTemplates = await getTemplates(familyId: familyId);
      return !existingTemplates.any(
        (template) =>
            template.templateName?.toLowerCase() == templateName.toLowerCase(),
      );
    } catch (e) {
      throw MealPlanException(
        'Failed to check template name availability: ${e.toString()}',
        'CHECK_TEMPLATE_NAME_ERROR',
      );
    }
  }

  /// Get template statistics (number of recipes, meal slots, etc.)
  Map<String, dynamic> getTemplateStats(MealPlan template) {
    if (!template.isTemplate) {
      throw MealPlanException(
        'The specified meal plan is not a template',
        'NOT_A_TEMPLATE',
      );
    }

    final assignedSlots = template.assignments.values
        .where((recipeId) => recipeId != null)
        .length;

    final totalSlots = template.mealSlots.length * 28; // 4 weeks
    final uniqueRecipes = template.recipeIds.length;

    return {
      'totalSlots': totalSlots,
      'assignedSlots': assignedSlots,
      'emptySlots': totalSlots - assignedSlots,
      'uniqueRecipes': uniqueRecipes,
      'completionPercentage': totalSlots > 0
          ? (assignedSlots / totalSlots * 100).round()
          : 0,
      'mealSlotsCount': template.mealSlots.length,
    };
  }
}
