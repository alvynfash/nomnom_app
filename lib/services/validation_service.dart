import '../models/recipe.dart';

/// Exception thrown when validation fails
class ValidationException implements Exception {
  final String message;
  final String field;
  final ValidationSeverity severity;

  ValidationException(
    this.message,
    this.field, {
    this.severity = ValidationSeverity.error,
  });

  @override
  String toString() =>
      'ValidationException: $message (field: $field, severity: $severity)';
}

/// Severity levels for validation messages
enum ValidationSeverity { info, warning, error }

/// Result of a validation operation
class ValidationResult {
  final bool isValid;
  final List<ValidationMessage> messages;

  ValidationResult({required this.isValid, required this.messages});

  ValidationResult.valid() : isValid = true, messages = [];

  ValidationResult.invalid(this.messages) : isValid = false;

  /// Get all error messages
  List<ValidationMessage> get errors =>
      messages.where((m) => m.severity == ValidationSeverity.error).toList();

  /// Get all warning messages
  List<ValidationMessage> get warnings =>
      messages.where((m) => m.severity == ValidationSeverity.warning).toList();

  /// Get all info messages
  List<ValidationMessage> get infos =>
      messages.where((m) => m.severity == ValidationSeverity.info).toList();

  /// Check if there are any errors
  bool get hasErrors => errors.isNotEmpty;

  /// Check if there are any warnings
  bool get hasWarnings => warnings.isNotEmpty;

  /// Get the first error message for a specific field
  String? getFieldError(String field) {
    final fieldErrors = errors.where((m) => m.field == field);
    return fieldErrors.isNotEmpty ? fieldErrors.first.message : null;
  }

  /// Get all messages for a specific field
  List<ValidationMessage> getFieldMessages(String field) {
    return messages.where((m) => m.field == field).toList();
  }
}

/// Individual validation message
class ValidationMessage {
  final String message;
  final String field;
  final ValidationSeverity severity;
  final String? suggestion;

  ValidationMessage({
    required this.message,
    required this.field,
    required this.severity,
    this.suggestion,
  });

  ValidationMessage.error(String message, String field, {String? suggestion})
    : this(
        message: message,
        field: field,
        severity: ValidationSeverity.error,
        suggestion: suggestion,
      );

  ValidationMessage.warning(String message, String field, {String? suggestion})
    : this(
        message: message,
        field: field,
        severity: ValidationSeverity.warning,
        suggestion: suggestion,
      );

  ValidationMessage.info(String message, String field, {String? suggestion})
    : this(
        message: message,
        field: field,
        severity: ValidationSeverity.info,
        suggestion: suggestion,
      );
}

/// Service for comprehensive validation and error recovery
class ValidationService {
  /// Validate a recipe comprehensively
  static ValidationResult validateRecipe(Recipe recipe) {
    final messages = <ValidationMessage>[];

    // Validate title
    messages.addAll(_validateTitle(recipe.title));

    // Validate description
    messages.addAll(_validateDescription(recipe.description));

    // Validate ingredients
    messages.addAll(_validateIngredients(recipe.ingredients));

    // Validate instructions
    messages.addAll(_validateInstructions(recipe.instructions));

    // Validate times
    messages.addAll(_validateTimes(recipe.prepTime, recipe.cookTime));

    // Validate servings
    messages.addAll(_validateServings(recipe.servings));

    // Validate tags
    messages.addAll(_validateTags(recipe.tags));

    // Validate photos
    messages.addAll(_validatePhotos(recipe.photoUrls));

    final hasErrors = messages.any(
      (m) => m.severity == ValidationSeverity.error,
    );
    return ValidationResult(isValid: !hasErrors, messages: messages);
  }

