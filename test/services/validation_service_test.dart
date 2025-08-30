import 'package:flutter_test/flutter_test.dart';
import 'package:nomnom/models/recipe.dart';
import 'package:nomnom/services/validation_service.dart';

void main() {
  group('ValidationService', () {
    late Recipe validRecipe;

    setUp(() {
      validRecipe = Recipe.create(
        title: 'Test Recipe',
        ingredients: [
          Ingredient(name: 'Flour', quantity: 2.0, unit: 'cups'),
          Ingredient(name: 'Sugar', quantity: 1.0, unit: 'cup'),
        ],
        instructions: [
          'Mix flour and sugar together',
          'Bake for 30 minutes at 350°F',
        ],
        prepTime: 15,
        cookTime: 30,
        servings: 4,
        tags: ['dessert', 'easy'],
      );
    });

    group('Recipe Validation', () {
      testWidgets('validates valid recipe successfully', (tester) async {
        final result = ValidationService.validateRecipe(validRecipe);

        expect(result.isValid, isTrue);
        expect(result.hasErrors, isFalse);
      });

      testWidgets('detects invalid recipe with multiple errors', (
        tester,
      ) async {
        final invalidRecipe = Recipe.create(
          title: '', // Empty title
          ingredients: [], // No ingredients
          instructions: [], // No instructions
          prepTime: -5, // Negative prep time
          cookTime: 2000, // Excessive cook time
          servings: 0, // Invalid servings
          tags: [
            '',
            'very-long-tag-that-exceeds-the-maximum-allowed-length',
          ], // Invalid tags
        );

        final result = ValidationService.validateRecipe(invalidRecipe);

        expect(result.isValid, isFalse);
        expect(result.hasErrors, isTrue);
        expect(result.errors.length, greaterThan(5));
      });
    });

    group('Title Validation', () {
      testWidgets('validates empty title', (tester) async {
        final result = ValidationService.validateField('title', '');

        expect(result.isValid, isFalse);
        expect(result.getFieldError('title'), contains('required'));
      });

      testWidgets('validates title length', (tester) async {
        final longTitle = 'A' * (Recipe.maxTitleLength + 1);
        final result = ValidationService.validateField('title', longTitle);

        expect(result.isValid, isFalse);
        expect(result.getFieldError('title'), contains('exceed'));
      });

      testWidgets('provides suggestions for short titles', (tester) async {
        final result = ValidationService.validateField('title', 'Cake');

        expect(result.warnings.isNotEmpty, isTrue);
        expect(result.warnings.first.suggestion, isNotNull);
      });

      testWidgets('suggests capitalization improvements', (tester) async {
        final result = ValidationService.validateField(
          'title',
          'chocolate cake',
        );

        expect(result.infos.isNotEmpty, isTrue);
        expect(result.infos.first.message, contains('capitalizing'));
      });
    });

    group('Ingredients Validation', () {
      testWidgets('validates empty ingredients list', (tester) async {
        final result = ValidationService.validateField(
          'ingredients',
          <Ingredient>[],
        );

        expect(result.isValid, isFalse);
        expect(result.getFieldError('ingredients'), contains('required'));
      });

      testWidgets('detects duplicate ingredients', (tester) async {
        final ingredients = [
          Ingredient(name: 'Flour', quantity: 1.0, unit: 'cup'),
          Ingredient(
            name: 'flour',
            quantity: 2.0,
            unit: 'cups',
          ), // Duplicate (case insensitive)
        ];

        final result = ValidationService.validateField(
          'ingredients',
          ingredients,
        );

        expect(
          result.warnings.any((w) => w.message.contains('Duplicate')),
          isTrue,
        );
      });

      testWidgets('provides suggestions for single ingredient', (tester) async {
        final ingredients = [
          Ingredient(name: 'Flour', quantity: 1.0, unit: 'cup'),
        ];

        final result = ValidationService.validateField(
          'ingredients',
          ingredients,
        );

        expect(
          result.infos.any((i) => i.message.contains('only one ingredient')),
          isTrue,
        );
      });

      testWidgets('warns about too many ingredients', (tester) async {
        final ingredients = List.generate(
          25,
          (i) => Ingredient(name: 'Ingredient $i', quantity: 1.0, unit: 'unit'),
        );

        final result = ValidationService.validateField(
          'ingredients',
          ingredients,
        );

        expect(
          result.warnings.any((w) => w.message.contains('many ingredients')),
          isTrue,
        );
      });
    });

    group('Instructions Validation', () {
      testWidgets('validates empty instructions list', (tester) async {
        final result = ValidationService.validateField(
          'instructions',
          <String>[],
        );

        expect(result.isValid, isFalse);
        expect(result.getFieldError('instructions'), contains('required'));
      });

      testWidgets('detects empty instruction steps', (tester) async {
        final instructions = ['Mix ingredients', '', 'Bake'];

        final result = ValidationService.validateField(
          'instructions',
          instructions,
        );

        expect(result.isValid, isFalse);
        expect(
          result.getFieldError('instructions'),
          contains('cannot be empty'),
        );
      });

      testWidgets('warns about very short instructions', (tester) async {
        final instructions = ['Mix', 'Bake'];

        final result = ValidationService.validateField(
          'instructions',
          instructions,
        );

        expect(
          result.warnings.any((w) => w.message.contains('very short')),
          isTrue,
        );
      });

      testWidgets('warns about very long instructions', (tester) async {
        final longInstruction = 'A' * 600;
        final instructions = [longInstruction];

        final result = ValidationService.validateField(
          'instructions',
          instructions,
        );

        expect(
          result.warnings.any((w) => w.message.contains('very long')),
          isTrue,
        );
      });

      testWidgets('suggests adding cooking actions', (tester) async {
        final instructions = ['Get ingredients', 'Put in bowl'];

        final result = ValidationService.validateField(
          'instructions',
          instructions,
        );

        expect(
          result.infos.any((i) => i.message.contains('cooking actions')),
          isTrue,
        );
      });
    });

    group('Time Validation', () {
      testWidgets('validates negative prep time', (tester) async {
        final result = ValidationService.validateField('prepTime', -5);

        expect(result.isValid, isFalse);
        expect(
          result.getFieldError('prepTime'),
          contains('cannot be negative'),
        );
      });

      testWidgets('validates excessive cook time', (tester) async {
        final result = ValidationService.validateField('cookTime', 2000);

        expect(result.isValid, isFalse);
        expect(result.getFieldError('cookTime'), contains('exceed 24 hours'));
      });

      testWidgets('warns about long prep time', (tester) async {
        final result = ValidationService.validateField('prepTime', 300);

        expect(
          result.warnings.any((w) => w.message.contains('quite long')),
          isTrue,
        );
      });

      testWidgets('provides info for no-cook recipes', (tester) async {
        final recipe = validRecipe.copyWith(prepTime: 10, cookTime: 0);
        final result = ValidationService.validateRecipe(recipe);

        expect(
          result.infos.any((i) => i.message.contains('no cook time')),
          isTrue,
        );
      });
    });

    group('Servings Validation', () {
      testWidgets('validates zero servings', (tester) async {
        final result = ValidationService.validateField('servings', 0);

        expect(result.isValid, isFalse);
        expect(result.getFieldError('servings'), contains('at least 1'));
      });

      testWidgets('validates excessive servings', (tester) async {
        final result = ValidationService.validateField('servings', 150);

        expect(result.isValid, isFalse);
        expect(result.getFieldError('servings'), contains('exceed 100'));
      });

      testWidgets('warns about many servings', (tester) async {
        final result = ValidationService.validateField('servings', 25);

        expect(
          result.warnings.any((w) => w.message.contains('many people')),
          isTrue,
        );
      });
    });

    group('Tags Validation', () {
      testWidgets('provides info for no tags', (tester) async {
        final result = ValidationService.validateField('tags', <String>[]);

        expect(result.infos.any((i) => i.message.contains('No tags')), isTrue);
      });

      testWidgets('detects empty tags', (tester) async {
        final tags = ['dessert', '', 'easy'];

        final result = ValidationService.validateField('tags', tags);

        expect(result.isValid, isFalse);
        expect(result.getFieldError('tags'), contains('cannot be empty'));
      });

      testWidgets('validates tag length', (tester) async {
        final longTag = 'A' * (Recipe.maxTagLength + 1);
        final tags = [longTag];

        final result = ValidationService.validateField('tags', tags);

        expect(result.isValid, isFalse);
        expect(result.getFieldError('tags'), contains('exceeds'));
      });

      testWidgets('validates tag characters', (tester) async {
        final tags = ['dessert!', 'easy@home'];

        final result = ValidationService.validateField('tags', tags);

        expect(result.isValid, isFalse);
        expect(result.getFieldError('tags'), contains('invalid characters'));
      });

      testWidgets('detects duplicate tags', (tester) async {
        final tags = ['dessert', 'easy', 'DESSERT'];

        final result = ValidationService.validateField('tags', tags);

        expect(
          result.warnings.any((w) => w.message.contains('Duplicate')),
          isTrue,
        );
      });

      testWidgets('warns about too many tags', (tester) async {
        final tags = List.generate(15, (i) => 'tag$i');

        final result = ValidationService.validateField('tags', tags);

        expect(
          result.warnings.any((w) => w.message.contains('Many tags')),
          isTrue,
        );
      });
    });

    group('Photos Validation', () {
      testWidgets('provides info for no photos', (tester) async {
        final result = ValidationService.validateField('photos', <String>[]);

        expect(
          result.infos.any((i) => i.message.contains('No photos')),
          isTrue,
        );
      });

      testWidgets('detects empty photo URLs', (tester) async {
        final photos = [
          '/path/to/photo.jpg',
          '',
          'http://example.com/photo.png',
        ];

        final result = ValidationService.validateField('photos', photos);

        expect(result.isValid, isFalse);
        expect(result.getFieldError('photos'), contains('cannot be empty'));
      });

      testWidgets('validates photo URL format', (tester) async {
        final photos = ['invalid-url', 'another-bad-url'];

        final result = ValidationService.validateField('photos', photos);

        expect(result.isValid, isFalse);
        expect(result.getFieldError('photos'), contains('invalid URL format'));
      });

      testWidgets('warns about too many photos', (tester) async {
        final photos = List.generate(8, (i) => '/path/to/photo$i.jpg');

        final result = ValidationService.validateField('photos', photos);

        expect(
          result.warnings.any((w) => w.message.contains('Many photos')),
          isTrue,
        );
      });
    });

    group('Error Message Generation', () {
      testWidgets('handles validation exceptions', (tester) async {
        final error = ValidationException('Test error', 'testField');
        final message = ValidationService.getErrorMessage(error);

        expect(message, equals('Test error'));
      });

      testWidgets('handles recipe validation exceptions', (tester) async {
        final error = RecipeValidationException('Recipe error', 'title');
        final message = ValidationService.getErrorMessage(error);

        expect(message, equals('Recipe error'));
      });

      testWidgets('handles network errors', (tester) async {
        final error = Exception('Network connection failed');
        final message = ValidationService.getErrorMessage(error);

        expect(message, contains('Network'));
      });

      testWidgets('handles storage errors', (tester) async {
        final error = Exception('Database storage error');
        final message = ValidationService.getErrorMessage(error);

        expect(message, contains('Storage'));
      });

      testWidgets('handles permission errors', (tester) async {
        final error = Exception('Permission denied');
        final message = ValidationService.getErrorMessage(error);

        expect(message, contains('Permission'));
      });

      testWidgets('handles unknown errors', (tester) async {
        final error = Exception('Unknown error');
        final message = ValidationService.getErrorMessage(error);

        expect(message, contains('unexpected error'));
      });
    });

    group('Recovery Suggestions', () {
      testWidgets('provides validation error suggestions', (tester) async {
        final error = ValidationException('Test error', 'testField');
        final suggestions = ValidationService.getRecoverySuggestions(error);

        expect(
          suggestions,
          contains('Fix the validation errors and try again'),
        );
        expect(
          suggestions,
          contains('Check the highlighted fields for issues'),
        );
      });

      testWidgets('provides network error suggestions', (tester) async {
        final error = Exception('Network connection failed');
        final suggestions = ValidationService.getRecoverySuggestions(error);

        expect(suggestions, contains('Check your internet connection'));
        expect(suggestions, contains('Try again in a few moments'));
      });

      testWidgets('provides storage error suggestions', (tester) async {
        final error = Exception('Database storage error');
        final suggestions = ValidationService.getRecoverySuggestions(error);

        expect(suggestions, contains('Try closing and reopening the app'));
        expect(suggestions, contains('Check available storage space'));
      });

      testWidgets('provides permission error suggestions', (tester) async {
        final error = Exception('Permission denied');
        final suggestions = ValidationService.getRecoverySuggestions(error);

        expect(
          suggestions,
          contains('Check app permissions in device settings'),
        );
        expect(
          suggestions,
          contains('Grant necessary permissions and try again'),
        );
      });

      testWidgets('provides generic error suggestions', (tester) async {
        final error = Exception('Unknown error');
        final suggestions = ValidationService.getRecoverySuggestions(error);

        expect(suggestions, contains('Try the operation again'));
        expect(
          suggestions,
          contains('Restart the app if the problem persists'),
        );
      });
    });

    group('ValidationResult', () {
      testWidgets('creates valid result correctly', (tester) async {
        final result = ValidationResult.valid();

        expect(result.isValid, isTrue);
        expect(result.messages, isEmpty);
        expect(result.hasErrors, isFalse);
        expect(result.hasWarnings, isFalse);
      });

      testWidgets('creates invalid result correctly', (tester) async {
        final messages = [
          ValidationMessage.error('Error message', 'field1'),
          ValidationMessage.warning('Warning message', 'field2'),
        ];
        final result = ValidationResult.invalid(messages);

        expect(result.isValid, isFalse);
        expect(result.messages.length, equals(2));
        expect(result.hasErrors, isTrue);
        expect(result.hasWarnings, isTrue);
      });

      testWidgets('filters messages by severity', (tester) async {
        final messages = [
          ValidationMessage.error('Error 1', 'field1'),
          ValidationMessage.warning('Warning 1', 'field2'),
          ValidationMessage.info('Info 1', 'field3'),
          ValidationMessage.error('Error 2', 'field4'),
        ];
        final result = ValidationResult(isValid: false, messages: messages);

        expect(result.errors.length, equals(2));
        expect(result.warnings.length, equals(1));
        expect(result.infos.length, equals(1));
      });

      testWidgets('gets field-specific messages', (tester) async {
        final messages = [
          ValidationMessage.error('Error for field1', 'field1'),
          ValidationMessage.warning('Warning for field1', 'field1'),
          ValidationMessage.error('Error for field2', 'field2'),
        ];
        final result = ValidationResult(isValid: false, messages: messages);

        final field1Messages = result.getFieldMessages('field1');
        expect(field1Messages.length, equals(2));

        final field1Error = result.getFieldError('field1');
        expect(field1Error, equals('Error for field1'));

        final field3Error = result.getFieldError('field3');
        expect(field3Error, isNull);
      });
    });

    group('ValidationMessage', () {
      testWidgets('creates error message correctly', (tester) async {
        final message = ValidationMessage.error(
          'Test error',
          'testField',
          suggestion: 'Fix it',
        );

        expect(message.severity, equals(ValidationSeverity.error));
        expect(message.message, equals('Test error'));
        expect(message.field, equals('testField'));
        expect(message.suggestion, equals('Fix it'));
      });

      testWidgets('creates warning message correctly', (tester) async {
        final message = ValidationMessage.warning('Test warning', 'testField');

        expect(message.severity, equals(ValidationSeverity.warning));
        expect(message.message, equals('Test warning'));
        expect(message.field, equals('testField'));
        expect(message.suggestion, isNull);
      });

      testWidgets('creates info message correctly', (tester) async {
        final message = ValidationMessage.info('Test info', 'testField');

        expect(message.severity, equals(ValidationSeverity.info));
        expect(message.message, equals('Test info'));
        expect(message.field, equals('testField'));
      });
    });
  });
}
