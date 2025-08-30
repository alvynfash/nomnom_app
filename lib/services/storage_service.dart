import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/recipe.dart';

class StorageService {
  static Database? _database;
  static const String _databaseName = 'nomnom.db';
  static const int _databaseVersion = 2;

  // Table names
  static const String _recipesTable = 'recipes';
  static const String _ingredientsTable = 'ingredients';
  static const String _mealPlansTable = 'meal_plans';
  static const String _mealAssignmentsTable = 'meal_assignments';
  static const String _familyMealSlotsTable = 'family_meal_slots';

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create recipes table
    await db.execute('''
      CREATE TABLE $_recipesTable (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        instructions TEXT NOT NULL,
        prepTime INTEGER NOT NULL DEFAULT 0,
        cookTime INTEGER NOT NULL DEFAULT 0,
        servings INTEGER NOT NULL DEFAULT 1,
        tags TEXT NOT NULL DEFAULT '',
        photoUrls TEXT NOT NULL DEFAULT '',
        isPrivate INTEGER NOT NULL DEFAULT 1,
        isPublished INTEGER NOT NULL DEFAULT 0,
        familyId TEXT NOT NULL DEFAULT '',
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Create ingredients table
    await db.execute('''
      CREATE TABLE $_ingredientsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        recipeId TEXT NOT NULL,
        name TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit TEXT NOT NULL,
        FOREIGN KEY (recipeId) REFERENCES $_recipesTable (id) ON DELETE CASCADE
      )
    ''');

    // Create meal plans table
    await db.execute('''
      CREATE TABLE $_mealPlansTable (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        family_id TEXT NOT NULL,
        start_date TEXT NOT NULL,
        meal_slots TEXT NOT NULL,
        is_template INTEGER NOT NULL DEFAULT 0,
        template_name TEXT,
        template_description TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        created_by TEXT NOT NULL
      )
    ''');

    // Create meal assignments table
    await db.execute('''
      CREATE TABLE $_mealAssignmentsTable (
        id TEXT PRIMARY KEY,
        meal_plan_id TEXT NOT NULL,
        assignment_date TEXT NOT NULL,
        slot_id TEXT NOT NULL,
        recipe_id TEXT,
        FOREIGN KEY (meal_plan_id) REFERENCES $_mealPlansTable (id) ON DELETE CASCADE,
        FOREIGN KEY (recipe_id) REFERENCES $_recipesTable (id) ON DELETE SET NULL,
        UNIQUE(meal_plan_id, assignment_date, slot_id)
      )
    ''');

    // Create family meal slots table
    await db.execute('''
      CREATE TABLE $_familyMealSlotsTable (
        id TEXT PRIMARY KEY,
        family_id TEXT NOT NULL,
        slot_name TEXT NOT NULL,
        slot_order INTEGER NOT NULL,
        is_default INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Create indexes for better performance
    await db.execute(
      'CREATE INDEX idx_recipes_title ON $_recipesTable (title)',
    );
    await db.execute(
      'CREATE INDEX idx_recipes_familyId ON $_recipesTable (familyId)',
    );
    await db.execute(
      'CREATE INDEX idx_ingredients_recipeId ON $_ingredientsTable (recipeId)',
    );
    await db.execute(
      'CREATE INDEX idx_meal_plans_familyId ON $_mealPlansTable (family_id)',
    );
    await db.execute(
      'CREATE INDEX idx_meal_plans_start_date ON $_mealPlansTable (start_date)',
    );
    await db.execute(
      'CREATE INDEX idx_meal_assignments_plan_id ON $_mealAssignmentsTable (meal_plan_id)',
    );
    await db.execute(
      'CREATE INDEX idx_meal_assignments_date ON $_mealAssignmentsTable (assignment_date)',
    );
    await db.execute(
      'CREATE INDEX idx_family_meal_slots_family_id ON $_familyMealSlotsTable (family_id)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades here
    if (oldVersion < 2 && newVersion >= 2) {
      // Add meal planning tables
      await db.execute('''
        CREATE TABLE $_mealPlansTable (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          family_id TEXT NOT NULL,
          start_date TEXT NOT NULL,
          meal_slots TEXT NOT NULL,
          is_template INTEGER NOT NULL DEFAULT 0,
          template_name TEXT,
          template_description TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          created_by TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE $_mealAssignmentsTable (
          id TEXT PRIMARY KEY,
          meal_plan_id TEXT NOT NULL,
          assignment_date TEXT NOT NULL,
          slot_id TEXT NOT NULL,
          recipe_id TEXT,
          FOREIGN KEY (meal_plan_id) REFERENCES $_mealPlansTable (id) ON DELETE CASCADE,
          FOREIGN KEY (recipe_id) REFERENCES $_recipesTable (id) ON DELETE SET NULL,
          UNIQUE(meal_plan_id, assignment_date, slot_id)
        )
      ''');

      await db.execute('''
        CREATE TABLE $_familyMealSlotsTable (
          id TEXT PRIMARY KEY,
          family_id TEXT NOT NULL,
          slot_name TEXT NOT NULL,
          slot_order INTEGER NOT NULL,
          is_default INTEGER NOT NULL DEFAULT 0
        )
      ''');

      // Add indexes for new tables
      await db.execute(
        'CREATE INDEX idx_meal_plans_familyId ON $_mealPlansTable (family_id)',
      );
      await db.execute(
        'CREATE INDEX idx_meal_plans_start_date ON $_mealPlansTable (start_date)',
      );
      await db.execute(
        'CREATE INDEX idx_meal_assignments_plan_id ON $_mealAssignmentsTable (meal_plan_id)',
      );
      await db.execute(
        'CREATE INDEX idx_meal_assignments_date ON $_mealAssignmentsTable (assignment_date)',
      );
      await db.execute(
        'CREATE INDEX idx_family_meal_slots_family_id ON $_familyMealSlotsTable (family_id)',
      );
    }
  }

  Future<void> saveRecipe(Recipe recipe) async {
    final db = await database;

    await db.transaction((txn) async {
      // Insert or update recipe
      await txn.insert(
        _recipesTable,
        _recipeToMap(recipe),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Delete existing ingredients for this recipe
      await txn.delete(
        _ingredientsTable,
        where: 'recipeId = ?',
        whereArgs: [recipe.id],
      );

      // Insert ingredients
      for (final ingredient in recipe.ingredients) {
        await txn.insert(_ingredientsTable, {
          'recipeId': recipe.id,
          'name': ingredient.name,
          'quantity': ingredient.quantity,
          'unit': ingredient.unit,
        });
      }
    });
  }

  Future<List<Recipe>> loadRecipes() async {
    final db = await database;

    final recipeMaps = await db.query(_recipesTable, orderBy: 'updatedAt DESC');
    final recipes = <Recipe>[];

    for (final recipeMap in recipeMaps) {
      final ingredientMaps = await db.query(
        _ingredientsTable,
        where: 'recipeId = ?',
        whereArgs: [recipeMap['id']],
      );

      final ingredients = ingredientMaps
          .map(
            (map) => Ingredient(
              name: map['name'] as String,
              quantity: map['quantity'] as double,
              unit: map['unit'] as String,
            ),
          )
          .toList();

      recipes.add(_mapToRecipe(recipeMap, ingredients));
    }

    return recipes;
  }

  Future<Recipe?> getRecipeById(String id) async {
    final db = await database;

    final recipeMaps = await db.query(
      _recipesTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (recipeMaps.isEmpty) return null;

    final ingredientMaps = await db.query(
      _ingredientsTable,
      where: 'recipeId = ?',
      whereArgs: [id],
    );

    final ingredients = ingredientMaps
        .map(
          (map) => Ingredient(
            name: map['name'] as String,
            quantity: map['quantity'] as double,
            unit: map['unit'] as String,
          ),
        )
        .toList();

    return _mapToRecipe(recipeMaps.first, ingredients);
  }

  Future<void> deleteRecipe(String id) async {
    final db = await database;

    await db.transaction((txn) async {
      // Delete ingredients first (foreign key constraint)
      await txn.delete(
        _ingredientsTable,
        where: 'recipeId = ?',
        whereArgs: [id],
      );

      // Delete recipe
      await txn.delete(_recipesTable, where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<List<String>> getAllTags() async {
    final db = await database;

    final result = await db.query(
      _recipesTable,
      columns: ['tags'],
      where: 'tags != ?',
      whereArgs: [''],
    );

    final allTags = <String>{};
    for (final row in result) {
      final tagsString = row['tags'] as String;
      if (tagsString.isNotEmpty) {
        final tags = tagsString.split(',').map((tag) => tag.trim()).toList();
        allTags.addAll(tags);
      }
    }

    return allTags.toList()..sort();
  }

  Map<String, dynamic> _recipeToMap(Recipe recipe) {
    return {
      'id': recipe.id,
      'title': recipe.title,
      'instructions': recipe.instructions.join(
        '|||',
      ), // Use delimiter for multiple instructions
      'prepTime': recipe.prepTime,
      'cookTime': recipe.cookTime,
      'servings': recipe.servings,
      'tags': recipe.tags.join(','),
      'photoUrls': recipe.photoUrls.join(','),
      'isPrivate': recipe.isPrivate ? 1 : 0,
      'isPublished': recipe.isPublished ? 1 : 0,
      'familyId': recipe.familyId,
      'createdAt': recipe.createdAt.toIso8601String(),
      'updatedAt': recipe.updatedAt.toIso8601String(),
    };
  }

  Recipe _mapToRecipe(Map<String, dynamic> map, List<Ingredient> ingredients) {
    return Recipe(
      id: map['id'] as String,
      title: map['title'] as String,
      ingredients: ingredients,
      instructions: (map['instructions'] as String).split('|||'),
      prepTime: map['prepTime'] as int,
      cookTime: map['cookTime'] as int,
      servings: map['servings'] as int,
      tags: (map['tags'] as String).isEmpty
          ? <String>[]
          : (map['tags'] as String)
                .split(',')
                .map((tag) => tag.trim())
                .toList(),
      photoUrls: (map['photoUrls'] as String).isEmpty
          ? <String>[]
          : (map['photoUrls'] as String)
                .split(',')
                .map((url) => url.trim())
                .toList(),
      isPrivate: (map['isPrivate'] as int) == 1,
      isPublished: (map['isPublished'] as int) == 1,
      familyId: map['familyId'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  // Meal Plan storage methods
  Future<void> saveMealPlan(
    Map<String, dynamic> mealPlan,
    List<Map<String, dynamic>> assignments,
  ) async {
    final db = await database;

    await db.transaction((txn) async {
      // Insert or update meal plan
      await txn.insert(
        _mealPlansTable,
        _mealPlanToDbMap(mealPlan),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Delete existing assignments for this meal plan
      await txn.delete(
        _mealAssignmentsTable,
        where: 'meal_plan_id = ?',
        whereArgs: [mealPlan['id']],
      );

      // Insert new assignments
      for (final assignment in assignments) {
        if (assignment['recipeId'] != null) {
          await txn.insert(_mealAssignmentsTable, {
            'id':
                '${assignment['mealPlanId']}_${assignment['assignmentDate']}_${assignment['slotId']}',
            'meal_plan_id': assignment['mealPlanId'],
            'assignment_date': assignment['assignmentDate'],
            'slot_id': assignment['slotId'],
            'recipe_id': assignment['recipeId'],
          });
        }
      }
    });
  }

  Future<List<Map<String, dynamic>>> loadMealPlans({String? familyId}) async {
    final db = await database;

    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (familyId != null) {
      whereClause = 'WHERE family_id = ?';
      whereArgs = [familyId];
    }

    final mealPlanMaps = await db.rawQuery('''
      SELECT * FROM $_mealPlansTable 
      $whereClause 
      ORDER BY start_date DESC
    ''', whereArgs);

    final mealPlans = <Map<String, dynamic>>[];

    for (final mealPlanMap in mealPlanMaps) {
      // Load assignments for this meal plan
      final assignmentMaps = await db.query(
        _mealAssignmentsTable,
        where: 'meal_plan_id = ?',
        whereArgs: [mealPlanMap['id']],
      );

      // Convert assignments to the format expected by MealPlan
      final assignments = <String, String?>{};
      for (final assignmentMap in assignmentMaps) {
        final key =
            '${assignmentMap['assignment_date']}_${assignmentMap['slot_id']}';
        assignments[key] = assignmentMap['recipe_id'] as String?;
      }

      final mealPlan = _dbMapToMealPlan(mealPlanMap, assignments);
      mealPlans.add(mealPlan);
    }

    return mealPlans;
  }

  Future<Map<String, dynamic>?> getMealPlanById(String id) async {
    final db = await database;

    final mealPlanMaps = await db.query(
      _mealPlansTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (mealPlanMaps.isEmpty) return null;

    // Load assignments for this meal plan
    final assignmentMaps = await db.query(
      _mealAssignmentsTable,
      where: 'meal_plan_id = ?',
      whereArgs: [id],
    );

    // Convert assignments to the format expected by MealPlan
    final assignments = <String, String?>{};
    for (final assignmentMap in assignmentMaps) {
      final key =
          '${assignmentMap['assignment_date']}_${assignmentMap['slot_id']}';
      assignments[key] = assignmentMap['recipe_id'] as String?;
    }

    return _dbMapToMealPlan(mealPlanMaps.first, assignments);
  }

  Future<void> deleteMealPlan(String id) async {
    final db = await database;

    await db.transaction((txn) async {
      // Delete assignments first (foreign key constraint)
      await txn.delete(
        _mealAssignmentsTable,
        where: 'meal_plan_id = ?',
        whereArgs: [id],
      );

      // Delete meal plan
      await txn.delete(_mealPlansTable, where: 'id = ?', whereArgs: [id]);
    });
  }

  // Family meal slots storage methods
  Future<void> saveFamilyMealSlots(
    String familyId,
    List<Map<String, dynamic>> slots,
  ) async {
    final db = await database;

    await db.transaction((txn) async {
      // Delete existing slots for this family
      await txn.delete(
        _familyMealSlotsTable,
        where: 'family_id = ?',
        whereArgs: [familyId],
      );

      // Insert new slots
      for (final slot in slots) {
        await txn.insert(_familyMealSlotsTable, {
          'id': slot['id'],
          'family_id': familyId,
          'slot_name': slot['name'],
          'slot_order': slot['order'],
          'is_default': slot['isDefault'] ? 1 : 0,
        });
      }
    });
  }

  Future<List<Map<String, dynamic>>> loadFamilyMealSlots(
    String familyId,
  ) async {
    final db = await database;

    final slotMaps = await db.query(
      _familyMealSlotsTable,
      where: 'family_id = ?',
      whereArgs: [familyId],
      orderBy: 'slot_order ASC',
    );

    return slotMaps
        .map(
          (map) => {
            'id': map['id'],
            'name': map['slot_name'],
            'order': map['slot_order'],
            'isDefault': (map['is_default'] as int) == 1,
          },
        )
        .toList();
  }

  // Helper methods for meal plan data conversion
  Map<String, dynamic> _mealPlanToDbMap(Map<String, dynamic> mealPlan) {
    return {
      'id': mealPlan['id'],
      'name': mealPlan['name'],
      'family_id': mealPlan['familyId'],
      'start_date': mealPlan['startDate'],
      'meal_slots': (mealPlan['mealSlots'] as List<String>).join(','),
      'is_template': mealPlan['isTemplate'] ? 1 : 0,
      'template_name': mealPlan['templateName'],
      'template_description': mealPlan['templateDescription'],
      'created_at': mealPlan['createdAt'],
      'updated_at': mealPlan['updatedAt'],
      'created_by': mealPlan['createdBy'],
    };
  }

  Map<String, dynamic> _dbMapToMealPlan(
    Map<String, dynamic> dbMap,
    Map<String, String?> assignments,
  ) {
    return {
      'id': dbMap['id'],
      'name': dbMap['name'],
      'familyId': dbMap['family_id'],
      'startDate': dbMap['start_date'],
      'mealSlots': (dbMap['meal_slots'] as String).split(','),
      'assignments': assignments,
      'isTemplate': (dbMap['is_template'] as int) == 1,
      'templateName': dbMap['template_name'],
      'templateDescription': dbMap['template_description'],
      'createdAt': dbMap['created_at'],
      'updatedAt': dbMap['updated_at'],
      'createdBy': dbMap['created_by'],
    };
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