  /// Validate recipe title with detailed feedback
  static List<ValidationMessage> _validateTitle(String title) {
    final messages = <ValidationMessage>[];
    final trimmedTitle = title.trim();

    if (trimmedTitle.isEmpty) {
      messages.add(
        ValidationMessage.error(
          'Recipe title is required',
          'title',
          suggestion: 'Enter a descriptive name for your recipe',
        ),
      );
    } else if (trimmedTitle.length < Recipe.minTitleLength) {
      messages.add(
        ValidationMessage.error(
          'Recipe title must be at least ${Recipe.minTitleLength} character long',
          'title',
          suggestion: 'Add more characters to make the title more descriptive',
        ),
      );
    } else if (trimmedTitle.length > Recipe.maxTitleLength) {
      messages.add(
        ValidationMessage.error(
          'Recipe title cannot exceed ${Recipe.maxTitleLength} characters',
          'title',
          suggestion:
              'Shorten the title to ${Recipe.maxTitleLength} characters or less',
        ),
      );
    } else {
      // Check for potential improvements
      if (trimmedTitle.length < 5) {
        messages.add(
          ValidationMessage.warning(
            'Title is quite short',
            'title',
            suggestion:
                'Consider adding more detail to help identify this recipe',
          ),
        );
      }

      if (trimmedTitle.toLowerCase() == trimmedTitle) {
        messages.add(
          ValidationMessage.info(
            'Consider capitalizing the first letter',
            'title',
            suggestion: 'Proper capitalization makes recipes easier to read',
          ),
        );
      }
    }

    return messages;
  }

  /// Validate recipe description with detailed feedback
  static List<ValidationMessage> _validateDescription(String description) {
    final messages = <ValidationMessage>[];
    final trimmedDescription = description.trim();

    if (trimmedDescription.length > 500) {
      messages.add(
        ValidationMessage.error(
          'Recipe description cannot exceed 500 characters',
          'description',
          suggestion: 'Shorten the description to 500 characters or less',
        ),
      );
    } else if (trimmedDescription.length > 400) {
      messages.add(
        ValidationMessage.warning(
          'Description is quite long (${trimmedDescription.length} characters)',
          'description',
          suggestion: 'Consider shortening for better readability',
        ),
      );
    }

    if (trimmedDescription.isEmpty) {
      messages.add(
        ValidationMessage.info(
          'No description provided',
          'description',
          suggestion:
              'Adding a description helps others understand your recipe',
        ),
      );
    } else if (trimmedDescription.length < 20) {
      messages.add(
        ValidationMessage.info(
          'Description is quite short',
          'description',
          suggestion: 'Consider adding more detail about your recipe',
        ),
      );
    }

    return messages;
  }

  /// Validate ingredients with detailed feedback
  static List<ValidationMessage> _validateIngredients(
    List<Ingredient> ingredients,
  ) {
    final messages = <ValidationMessage>[];

    if (ingredients.isEmpty) {
      messages.add(
        ValidationMessage.error(
          'At least one ingredient is required',
          'ingredients',
          suggestion: 'Add ingredients to complete your recipe',
        ),
      );
      return messages;
    }

    // Check for duplicate ingredients
    final ingredientNames = <String>[];
    for (int i = 0; i < ingredients.length; i++) {
      final ingredient = ingredients[i];
      final normalizedName = ingredient.name.toLowerCase().trim();

      if (ingredientNames.contains(normalizedName)) {
        messages.add(
          ValidationMessage.warning(
            'Duplicate ingredient: ${ingredient.name}',
            'ingredients',
            suggestion:
                'Consider combining duplicate ingredients or removing one',
          ),
        );
      } else {
        ingredientNames.add(normalizedName);
      }

      // Validate individual ingredient
      try {
        ingredient.validate();
      } catch (e) {
        if (e is RecipeValidationException) {
          messages.add(
            ValidationMessage.error(
              'Ingredient ${i + 1}: ${e.message}',
              'ingredients',
              suggestion: 'Check the ingredient details and fix any issues',
            ),
          );
        }
      }
    }

    // Provide helpful suggestions
    if (ingredients.length == 1) {
      messages.add(
        ValidationMessage.info(
          'Recipe has only one ingredient',
          'ingredients',
          suggestion: 'Most recipes benefit from multiple ingredients',
        ),
      );
    } else if (ingredients.length > 20) {
      messages.add(
        ValidationMessage.warning(
          'Recipe has many ingredients (${ingredients.length})',
          'ingredients',
          suggestion:
              'Consider if all ingredients are necessary or if some can be combined',
        ),
      );
    }

    return messages;
  }

