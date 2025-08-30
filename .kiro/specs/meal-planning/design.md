# Design Document

## Overview

The Meal Planning feature extends the NomNom application with comprehensive meal scheduling capabilities. Building on the existing recipe management system, this feature provides a structured 4-week calendar interface for meal organization, template creation, and family collaboration. The design maintains consistency with the existing Flutter architecture while introducing new components for calendar management, template storage, and collaborative meal planning.

## Architecture

The meal planning system follows the established layered architecture:

- **Presentation Layer**: Calendar widgets, meal slot components, and template management screens
- **Service Layer**: Meal plan operations, template management, and family collaboration logic
- **Model Layer**: Meal plan data structures, calendar utilities, and validation
- **Storage Layer**: Extended database schema for meal plans and templates

### Key Architectural Decisions

1. **Calendar Management**: Use Flutter's built-in DateTime utilities with custom calendar widgets for 4-week views
2. **Template Storage**: Extend SQLite schema to store reusable meal plan templates separately from active plans
3. **Family Collaboration**: Leverage existing family system with role-based permissions for meal plan access
4. **Recipe Integration**: Deep integration with existing RecipeService for seamless recipe assignment
5. **State Management**: Continue StatefulWidget pattern with potential Provider integration for complex state

## Components and Interfaces

### Core Models

#### MealPlan Model
```dart
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
}
```

#### MealSlot Model
```dart
class MealSlot {
  final String id;
  final String name;
  final int order;
  final bool isDefault;
}
```

#### MealAssignment Model
```dart
class MealAssignment {
  final String mealPlanId;
  final DateTime date;
  final String slotId;
  final String? recipeId;
  final Recipe? recipe; // Populated when loaded
}
```

### Service Layer

#### MealPlanService
```dart
class MealPlanService {
  // CRUD operations
  Future<List<MealPlan>> getMealPlans({String? familyId});
  Future<MealPlan> createMealPlan(MealPlan mealPlan);
  Future<MealPlan> updateMealPlan(String id, MealPlan updatedPlan);
  Future<void> deleteMealPlan(String id);
  Future<MealPlan?> getMealPlanById(String id);
  
  // Assignment operations
  Future<void> assignRecipeToSlot(String planId, DateTime date, String slotId, String recipeId);
  Future<void> removeRecipeFromSlot(String planId, DateTime date, String slotId);
  Future<List<MealAssignment>> getMealAssignments(String planId);
  
  // Template operations
  Future<MealPlan> saveAsTemplate(String planId, String templateName, String? description);
  Future<List<MealPlan>> getTemplates({String? familyId});
  Future<MealPlan> applyTemplate(String templateId, DateTime startDate);
  
  // Calendar utilities
  List<DateTime> generateWeekDates(DateTime startDate, int weekNumber);
  List<DateTime> generateFourWeekDates(DateTime startDate);
  String generateAssignmentKey(DateTime date, String slotId);
}
```

#### MealSlotService
```dart
class MealSlotService {
  Future<List<MealSlot>> getDefaultMealSlots();
  Future<List<MealSlot>> getFamilyMealSlots(String familyId);
  Future<void> updateFamilyMealSlots(String familyId, List<MealSlot> slots);
}
```

### Presentation Layer

#### MealPlanScreen
- Main meal planning interface with 4-week calendar view
- Week navigation and date display
- Meal slot configuration
- Recipe assignment interface

#### MealPlanCalendarWidget
```dart
class MealPlanCalendarWidget extends StatefulWidget {
  final MealPlan mealPlan;
  final int currentWeek;
  final Function(DateTime, String) onSlotTap;
  final Function(int) onWeekChanged;
}
```

#### MealSlotWidget
```dart
class MealSlotWidget extends StatefulWidget {
  final DateTime date;
  final MealSlot slot;
  final Recipe? assignedRecipe;
  final VoidCallback onTap;
  final bool isEditable;
}
```

#### RecipeSelectionDialog
```dart
class RecipeSelectionDialog extends StatefulWidget {
  final List<Recipe> availableRecipes;
  final Function(Recipe?) onRecipeSelected;
  final String? currentRecipeId;
}
```

#### TemplateManagementScreen
- Template creation and naming interface
- Template library with search and filtering
- Template application with date selection

#### MealPlanTemplateWidget
```dart
class MealPlanTemplateWidget extends StatefulWidget {
  final MealPlan template;
  final VoidCallback onApply;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
}
```

## Data Models

### Database Schema Extensions

#### meal_plans Table
```sql
CREATE TABLE meal_plans (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  family_id TEXT NOT NULL,
  start_date TEXT NOT NULL,
  meal_slots TEXT NOT NULL, -- JSON array
  is_template INTEGER NOT NULL DEFAULT 0,
  template_name TEXT,
  template_description TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  created_by TEXT NOT NULL
);
```

#### meal_assignments Table
```sql
CREATE TABLE meal_assignments (
  id TEXT PRIMARY KEY,
  meal_plan_id TEXT NOT NULL,
  assignment_date TEXT NOT NULL,
  slot_id TEXT NOT NULL,
  recipe_id TEXT,
  FOREIGN KEY (meal_plan_id) REFERENCES meal_plans (id),
  FOREIGN KEY (recipe_id) REFERENCES recipes (id),
  UNIQUE(meal_plan_id, assignment_date, slot_id)
);
```

#### family_meal_slots Table
```sql
CREATE TABLE family_meal_slots (
  id TEXT PRIMARY KEY,
  family_id TEXT NOT NULL,
  slot_name TEXT NOT NULL,
  slot_order INTEGER NOT NULL,
  is_default INTEGER NOT NULL DEFAULT 0
);
```

### JSON Storage Formats

#### Meal Slots Configuration
```json
[
  {
    "id": "breakfast",
    "name": "Breakfast",
    "order": 1,
    "isDefault": true
  },
  {
    "id": "lunch", 
    "name": "Lunch",
    "order": 2,
    "isDefault": true
  }
]
```

## Error Handling

### Validation Rules
1. **Meal Plan Name**: Required, 1-50 characters
2. **Start Date**: Must be a valid date, cannot be more than 1 year in the past
3. **Meal Slots**: At least one slot required, maximum 8 slots per plan
4. **Recipe Assignments**: Recipe must exist and be accessible to family
5. **Template Names**: Required when saving templates, must be unique per family

### Error Scenarios
- **Date Conflicts**: Handle overlapping meal plans gracefully
- **Recipe Deletion**: Update meal plans when assigned recipes are deleted
- **Family Permission Changes**: Handle access changes to meal plans
- **Template Application**: Validate date ranges and handle calendar edge cases
- **Concurrent Editing**: Handle multiple family members editing simultaneously

### Error Recovery
- Auto-save meal plan changes during editing
- Backup meal plans before major operations
- Graceful degradation when recipes become unavailable
- Clear error messages for validation failures

## Testing Strategy

### Unit Tests
- MealPlan model serialization and validation
- Date calculation utilities for 4-week periods
- Template creation and application logic
- Permission validation for family roles

### Widget Tests
- Calendar widget navigation and display
- Meal slot interaction and recipe assignment
- Template management interface
- Error handling and validation feedback

### Integration Tests
- End-to-end meal plan creation and editing
- Template saving and application workflows
- Family collaboration and permission enforcement
- Recipe integration and assignment flows

### Test Data Strategy
- Mock meal plan data with various configurations
- Test date ranges including edge cases (month boundaries, leap years)
- Family permission scenarios with different roles
- Recipe assignment and removal scenarios