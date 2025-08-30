# Design Document

## Overview

The Recipe Management feature builds upon the existing Flutter application architecture to provide comprehensive recipe creation, editing, and organization capabilities. The design leverages the current Model-View-Service pattern with enhancements for data persistence, search functionality, and photo management. The system maintains the existing UI/UX patterns while extending functionality to meet all requirements.

## Architecture

The recipe management system follows a layered architecture pattern:

- **Presentation Layer**: Flutter widgets and screens for user interaction
- **Service Layer**: Business logic and data operations
- **Model Layer**: Data structures and validation
- **Storage Layer**: Local data persistence (to be implemented)

### Key Architectural Decisions

1. **State Management**: Continue using StatefulWidget pattern for simplicity, with potential future migration to Provider or Riverpod
2. **Data Persistence**: Implement local storage using shared_preferences for simple data and sqflite for complex recipe data
3. **Image Handling**: Use image_picker for photo capture/selection and path_provider for local storage
4. **Search Implementation**: In-memory filtering with future database indexing support

## Components and Interfaces

### Core Models

#### Recipe Model (Enhanced)
```dart
class Recipe {
  final String id;
  final String title;
  final List<Ingredient> ingredients;
  final List<String> instructions;
  final int prepTime;
  final int cookTime;
  final int servings;
  final List<String> tags;
  final List<String> photoUrls; // New field
  final bool isPrivate;
  final bool isPublished;
  final String familyId; // New field for family sharing
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

#### Ingredient Model (Existing)
```dart
class Ingredient {
  final String name;
  final double quantity;
  final String unit;
}
```

### Service Layer

#### RecipeService (Enhanced)
```dart
class RecipeService {
  // CRUD operations
  Future<List<Recipe>> getRecipes({String? searchQuery, List<String>? tagFilters});
  Future<Recipe> createRecipe(Recipe recipe);
  Future<Recipe> updateRecipe(String id, Recipe updatedRecipe);
  Future<void> deleteRecipe(String id);
  Future<Recipe?> getRecipeById(String id);
  
  // New methods
  Future<List<String>> getAllTags();
  Future<List<Recipe>> searchRecipes(String query);
  Future<void> validateRecipeForDeletion(String id);
}
```

#### PhotoService (New)
```dart
class PhotoService {
  Future<String> saveRecipePhoto(String recipeId, File imageFile);
  Future<void> deleteRecipePhoto(String photoUrl);
  Future<List<String>> getRecipePhotos(String recipeId);
}
```

#### StorageService (New)
```dart
class StorageService {
  Future<void> saveRecipe(Recipe recipe);
  Future<List<Recipe>> loadRecipes();
  Future<void> deleteRecipe(String id);
  Future<Recipe?> getRecipeById(String id);
}
```

### Presentation Layer

#### RecipeListScreen (Enhanced)
- Add search bar with real-time filtering
- Implement tag-based filtering
- Add photo thumbnails in list view
- Enhance empty state with onboarding guidance

#### RecipeEditScreen (Enhanced)
- Add photo upload/management section
- Implement tag autocomplete
- Add form validation with better error handling
- Include save confirmation dialogs

#### RecipeDetailScreen (New)
- Full recipe view with photos
- Print/share functionality
- Navigation to edit mode

### UI Components

#### PhotoUploadWidget (New)
```dart
class PhotoUploadWidget extends StatefulWidget {
  final List<String> photoUrls;
  final Function(List<String>) onPhotosChanged;
}
```

#### TagInputWidget (New)
```dart
class TagInputWidget extends StatefulWidget {
  final List<String> selectedTags;
  final List<String> availableTags;
  final Function(List<String>) onTagsChanged;
}
```

#### SearchBarWidget (New)
```dart
class SearchBarWidget extends StatefulWidget {
  final Function(String) onSearchChanged;
  final Function(List<String>) onTagFiltersChanged;
}
```

## Data Models

### Recipe Storage Schema
```json
{
  "id": "string",
  "title": "string",
  "ingredients": [
    {
      "name": "string",
      "quantity": "number",
      "unit": "string"
    }
  ],
  "instructions": ["string"],
  "prepTime": "number",
  "cookTime": "number",
  "servings": "number",
  "tags": ["string"],
  "photoUrls": ["string"],
  "isPrivate": "boolean",
  "isPublished": "boolean",
  "familyId": "string",
  "createdAt": "ISO8601 string",
  "updatedAt": "ISO8601 string"
}
```

### Local Storage Structure
- **Recipes**: SQLite database for structured data and complex queries
- **Photos**: Local file system with organized directory structure
- **Tags**: Cached in shared_preferences for quick access
- **User Preferences**: shared_preferences for UI state

## Error Handling

### Validation Rules
1. **Recipe Title**: Required, 1-100 characters
2. **Ingredients**: At least one ingredient required
3. **Instructions**: At least one instruction step required
4. **Numeric Fields**: Non-negative integers for times and servings
5. **Photos**: Valid image formats (jpg, png), max 5MB per image
6. **Tags**: Alphanumeric characters, max 20 characters per tag

### Error Scenarios
- **Network Issues**: Graceful offline mode with local storage
- **Storage Full**: Clear error messages with cleanup suggestions
- **Invalid Data**: Field-level validation with helpful error messages
- **Photo Upload Failures**: Retry mechanisms and fallback options
- **Deletion Conflicts**: Warning dialogs when recipes are used in meal plans

### Error Recovery
- Auto-save drafts during recipe editing
- Backup and restore functionality
- Data validation before save operations
- Graceful degradation when features are unavailable

## Testing Strategy

### Unit Tests
- Model serialization/deserialization
- Service layer business logic
- Validation functions
- Search and filtering algorithms

### Widget Tests
- Form validation behavior
- User interaction flows
- State management correctness
- Error handling UI responses

### Integration Tests
- End-to-end recipe creation flow
- Photo upload and management
- Search and filtering functionality
- Data persistence across app restarts

### Test Data Strategy
- Mock recipe data for consistent testing
- Test image assets for photo functionality
- Edge case scenarios (empty lists, invalid data)
- Performance testing with large recipe collections

### Testing Tools
- Flutter's built-in testing framework
- mockito for service mocking
- golden_toolkit for UI regression testing
- integration_test for end-to-end scenarios