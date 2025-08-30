import 'package:flutter_test/flutter_test.dart';
import 'package:nomnom/models/recipe.dart';
import 'package:nomnom/services/validation_service.dart';

void main() {
  group('Enhanced ValidationService Tests', () {
    group('Recipe Validation', () {
      test('should validate complete recipe successfully', () {
        final recipe = Recipe.create(
          title: 'Delicious Pasta',
          ingredients: [
            Ingredient(name: 'Pasta', quantity: 200, unit: 'grams'),
            Ingredient(name: 'Tomato Sauce', quantity: 1, unit: 'cup'),
          ],
          instructions: [
            'Boil water in a large pot',
            'Add pasta and cook for 8-10 minutes',
            'Drain pasta and mix with sauce',
          ],
          prepTime: 10,
          cookTime: 15,
          servings: 2,
          tags: ['Italian', 'Quick'],
          photoUrls: [],
        );

        final result = ValidationService.validateRecipe(recipe);

        expect(result.isValid, isTrue);
        expect(result.errors, isEmpty);
      });

      test('should identify multiple validation errors', () {
        final recipe = Recipe.create(
          title: '', // Empty title
          ingredients: [], // No ingredients
          instructions: [], // No instructions
          prepTime: -5, // Negative prep time
          cookTime: 2000, // Excessive cook time
          servings: 0, // Invalid servings
          tags: ['', 'ValidTag', 'Another@Invalid#Tag'], // Invalid tags
          photoUrls: ['invalid-url'], // Invalid photo URL
        );

        final result = ValidationService.validateRecipe(recipe);

        expect(result.isValid, isFalse);
        expect(result.errors.length, greaterThan(5));

        // Check specific error fields
        expect(result.getFieldError('title'), isNotNull);
        expect(result.getFieldError('ingredients'), isNotNull);
        expect(result.getFieldError('instructions'), isNotNull);
        expect(result.getFieldError('prepTime'), isNotNull);
        expect(result.getFieldError('cookTime'), isNotNull);
        expect(result.getFieldError('servings'), isNotNull);
      });

      test('should provide helpful suggestions for errors', () {
        final recipe = Recipe.create(
          title: 'A', // Too short
          ingredients: [Ingredient(name: 'Salt', quantity: 1, unit: 'pinch')],
          instructions: ['Mix'], // Too short
          prepTime: 0,
          cookTime: 0,
          servings: 1,
          tags: [],
          photoUrls: [],
        );

        final result = ValidationService.validateRecipe(recipe);

        expect(result.hasWarnings, isTrue);

        final titleMessages = result.getFieldMessages('title');
        expect(titleMessages.any((m) => m.suggestion != null), isTrue);

        final instructionMessages = result.getFieldMessages('instructions');
        expect(instructionMessages.any((m) => m.suggestion != null), isTrue);
      });
    });

    group('Field-Level Validation', () {
      test('should validate title field with detailed feedback', () {
        // Empty title
        var result = ValidationService.validateField('title', '');
        expect(result.isValid, isFalse);
        expect(result.errors.first.suggestion, isNotNull);

        // Short title with warning
        result = ValidationService.validateField('title', 'Hi');
        expect(result.isValid, isTrue);
        expect(result.hasWarnings, isTrue);

        // Good title
        result = ValidationService.validateField(
          'title',
          'Delicious Chocolate Cake',
        );
        expect(result.isValid, isTrue);
        expect(result.hasWarnings, isFalse);

        // Too long title
        result = ValidationService.validateField('title', 'A' * 101);
        expect(result.isValid, isFalse);
        expect(result.errors.first.message, contains('exceed'));
      });

      test('should validate ingredients with duplicate detection', () {
        final ingredients = [
          Ingredient(name: 'Salt', quantity: 1, unit: 'tsp'),
          Ingredient(name: 'salt', quantity: 2, unit: 'tsp'), // Duplicate
        ];

        final result = ValidationService.validateField(
          'ingredients',
          ingredients,
        );

        expect(result.hasWarnings, isTrue);
        expect(
          result.warnings.any((w) => w.message.contains('Duplicate')),
          isTrue,
        );
      });

      test('should validate instructions with length checks', () {
        final instructions = [
          'This is a good instruction with sufficient detail',
          'Short', // Too short
          'A' * 501, // Too long
        ];

        final result = ValidationService.validateField(
          'instructions',
          instructions,
        );

        expect(result.hasWarnings, isTrue);
        expect(result.warnings.any((w) => w.message.contains('short')), isTrue);
        expect(result.warnings.any((w) => w.message.contains('long')), isTrue);
      });

      test('should validate cooking times with context', () {
        final recipe = Recipe.create(
          title: 'Test Recipe',
          ingredients: [Ingredient(name: 'Test', quantity: 1, unit: 'cup')],
          instructions: ['Test instruction'],
          prepTime: 300, // 5 hours - should warn
          cookTime: 10,
          servings: 4,
          tags: [],
          photoUrls: [],
        );

        final result = ValidationService.validateField(
          'prepTime',
          300,
          context: recipe,
        );

        expect(result.isValid, isTrue);
        expect(result.hasWarnings, isTrue);
        expect(result.warnings.first.message, contains('quite long'));
      });

      test('should validate servings with reasonable limits', () {
        // Zero servings
        var result = ValidationService.validateField('servings', 0);
        expect(result.isValid, isFalse);
        expect(result.errors.first.message, contains('at least 1'));

        // Excessive servings
        result = ValidationService.validateField('servings', 150);
        expect(result.isValid, isFalse);
        expect(result.errors.first.message, contains('exceed 100'));

        // Many servings with warning
        result = ValidationService.validateField('servings', 25);
        expect(result.isValid, isTrue);
        expect(result.hasWarnings, isTrue);
      });

      test('should validate tags with format and duplicate checks', () {
        final tags = [
          'ValidTag',
          'Another Valid Tag',
          'invalid@tag', // Invalid characters
          'ValidTag', // Duplicate
          '', // Empty
          'A' * 25, // Too long
        ];

        final result = ValidationService.validateField('tags', tags);

        expect(result.isValid, isFalse);
        expect(
          result.errors.any((e) => e.message.contains('invalid characters')),
          isTrue,
        );
        expect(result.errors.any((e) => e.message.contains('empty')), isTrue);
        expect(result.errors.any((e) => e.message.contains('exceeds')), isTrue);
        expect(
          result.warnings.any((w) => w.message.contains('Duplicate')),
          isTrue,
        );
      });

      test('should validate photo URLs with format checks', () {
        final photoUrls = [
          '/valid/local/path.jpg',
          'https://example.com/photo.png',
          'file:///local/file.jpeg',
          'invalid-url', // Invalid format
          '', // Empty
        ];

        final result = ValidationService.validateField('photos', photoUrls);

        expect(result.isValid, isFalse);
        expect(
          result.errors.any((e) => e.message.contains('invalid URL format')),
          isTrue,
        );
        expect(result.errors.any((e) => e.message.contains('empty')), isTrue);
      });
    });

    group('Error Message Generation', () {
      test('should generate user-friendly error messages', () {
        final validationError = ValidationException(
          'Test validation error',
          'field',
        );
        final message = ValidationService.getErrorMessage(validationError);
        expect(message, equals('Test validation error'));

        final networkError = Exception('network connection failed');
        final networkMessage = ValidationService.getErrorMessage(networkError);
        expect(networkMessage, contains('Network'));
        expect(networkMessage, contains('internet connection'));

        final storageError = Exception('database storage error');
        final storageMessage = ValidationService.getErrorMessage(storageError);
        expect(storageMessage, contains('Storage'));
        expect(storageMessage, contains('try again'));
      });

      test('should provide contextual recovery suggestions', () {
        final validationError = ValidationException('Invalid data', 'field');
        final suggestions = ValidationService.getRecoverySuggestions(
          validationError,
        );
        expect(
          suggestions,
          contains('Fix the validation errors and try again'),
        );

        final networkError = Exception('connection timeout');
        final networkSuggestions = ValidationService.getRecoverySuggestions(
          networkError,
        );
        expect(networkSuggestions.any((s) => s.contains('internet')), isTrue);
        expect(networkSuggestions.any((s) => s.contains('network')), isTrue);

        final storageError = Exception('storage full');
        final storageSuggestions = ValidationService.getRecoverySuggestions(
          storageError,
        );
        expect(storageSuggestions.any((s) => s.contains('storage')), isTrue);
        expect(storageSuggestions.any((s) => s.contains('space')), isTrue);
      });
    });

    group('Validation Result Utilities', () {
      test('should correctly categorize validation messages', () {
        final messages = [
          ValidationMessage.error('Error 1', 'field1'),
          ValidationMessage.warning('Warning 1', 'field2'),
          ValidationMessage.info('Info 1', 'field3'),
          ValidationMessage.error('Error 2', 'field1'),
        ];

        final result = ValidationResult(isValid: false, messages: messages);

        expect(result.errors.length, equals(2));
        expect(result.warnings.length, equals(1));
        expect(result.infos.length, equals(1));
        expect(result.hasErrors, isTrue);
        expect(result.hasWarnings, isTrue);
      });

      test('should retrieve field-specific messages', () {
        final messages = [
          ValidationMessage.error('Field1 Error', 'field1'),
          ValidationMessage.warning('Field1 Warning', 'field1'),
          ValidationMessage.error('Field2 Error', 'field2'),
        ];

        final result = ValidationResult(isValid: false, messages: messages);

        final field1Messages = result.getFieldMessages('field1');
        expect(field1Messages.length, equals(2));

        final field1Error = result.getFieldError('field1');
        expect(field1Error, equals('Field1 Error'));

        final field3Error = result.getFieldError('field3');
        expect(field3Error, isNull);
      });
    });
  });
}
