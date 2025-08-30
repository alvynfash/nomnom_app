class RecipeValidationException implements Exception {
  final String message;
  final String field;

  RecipeValidationException(this.message, this.field);

  @override
  String toString() => 'RecipeValidationException: $message (field: $field)';
}

enum RecipeDifficulty {
  easy('Easy'),
  medium('Medium'),
  hard('Hard');

  const RecipeDifficulty(this.displayName);
  final String displayName;

  static RecipeDifficulty fromString(String value) {
    switch (value.toLowerCase()) {
      case 'easy':
        return RecipeDifficulty.easy;
      case 'medium':
        return RecipeDifficulty.medium;
      case 'hard':
        return RecipeDifficulty.hard;
      default:
        return RecipeDifficulty.easy;
    }
  }
}

class Recipe {
  final String id;
  final String title;
  final String description;
  final List<Ingredient> ingredients;
  final List<String> instructions;
  final int prepTime;
  final int cookTime;
  final int servings;
  final RecipeDifficulty difficulty;
  final List<String> tags;
  final List<String> photoUrls;
  final bool isPrivate;
  final bool isPublished;
  final String familyId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Recipe({
    required this.id,
    required this.title,
    this.description = '',
    required this.ingredients,
    required this.instructions,
    this.prepTime = 0,
    this.cookTime = 0,
    this.servings = 1,
    this.difficulty = RecipeDifficulty.easy,
    this.tags = const [],
    this.photoUrls = const [],
    this.isPrivate = true,
    this.isPublished = false,
    this.familyId = '',
    required this.createdAt,
    required this.updatedAt,
  });

  Recipe.create({
    required this.title,
    this.description = '',
    required this.ingredients,
    required this.instructions,
    this.prepTime = 0,
    this.cookTime = 0,
    this.servings = 1,
    this.difficulty = RecipeDifficulty.easy,
    this.tags = const [],
    this.photoUrls = const [],
    this.isPrivate = true,
    this.isPublished = false,
    this.familyId = '',
  }) : id = _generateUniqueId(),
       createdAt = DateTime.now(),
       updatedAt = DateTime.now();

  static int _idCounter = 0;

