import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recipe.dart';
import '../services/recipe_service.dart';
import '../services/validation_service.dart';
import '../services/error_recovery_service.dart';
import '../widgets/photo_upload_widget.dart';
import '../widgets/tag_input_widget.dart';

class RecipeEditScreen extends StatefulWidget {
  final Recipe? recipe;
  final VoidCallback onRecipeSaved;

  const RecipeEditScreen({super.key, this.recipe, required this.onRecipeSaved});

  @override
  State<RecipeEditScreen> createState() => _RecipeEditScreenState();
}

class _RecipeEditScreenState extends State<RecipeEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final RecipeService _recipeService = RecipeService();

  late String _title;
  late String _description;
  late List<Ingredient> _ingredients;
  late List<String> _instructions;
  late int _prepTime;
  late int _cookTime;
  late int _servings;
  late RecipeDifficulty _difficulty;
  late List<String> _tags;
  late List<String> _photoUrls;
  List<String> _availableTags = [];

  // Time unit selections
  String _prepTimeUnit = 'minutes';
  String _cookTimeUnit = 'minutes';

  // Auto-save and form state management
  Timer? _autoSaveTimer;
  bool _hasUnsavedChanges = false;
  bool _isAutoSaving = false;
  String? _draftKey;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _prepTimeController = TextEditingController();
  final _cookTimeController = TextEditingController();
  final _servingsController = TextEditingController();
  final _ingredientNameController = TextEditingController();
  final _ingredientQuantityController = TextEditingController();
  final _ingredientUnitController = TextEditingController();
  final _instructionController = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.recipe != null) {
      _title = widget.recipe!.title;
      _description = widget.recipe!.description;
      _ingredients = List.from(widget.recipe!.ingredients);
      _instructions = List.from(widget.recipe!.instructions);
      _prepTime = widget.recipe!.prepTime;
      _cookTime = widget.recipe!.cookTime;
      _servings = widget.recipe!.servings;
      _difficulty = widget.recipe!.difficulty;
      _tags = List.from(widget.recipe!.tags);
      _photoUrls = List.from(widget.recipe!.photoUrls);

      _titleController.text = _title;
      _descriptionController.text = _description;

      // Handle time units - convert from minutes to appropriate unit
      if (_prepTime >= 60 && _prepTime % 60 == 0) {
        _prepTimeUnit = 'hours';
        _prepTimeController.text = (_prepTime ~/ 60).toString();
      } else {
        _prepTimeUnit = 'minutes';
        _prepTimeController.text = _prepTime.toString();
      }

      if (_cookTime >= 60 && _cookTime % 60 == 0) {
        _cookTimeUnit = 'hours';
        _cookTimeController.text = (_cookTime ~/ 60).toString();
      } else {
        _cookTimeUnit = 'minutes';
        _cookTimeController.text = _cookTime.toString();
      }

      _servingsController.text = _servings.toString();
    } else {
      _title = '';
      _description = '';
      _ingredients = [];
      _instructions = [];
      _prepTime = 0;
      _cookTime = 0;
      _servings = 1;
      _difficulty = RecipeDifficulty.easy;
      _tags = [];
      _photoUrls = [];
    }

    _loadAvailableTags();
    _initializeFormState();
  }

  void _initializeFormState() {
    // Set up draft key for auto-save
    _draftKey = widget.recipe != null
        ? 'recipe_draft_${widget.recipe!.id}'
        : 'recipe_draft_new_${DateTime.now().millisecondsSinceEpoch}';

    // Load draft if creating new recipe
    if (widget.recipe == null) {
      _loadDraft();
    }

    // Set up listeners for form changes
    _titleController.addListener(_onFormChanged);
    _descriptionController.addListener(_onFormChanged);
    _prepTimeController.addListener(_onFormChanged);
    _cookTimeController.addListener(_onFormChanged);
    _servingsController.addListener(_onFormChanged);
    _ingredientNameController.addListener(_onFormChanged);
    _ingredientQuantityController.addListener(_onFormChanged);
    _ingredientUnitController.addListener(_onFormChanged);
    _instructionController.addListener(_onFormChanged);
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _titleController.removeListener(_onFormChanged);
    _descriptionController.removeListener(_onFormChanged);
    _prepTimeController.removeListener(_onFormChanged);
    _cookTimeController.removeListener(_onFormChanged);
    _servingsController.removeListener(_onFormChanged);
    _ingredientNameController.removeListener(_onFormChanged);
    _ingredientQuantityController.removeListener(_onFormChanged);
    _ingredientUnitController.removeListener(_onFormChanged);
    _instructionController.removeListener(_onFormChanged);
    super.dispose();
  }

  void _onFormChanged() {
    if (!_hasUnsavedChanges) {
      // Use post-frame callback to avoid setState during build
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_hasUnsavedChanges) {
          setState(() {
            _hasUnsavedChanges = true;
          });
        }
      });
    }

    // Debounce auto-save
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 3), _autoSaveDraft);
  }

  // Real-time field validation
  String? _validateTitleField(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Let required validator handle empty
    }

    final validationResult = ValidationService.validateField('title', value);
    if (!validationResult.isValid) {
      return validationResult.errors.first.message;
    }
    return null;
  }

  String? _validateDescriptionField(String? value) {
    if (value == null || value.isEmpty) return null; // Description is optional

    final validationResult = ValidationService.validateField(
      'description',
      value,
    );
    if (!validationResult.isValid) {
      return validationResult.errors.first.message;
    }
    return null;
  }

  String? _validateTimeField(String? value, String fieldName) {
    if (value == null || value.isEmpty) return null;

    final time = int.tryParse(value);
    if (time == null) return 'Please enter a valid number';

    final validationResult = ValidationService.validateField(
      fieldName,
      time,
      context: Recipe.create(
        title: _title.isNotEmpty ? _title : 'temp',
        description: _description,
        ingredients: _ingredients.isNotEmpty
            ? _ingredients
            : [Ingredient(name: 'temp', quantity: 1, unit: 'temp')],
        instructions: _instructions.isNotEmpty ? _instructions : ['temp'],
        prepTime: fieldName == 'prepTime' ? time : _prepTime,
        cookTime: fieldName == 'cookTime' ? time : _cookTime,
        servings: _servings,
        difficulty: _difficulty,
        tags: _tags,
        photoUrls: _photoUrls,
      ),
    );

    if (!validationResult.isValid) {
      return validationResult.errors.first.message;
    }
    return null;
  }

  String? _validateServingsField(String? value) {
    if (value == null || value.isEmpty) return null;

    final servings = int.tryParse(value);
    if (servings == null) return 'Please enter a valid number';

    final validationResult = ValidationService.validateField(
      'servings',
      servings,
    );
    if (!validationResult.isValid) {
      return validationResult.errors.first.message;
    }
    return null;
  }

  Future<void> _loadDraft() async {
    if (_draftKey == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final draftJson = prefs.getString(_draftKey!);

      if (draftJson != null) {
        // For now, just show that draft exists - full implementation would parse JSON
        // final draftData = Recipe.fromJson(jsonDecode(draftJson));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Draft found! Continue editing or start fresh.',
              ),
              action: SnackBarAction(
                label: 'Load Draft',
                onPressed: () {
                  // Load draft data - simplified for now
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _autoSaveDraft() async {
    if (_draftKey == null || _isAutoSaving) return;

    setState(() {
      _isAutoSaving = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      // Create a draft recipe object
      final draftRecipe = Recipe.create(
        title: _title.isNotEmpty ? _title : 'Untitled Recipe',
        description: _description,
        ingredients: _ingredients,
        instructions: _instructions,
        prepTime: _prepTime,
        cookTime: _cookTime,
        servings: _servings,
        difficulty: _difficulty,
        tags: _tags,
        photoUrls: _photoUrls,
      );

      await prefs.setString(_draftKey!, draftRecipe.toJson().toString());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.cloud_done_rounded, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text('Draft saved automatically'),
              ],
            ),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Handle error silently
    } finally {
      if (mounted) {
        setState(() {
          _isAutoSaving = false;
        });
      }
    }
  }

  Future<void> _clearDraft() async {
    if (_draftKey == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_draftKey!);
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _loadAvailableTags() async {
    try {
      final tags = await _recipeService.getAllTags();
      setState(() {
        _availableTags = tags;
      });
    } catch (e) {
      // Handle error silently, autocomplete will just not work
    }
  }

  void _addIngredient() {
    final name = _ingredientNameController.text.trim();
    final quantityText = _ingredientQuantityController.text.trim();
    final unit = _ingredientUnitController.text.trim();

    try {
      // Create temporary ingredient for validation
      final quantity = double.tryParse(quantityText);
      if (quantity == null) {
        throw ValidationException(
          'Please enter a valid number for quantity',
          'quantity',
        );
      }

      final ingredient = Ingredient(name: name, quantity: quantity, unit: unit);

      // Validate using ValidationService
      final tempIngredients = [..._ingredients, ingredient];
      final validationResult = ValidationService.validateField(
        'ingredients',
        tempIngredients,
      );

      if (!validationResult.isValid) {
        final errorMessage = validationResult.errors.first.message;
        final suggestion = validationResult.errors.first.suggestion;

        _showValidationError(errorMessage, suggestion: suggestion);
        return;
      }

      // Show warnings if any
      if (validationResult.hasWarnings) {
        final warning = validationResult.warnings.first;
        _showValidationWarning(warning.message, suggestion: warning.suggestion);
      }

      setState(() {
        _ingredients.add(ingredient);
        _hasUnsavedChanges = true;
      });

      _ingredientNameController.clear();
      _ingredientQuantityController.clear();
      _ingredientUnitController.clear();

      _showSuccessMessage('Ingredient added successfully');
    } catch (e) {
      final errorMessage = ValidationService.getErrorMessage(e);
      final suggestions = ValidationService.getRecoverySuggestions(e);

      _showValidationError(
        errorMessage,
        suggestion: suggestions.isNotEmpty ? suggestions.first : null,
      );
    }
  }

  Future<void> _removeIngredient(int index) async {
    if (index < 0 || index >= _ingredients.length) return;

    final ingredient = _ingredients[index];
    final confirmed = await _showConfirmationDialog(
      title: 'Remove Ingredient',
      content: 'Are you sure you want to remove "${ingredient.name}"?',
      confirmText: 'Remove',
      isDestructive: true,
    );

    if (confirmed) {
      setState(() {
        _ingredients.removeAt(index);
        _hasUnsavedChanges = true;
      });
      _showSuccessMessage('Ingredient removed');
    }
  }

  void _addInstruction() {
    final instruction = _instructionController.text.trim();

    try {
      // Validate using ValidationService
      final tempInstructions = [..._instructions, instruction];
      final validationResult = ValidationService.validateField(
        'instructions',
        tempInstructions,
      );

      if (!validationResult.isValid) {
        final errorMessage = validationResult.errors.first.message;
        final suggestion = validationResult.errors.first.suggestion;

        _showValidationError(errorMessage, suggestion: suggestion);
        return;
      }

      // Show warnings if any
      if (validationResult.hasWarnings) {
        final warning = validationResult.warnings.first;
        _showValidationWarning(warning.message, suggestion: warning.suggestion);
      }

      setState(() {
        _instructions.add(instruction);
        _hasUnsavedChanges = true;
      });

      _instructionController.clear();
      _showSuccessMessage('Instruction step added');
    } catch (e) {
      final errorMessage = ValidationService.getErrorMessage(e);
      final suggestions = ValidationService.getRecoverySuggestions(e);

      _showValidationError(
        errorMessage,
        suggestion: suggestions.isNotEmpty ? suggestions.first : null,
      );
    }
  }

  Future<void> _removeInstruction(int index) async {
    if (index < 0 || index >= _instructions.length) return;

    final confirmed = await _showConfirmationDialog(
      title: 'Remove Instruction',
      content: 'Are you sure you want to remove step ${index + 1}?',
      confirmText: 'Remove',
      isDestructive: true,
    );

    if (confirmed) {
      setState(() {
        _instructions.removeAt(index);
        _hasUnsavedChanges = true;
      });
      _showSuccessMessage('Instruction step removed');
    }
  }

  void _onTagsChanged(List<String> tags) {
    setState(() {
      _tags = tags;
      _hasUnsavedChanges = true;
    });
  }

  void _onPhotosChanged(List<String> photoUrls) {
    setState(() {
      _photoUrls = photoUrls;
      _hasUnsavedChanges = true;
    });
  }

  void _showValidationError(String message, {String? suggestion}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.error_rounded, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(message)),
              ],
            ),
            if (suggestion != null) ...[
              const SizedBox(height: 4),
              Text(
                suggestion,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: Duration(seconds: suggestion != null ? 4 : 3),
      ),
    );
  }

  void _showValidationWarning(String message, {String? suggestion}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.warning_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(message)),
              ],
            ),
            if (suggestion != null) ...[
              const SizedBox(height: 4),
              Text(
                suggestion,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ],
        ),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<bool> _showConfirmationDialog({
    required String title,
    required String content,
    required String confirmText,
    String cancelText = 'Cancel',
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: isDestructive
                ? FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                  )
                : null,
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _saveRecipe() async {
    // Comprehensive validation using ValidationService
    if (!_formKey.currentState!.validate()) {
      _showValidationError(
        'Please fix the form errors before saving',
        suggestion: 'Check the highlighted fields for issues',
      );
      return;
    }

    _formKey.currentState!.save();

    // Create recipe for validation
    final recipe = widget.recipe != null
        ? widget.recipe!.copyWith(
            title: _title,
            description: _description,
            ingredients: _ingredients,
            instructions: _instructions,
            prepTime: _prepTime,
            cookTime: _cookTime,
            servings: _servings,
            difficulty: _difficulty,
            tags: _tags,
            photoUrls: _photoUrls,
            updatedAt: DateTime.now(),
          )
        : Recipe.create(
            title: _title,
            description: _description,
            ingredients: _ingredients,
            instructions: _instructions,
            prepTime: _prepTime,
            cookTime: _cookTime,
            servings: _servings,
            difficulty: _difficulty,
            tags: _tags,
            photoUrls: _photoUrls,
          );

    // Comprehensive validation
    final validationResult = ValidationService.validateRecipe(recipe);

    if (!validationResult.isValid) {
      _showValidationErrors(validationResult);
      return;
    }

    // Show warnings if any
    if (validationResult.hasWarnings) {
      final shouldContinue = await _showValidationWarningsDialog(
        validationResult,
      );
      if (!shouldContinue) return;
    }

    // Show loading indicator
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Saving recipe...'),
              ],
            ),
          ),
        ),
      ),
    );

    // Use ErrorRecoveryService for save operation
    final operationId = 'save_recipe_${recipe.id}';
    final result = await ErrorRecoveryService.executeWithRecovery<Recipe>(
      operationId,
      () async {
        if (widget.recipe != null) {
          return await _recipeService.updateRecipe(recipe.id, recipe);
        } else {
          return await _recipeService.createRecipe(recipe);
        }
      },
      OperationType.save,
      config: RetryConfig.standard,
      fallbackOperation: () async {
        // Fallback: save as draft
        await _autoSaveDraft();
        throw Exception('Saved as draft due to connection issues');
      },
    );

    // Close loading dialog
    if (mounted) Navigator.of(context).pop();

    if (result.success) {
      // Clear draft after successful save
      await _clearDraft();

      setState(() {
        _hasUnsavedChanges = false;
      });

      widget.onRecipeSaved();
      if (!mounted) return;

      _showSuccessMessage(
        widget.recipe != null
            ? 'Recipe updated successfully!'
            : 'Recipe created successfully!',
      );

      Navigator.pop(context);
    } else {
      if (!mounted) return;

      // Show comprehensive error dialog with recovery options
      _showSaveErrorDialog(result);
    }
  }

  void _showValidationErrors(ValidationResult validationResult) {
    final errors = validationResult.errors;
    if (errors.isEmpty) return;

    final primaryError = errors.first;
    final additionalErrors = errors.skip(1).take(2).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Validation Errors'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              primaryError.message,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            if (primaryError.suggestion != null) ...[
              const SizedBox(height: 4),
              Text(
                primaryError.suggestion!,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (additionalErrors.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Additional issues:',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              ...additionalErrors.map(
                (error) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '• ${error.message}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
            ],
            if (errors.length > 3) ...[
              const SizedBox(height: 8),
              Text(
                'And ${errors.length - 3} more issues...',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fix Issues'),
          ),
        ],
      ),
    );
  }

  Future<bool> _showValidationWarningsDialog(
    ValidationResult validationResult,
  ) async {
    final warnings = validationResult.warnings;
    if (warnings.isEmpty) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Recipe Warnings'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your recipe has some suggestions for improvement:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            ...warnings
                .take(3)
                .map(
                  (warning) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('• ${warning.message}'),
                        if (warning.suggestion != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 12, top: 2),
                            child: Text(
                              warning.suggestion!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            const SizedBox(height: 8),
            const Text(
              'Would you like to save anyway?',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Fix First'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Save Anyway'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  void _showSaveErrorDialog(RecoveryResult<Recipe> result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Save Failed'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.error ?? 'An unexpected error occurred',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            if (result.suggestions.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Suggestions:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              ...result.suggestions
                  .take(3)
                  .map(
                    (suggestion) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '• $suggestion',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          if (result.nextStrategy == RecoveryStrategy.userIntervention) ...[
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                _saveRecipe(); // Retry
              },
              child: const Text('Retry'),
            ),
          ],
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _autoSaveDraft();
              _showSuccessMessage('Recipe saved as draft');
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Save as Draft'),
          ),
        ],
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    final shouldLeave = await _showConfirmationDialog(
      title: 'Unsaved Changes',
      content: 'You have unsaved changes. Are you sure you want to leave?',
      confirmText: 'Leave',
      cancelText: 'Stay',
      isDestructive: true,
    );

    if (shouldLeave) {
      // Auto-save as draft before leaving
      await _autoSaveDraft();
    }

    return shouldLeave;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && _hasUnsavedChanges) {
          final shouldPop = await _onWillPop();
          if (shouldPop && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          title: Text(
            widget.recipe != null ? 'Edit Recipe' : 'Create Recipe',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          actions: [
            FilledButton.icon(
              onPressed: _saveRecipe,
              icon: const Icon(Icons.save_rounded, size: 18),
              label: const Text('Save'),
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.onPrimary,
                foregroundColor: colorScheme.primary,
                elevation: 0,
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Recipe Details Section - Modern Layout
              _buildModernSectionCard(
                title: 'Recipe Details',
                icon: Icons.restaurant_menu_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title Field - Prominent
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Recipe Title',
                        hintText: 'Enter a delicious recipe name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: colorScheme.outline.withValues(alpha: 0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: colorScheme.outline.withValues(alpha: 0.2),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: colorScheme.surface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a recipe title';
                        }
                        return _validateTitleField(value);
                      },
                      onChanged: (value) {
                        _title = value;
                        _formKey.currentState?.validate();
                      },
                    ),

                    const SizedBox(height: 20),

                    // Description Field - Compact
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description (Optional)',
                        hintText: 'What makes this recipe special?',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colorScheme.outline.withValues(alpha: 0.2),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colorScheme.outline.withValues(alpha: 0.15),
                          ),
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.3),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      style: const TextStyle(fontSize: 14),
                      maxLines: 2,
                      maxLength: 200,
                      validator: _validateDescriptionField,
                      onChanged: (value) {
                        _description = value;
                        _formKey.currentState?.validate();
                      },
                    ),

                    const SizedBox(height: 24),

                    // Compact Info Grid
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(
                          alpha: 0.1,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Column(
                        children: [
                          // First Row: Difficulty and Servings
                          Row(
                            children: [
                              // Difficulty - Compact Chips
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Difficulty',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.primary,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildDifficultyChips(colorScheme),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 20),
                              // Servings - Compact
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Servings',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.primary,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: colorScheme.surface,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: colorScheme.outline.withValues(
                                            alpha: 0.2,
                                          ),
                                        ),
                                      ),
                                      child: TextFormField(
                                        controller: _servingsController,
                                        decoration: InputDecoration(
                                          hintText: '4',
                                          prefixIcon: Icon(
                                            Icons.people_rounded,
                                            size: 18,
                                            color: colorScheme.primary,
                                          ),
                                          border: InputBorder.none,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 8,
                                              ),
                                        ),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                        ],
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Required';
                                          }
                                          return _validateServingsField(value);
                                        },
                                        onChanged: (value) {
                                          _servings = int.tryParse(value) ?? 1;
                                          _formKey.currentState?.validate();
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Second Row: Time Fields - Compact
                          Row(
                            children: [
                              // Prep Time
                              Expanded(
                                child: _buildCompactTimeField(
                                  'Prep Time',
                                  Icons.timer_outlined,
                                  _prepTimeController,
                                  _prepTimeUnit,
                                  (value) {
                                    if (value != null) {
                                      setState(() {
                                        _prepTimeUnit = value;
                                        final currentValue =
                                            int.tryParse(
                                              _prepTimeController.text,
                                            ) ??
                                            0;
                                        _prepTime = value == 'hours'
                                            ? currentValue * 60
                                            : currentValue;
                                      });
                                    }
                                  },
                                  (value) {
                                    final time = int.tryParse(value) ?? 0;
                                    _prepTime = _prepTimeUnit == 'hours'
                                        ? time * 60
                                        : time;
                                    _formKey.currentState?.validate();
                                  },
                                  colorScheme,
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Cook Time
                              Expanded(
                                child: _buildCompactTimeField(
                                  'Cook Time',
                                  Icons.local_fire_department_rounded,
                                  _cookTimeController,
                                  _cookTimeUnit,
                                  (value) {
                                    if (value != null) {
                                      setState(() {
                                        _cookTimeUnit = value;
                                        final currentValue =
                                            int.tryParse(
                                              _cookTimeController.text,
                                            ) ??
                                            0;
                                        _cookTime = value == 'hours'
                                            ? currentValue * 60
                                            : currentValue;
                                      });
                                    }
                                  },
                                  (value) {
                                    final time = int.tryParse(value) ?? 0;
                                    _cookTime = _cookTimeUnit == 'hours'
                                        ? time * 60
                                        : time;
                                    _formKey.currentState?.validate();
                                  },
                                  colorScheme,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Photos Section
              _buildSectionCard(
                title: 'Photos',
                icon: Icons.photo_camera_rounded,
                child: PhotoUploadWidget(
                  photoUrls: _photoUrls,
                  onPhotosChanged: _onPhotosChanged,
                  recipeId:
                      widget.recipe?.id ??
                      'temp_${DateTime.now().millisecondsSinceEpoch}',
                  maxPhotos: 5,
                  enabled: true,
                  compactMode: true, // This will make photos smaller
                ),
              ),

              const SizedBox(height: 24),

              // Ingredients Section
              _buildSectionCard(
                title: 'Ingredients',
                icon: Icons.shopping_cart_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ingredients List (moved above the form)
                    if (_ingredients.isNotEmpty) ...[
                      ...List.generate(_ingredients.length, (index) {
                        final ingredient = _ingredients[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Card(
                            elevation: 0,
                            color: colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: colorScheme.outline.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                                radius: 16,
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                ingredient.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(
                                '${ingredient.quantity} ${ingredient.unit}',
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              trailing: IconButton(
                                onPressed: () => _removeIngredient(index),
                                icon: Icon(
                                  Icons.remove_circle_rounded,
                                  color: colorScheme.error,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                    ],

                    // Add Ingredient Form (moved below the list)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(
                          alpha: 0.3,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.outline.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  controller: _ingredientNameController,
                                  decoration: InputDecoration(
                                    labelText: 'Ingredient',
                                    hintText: 'e.g., Flour',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: _ingredientQuantityController,
                                  decoration: InputDecoration(
                                    labelText: 'Amount',
                                    hintText: '1',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d*\.?\d*'),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: _ingredientUnitController,
                                  decoration: InputDecoration(
                                    labelText: 'Unit',
                                    hintText: 'cups',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Smaller, left-aligned button
                          Align(
                            alignment: Alignment.centerLeft,
                            child: FilledButton.icon(
                              onPressed: _addIngredient,
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text('Add Ingredient'),
                              style: FilledButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Instructions Section
              _buildSectionCard(
                title: 'Instructions',
                icon: Icons.list_alt_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Instructions List (moved above the form)
                    if (_instructions.isNotEmpty) ...[
                      ...List.generate(_instructions.length, (index) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Card(
                            elevation: 0,
                            color: colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: colorScheme.outline.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    backgroundColor: colorScheme.secondary,
                                    foregroundColor: colorScheme.onSecondary,
                                    radius: 16,
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _instructions[index],
                                      style: const TextStyle(
                                        fontSize: 14,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => _removeInstruction(index),
                                    icon: Icon(
                                      Icons.remove_circle_rounded,
                                      color: colorScheme.error,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                    ],

                    // Add Instruction Form (moved below the list)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer.withValues(
                          alpha: 0.3,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.outline.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _instructionController,
                            decoration: InputDecoration(
                              labelText: 'Instruction Step',
                              hintText: 'Describe what to do...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.all(16),
                            ),
                            maxLines: 3,
                            minLines: 2,
                          ),
                          const SizedBox(height: 12),
                          // Smaller, left-aligned button
                          Align(
                            alignment: Alignment.centerLeft,
                            child: FilledButton.icon(
                              onPressed: _addInstruction,
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text('Add Step'),
                              style: FilledButton.styleFrom(
                                backgroundColor: colorScheme.secondary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Tags Section
              _buildSectionCard(
                title: 'Tags',
                icon: Icons.local_offer_rounded,
                child: TagInputWidget(
                  initialTags: _tags,
                  suggestions: _availableTags,
                  onTagsChanged: _onTagsChanged,
                  hintText: 'Add tags (e.g., Vegetarian, Quick, Healthy)',
                  maxTags: 10,
                  maxTagLength: Recipe.maxTagLength,
                  allowDuplicates: false,
                  caseSensitive: false,
                  tagBackgroundColor: colorScheme.tertiaryContainer,
                  tagTextColor: colorScheme.onTertiaryContainer,
                  tagBorderColor: colorScheme.outline.withValues(alpha: 0.2),
                  tagValidator: (tag) {
                    // Use Recipe model validation
                    if (tag.trim().isEmpty) {
                      return 'Tag cannot be empty';
                    }
                    if (tag.length > Recipe.maxTagLength) {
                      return 'Tag cannot exceed ${Recipe.maxTagLength} characters';
                    }
                    if (!RegExp(r'^[a-zA-Z0-9\s\-_]+$').hasMatch(tag)) {
                      return 'Tag contains invalid characters. Only letters, numbers, spaces, hyphens, and underscores are allowed';
                    }
                    return null;
                  },
                  enabled: true,
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: colorScheme.onPrimaryContainer,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildModernSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: colorScheme.onPrimary, size: 20),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyChips(ColorScheme colorScheme) {
    return Row(
      children: RecipeDifficulty.values.map((difficulty) {
        final isSelected = _difficulty == difficulty;
        final colors = _getDifficultyColors(difficulty);

        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () {
              setState(() {
                _difficulty = difficulty;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? colors['bg'] : colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? colors['border']!
                      : colorScheme.outline.withValues(alpha: 0.3),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    colors['icon'] as IconData,
                    size: 14,
                    color: isSelected
                        ? colors['iconColor']
                        : colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    difficulty.displayName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isSelected
                          ? colors['textColor']
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Map<String, dynamic> _getDifficultyColors(RecipeDifficulty difficulty) {
    switch (difficulty) {
      case RecipeDifficulty.easy:
        return {
          'bg': Colors.green.withValues(alpha: 0.1),
          'border': Colors.green,
          'icon': Icons.sentiment_satisfied_rounded,
          'iconColor': Colors.green,
          'textColor': Colors.green.shade700,
        };
      case RecipeDifficulty.medium:
        return {
          'bg': Colors.orange.withValues(alpha: 0.1),
          'border': Colors.orange,
          'icon': Icons.sentiment_neutral_rounded,
          'iconColor': Colors.orange,
          'textColor': Colors.orange.shade700,
        };
      case RecipeDifficulty.hard:
        return {
          'bg': Colors.red.withValues(alpha: 0.1),
          'border': Colors.red,
          'icon': Icons.sentiment_very_dissatisfied_rounded,
          'iconColor': Colors.red,
          'textColor': Colors.red.shade700,
        };
    }
  }

  Widget _buildCompactTimeField(
    String label,
    IconData icon,
    TextEditingController controller,
    String currentUnit,
    Function(String?) onUnitChanged,
    Function(String) onTimeChanged,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colorScheme.primary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              // Icon
              Padding(
                padding: const EdgeInsets.only(left: 12, right: 8),
                child: Icon(icon, size: 16, color: colorScheme.primary),
              ),
              // Time Input
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: controller,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '30',
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) => _validateTimeField(
                    value,
                    label.toLowerCase().replaceAll(' ', ''),
                  ),
                  onChanged: onTimeChanged,
                ),
              ),
              // Unit Dropdown
              Container(
                width: 60,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: DropdownButtonFormField<String>(
                  value: currentUnit,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'minutes', child: Text('min')),
                    DropdownMenuItem(value: 'hours', child: Text('hrs')),
                  ],
                  onChanged: onUnitChanged,
                  icon: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
