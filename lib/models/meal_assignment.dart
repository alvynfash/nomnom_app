import 'recipe.dart';

class MealAssignment {
  final String mealPlanId;
  final DateTime date;
  final String slotId;
  final String? recipeId;
  final Recipe? recipe; // Populated when loaded with recipe data

  MealAssignment({
    required this.mealPlanId,
    required this.date,
    required this.slotId,
    this.recipeId,
    this.recipe,
  });

  /// Generate the assignment key for this assignment
  String get assignmentKey {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return '${dateStr}_$slotId';
  }

  /// Check if this assignment has a recipe assigned
  bool get hasRecipe => recipeId != null;

  /// Check if this assignment has recipe data loaded
  bool get hasRecipeData => recipe != null;

  /// Serialization methods
  Map<String, dynamic> toMap() {
    return {
      'mealPlanId': mealPlanId,
      'date': date.toIso8601String(),
      'slotId': slotId,
      'recipeId': recipeId,
      'recipe': recipe?.toMap(),
    };
  }

  factory MealAssignment.fromMap(Map<String, dynamic> map) {
    return MealAssignment(
      mealPlanId: map['mealPlanId'],
      date: DateTime.parse(map['date']),
      slotId: map['slotId'],
      recipeId: map['recipeId'],
      recipe: map['recipe'] != null ? Recipe.fromMap(map['recipe']) : null,
    );
  }

  /// Database serialization (without nested recipe data)
  Map<String, dynamic> toDatabaseMap() {
    return {
      'mealPlanId': mealPlanId,
      'assignmentDate': date.toIso8601String(),
      'slotId': slotId,
      'recipeId': recipeId,
    };
  }

  factory MealAssignment.fromDatabaseMap(Map<String, dynamic> map) {
    return MealAssignment(
      mealPlanId: map['mealPlanId'],
      date: DateTime.parse(map['assignmentDate']),
      slotId: map['slotId'],
      recipeId: map['recipeId'],
    );
  }

  /// JSON serialization methods for compatibility
  Map<String, dynamic> toJson() => toMap();
  factory MealAssignment.fromJson(Map<String, dynamic> json) =>
      MealAssignment.fromMap(json);

  /// Create a copy with updated values
  MealAssignment copyWith({
    String? mealPlanId,
    DateTime? date,
    String? slotId,
    String? recipeId,
    Recipe? recipe,
  }) {
    return MealAssignment(
      mealPlanId: mealPlanId ?? this.mealPlanId,
      date: date ?? this.date,
      slotId: slotId ?? this.slotId,
      recipeId: recipeId ?? this.recipeId,
      recipe: recipe ?? this.recipe,
    );
  }

  /// Create a copy with recipe data populated
  MealAssignment withRecipe(Recipe recipe) {
    return copyWith(recipe: recipe);
  }

  /// Create a copy without recipe assignment
  MealAssignment withoutRecipe() {
    return MealAssignment(
      mealPlanId: mealPlanId,
      date: date,
      slotId: slotId,
      recipeId: null,
      recipe: null,
    );
  }

  /// Validation methods
  void validate() {
    if (mealPlanId.trim().isEmpty) {
      throw MealAssignmentException(
        'Meal plan ID cannot be empty',
        'INVALID_MEAL_PLAN_ID',
      );
    }
    if (slotId.trim().isEmpty) {
      throw MealAssignmentException(
        'Slot ID cannot be empty',
        'INVALID_SLOT_ID',
      );
    }

    // Validate that if recipeId is provided, it's not empty
    if (recipeId != null && recipeId!.trim().isEmpty) {
      throw MealAssignmentException(
        'Recipe ID cannot be empty when provided',
        'INVALID_RECIPE_ID',
      );
    }
  }

  /// Returns true if the meal assignment is valid
  bool get isValid {
    try {
      validate();
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MealAssignment &&
        other.mealPlanId == mealPlanId &&
        other.date == date &&
        other.slotId == slotId &&
        other.recipeId == recipeId;
  }

  @override
  int get hashCode =>
      mealPlanId.hashCode ^ date.hashCode ^ slotId.hashCode ^ recipeId.hashCode;

  @override
  String toString() =>
      'MealAssignment(mealPlanId: $mealPlanId, date: $date, slotId: $slotId, recipeId: $recipeId)';
}

/// Exception for meal assignment operations
class MealAssignmentException implements Exception {
  final String message;
  final String code;

  MealAssignmentException(this.message, this.code);

  @override
  String toString() => 'MealAssignmentException: $message (code: $code)';
}