  /// Validate instructions with detailed feedback
  static List<ValidationMessage> _validateInstructions(
    List<String> instructions,
  ) {
    final messages = <ValidationMessage>[];

    if (instructions.isEmpty) {
      messages.add(
        ValidationMessage.error(
          'At least one instruction step is required',
          'instructions',
          suggestion: 'Add step-by-step instructions for your recipe',
        ),
      );
      return messages;
    }

    for (int i = 0; i < instructions.length; i++) {
      final instruction = instructions[i].trim();

      if (instruction.isEmpty) {
        messages.add(
          ValidationMessage.error(
            'Instruction step ${i + 1} cannot be empty',
            'instructions',
            suggestion: 'Remove empty steps or add content',
          ),
        );
      } else if (instruction.length < 10) {
        messages.add(
          ValidationMessage.warning(
            'Instruction step ${i + 1} is very short',
            'instructions',
            suggestion: 'Consider adding more detail to make the step clearer',
          ),
        );
      } else if (instruction.length > 500) {
        messages.add(
          ValidationMessage.warning(
            'Instruction step ${i + 1} is very long',
            'instructions',
            suggestion:
                'Consider breaking this step into smaller, more manageable steps',
          ),
        );
      }
    }

    // Check for common issues
    final allText = instructions.join(' ').toLowerCase();
    if (!allText.contains('cook') &&
        !allText.contains('bake') &&
        !allText.contains('mix') &&
        !allText.contains('add')) {
      messages.add(
        ValidationMessage.info(
          'Instructions might be missing cooking actions',
          'instructions',
          suggestion:
              'Consider adding action words like "mix", "cook", "bake", etc.',
        ),
      );
    }

    return messages;
  }

  /// Validate cooking times with detailed feedback
  static List<ValidationMessage> _validateTimes(int prepTime, int cookTime) {
    final messages = <ValidationMessage>[];

    if (prepTime < 0) {
      messages.add(
        ValidationMessage.error(
          'Prep time cannot be negative',
          'prepTime',
          suggestion: 'Enter 0 if no prep time is needed',
        ),
      );
    } else if (prepTime > 1440) {
      messages.add(
        ValidationMessage.error(
          'Prep time cannot exceed 24 hours (1440 minutes)',
          'prepTime',
          suggestion: 'Check if the time is entered correctly',
        ),
      );
    } else if (prepTime > 240) {
      messages.add(
        ValidationMessage.warning(
          'Prep time is quite long ($prepTime minutes)',
          'prepTime',
          suggestion: 'Double-check if this prep time is correct',
        ),
      );
    }

    if (cookTime < 0) {
      messages.add(
        ValidationMessage.error(
          'Cook time cannot be negative',
          'cookTime',
          suggestion: 'Enter 0 if no cooking is required',
        ),
      );
    } else if (cookTime > 1440) {
      messages.add(
        ValidationMessage.error(
          'Cook time cannot exceed 24 hours (1440 minutes)',
          'cookTime',
          suggestion: 'Check if the time is entered correctly',
        ),
      );
    } else if (cookTime > 480) {
      messages.add(
        ValidationMessage.warning(
          'Cook time is quite long ($cookTime minutes)',
          'cookTime',
          suggestion: 'Double-check if this cook time is correct',
        ),
      );
    }

    // Provide helpful suggestions
    if (prepTime == 0 && cookTime == 0) {
      messages.add(
        ValidationMessage.info(
          'No prep or cook time specified',
          'times',
          suggestion: 'Adding time estimates helps with meal planning',
        ),
      );
    }

    if (prepTime > 0 && cookTime == 0) {
      messages.add(
        ValidationMessage.info(
          'Recipe has prep time but no cook time',
          'times',
          suggestion:
              'Is this a no-cook recipe? Consider adding a note in instructions',
        ),
      );
    }

    return messages;
  }

