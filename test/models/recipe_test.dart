import 'package:flutter_test/flutter_test.dart';
import 'package:nomnom/models/recipe.dart';

void main() {
  group('Recipe Model Tests', () {
    late Recipe validRecipe;
    late List<Ingredient> validIngredients;
    late List<String> validInstructions;

    setUp(() {
      validIngredients = [
        Ingredient(name: 'Flour', quantity: 2.0, unit: 'cups'),
        Ingredient(name: 'Sugar', quantity: 1.0, unit: 'cup'),
        Ingredient(name: 'Eggs', quantity: 3.0, unit: 'pieces'),
      ];

      validInstructions = [
        'Mix flour and sugar in a bowl',
        'Add eggs and mix well',
        'Bake at 350°F for 30 minutes',
      ];

      validRecipe = Recipe.create(
        title: 'Test Recipe',
        ingredients: validIngredients,
        instructions: validInstructions,
        prepTime: 15,
        cookTime: 30,
        servings: 4,
        tags: ['dessert', 'easy'],
      );
    });

    group('Recipe Creation', () {
      test('should create a valid recipe with all fields', () {
        expect(validRecipe.title, equals('Test Recipe'));
        expect(validRecipe.ingredients.length, equals(3));
        expect(validRecipe.instructions.length, equals(3));
        expect(validRecipe.prepTime, equals(15));
        expect(validRecipe.cookTime, equals(30));
        expect(validRecipe.servings, equals(4));
        expect(validRecipe.tags.length, equals(2));
        expect(validRecipe.isPrivate, isTrue);
        expect(validRecipe.isPublished, isFalse);
        expect(validRecipe.familyId, isEmpty);
        expect(validRecipe.photoUrls, isEmpty);
      });

      test('should generate unique IDs for different recipes', () {
        final recipe1 = Recipe.create(
          title: 'Recipe 1',
          ingredients: validIngredients,
          instructions: validInstructions,
        );

        final recipe2 = Recipe.create(
          title: 'Recipe 2',
          ingredients: validIngredients,
          instructions: validInstructions,
        );

        expect(recipe1.id, isNot(equals(recipe2.id)));
      });

      test('should set creation and update timestamps', () {
        final now = DateTime.now();
        final recipe = Recipe.create(
          title: 'Test Recipe',
          ingredients: validIngredients,
          instructions: validInstructions,
        );

        expect(recipe.createdAt.difference(now).inSeconds, lessThan(2));
        expect(recipe.updatedAt.difference(now).inSeconds, lessThan(2));
      });
    });

    group('Recipe Validation', () {
      test('should validate a correct recipe', () {
        expect(() => validRecipe.validate(), returnsNormally);
        expect(validRecipe.isValid, isTrue);
        expect(validRecipe.getValidationErrors(), isEmpty);
      });

      group('Title Validation', () {
        test('should reject empty title', () {
          final recipe = validRecipe.copyWith(title: '');
          expect(
            () => recipe.validateTitle(),
            throwsA(isA<RecipeValidationException>()),
          );
          expect(recipe.isValid, isFalse);
        });

        test('should reject title that is too long', () {
          final longTitle = 'a' * 101;
          final recipe = validRecipe.copyWith(title: longTitle);
          expect(
            () => recipe.validateTitle(),
            throwsA(isA<RecipeValidationException>()),
          );
        });

        test(
          'should accept title with whitespace that trims to valid length',
          () {
            final recipe = validRecipe.copyWith(title: '  Valid Title  ');
            expect(() => recipe.validateTitle(), returnsNormally);
          },
        );
      });

      group('Ingredients Validation', () {
        test('should reject empty ingredients list', () {
          final recipe = validRecipe.copyWith(ingredients: []);
          expect(
            () => recipe.validateIngredients(),
            throwsA(isA<RecipeValidationException>()),
          );
        });

        test('should reject invalid ingredient', () {
          final invalidIngredients = [
            Ingredient(name: '', quantity: 1.0, unit: 'cup'),
          ];
          final recipe = validRecipe.copyWith(ingredients: invalidIngredients);
          expect(
            () => recipe.validateIngredients(),
            throwsA(isA<RecipeValidationException>()),
          );
        });
      });

      group('Instructions Validation', () {
        test('should reject empty instructions list', () {
          final recipe = validRecipe.copyWith(instructions: []);
          expect(
            () => recipe.validateInstructions(),
            throwsA(isA<RecipeValidationException>()),
          );
        });

        test('should reject empty instruction step', () {
          final recipe = validRecipe.copyWith(
            instructions: ['Step 1', '', 'Step 3'],
          );
          expect(
            () => recipe.validateInstructions(),
            throwsA(isA<RecipeValidationException>()),
          );
        });
      });

      group('Times Validation', () {
        test('should reject negative prep time', () {
          final recipe = validRecipe.copyWith(prepTime: -1);
          expect(
            () => recipe.validateTimes(),
            throwsA(isA<RecipeValidationException>()),
          );
        });

        test('should reject negative cook time', () {
          final recipe = validRecipe.copyWith(cookTime: -1);
          expect(
            () => recipe.validateTimes(),
            throwsA(isA<RecipeValidationException>()),
          );
        });

        test('should reject excessive prep time', () {
          final recipe = validRecipe.copyWith(prepTime: 1441); // > 24 hours
          expect(
            () => recipe.validateTimes(),
            throwsA(isA<RecipeValidationException>()),
          );
        });

        test('should accept zero times', () {
          final recipe = validRecipe.copyWith(prepTime: 0, cookTime: 0);
          expect(() => recipe.validateTimes(), returnsNormally);
        });
      });

      group('Servings Validation', () {
        test('should reject zero servings', () {
          final recipe = validRecipe.copyWith(servings: 0);
          expect(
            () => recipe.validateServings(),
            throwsA(isA<RecipeValidationException>()),
          );
        });

        test('should reject negative servings', () {
          final recipe = validRecipe.copyWith(servings: -1);
          expect(
            () => recipe.validateServings(),
            throwsA(isA<RecipeValidationException>()),
          );
        });

        test('should reject excessive servings', () {
          final recipe = validRecipe.copyWith(servings: 101);
          expect(
            () => recipe.validateServings(),
            throwsA(isA<RecipeValidationException>()),
          );
        });
      });

      group('Tags Validation', () {
        test('should reject empty tag', () {
          final recipe = validRecipe.copyWith(tags: ['valid', '', 'another']);
          expect(
            () => recipe.validateTags(),
            throwsA(isA<RecipeValidationException>()),
          );
        });

        test('should reject tag that is too long', () {
          final longTag = 'a' * 21;
          final recipe = validRecipe.copyWith(tags: [longTag]);
          expect(
            () => recipe.validateTags(),
            throwsA(isA<RecipeValidationException>()),
          );
        });

        test('should reject tag with invalid characters', () {
          final recipe = validRecipe.copyWith(tags: ['valid@tag']);
          expect(
            () => recipe.validateTags(),
            throwsA(isA<RecipeValidationException>()),
          );
        });

        test('should reject duplicate tags', () {
          final recipe = validRecipe.copyWith(tags: ['dessert', 'Dessert']);
          expect(
            () => recipe.validateTags(),
            throwsA(isA<RecipeValidationException>()),
          );
        });

        test('should accept valid tags', () {
          final recipe = validRecipe.copyWith(
            tags: ['dessert', 'easy-recipe', 'family_favorite'],
          );
          expect(() => recipe.validateTags(), returnsNormally);
        });
      });

      group('Photo URLs Validation', () {
        test('should reject empty photo URL', () {
          final recipe = validRecipe.copyWith(photoUrls: ['']);
          expect(
            () => recipe.validatePhotoUrls(),
            throwsA(isA<RecipeValidationException>()),
          );
        });

        test('should accept valid file paths', () {
          final recipe = validRecipe.copyWith(
            photoUrls: ['/path/to/photo.jpg'],
          );
          expect(() => recipe.validatePhotoUrls(), returnsNormally);
        });

        test('should accept valid URLs', () {
          final recipe = validRecipe.copyWith(
            photoUrls: ['https://example.com/photo.jpg'],
          );
          expect(() => recipe.validatePhotoUrls(), returnsNormally);
        });
      });
    });

    group('Recipe Serialization', () {
      test('should serialize to map correctly', () {
        final map = validRecipe.toMap();

        expect(map['id'], equals(validRecipe.id));
        expect(map['title'], equals(validRecipe.title));
        expect(map['ingredients'], isA<List>());
        expect(map['instructions'], equals(validRecipe.instructions));
        expect(map['prepTime'], equals(validRecipe.prepTime));
        expect(map['cookTime'], equals(validRecipe.cookTime));
        expect(map['servings'], equals(validRecipe.servings));
        expect(map['tags'], equals(validRecipe.tags));
        expect(map['photoUrls'], equals(validRecipe.photoUrls));
        expect(map['isPrivate'], equals(validRecipe.isPrivate));
        expect(map['isPublished'], equals(validRecipe.isPublished));
        expect(map['familyId'], equals(validRecipe.familyId));
        expect(map['createdAt'], isA<String>());
        expect(map['updatedAt'], isA<String>());
      });

      test('should deserialize from map correctly', () {
        final map = validRecipe.toMap();
        final deserializedRecipe = Recipe.fromMap(map);

        expect(deserializedRecipe.id, equals(validRecipe.id));
        expect(deserializedRecipe.title, equals(validRecipe.title));
        expect(
          deserializedRecipe.ingredients.length,
          equals(validRecipe.ingredients.length),
        );
        expect(
          deserializedRecipe.instructions,
          equals(validRecipe.instructions),
        );
        expect(deserializedRecipe.prepTime, equals(validRecipe.prepTime));
        expect(deserializedRecipe.cookTime, equals(validRecipe.cookTime));
        expect(deserializedRecipe.servings, equals(validRecipe.servings));
        expect(deserializedRecipe.tags, equals(validRecipe.tags));
        expect(deserializedRecipe.photoUrls, equals(validRecipe.photoUrls));
        expect(deserializedRecipe.isPrivate, equals(validRecipe.isPrivate));
        expect(deserializedRecipe.isPublished, equals(validRecipe.isPublished));
        expect(deserializedRecipe.familyId, equals(validRecipe.familyId));
        expect(deserializedRecipe.createdAt, equals(validRecipe.createdAt));
        expect(deserializedRecipe.updatedAt, equals(validRecipe.updatedAt));
      });

      test('should handle missing optional fields in deserialization', () {
        final map = {
          'id': 'test-id',
          'title': 'Test Recipe',
          'ingredients': [
            {'name': 'Flour', 'quantity': 2.0, 'unit': 'cups'},
          ],
          'instructions': ['Mix ingredients'],
          'prepTime': 10,
          'cookTime': 20,
          'servings': 2,
          'tags': ['test'],
          'isPrivate': true,
          'isPublished': false,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        };

        final recipe = Recipe.fromMap(map);
        expect(recipe.photoUrls, isEmpty);
        expect(recipe.familyId, isEmpty);
      });
    });

    group('Recipe Utility Methods', () {
      test('should calculate total time correctly', () {
        expect(validRecipe.totalTime, equals(45)); // 15 + 30
      });

      test('should format time correctly', () {
        final recipe1 = validRecipe.copyWith(prepTime: 0, cookTime: 0);
        expect(recipe1.formattedTime, equals('No time specified'));

        final recipe2 = validRecipe.copyWith(prepTime: 30, cookTime: 0);
        expect(recipe2.formattedTime, equals('30m'));

        final recipe3 = validRecipe.copyWith(prepTime: 60, cookTime: 0);
        expect(recipe3.formattedTime, equals('1h'));

        final recipe4 = validRecipe.copyWith(prepTime: 75, cookTime: 0);
        expect(recipe4.formattedTime, equals('1h 15m'));
      });

      test('should generate summary correctly', () {
        final summary = validRecipe.summary;
        expect(summary, contains('3 ingredients'));
        expect(summary, contains('3 steps'));
        expect(summary, contains('45m'));
      });
    });

    group('Photo Validation Static Methods', () {
      test('should validate photo extensions correctly', () {
        expect(Recipe.isValidPhotoExtension('photo.jpg'), isTrue);
        expect(Recipe.isValidPhotoExtension('photo.jpeg'), isTrue);
        expect(Recipe.isValidPhotoExtension('photo.png'), isTrue);
        expect(Recipe.isValidPhotoExtension('photo.JPG'), isTrue);
        expect(Recipe.isValidPhotoExtension('photo.gif'), isFalse);
        expect(Recipe.isValidPhotoExtension('photo.bmp'), isFalse);
      });

      test('should validate photo sizes correctly', () {
        expect(Recipe.isValidPhotoSize(1024), isTrue); // 1KB
        expect(Recipe.isValidPhotoSize(5 * 1024 * 1024), isTrue); // 5MB
        expect(Recipe.isValidPhotoSize(6 * 1024 * 1024), isFalse); // 6MB
      });
    });
  });

  group('Ingredient Model Tests', () {
    late Ingredient validIngredient;

    setUp(() {
      validIngredient = Ingredient(name: 'Flour', quantity: 2.0, unit: 'cups');
    });

    group('Ingredient Creation', () {
      test('should create a valid ingredient', () {
        expect(validIngredient.name, equals('Flour'));
        expect(validIngredient.quantity, equals(2.0));
        expect(validIngredient.unit, equals('cups'));
      });
    });

    group('Ingredient Validation', () {
      test('should validate a correct ingredient', () {
        expect(() => validIngredient.validate(), returnsNormally);
        expect(validIngredient.isValid, isTrue);
      });

      test('should reject empty name', () {
        final ingredient = Ingredient(name: '', quantity: 1.0, unit: 'cup');
        expect(
          () => ingredient.validate(),
          throwsA(isA<RecipeValidationException>()),
        );
        expect(ingredient.isValid, isFalse);
      });

      test('should reject name that is too long', () {
        final longName = 'a' * 101;
        final ingredient = Ingredient(
          name: longName,
          quantity: 1.0,
          unit: 'cup',
        );
        expect(
          () => ingredient.validate(),
          throwsA(isA<RecipeValidationException>()),
        );
      });

      test('should reject zero or negative quantity', () {
        final ingredient1 = Ingredient(
          name: 'Flour',
          quantity: 0.0,
          unit: 'cup',
        );
        final ingredient2 = Ingredient(
          name: 'Flour',
          quantity: -1.0,
          unit: 'cup',
        );

        expect(
          () => ingredient1.validate(),
          throwsA(isA<RecipeValidationException>()),
        );
        expect(
          () => ingredient2.validate(),
          throwsA(isA<RecipeValidationException>()),
        );
      });

      test('should reject excessive quantity', () {
        final ingredient = Ingredient(
          name: 'Flour',
          quantity: 10001.0,
          unit: 'cup',
        );
        expect(
          () => ingredient.validate(),
          throwsA(isA<RecipeValidationException>()),
        );
      });

      test('should reject empty unit', () {
        final ingredient = Ingredient(name: 'Flour', quantity: 1.0, unit: '');
        expect(
          () => ingredient.validate(),
          throwsA(isA<RecipeValidationException>()),
        );
      });

      test('should reject unit that is too long', () {
        final longUnit = 'a' * 51;
        final ingredient = Ingredient(
          name: 'Flour',
          quantity: 1.0,
          unit: longUnit,
        );
        expect(
          () => ingredient.validate(),
          throwsA(isA<RecipeValidationException>()),
        );
      });
    });

    group('Ingredient Serialization', () {
      test('should serialize to map correctly', () {
        final map = validIngredient.toMap();

        expect(map['name'], equals('Flour'));
        expect(map['quantity'], equals(2.0));
        expect(map['unit'], equals('cups'));
      });

      test('should deserialize from map correctly', () {
        final map = {'name': 'Sugar', 'quantity': 1.5, 'unit': 'cup'};
        final ingredient = Ingredient.fromMap(map);

        expect(ingredient.name, equals('Sugar'));
        expect(ingredient.quantity, equals(1.5));
        expect(ingredient.unit, equals('cup'));
      });

      test('should handle integer quantities in deserialization', () {
        final map = {'name': 'Eggs', 'quantity': 3, 'unit': 'pieces'};
        final ingredient = Ingredient.fromMap(map);

        expect(ingredient.quantity, equals(3.0));
      });
    });

    group('Ingredient Utility Methods', () {
      test('should format ingredient correctly', () {
        final ingredient1 = Ingredient(
          name: 'Flour',
          quantity: 2.0,
          unit: 'cups',
        );
        expect(ingredient1.formatted, equals('2 cups Flour'));

        final ingredient2 = Ingredient(
          name: 'Sugar',
          quantity: 1.5,
          unit: 'cup',
        );
        expect(ingredient2.formatted, equals('1.5 cup Sugar'));
      });

      test('should copy with updated values', () {
        final updated = validIngredient.copyWith(quantity: 3.0);

        expect(updated.name, equals(validIngredient.name));
        expect(updated.quantity, equals(3.0));
        expect(updated.unit, equals(validIngredient.unit));
      });

      test('should implement equality correctly', () {
        final ingredient1 = Ingredient(
          name: 'Flour',
          quantity: 2.0,
          unit: 'cups',
        );
        final ingredient2 = Ingredient(
          name: 'Flour',
          quantity: 2.0,
          unit: 'cups',
        );
        final ingredient3 = Ingredient(
          name: 'Sugar',
          quantity: 2.0,
          unit: 'cups',
        );

        expect(ingredient1, equals(ingredient2));
        expect(ingredient1, isNot(equals(ingredient3)));
      });

      test('should implement toString correctly', () {
        expect(validIngredient.toString(), equals('2 cups Flour'));
      });
    });
  });
}