  static String _generateUniqueId() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch;
    final counter = _idCounter++;
    return '${timestamp}_$counter';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'ingredients': ingredients
          .map((ingredient) => ingredient.toMap())
          .toList(),
      'instructions': instructions,
      'prepTime': prepTime,
      'cookTime': cookTime,
      'servings': servings,
      'difficulty': difficulty.name,
      'tags': tags,
      'photoUrls': photoUrls,
      'isPrivate': isPrivate,
      'isPublished': isPublished,
      'familyId': familyId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Recipe.fromMap(Map<String, dynamic> map) {
    return Recipe(
      id: map['id'],
      title: map['title'],
      description: map['description'] ?? '',
      ingredients: List<Ingredient>.from(
        map['ingredients'].map((x) => Ingredient.fromMap(x)),
      ),
      instructions: List<String>.from(map['instructions']),
      prepTime: map['prepTime'],
      cookTime: map['cookTime'],
      servings: map['servings'],
      difficulty: RecipeDifficulty.fromString(map['difficulty'] ?? 'easy'),
      tags: List<String>.from(map['tags']),
      photoUrls: List<String>.from(map['photoUrls'] ?? []),
      isPrivate: map['isPrivate'],
      isPublished: map['isPublished'],
      familyId: map['familyId'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  // JSON serialization methods for compatibility
  Map<String, dynamic> toJson() => toMap();

  factory Recipe.fromJson(Map<String, dynamic> json) => Recipe.fromMap(json);

  Recipe copyWith({
    String? id,
    String? title,
    String? description,
    List<Ingredient>? ingredients,
    List<String>? instructions,
    int? prepTime,
    int? cookTime,
    int? servings,
    RecipeDifficulty? difficulty,
    List<String>? tags,
    List<String>? photoUrls,
    bool? isPrivate,
    bool? isPublished,
    String? familyId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Recipe(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      ingredients: ingredients ?? this.ingredients,
      instructions: instructions ?? this.instructions,
      prepTime: prepTime ?? this.prepTime,
      cookTime: cookTime ?? this.cookTime,
      servings: servings ?? this.servings,
      difficulty: difficulty ?? this.difficulty,
      tags: tags ?? this.tags,
      photoUrls: photoUrls ?? this.photoUrls,
      isPrivate: isPrivate ?? this.isPrivate,
      isPublished: isPublished ?? this.isPublished,
      familyId: familyId ?? this.familyId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Validation methods
  static const int maxTitleLength = 100;
  static const int minTitleLength = 1;
  static const int maxTagLength = 20;
  static const int maxPhotoSize = 5 * 1024 * 1024; // 5MB in bytes
  static const List<String> allowedPhotoExtensions = ['jpg', 'jpeg', 'png'];

  /// Validates the entire recipe and throws RecipeValidationException if invalid
  void validate() {
    validateTitle();
    validateDescription();
    validateIngredients();
    validateInstructions();
    validateTimes();
    validateServings();
    validateTags();
    validatePhotoUrls();
  }

  /// Validates the recipe title
  void validateTitle() {
    if (title.trim().isEmpty) {
      throw RecipeValidationException('Recipe title cannot be empty', 'title');
    }
    if (title.length < minTitleLength) {
      throw RecipeValidationException(
        'Recipe title must be at least $minTitleLength character long',
        'title',
      );
    }
    if (title.length > maxTitleLength) {
      throw RecipeValidationException(
        'Recipe title cannot exceed $maxTitleLength characters',
        'title',
      );
    }
  }

  /// Validates the recipe description
  void validateDescription() {
    if (description.length > 500) {
      throw RecipeValidationException(
        'Recipe description cannot exceed 500 characters',
        'description',
      );
    }
  }

  /// Validates the ingredients list
  void validateIngredients() {
    if (ingredients.isEmpty) {
      throw RecipeValidationException(
        'Recipe must have at least one ingredient',
        'ingredients',
      );
    }

    for (int i = 0; i < ingredients.length; i++) {
      try {
        ingredients[i].validate();
      } catch (e) {
        throw RecipeValidationException(
          'Invalid ingredient at position ${i + 1}: $e',
          'ingredients',
        );
      }
    }
  }

  /// Validates the instructions list
  void validateInstructions() {
    if (instructions.isEmpty) {
      throw RecipeValidationException(
        'Recipe must have at least one instruction step',
        'instructions',
      );
    }

    for (int i = 0; i < instructions.length; i++) {
      final instruction = instructions[i].trim();
      if (instruction.isEmpty) {
        throw RecipeValidationException(
          'Instruction step ${i + 1} cannot be empty',
          'instructions',
        );
      }
    }
  }

  /// Validates prep and cook times
  void validateTimes() {
    if (prepTime < 0) {
      throw RecipeValidationException(
        'Prep time cannot be negative',
        'prepTime',
      );
    }
    if (cookTime < 0) {
      throw RecipeValidationException(
        'Cook time cannot be negative',
        'cookTime',
      );
    }
    if (prepTime > 1440) {
      // 24 hours in minutes
      throw RecipeValidationException(
        'Prep time cannot exceed 24 hours (1440 minutes)',
        'prepTime',
      );
    }
    if (cookTime > 1440) {
      // 24 hours in minutes
      throw RecipeValidationException(
        'Cook time cannot exceed 24 hours (1440 minutes)',
        'cookTime',
      );
    }
  }

  /// Validates the servings count
  void validateServings() {
    if (servings <= 0) {
      throw RecipeValidationException(
        'Servings must be at least 1',
        'servings',
      );
    }
    if (servings > 100) {
      throw RecipeValidationException('Servings cannot exceed 100', 'servings');
    }
  }

  /// Validates the tags list
  void validateTags() {
    for (int i = 0; i < tags.length; i++) {
      final tag = tags[i].trim();
      if (tag.isEmpty) {
        throw RecipeValidationException('Tag ${i + 1} cannot be empty', 'tags');
      }
      if (tag.length > maxTagLength) {
        throw RecipeValidationException(
          'Tag "$tag" cannot exceed $maxTagLength characters',
          'tags',
        );
      }
      if (!RegExp(r'^[a-zA-Z0-9\s\-_]+$').hasMatch(tag)) {
        throw RecipeValidationException(
          'Tag "$tag" contains invalid characters. Only letters, numbers, spaces, hyphens, and underscores are allowed',
          'tags',
        );
      }
    }

    // Check for duplicate tags (case-insensitive)
    final lowerCaseTags = tags.map((tag) => tag.toLowerCase()).toList();
    final uniqueTags = lowerCaseTags.toSet();
    if (lowerCaseTags.length != uniqueTags.length) {
      throw RecipeValidationException('Duplicate tags are not allowed', 'tags');
    }
  }

  /// Validates photo URLs
  void validatePhotoUrls() {
    for (int i = 0; i < photoUrls.length; i++) {
      final photoUrl = photoUrls[i].trim();
      if (photoUrl.isEmpty) {
        throw RecipeValidationException(
          'Photo URL ${i + 1} cannot be empty',
          'photoUrls',
        );
      }

      // Basic URL validation for local file paths or URLs
      if (!photoUrl.startsWith('/') &&
          !photoUrl.startsWith('http') &&
          !photoUrl.startsWith('file://')) {
        throw RecipeValidationException(
          'Photo URL "$photoUrl" is not a valid file path or URL',
          'photoUrls',
        );
      }
    }
  }

  /// Validates a photo file extension
  static bool isValidPhotoExtension(String filename) {
    final extension = filename.toLowerCase().split('.').last;
    return allowedPhotoExtensions.contains(extension);
  }

  /// Validates a photo file size
  static bool isValidPhotoSize(int sizeInBytes) {
    return sizeInBytes <= maxPhotoSize;
  }

  /// Returns a user-friendly validation summary
  Map<String, String> getValidationErrors() {
    final errors = <String, String>{};

    try {
      validateTitle();
    } catch (e) {
      if (e is RecipeValidationException) {
        errors[e.field] = e.message;
      }
    }

    try {
      validateDescription();
    } catch (e) {
      if (e is RecipeValidationException) {
        errors[e.field] = e.message;
      }
    }

    try {
      validateIngredients();
    } catch (e) {
      if (e is RecipeValidationException) {
        errors[e.field] = e.message;
      }
    }

    try {
      validateInstructions();
    } catch (e) {
      if (e is RecipeValidationException) {
        errors[e.field] = e.message;
      }
    }

    try {
      validateTimes();
    } catch (e) {
      if (e is RecipeValidationException) {
        errors[e.field] = e.message;
      }
    }

    try {
      validateServings();
    } catch (e) {
      if (e is RecipeValidationException) {
        errors[e.field] = e.message;
      }
    }

    try {
      validateTags();
    } catch (e) {
      if (e is RecipeValidationException) {
        errors[e.field] = e.message;
      }
    }

    try {
      validatePhotoUrls();
    } catch (e) {
      if (e is RecipeValidationException) {
        errors[e.field] = e.message;
      }
    }

    return errors;
  }

  /// Returns true if the recipe is valid
  bool get isValid => getValidationErrors().isEmpty;

  /// Returns the total cooking time (prep + cook)
  int get totalTime => prepTime + cookTime;

  /// Returns a formatted time string
  String get formattedTime {
    if (totalTime == 0) return 'No time specified';
    if (totalTime < 60) return '${totalTime}m';

    final hours = totalTime ~/ 60;
    final minutes = totalTime % 60;

    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}m';
  }

  /// Returns a summary of the recipe for display
  String get summary {
    final ingredientCount = ingredients.length;
    final stepCount = instructions.length;
    return '$ingredientCount ingredients • $stepCount steps • $formattedTime';
  }
}

class Ingredient {
  final String name;
  final double quantity;
  final String unit;

  Ingredient({required this.name, required this.quantity, required this.unit});

  Map<String, dynamic> toMap() {
    return {'name': name, 'quantity': quantity, 'unit': unit};
  }

  factory Ingredient.fromMap(Map<String, dynamic> map) {
    return Ingredient(
      name: map['name'],
      quantity: map['quantity'].toDouble(),
      unit: map['unit'],
    );
  }

  /// Validates the ingredient
  void validate() {
    if (name.trim().isEmpty) {
      throw RecipeValidationException(
        'Ingredient name cannot be empty',
        'ingredient.name',
      );
    }
    if (name.length > 100) {
      throw RecipeValidationException(
        'Ingredient name cannot exceed 100 characters',
        'ingredient.name',
      );
    }
    if (quantity <= 0) {
      throw RecipeValidationException(
        'Ingredient quantity must be greater than 0',
        'ingredient.quantity',
      );
    }
    if (quantity > 10000) {
      throw RecipeValidationException(
        'Ingredient quantity cannot exceed 10,000',
        'ingredient.quantity',
      );
    }
    if (unit.trim().isEmpty) {
      throw RecipeValidationException(
        'Ingredient unit cannot be empty',
        'ingredient.unit',
      );
    }
    if (unit.length > 50) {
      throw RecipeValidationException(
        'Ingredient unit cannot exceed 50 characters',
        'ingredient.unit',
      );
    }
  }

  /// Returns true if the ingredient is valid
  bool get isValid {
    try {
      validate();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Returns a formatted string representation of the ingredient
  String get formatted {
    // Format quantity to remove unnecessary decimal places
    final formattedQuantity = quantity == quantity.toInt()
        ? quantity.toInt().toString()
        : quantity.toString();
    return '$formattedQuantity $unit $name';
  }

  /// Creates a copy of the ingredient with updated values
  Ingredient copyWith({String? name, double? quantity, String? unit}) {
    return Ingredient(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Ingredient &&
        other.name == name &&
        other.quantity == quantity &&
        other.unit == unit;
  }

  @override
  int get hashCode => name.hashCode ^ quantity.hashCode ^ unit.hashCode;

  @override
  String toString() => formatted;
}