  /// Validate servings with detailed feedback
  static List<ValidationMessage> _validateServings(int servings) {
    final messages = <ValidationMessage>[];

    if (servings <= 0) {
      messages.add(
        ValidationMessage.error(
          'Servings must be at least 1',
          'servings',
          suggestion: 'Enter the number of people this recipe serves',
        ),
      );
    } else if (servings > 100) {
      messages.add(
        ValidationMessage.error(
          'Servings cannot exceed 100',
          'servings',
          suggestion: 'Check if the serving count is correct',
        ),
      );
    } else if (servings > 20) {
      messages.add(
        ValidationMessage.warning(
          'Recipe serves many people ($servings)',
          'servings',
          suggestion: 'Double-check if this serving count is correct',
        ),
      );
    }

    return messages;
  }

  /// Validate tags with detailed feedback
  static List<ValidationMessage> _validateTags(List<String> tags) {
    final messages = <ValidationMessage>[];

    if (tags.isEmpty) {
      messages.add(
        ValidationMessage.info(
          'No tags specified',
          'tags',
          suggestion: 'Adding tags helps organize and find recipes',
        ),
      );
      return messages;
    }

    final seenTags = <String>[];
    for (int i = 0; i < tags.length; i++) {
      final tag = tags[i].trim();
      final normalizedTag = tag.toLowerCase();

      if (tag.isEmpty) {
        messages.add(
          ValidationMessage.error(
            'Tag ${i + 1} cannot be empty',
            'tags',
            suggestion: 'Remove empty tags or add content',
          ),
        );
        continue;
      }

      if (tag.length > Recipe.maxTagLength) {
        messages.add(
          ValidationMessage.error(
            'Tag "$tag" exceeds ${Recipe.maxTagLength} characters',
            'tags',
            suggestion: 'Shorten the tag or use abbreviations',
          ),
        );
      }

      if (!RegExp(r'^[a-zA-Z0-9\s\-_]+$').hasMatch(tag)) {
        messages.add(
          ValidationMessage.error(
            'Tag "$tag" contains invalid characters',
            'tags',
            suggestion:
                'Use only letters, numbers, spaces, hyphens, and underscores',
          ),
        );
      }

      if (seenTags.contains(normalizedTag)) {
        messages.add(
          ValidationMessage.warning(
            'Duplicate tag: $tag',
            'tags',
            suggestion: 'Remove duplicate tags',
          ),
        );
      } else {
        seenTags.add(normalizedTag);
      }
    }

    // Provide suggestions
    if (tags.length > 10) {
      messages.add(
        ValidationMessage.warning(
          'Many tags specified (${tags.length})',
          'tags',
          suggestion: 'Consider using fewer, more specific tags',
        ),
      );
    }

    return messages;
  }

