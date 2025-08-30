class MealPlan {
  final String id;
  final String name;
  final String familyId;
  final DateTime startDate; // First day of the 4-week plan
  final List<String> mealSlots; // Configurable meal types
  final Map<String, String?> assignments; // Date-slot key to recipe ID
  final bool isTemplate;
  final String? templateName;
  final String? templateDescription;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  MealPlan({
    required this.id,
    required this.name,
    required this.familyId,
    required this.startDate,
    required this.mealSlots,
    required this.assignments,
    this.isTemplate = false,
    this.templateName,
    this.templateDescription,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  /// Create a new meal plan with generated ID
  MealPlan.create({
    required this.name,
    required this.familyId,
    required this.startDate,
    required this.mealSlots,
    this.assignments = const {},
    this.isTemplate = false,
    this.templateName,
    this.templateDescription,
    required this.createdBy,
  }) : id = _generateUniqueId(),
       createdAt = DateTime.now(),
       updatedAt = DateTime.now();

  static int _idCounter = 0;

  static String _generateUniqueId() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch;
    final counter = _idCounter++;
    return 'mp_${timestamp}_$counter';
  }

  /// Check if this meal plan contains a specific recipe
  bool containsRecipe(String recipeId) {
    return assignments.values.contains(recipeId);
  }

  /// Get all unique recipe IDs used in this meal plan
  List<String> get recipeIds {
    return assignments.values
        .where((recipeId) => recipeId != null)
        .cast<String>()
        .toSet()
        .toList();
  }

  /// Check if this meal plan is currently active (within the 4-week period)
  bool get isCurrentlyActive {
    final now = DateTime.now();
    final endDate = startDate.add(const Duration(days: 28)); // 4 weeks
    return now.isAfter(startDate.subtract(const Duration(days: 1))) &&
        now.isBefore(endDate.add(const Duration(days: 1)));
  }

  /// Get the end date of the 4-week meal plan
  DateTime get endDate =>
      startDate.add(const Duration(days: 27)); // 4 weeks - 1 day

  /// Get a display-friendly date range
  String get dateRange {
    final start = '${startDate.month}/${startDate.day}';
    final end = '${endDate.month}/${endDate.day}';
    return '$start - $end';
  }

  /// Generate assignment key for a specific date and meal slot
  static String generateAssignmentKey(DateTime date, String slotId) {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return '${dateStr}_$slotId';
  }

  /// Get recipe ID for a specific date and meal slot
  String? getRecipeForSlot(DateTime date, String slotId) {
    final key = generateAssignmentKey(date, slotId);
    return assignments[key];
  }

  /// Get all dates in the 4-week meal plan
  List<DateTime> get allDates {
    final dates = <DateTime>[];
    for (int i = 0; i < 28; i++) {
      dates.add(startDate.add(Duration(days: i)));
    }
    return dates;
  }

  /// Get dates for a specific week (0-3)
  List<DateTime> getWeekDates(int weekNumber) {
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

  /// Serialization methods
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'familyId': familyId,
      'startDate': startDate.toIso8601String(),
      'mealSlots': mealSlots,
      'assignments': assignments,
      'isTemplate': isTemplate,
      'templateName': templateName,
      'templateDescription': templateDescription,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'createdBy': createdBy,
    };
  }

  factory MealPlan.fromMap(Map<String, dynamic> map) {
    return MealPlan(
      id: map['id'],
      name: map['name'],
      familyId: map['familyId'],
      startDate: DateTime.parse(map['startDate']),
      mealSlots: List<String>.from(map['mealSlots']),
      assignments: Map<String, String?>.from(map['assignments']),
      isTemplate: map['isTemplate'] ?? false,
      templateName: map['templateName'],
      templateDescription: map['templateDescription'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      createdBy: map['createdBy'],
    );
  }

  /// JSON serialization methods for compatibility
  Map<String, dynamic> toJson() => toMap();
  factory MealPlan.fromJson(Map<String, dynamic> json) =>
      MealPlan.fromMap(json);

  /// Create a copy with updated values
  MealPlan copyWith({
    String? id,
    String? name,
    String? familyId,
    DateTime? startDate,
    List<String>? mealSlots,
    Map<String, String?>? assignments,
    bool? isTemplate,
    String? templateName,
    String? templateDescription,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return MealPlan(
      id: id ?? this.id,
      name: name ?? this.name,
      familyId: familyId ?? this.familyId,
      startDate: startDate ?? this.startDate,
      mealSlots: mealSlots ?? this.mealSlots,
      assignments: assignments ?? this.assignments,
      isTemplate: isTemplate ?? this.isTemplate,
      templateName: templateName ?? this.templateName,
      templateDescription: templateDescription ?? this.templateDescription,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  /// Validation methods
  void validate() {
    validateName();
    validateStartDate();
    validateMealSlots();
    validateAssignments();
    if (isTemplate) {
      validateTemplate();
    }
  }

  void validateName() {
    if (name.trim().isEmpty) {
      throw MealPlanException('Meal plan name cannot be empty', 'INVALID_NAME');
    }
    if (name.length > 50) {
      throw MealPlanException(
        'Meal plan name cannot exceed 50 characters',
        'INVALID_NAME',
      );
    }
  }

  void validateStartDate() {
    final oneYearAgo = DateTime.now().subtract(const Duration(days: 365));
    if (startDate.isBefore(oneYearAgo)) {
      throw MealPlanException(
        'Start date cannot be more than 1 year in the past',
        'INVALID_DATE',
      );
    }
  }

  void validateMealSlots() {
    if (mealSlots.isEmpty) {
      throw MealPlanException(
        'At least one meal slot is required',
        'INVALID_SLOTS',
      );
    }
    if (mealSlots.length > 8) {
      throw MealPlanException(
        'Cannot have more than 8 meal slots',
        'INVALID_SLOTS',
      );
    }

    for (final slot in mealSlots) {
      if (slot.trim().isEmpty) {
        throw MealPlanException(
          'Meal slot names cannot be empty',
          'INVALID_SLOTS',
        );
      }
    }
  }

  void validateAssignments() {
    for (final key in assignments.keys) {
      if (!key.contains('_')) {
        throw MealPlanException(
          'Invalid assignment key format: $key',
          'INVALID_ASSIGNMENT',
        );
      }
    }
  }

  void validateTemplate() {
    if (templateName == null || templateName!.trim().isEmpty) {
      throw MealPlanException(
        'Template name is required for templates',
        'INVALID_TEMPLATE',
      );
    }
  }

  /// Get validation errors as a map
  Map<String, String> getValidationErrors() {
    final errors = <String, String>{};

    try {
      validateName();
    } catch (e) {
      if (e is MealPlanException) {
        errors['name'] = e.message;
      }
    }

    try {
      validateStartDate();
    } catch (e) {
      if (e is MealPlanException) {
        errors['startDate'] = e.message;
      }
    }

    try {
      validateMealSlots();
    } catch (e) {
      if (e is MealPlanException) {
        errors['mealSlots'] = e.message;
      }
    }

    try {
      validateAssignments();
    } catch (e) {
      if (e is MealPlanException) {
        errors['assignments'] = e.message;
      }
    }

    if (isTemplate) {
      try {
        validateTemplate();
      } catch (e) {
        if (e is MealPlanException) {
          errors['template'] = e.message;
        }
      }
    }

    return errors;
  }

  /// Returns true if the meal plan is valid
  bool get isValid => getValidationErrors().isEmpty;
}

/// Exception for meal plan operations
class MealPlanException implements Exception {
  final String message;
  final String code;

  MealPlanException(this.message, this.code);

  @override
  String toString() => 'MealPlanException: $message (code: $code)';
}