  /// Validate photo URLs with detailed feedback
  static List<ValidationMessage> _validatePhotos(List<String> photoUrls) {
    final messages = <ValidationMessage>[];

    if (photoUrls.isEmpty) {
      messages.add(
        ValidationMessage.info(
          'No photos added',
          'photos',
          suggestion: 'Adding photos makes recipes more appealing',
        ),
      );
      return messages;
    }

    for (int i = 0; i < photoUrls.length; i++) {
      final photoUrl = photoUrls[i].trim();

      if (photoUrl.isEmpty) {
        messages.add(
          ValidationMessage.error(
            'Photo ${i + 1} URL cannot be empty',
            'photos',
            suggestion: 'Remove empty photo entries',
          ),
        );
        continue;
      }

      // Basic URL validation
      if (!photoUrl.startsWith('/') &&
          !photoUrl.startsWith('http') &&
          !photoUrl.startsWith('file://')) {
        messages.add(
          ValidationMessage.error(
            'Photo ${i + 1} has invalid URL format',
            'photos',
            suggestion: 'Ensure the photo path or URL is correct',
          ),
        );
      }
    }

    if (photoUrls.length > 5) {
      messages.add(
        ValidationMessage.warning(
          'Many photos added (${photoUrls.length})',
          'photos',
          suggestion:
              'Consider keeping only the best photos to improve performance',
        ),
      );
    }

    return messages;
  }

  /// Validate a single field in real-time
  static ValidationResult validateField(
    String fieldName,
    dynamic value, {
    Recipe? context,
  }) {
    final messages = <ValidationMessage>[];

    switch (fieldName) {
      case 'title':
        messages.addAll(_validateTitle(value as String));
        break;
      case 'description':
        messages.addAll(_validateDescription(value as String));
        break;
      case 'ingredients':
        messages.addAll(_validateIngredients(value as List<Ingredient>));
        break;
      case 'instructions':
        messages.addAll(_validateInstructions(value as List<String>));
        break;
      case 'prepTime':
        messages.addAll(_validateTimes(value as int, context?.cookTime ?? 0));
        break;
      case 'cookTime':
        messages.addAll(_validateTimes(context?.prepTime ?? 0, value as int));
        break;
      case 'servings':
        messages.addAll(_validateServings(value as int));
        break;
      case 'tags':
        messages.addAll(_validateTags(value as List<String>));
        break;
      case 'photos':
        messages.addAll(_validatePhotos(value as List<String>));
        break;
      default:
        return ValidationResult.valid();
    }

    final hasErrors = messages.any(
      (m) => m.severity == ValidationSeverity.error,
    );
    return ValidationResult(isValid: !hasErrors, messages: messages);
  }

  /// Get user-friendly error message for common exceptions
  static String getErrorMessage(dynamic error) {
    if (error is ValidationException) {
      return error.message;
    } else if (error is RecipeValidationException) {
      return error.message;
    } else if (error is FormatException) {
      return 'Invalid data format. Please check your input.';
    } else if (error is ArgumentError) {
      return 'Invalid input provided. Please check your data.';
    } else if (error.toString().contains('network')) {
      return 'Network error. Please check your internet connection and try again.';
    } else if (error.toString().contains('storage') ||
        error.toString().contains('database')) {
      return 'Storage error. Please try again or restart the app.';
    } else if (error.toString().contains('permission')) {
      return 'Permission denied. Please check app permissions.';
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Get recovery suggestions for common errors
  static List<String> getRecoverySuggestions(dynamic error) {
    final suggestions = <String>[];

    if (error is ValidationException || error is RecipeValidationException) {
      suggestions.add('Fix the validation errors and try again');
      suggestions.add('Check the highlighted fields for issues');
    } else {
      final errorString = error.toString().toLowerCase();
      if (errorString.contains('network') ||
          errorString.contains('connection')) {
        suggestions.add('Check your internet connection');
        suggestions.add('Try again in a few moments');
        suggestions.add('Switch to a different network if available');
      } else if (errorString.contains('storage') ||
          errorString.contains('database')) {
        suggestions.add('Try closing and reopening the app');
        suggestions.add('Check available storage space');
        suggestions.add('Clear app cache if the problem persists');
      } else if (errorString.contains('permission')) {
        suggestions.add('Check app permissions in device settings');
        suggestions.add('Grant necessary permissions and try again');
      } else {
        suggestions.add('Try the operation again');
        suggestions.add('Restart the app if the problem persists');
        suggestions.add('Contact support if the issue continues');
      }
    }

    return suggestions;
  }
}
